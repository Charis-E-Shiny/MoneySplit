import 'package:flutter/material.dart';
import '../models.dart';
import '../services/db_service.dart';
import '../theme.dart';
import '../widgets.dart';
import 'success_screen.dart';

class ApprovalScreen extends StatefulWidget {
  final String groupId, requestId;
  const ApprovalScreen({super.key, required this.groupId, required this.requestId});
  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  bool _busy = false;

  Future<void> _run(Future<String?> Function() job) async {
    setState(() => _busy = true);
    try {
      final txnId = await job();
      if (txnId != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => SuccessScreen(groupId: widget.groupId, txnDocId: txnId)),
        );
        return;
      }
    } catch (e) {
      if (mounted) toast(context, e.toString());
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<Group?>(
        stream: Db.group(widget.groupId),
        builder: (context, gs) => StreamBuilder<PayRequest?>(
          stream: Db.request(widget.groupId, widget.requestId),
          builder: (context, rs) {
            final g = gs.data;
            final r = rs.data;
            if (g == null || r == null) {
              return const Scaffold(body: Center(child: CircularProgressIndicator(color: PV.navy)));
            }
            final n = g.memberIds.length;
            final myVote = r.votes[Db.uid];
            final isAdmin = g.adminId == Db.uid;
            final pending = n - r.approvals - r.rejections;

            Widget action;
            if (r.status == 'paid') {
              action = PrimaryButton(
                label: 'View receipt',
                onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => SuccessScreen(groupId: g.id, txnDocId: r.txnDocId))),
              );
            } else if (r.status == 'rejected') {
              action = Text('The group rejected this payment.', textAlign: TextAlign.center, style: bs(14, w: FontWeight.w600, c: PV.red));
            } else if (r.status == 'approved') {
              action = isAdmin
                  ? PrimaryButton(
                      label: 'Pay now • ${inr(r.optimized)}',
                      color: PV.green,
                      loading: _busy,
                      onPressed: () => _run(() => Db.executePayment(g.id, r.id)),
                    )
                  : Text('Approved. Waiting for the admin to release the payment.', textAlign: TextAlign.center, style: bs(13, c: PV.muted));
            } else if (myVote == null) {
              action = Row(children: [
                Expanded(child: OutlineBtn(label: 'Reject', onPressed: _busy ? null : () => _run(() async { await Db.vote(g.id, r.id, false); return null; }))),
                const SizedBox(width: 12),
                Expanded(child: PrimaryButton(label: 'Approve', loading: _busy, onPressed: () => _run(() async { await Db.vote(g.id, r.id, true); return null; }))),
              ]);
            } else {
              action = Text('You ${myVote == 'approve' ? 'approved' : 'rejected'} this. Waiting for others.',
                  textAlign: TextAlign.center, style: bs(13, c: PV.muted));
            }

            return Scaffold(
              body: SafeArea(
                child: Column(children: [
                  const TopBar(title: 'Approval Required'),
                  Expanded(
                    child: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 20), children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(color: PV.navy, borderRadius: BorderRadius.circular(26)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Expanded(child: Text('${g.name}: ${r.title}', style: bs(13, w: FontWeight.w600, c: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            if (r.saved > 0) Pill('SAVED ${inr(r.saved)}', bg: PV.green),
                          ]),
                          const SizedBox(height: 10),
                          Text(inr(r.optimized, decimals: true), style: hs(34, c: Colors.white)),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(color: Colors.white24, height: 1)),
                          Row(children: [
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.payments_outlined, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Optimized Payment', style: bs(10, c: Colors.white70)),
                                Text(r.method, style: hs(15, c: Colors.white)),
                              ]),
                            ),
                            const Icon(Icons.verified_user, color: Color(0xFF34D399)),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      PvCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('Voting Progress', style: hs(15)),
                            Text('${r.approvals} of $n Approved', style: bs(12, c: PV.muted)),
                          ]),
                          const SizedBox(height: 12),
                          Progress(n == 0 ? 0 : r.approvals / n, color: PV.green),
                          const SizedBox(height: 14),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                            _count('${r.approvals}', 'Approved', PV.green),
                            _count('${r.rejections}', 'Rejected', PV.red),
                            _count('$pending', 'Pending', PV.muted),
                          ]),
                          const SizedBox(height: 10),
                          Text('A majority (${n ~/ 2 + 1} of $n) must approve before the admin can pay.', style: bs(11, c: PV.muted)),
                        ]),
                      ),
                      sectionTitle('Member Status'),
                      for (final m in g.members)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PvCard(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(children: [
                              Avatar(m.initial, size: 42),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(m.uid == Db.uid ? '${m.name} (You)' : m.name, style: hs(14)),
                                  Text(m.role, style: bs(11, c: PV.muted)),
                                ]),
                              ),
                              _status(r.votes[m.uid]),
                            ]),
                          ),
                        ),
                    ]),
                  ),
                  Padding(padding: const EdgeInsets.fromLTRB(18, 6, 18, 14), child: action),
                ]),
              ),
            );
          },
        ),
      );

  Widget _count(String v, String l, Color c) => Column(children: [
        Text(v, style: hs(22, c: c)),
        Text(l, style: bs(11, c: PV.muted)),
      ]);

  Widget _status(String? vote) {
    if (vote == 'approve') return const Pill('Approved', fg: PV.green, bg: PV.mint, icon: Icons.check_circle);
    if (vote == 'reject') return const Pill('Rejected', fg: PV.red, bg: Color(0xFFFDE8E8), icon: Icons.cancel);
    return const Pill('Pending', fg: PV.muted, bg: PV.chip, icon: Icons.schedule);
  }
}
