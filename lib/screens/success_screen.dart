import 'package:flutter/material.dart';
import '../models.dart';
import '../services/db_service.dart';
import '../theme.dart';
import '../widgets.dart';

class SuccessScreen extends StatelessWidget {
  final String groupId, txnDocId;
  const SuccessScreen({super.key, required this.groupId, required this.txnDocId});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: FutureBuilder<List<Object?>>(
            future: Future.wait<Object?>([Db.groupOnce(groupId), Db.txnOnce(groupId, txnDocId)]),
            builder: (context, snap) {
              if (!snap.hasData) {
                return Center(child: snap.hasError
                    ? Text('Could not load receipt.', style: bs(14, c: PV.red))
                    : const CircularProgressIndicator(color: PV.navy));
              }
              final g = snap.data![0] as Group?;
              final t = snap.data![1] as Txn?;
              if (g == null || t == null) return Center(child: Text('Receipt not found.', style: bs(14, c: PV.muted)));
              final n = g.members.length;
              final base = (t.paid * 100).floor() ~/ (n == 0 ? 1 : n);
              var extra = (t.paid * 100).round() - base * n;
              final shares = <double>[];
              for (var i = 0; i < n; i++) {
                shares.add((base + (extra > 0 ? 1 : 0)) / 100);
                if (extra > 0) extra--;
              }

              return Column(children: [
                Expanded(
                  child: ListView(padding: const EdgeInsets.all(18), children: [
                    PvCard(
                      radius: 26,
                      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
                      child: Column(children: [
                        Container(
                          width: 82, height: 82,
                          decoration: const BoxDecoration(color: PV.green, shape: BoxShape.circle),
                          child: const Icon(Icons.check, color: Colors.white, size: 46),
                        ),
                        const SizedBox(height: 14),
                        Text('Payment Successful', style: hs(24), textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text(t.title, style: bs(15, c: PV.muted), textAlign: TextAlign.center),
                        Text(fmtDate(t.date), style: bs(11, w: FontWeight.w600, c: PV.muted)),
                        const SizedBox(height: 16),
                        if (t.saved > 0) Pill('Group Saved ${inr(t.saved)}', fg: PV.green, bg: PV.mint, icon: Icons.trending_down),
                      ]),
                    ),
                    sectionTitle('Transaction Details'),
                    PvCard(
                      radius: 22,
                      child: Column(children: [
                        _row('Original Amount', Text(inr(t.original), style: bs(14, w: FontWeight.w600).copyWith(decoration: TextDecoration.lineThrough))),
                        _row('Optimized Payment', Text(inr(t.paid), style: hs(15))),
                        _row('Method', Text(t.method, style: bs(14, w: FontWeight.w600))),
                        const Divider(height: 22),
                        _row('Transaction ID', Text(t.txnCode, style: bs(13, w: FontWeight.w700, c: PV.muted))),
                      ]),
                    ),
                    sectionTitle('Auto-Split Breakdown', trailing: const Pill('Equal Split', fg: PV.ink, bg: Colors.white, icon: Icons.check)),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFFE9EEF5), borderRadius: BorderRadius.circular(14)),
                      child: Row(children: [
                        const Icon(Icons.info_outline, size: 18, color: PV.muted),
                        const SizedBox(width: 10),
                        Expanded(child: Text('${inr(t.paid)} is being split equally among $n members of ${g.name}.', style: bs(12, c: PV.muted))),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < n; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PvCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(children: [
                            Avatar(g.members[i].initial, size: 42),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(g.members[i].uid == Db.uid ? '${g.members[i].name} (You)' : g.members[i].name, style: hs(14)),
                                Text(g.members[i].role, style: bs(11, c: PV.muted)),
                              ]),
                            ),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(inr(shares[i], decimals: shares[i] % 1 != 0), style: hs(16)),
                              Text('Share', style: bs(10, c: PV.muted)),
                            ]),
                          ]),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text('Payments are simulated in demo mode (PAYMENT_MODE in .env).', textAlign: TextAlign.center, style: bs(11, c: PV.muted)),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
                  child: PrimaryButton(label: 'Done', onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
                ),
              ]);
            },
          ),
        ),
      );

  Widget _row(String l, Widget v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: bs(13, c: PV.muted)), v]),
      );
}
