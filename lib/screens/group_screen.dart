import 'package:flutter/material.dart';
import '../models.dart';
import '../services/db_service.dart';
import '../theme.dart';
import '../widgets.dart';
import 'approval_screen.dart';
import 'discover_screen.dart';
import 'savings_screen.dart';
import 'sheets.dart';
import 'success_screen.dart';

class GroupScreen extends StatefulWidget {
  final String groupId;
  const GroupScreen({super.key, required this.groupId});
  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  bool _allMembers = false;

  @override
  Widget build(BuildContext context) => StreamBuilder<Group?>(
        stream: Db.group(widget.groupId),
        builder: (context, snap) {
          final g = snap.data;
          if (g == null) {
            return Scaffold(
              body: SafeArea(
                child: Column(children: [
                  const TopBar(title: 'Group'),
                  Expanded(child: Center(
                    child: snap.connectionState == ConnectionState.waiting
                        ? const CircularProgressIndicator(color: PV.navy)
                        : Text('This group no longer exists.', style: bs(14, c: PV.muted)),
                  )),
                ]),
              ),
            );
          }
          final progress = g.budgetLimit > 0 ? g.spent / g.budgetLimit : 0.0;
          final members = _allMembers ? g.members : g.members.take(4).toList();

          return Scaffold(
            body: SafeArea(
              child: ListView(padding: const EdgeInsets.only(bottom: 30), children: [
                TopBar(
                  title: g.name,
                  subtitle: '${g.memberIds.length} Members • ${g.category}',
                  right: IconButton(icon: const Icon(Icons.settings), onPressed: () => showGroupSettingsSheet(context, g)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 8),
                    GradientCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('TOTAL GROUP BALANCE', style: bs(11, w: FontWeight.w700, c: Colors.white)),
                          const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 18),
                        ]),
                        const SizedBox(height: 12),
                        Text(inr(g.balance), style: hs(36, c: Colors.white)),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white24, height: 1)),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          _mini('Contributed', inr(g.contributed), Colors.white),
                          _mini('Spent', inr(g.spent), Colors.white),
                          _mini('Saved', inr(g.saved), const Color(0xFF34D399)),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    PvCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('Spending Progress', style: hs(14)),
                          Text(g.budgetLimit > 0 ? '${inr(g.budgetLimit)} Limit' : 'No limit set', style: bs(12, c: PV.muted)),
                        ]),
                        const SizedBox(height: 10),
                        Progress(progress, color: progress > 0.9 ? PV.red : PV.navy),
                        const SizedBox(height: 8),
                        Text(g.budgetLimit > 0 ? '${(progress * 100).round()}% of budget used' : 'Set a limit in group settings',
                            style: bs(11, w: FontWeight.w500, c: PV.muted)),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      _action(Icons.add, 'Add Money', () => showAddMoneySheet(context, g)),
                      _action(Icons.payments_outlined, 'Pay', () => showCustomPaySheet(context, g)),
                      _action(Icons.explore_outlined, 'Discover', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DiscoverScreen(group: g)))),
                      _action(Icons.call_split, 'Split', () => showSplitSheet(context, g)),
                    ]),
                    const SizedBox(height: 14),
                    OutlineBtn(
                      label: 'Group Savings',
                      leading: const Icon(Icons.show_chart, size: 18, color: PV.green),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SavingsScreen(group: g))),
                    ),

                    // pending approvals
                    StreamBuilder<List<PayRequest>>(
                      stream: Db.openRequests(g.id),
                      builder: (context, rs) {
                        final reqs = rs.data ?? const <PayRequest>[];
                        if (reqs.isEmpty) return const SizedBox.shrink();
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          sectionTitle('Needs approval'),
                          for (final r in reqs)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: PvCard(
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => ApprovalScreen(groupId: g.id, requestId: r.id))),
                                child: Row(children: [
                                  IconBox(catIcon(r.category), bg: catColor(r.category), size: 46),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(r.title, style: hs(14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text(r.status == 'approved' ? 'Approved, ready to pay' : '${r.approvals} of ${g.memberIds.length} approved',
                                          style: bs(12, c: r.status == 'approved' ? PV.green : PV.muted)),
                                    ]),
                                  ),
                                  Text(inr(r.optimized), style: hs(15)),
                                ]),
                              ),
                            ),
                        ]);
                      },
                    ),

                    sectionTitle('Members', trailing: GestureDetector(
                      onTap: () => setState(() => _allMembers = !_allMembers),
                      child: Text(_allMembers ? 'Show less' : 'See All', style: hs(14)),
                    )),
                    PvCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(children: [
                        for (var i = 0; i < members.length; i++) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(children: [
                              Avatar(members[i].initial),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(members[i].uid == Db.uid ? '${members[i].name} (You)' : members[i].name, style: hs(15)),
                                  Text(members[i].role, style: bs(11, c: PV.muted)),
                                ]),
                              ),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(inr(members[i].contributed), style: hs(15)),
                                Text('Contributed', style: bs(10, c: PV.muted)),
                              ]),
                            ]),
                          ),
                          if (i != members.length - 1) const Divider(height: 1),
                        ],
                      ]),
                    ),

                    StreamBuilder<List<Txn>>(
                      stream: Db.transactions(g.id),
                      builder: (context, ts) {
                        final list = (ts.data ?? const <Txn>[]).take(5).toList();
                        if (list.isEmpty) return const SizedBox.shrink();
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          sectionTitle('Recent payments'),
                          for (final t in list)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: PvCard(
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => SuccessScreen(groupId: g.id, txnDocId: t.id))),
                                child: Row(children: [
                                  IconBox(catIcon(t.category), bg: catColor(t.category), size: 46),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(t.title, style: hs(14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text('${fmtDate(t.date)} • ${t.method}', style: bs(11, c: PV.muted)),
                                    ]),
                                  ),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    Text(inr(t.paid), style: hs(15)),
                                    if (t.saved > 0) Text('Saved ${inr(t.saved)}', style: bs(10, w: FontWeight.w600, c: PV.green)),
                                  ]),
                                ]),
                              ),
                            ),
                        ]);
                      },
                    ),
                  ]),
                ),
              ]),
            ),
          );
        },
      );

  Widget _mini(String label, String value, Color c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: bs(11, w: FontWeight.w700, c: Colors.white)),
        const SizedBox(height: 4),
        Text(value, style: hs(16, c: c)),
      ]);

  Widget _action(IconData icon, String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 76,
          child: Column(children: [
            Container(
              width: 62, height: 62,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: PV.border)),
              child: Icon(icon, color: PV.navy),
            ),
            const SizedBox(height: 8),
            Text(label, style: bs(12, w: FontWeight.w600, c: PV.muted)),
          ]),
        ),
      );
}
