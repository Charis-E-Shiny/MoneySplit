import 'dart:convert';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../models.dart';
import '../theme.dart';
import 'optimizer.dart';

class ChatMsg {
  final bool fromUser;
  final String text;
  final DateTime time;
  ChatMsg(this.fromUser, this.text) : time = DateTime.now();
}

/// "Ask Paisa Vasool". Uses Gemini when GEMINI_API_KEY is set,
/// otherwise answers offline using the optimizer rules.
class AiService {
  static String _system(Group g) {
    final rules = offerRules
        .map((r) => '- ${r.name} (${r.subtitle}): ${r.pct}% off, max ${inr(r.cap)}, min bill ${inr(r.min)}')
        .join('\n');
    final members = g.members.map((m) => '${m.name} (${inr(m.contributed)})').join(', ');
    return 'You are "Paisa Vasool", a concise finance assistant inside a group-wallet app for Indian users. '
        'Always use the rupee symbol and Indian number formatting. Be brief (under 120 words). '
        'Never invent offers beyond the list below; if unsure, say so.\n\n'
        'Group: ${g.name} (${g.category}), ${g.memberIds.length} members: $members.\n'
        'Pool balance: ${inr(g.balance)}. Contributed: ${inr(g.contributed)}. Spent: ${inr(g.spent)}. '
        'Total saved via optimized payments: ${inr(g.saved)}. Budget limit: ${inr(g.budgetLimit)}.\n\n'
        'Payment offer rules available:\n$rules';
  }

  static Future<String> ask(Group g, List<ChatMsg> history, String prompt) async {
    if (!Env.hasGemini) return _local(g, prompt);
    try {
      return await _gemini(g, history, prompt);
    } catch (e) {
      return 'I could not reach the AI service (${e.toString().replaceFirst('Exception: ', '')}). '
          'Here is what I can tell you offline:\n\n${_local(g, prompt)}';
    }
  }

  static Future<String> _gemini(Group g, List<ChatMsg> history, String prompt) async {
    final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/${Env.geminiModel}:generateContent');
    final contents = <Map<String, dynamic>>[
      for (final m in history)
        {'role': m.fromUser ? 'user' : 'model', 'parts': [{'text': m.text}]},
      {'role': 'user', 'parts': [{'text': prompt}]},
    ];
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json', 'x-goog-api-key': Env.geminiApiKey},
          body: jsonEncode({
            'systemInstruction': {'parts': [{'text': _system(g)}]},
            'contents': contents,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw Exception('error ${res.statusCode}');
    }
    final data = jsonDecode(res.body);
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
    if (text is! String || text.trim().isEmpty) throw Exception('empty reply');
    return text.trim();
  }

  // ---------- offline assistant ----------
  static String _local(Group g, String prompt) {
    final p = prompt.toLowerCase();
    final m = RegExp(r'(\d[\d,]*(?:\.\d+)?)').firstMatch(p.replaceAll('₹', ''));
    final amount = m == null ? null : double.tryParse(m.group(1)!.replaceAll(',', ''));
    var cat = 'Other';
    if (RegExp(r'dinner|lunch|food|restaurant|brunch|cafe').hasMatch(p)) cat = 'Food';
    if (RegExp(r'hotel|flight|trip|travel|stay|resort|train').hasMatch(p)) cat = 'Travel';

    if (amount != null && amount >= 100 && RegExp(r'pay|cheap|deal|book|best|hotel|flight|dinner|bill').hasMatch(p)) {
      final opts = Optimizer.compare(amount: amount, category: cat);
      final lines = [
        for (var i = 0; i < opts.length; i++) '${i + 1}. ${opts[i].name}: ${inr(opts[i].effective)}'
      ].join('\n');
      final best = opts.first;
      return 'I compared ${opts.length} payment options for ${inr(amount)}:\n$lines\n\n'
          '${best.savings > 0 ? 'Best pick: ${best.name}, saving ${inr(best.savings)}.' : 'No offer applies to this amount, so paying directly is fine.'}'
          '${g.balance < best.effective ? '\nNote: your pool has ${inr(g.balance)}, so add ${inr(best.effective - g.balance)} first.' : ''}';
    }
    if (p.contains('save') || p.contains('saving')) {
      return 'Your "${g.name}" group has saved ${inr(g.saved)} so far by paying through optimized methods. '
          'Open Group Savings for the monthly trend.';
    }
    if (RegExp(r'dinner|food|restaurant|lunch').hasMatch(p)) {
      final r = offerRules.first;
      return 'For dinner bills, ${r.name} gives ${r.pct}% off (up to ${inr(r.cap)}) when the bill is ${inr(r.min)} or more. '
          'Tell me the bill amount and I will compare every option.';
    }
    if (p.contains('balance') || p.contains('pool') || p.contains('budget')) {
      return 'Pool balance: ${inr(g.balance)}. Spent ${inr(g.spent)} of your ${inr(g.budgetLimit)} budget. '
          'Pending approvals: ${inr(g.pendingAmount)}.';
    }
    return 'I can compare payment options (try "cheapest way to pay ₹8,000 for a hotel"), '
        'show how much you saved, or check your pool balance. '
        '${Env.hasGemini ? '' : '(Add a GEMINI_API_KEY in .env for full AI answers.)'}';
  }
}
