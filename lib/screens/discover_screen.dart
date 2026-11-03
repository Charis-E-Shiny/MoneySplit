import 'package:flutter/material.dart';
import '../data/deals.dart';
import '../models.dart';
import '../services/optimizer.dart';
import '../theme.dart';
import '../widgets.dart';
import 'optimizer_screen.dart';

class DiscoverScreen extends StatefulWidget {
  final Group group;
  const DiscoverScreen({super.key, required this.group});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String _tab = 'All';
  String _q = '';
  bool _searching = false;
  final _search = TextEditingController();

  static const _tabs = [('All', Icons.grid_view_rounded), ('Travel', Icons.flight), ('Food', Icons.restaurant)];

  List<Color> _grad(String c) {
    switch (c) {
      case 'Travel':
        return const [Color(0xFF0E7490), Color(0xFF67E8F9)];
      case 'Food':
        return const [Color(0xFF7C2D12), Color(0xFFFBBF24)];
      default:
        return const [Color(0xFF4C1D95), Color(0xFFC4B5FD)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final deals = sampleDeals.where((d) {
      final okTab = _tab == 'All' || d.category == _tab;
      final q = _q.trim().toLowerCase();
      final okQ = q.isEmpty || d.title.toLowerCase().contains(q) || d.merchant.toLowerCase().contains(q);
      return okTab && okQ;
    }).toList();

    double bestSave(Deal d) => Optimizer.compare(amount: d.price, category: d.category).first.savings;
    final travelSave = sampleDeals.where((d) => d.category == 'Travel').fold(0.0, (a, d) => a + bestSave(d));

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).maybePop()),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('DISCOVER', style: bs(11, w: FontWeight.w800, c: PV.green)),
                  Text('Deals for Your Group', style: hs(24)),
                ]),
              ),
              IconButton(
                style: IconButton.styleFrom(backgroundColor: PV.chip),
                icon: Icon(_searching ? Icons.close : Icons.search),
                onPressed: () => setState(() {
                  _searching = !_searching;
                  if (!_searching) {
                    _q = '';
                    _search.clear();
                  }
                }),
              ),
            ]),
          ),
          if (_searching)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: PvField(controller: _search, hint: 'What are you buying?', icon: Icons.search, onChanged: (v) => setState(() => _q = v)),
            ),
          Row(children: [
            for (final t in _tabs)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tab = t.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _tab == t.$1 ? PV.navy : PV.border, width: 2))),
                    child: Icon(t.$2, color: _tab == t.$1 ? PV.navy : PV.muted),
                  ),
                ),
              ),
          ]),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(20), children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: PV.slate, borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('AI Suggestion', style: bs(12, w: FontWeight.w700, c: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Your group can save ${inr(travelSave)} more on Travel bookings this week.',
                      style: bs(14, c: Colors.white).copyWith(height: 1.35)),
                ]),
              ),
              const SizedBox(height: 16),
              if (deals.isEmpty)
                Padding(padding: const EdgeInsets.all(30), child: Center(child: Text('No deals match your search.', style: bs(14, c: PV.muted)))),
              for (final d in deals) _dealCard(context, d),
              Text('Sample deals for the demo. Connect a real deals source in lib/data/deals.dart.', style: bs(11, c: PV.muted)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _dealCard(BuildContext context, Deal d) {
    final best = Optimizer.compare(amount: d.price, category: d.category).first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: PvCard(
        padding: EdgeInsets.zero,
        radius: 24,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              height: 150,
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _grad(d.category))),
              child: Stack(children: [
                Center(child: Icon(catIcon(d.category), size: 76, color: Colors.white.withOpacity(0.35))),
                Positioned(top: 14, right: 14, child: Pill(d.badge, bg: PV.green)),
                Positioned(
                  left: 14, bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.storefront, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(d.merchant, style: bs(12, w: FontWeight.w700, c: Colors.white)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d.title, style: hs(17)),
                    const SizedBox(height: 3),
                    Text(best.savings > 0 ? 'Effective Price via ${best.name}' : 'Standard price', style: bs(11, c: PV.muted)),
                  ]),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(inr(best.effective), style: hs(21)),
                  if (best.savings > 0) Text('Save ${inr(best.savings)}', style: bs(11, w: FontWeight.w700, c: PV.green)),
                ]),
              ]),
              const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1)),
              Row(children: [
                const Icon(Icons.local_offer, size: 16, color: PV.green),
                const SizedBox(width: 8),
                Expanded(child: Text('Group Deal', style: bs(12, c: PV.muted))),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => OptimizerScreen(group: widget.group, title: d.title, merchant: d.merchant, category: d.category, amount: d.price),
                  )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PV.navy, foregroundColor: Colors.white, elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('View Deal', style: bs(13, w: FontWeight.w700, c: Colors.white)),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
