import 'package:flutter/material.dart';
import '../models.dart';
import '../services/ai_service.dart';
import '../services/db_service.dart';
import '../theme.dart';
import '../widgets.dart';

class ChatScreen extends StatefulWidget {
  final List<Group> groups;
  const ChatScreen({super.key, required this.groups});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _msgs = <ChatMsg>[];
  int _gi = 0;
  bool _busy = false;

  Group get _g => widget.groups[_gi];

  @override
  void initState() {
    super.initState();
    _greet();
  }

  void _greet() {
    final first = Db.userName.split(' ').first;
    _msgs
      ..clear()
      ..add(ChatMsg(false,
          "Hi $first! I've analyzed your '${_g.name}' pool. You have ${inr(_g.balance)} available. Would you like me to find the best deal for your upcoming booking?"));
  }

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty || _busy) return;
    // history = everything after the greeting (Gemini needs the first turn to be the user's)
    final history = List<ChatMsg>.from(_msgs.skip(1));
    setState(() {
      _msgs.add(ChatMsg(true, t));
      _busy = true;
      _ctrl.clear();
    });
    _toEnd();
    final reply = await AiService.ask(_g, history, t);
    if (!mounted) return;
    setState(() {
      _msgs.add(ChatMsg(false, reply));
      _busy = false;
    });
    _toEnd();
  }

  void _toEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent + 120, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        }
      });

  String _time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '${h.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  Widget _spark({double size = 38}) => Container(
        width: size, height: size,
        decoration: const BoxDecoration(color: PV.green, shape: BoxShape.circle),
        child: Icon(Icons.auto_awesome, color: Colors.white, size: size * 0.5),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(children: [
            Container(
              color: Colors.white,
              child: TopBar(
                title: 'Ask Paisa Vasool',
                subtitle: 'Always active for ${_g.name}',
                right: widget.groups.length > 1
                    ? PopupMenuButton<int>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (i) => setState(() {
                          _gi = i;
                          _greet();
                        }),
                        itemBuilder: (_) => [
                          for (var i = 0; i < widget.groups.length; i++)
                            PopupMenuItem(value: i, child: Text(widget.groups[i].name)),
                        ],
                      )
                    : null,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(controller: _scroll, padding: const EdgeInsets.all(18), children: [
                Center(child: _spark(size: 72)),
                const SizedBox(height: 10),
                Center(child: Text('Smart Finance Assistant', style: hs(17))),
                const SizedBox(height: 4),
                Center(child: Text('Ask me about group savings, deals, or transaction optimizations.',
                    textAlign: TextAlign.center, style: bs(12, c: PV.muted))),
                const SizedBox(height: 22),
                for (final m in _msgs) _bubble(m),
                if (_busy)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(children: [
                      _spark(),
                      const SizedBox(width: 10),
                      Text('Thinking…', style: bs(13, c: PV.muted)),
                    ]),
                  ),
              ]),
            ),
            SizedBox(
              height: 46,
              child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 14), children: [
                _quick(Icons.local_offer, 'Best deal for Dinner?'),
                _quick(Icons.trending_up, 'How much did we save?'),
                _quick(Icons.account_balance_wallet_outlined, "What's our pool balance?"),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onSubmitted: _send,
                    textInputAction: TextInputAction.send,
                    style: bs(14),
                    decoration: InputDecoration(
                      hintText: 'Ask anything about your group money…',
                      hintStyle: bs(13, c: const Color(0xFF9AA5B4)),
                      filled: true, fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: PV.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: PV.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: PV.navy)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _send(_ctrl.text),
                  child: Container(
                    width: 50, height: 50,
                    decoration: const BoxDecoration(color: PV.navy, shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      );

  Widget _quick(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => _send(text),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: PV.border)),
            child: Row(children: [
              Icon(icon, size: 15, color: PV.green),
              const SizedBox(width: 6),
              Text(text, style: bs(12, w: FontWeight.w600)),
            ]),
          ),
        ),
      );

  Widget _bubble(ChatMsg m) {
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: m.fromUser ? PV.navy : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: m.fromUser ? null : Border.all(color: PV.border),
      ),
      child: Text(m.text, style: bs(14, c: m.fromUser ? Colors.white : PV.ink).copyWith(height: 1.4)),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: m.fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: m.fromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!m.fromUser) ...[_spark(), const SizedBox(width: 10)],
            Flexible(child: bubble),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(top: 4, left: m.fromUser ? 0 : 48),
          child: Text(_time(m.time), style: bs(10, c: PV.muted)),
        ),
      ]),
    );
  }
}
