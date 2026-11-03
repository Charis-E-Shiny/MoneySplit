import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models.dart';
import '../services/db_service.dart';
import '../theme.dart';
import '../widgets.dart';
import 'chat_screen.dart';
import 'group_screen.dart';
import 'sheets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final full = (user?.displayName ?? '').trim();
    final first = full.isNotEmpty ? full.split(' ').first : (user?.email ?? 'there').split('@').first;

    return StreamBuilder<List<Group>>(
      stream: Db.myGroups(),
      builder: (context, snap) {
        final groups = snap.data ?? const <Group>[];
        final uid = user?.uid ?? '';
        final total = groups.fold(0.0, (a, g) => a + g.balance);
        final mine = groups.fold(0.0, (a, g) => a + (g.member(uid)?.contributed ?? 0));
        final pending = groups.fold(0.0, (a, g) => a + g.pendingAmount);
        final saved = groups.fold(0.0, (a, g) => a + g.saved);

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: PV.green,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.auto_awesome),
            label: Text('Ask PV', style: hs(15, c: Colors.white)),
            onPressed: groups.isEmpty
                ? () => toast(context, 'Create or join a group first, then ask me about it.')
                : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(groups: groups))),
          ),
          body: SafeArea(
            child: snap.hasError
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Could not load groups.\n${snap.error}', textAlign: TextAlign.center, style: bs(13, c: PV.red)),
                  ))
                : ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 100), children: [
                    Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Hey $first 👋', style: hs(24)),
                          Text('Your group money, made smarter.', style: bs(13, c: PV.muted)),
                        ]),
                      ),
                      GestureDetector(
                        onTap: () => showProfileSheet(context),
                        child: Container(
                          width: 44, height: 44, alignment: Alignment.center,
                          decoration: const BoxDecoration(color: PV.navy, shape: BoxShape.circle),
                          child: Text(first.isEmpty ? '?' : first[0].toUpperCase(), style: hs(16, c: Colors.white)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    GradientCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('TOTAL GROUP BALANCE', style: bs(12, w: FontWeight.w700, c: Colors.white70)),
                          const Icon(Icons.account_balance_wallet_outlined, color: Colors.white54, size: 20),
                        ]),
                        const SizedBox(height: 14),
                        Text(inr(total), style: hs(38, c: Colors.white)),
                        const SizedBox(height: 14),
                        Row(children: [
                          Pill('Saved ${inr(saved)}', bg: PV.green),
                          const SizedBox(width: 10),
                          Text('Across ${groups.length} group${groups.length == 1 ? '' : 's'}', style: bs(11, w: FontWeight.w600, c: Colors.white70)),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      _stat(Icons.payments_outlined, inr(mine), 'Your Contribution'),
                      const SizedBox(width: 10),
                      _stat(Icons.history, inr(pending), 'Pending'),
                      const SizedBox(width: 10),
                      _stat(Icons.savings_outlined, inr(saved), 'Total Savings'),
                    ]),
                    const SizedBox(height: 18),
                    Row(children: [
                      Expanded(child: PrimaryButton(label: 'Create Group', onPressed: () => showCreateGroupSheet(context))),
                      const SizedBox(width: 12),
                      Expanded(child: OutlineBtn(label: 'Join Group', onPressed: () => showJoinGroupSheet(context))),
                    ]),
                    sectionTitle('Your Groups'),
                    if (snap.connectionState == ConnectionState.waiting)
                      const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(color: PV.navy)))
                    else if (groups.isEmpty)
                      PvCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('No groups yet', style: hs(16)),
                          const SizedBox(height: 4),
                          Text('Create a group for your trip, flat or dinner, or join one with an invite code.', style: bs(13, c: PV.muted)),
                        ]),
                      )
                    else
                      for (final g in groups)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PvCard(
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupScreen(groupId: g.id))),
                            child: Row(children: [
                              IconBox(groupIcon(g.category), size: 54),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(g.name, style: hs(16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text('${g.memberIds.length} Members', style: bs(12, c: PV.muted)),
                                ]),
                              ),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(inr(g.balance), style: hs(17)),
                                Row(children: [
                                  const Icon(Icons.trending_up, size: 13, color: PV.green),
                                  const SizedBox(width: 3),
                                  Text('Saved ${inr(g.saved)}', style: bs(11, w: FontWeight.w600, c: PV.green)),
                                ]),
                              ]),
                            ]),
                          ),
                        ),
                  ]),
          ),
        );
      },
    );
  }

  Widget _stat(IconData icon, String value, String label) => Expanded(
        child: PvCard(
          radius: 18,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 22, color: PV.navy),
            const SizedBox(height: 10),
            FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: hs(16))),
            const SizedBox(height: 2),
            Text(label, style: bs(10, w: FontWeight.w600, c: PV.muted)),
          ]),
        ),
      );
}
