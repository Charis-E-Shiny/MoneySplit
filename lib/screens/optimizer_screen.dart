import 'package:flutter/material.dart';
import '../models.dart';
import '../services/db_service.dart';
import '../services/optimizer.dart';
import '../theme.dart';
import '../widgets.dart';
import 'approval_screen.dart';

class OptimizerScreen extends StatefulWidget {
  final Group group;
  final String title, merchant, category;
  final double amount;
  const OptimizerScreen({
    super.key, required this.group, required this.title, required this.merchant,
    required this.category, required this.amount,
  });
  @override
  State<OptimizerScreen> createState() => _OptimizerScreenState();
}

class _OptimizerScreenState extends State<OptimizerScreen> {
  late final List<PayOption> _opts = Optimizer.compare(amount: widget.amount, category: widget.category);
  int _sel = 0;
  bool _busy = false;

  Future<void> _request() async {
    setState(() => _busy = true);
    try {
      final id = await Db.createRequest(
        widget.group,
        title: widget.title,
        merchant: widget.merchant,
        category: widget.category,
        original: widget.amount,
        option: _opts[_sel],
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ApprovalScreen(groupId: widget.group.id, requestId: id)),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        toast(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sel = _opts[_sel];
    final short = widget.group.balance < sel.effective;
    return Scaffold(
      body: Column(children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 8, 20, 24),
          decoration: const BoxDecoration(
            color: PV.navy,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.of(context).maybePop()),
              const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.auto_awesome, color: PV.amber)),
            ]),
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PAYMENT OPTIMIZER', style: hs(14, c: PV.amber)),
                const SizedBox(height: 6),
                Text('Find the cheapest way for your group to pay.', style: bs(13, c: Colors.white)),
              ]),
            ),
          ]),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            PvCard(
              radius: 22,
              child: Row(children: [
                IconBox(catIcon(widget.category), bg: catColor(widget.category), size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.title, style: hs(16)),
                    Text('${widget.merchant} • ${widget.group.name}', style: bs(11, c: PV.muted)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Original', style: bs(10, c: PV.muted)),
                  Text(inr(widget.amount), style: hs(17)),
                ]),
              ]),
            ),
            sectionTitle('Compare Options', trailing: Pill('${_opts.length} Methods', fg: PV.muted, bg: PV.chip)),
            for (var i = 0; i < _opts.length; i++) _optionCard(i),
            if (short)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFFFF4D6), borderRadius: BorderRadius.circular(14)),
                child: Text(
                  'Your pool has ${inr(widget.group.balance)}. You can still request approval, but add ${inr(sel.effective - widget.group.balance)} before paying.',
                  style: bs(12, c: const Color(0xFF8A5A00)),
                ),
              ),
          ]),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: PrimaryButton(label: 'Request Group Approval • ${inr(sel.effective)}', loading: _busy, onPressed: _request),
          ),
        ),
      ]),
    );
  }

  Widget _optionCard(int i) {
    final o = _opts[i];
    final on = i == _sel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: PvCard(
        radius: 22,
        borderColor: on ? PV.green : PV.border,
        onTap: () => setState(() => _sel = i),
        child: Column(children: [
          Row(children: [
            IconBox(o.icon, bg: on ? PV.mint : PV.chip, fg: on ? PV.green : PV.navy, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(o.name, style: hs(16)),
                Text(o.subtitle, style: bs(11, c: PV.muted)),
              ]),
            ),
            if (o.isBest) const Pill('BEST VALUE'),
          ]),
          const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1)),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Effective Cost', style: bs(10, c: PV.muted)),
              Text(inr(o.effective), style: hs(24)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Savings', style: bs(10, c: PV.muted)),
              Text(inr(o.savings), style: hs(18, c: o.savings > 0 ? PV.green : PV.muted)),
            ]),
          ]),
        ]),
      ),
    );
  }
}
