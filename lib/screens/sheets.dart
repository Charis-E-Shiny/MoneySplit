import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../theme.dart';
import '../widgets.dart';
import 'group_screen.dart';
import 'optimizer_screen.dart';

Future<T?> _sheet<T>(BuildContext context, Widget child) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PV.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
        child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(22, 22, 22, 28), child: child),
      ),
    );

double _num(String s) => double.tryParse(s.replaceAll(',', '').trim()) ?? 0;

Widget _chips(List<String> items, String selected, ValueChanged<String> onTap) => Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        for (final c in items)
          GestureDetector(
            onTap: () => onTap(c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: c == selected ? PV.navy : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: c == selected ? PV.navy : PV.border),
              ),
              child: Text(c, style: bs(13, w: FontWeight.w600, c: c == selected ? Colors.white : PV.ink)),
            ),
          ),
      ],
    );

Widget _label(String t) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(t, style: bs(13, w: FontWeight.w600, c: PV.muted)),
    );

// ---------------- create group ----------------
void showCreateGroupSheet(BuildContext context) => _sheet(context, const _CreateGroup());

class _CreateGroup extends StatefulWidget {
  const _CreateGroup();
  @override
  State<_CreateGroup> createState() => _CreateGroupState();
}

class _CreateGroupState extends State<_CreateGroup> {
  final _name = TextEditingController();
  final _budget = TextEditingController();
  String _cat = 'Travel';
  bool _busy = false;

  Future<void> _go() async {
    if (_name.text.trim().isEmpty) return toast(context, 'Give your group a name.');
    setState(() => _busy = true);
    try {
      final id = await Db.createGroup(_name.text, _cat, _num(_budget.text));
      if (!mounted) return;
      final nav = Navigator.of(context);
      nav.pop();
      nav.push(MaterialPageRoute(builder: (_) => GroupScreen(groupId: id)));
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        toast(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Create group', style: hs(22)),
        _label('Group name'),
        PvField(controller: _name, hint: 'Goa Trip, Flatmates, Office lunch'),
        _label('Type'),
        _chips(['Travel', 'Flatmates', 'Event', 'Daily'], _cat, (c) => setState(() => _cat = c)),
        _label('Spending limit (optional)'),
        PvField(controller: _budget, hint: '20000', prefixText: '₹ ', keyboard: TextInputType.number),
        const SizedBox(height: 22),
        PrimaryButton(label: 'Create group', loading: _busy, onPressed: _go),
      ]);
}

// ---------------- join group ----------------
void showJoinGroupSheet(BuildContext context) => _sheet(context, const _JoinGroup());

class _JoinGroup extends StatefulWidget {
  const _JoinGroup();
  @override
  State<_JoinGroup> createState() => _JoinGroupState();
}

class _JoinGroupState extends State<_JoinGroup> {
  final _code = TextEditingController();
  bool _busy = false;

  Future<void> _go() async {
    if (_code.text.trim().length < 4) return toast(context, 'Enter the invite code you were sent.');
    setState(() => _busy = true);
    try {
      final id = await Db.joinGroup(_code.text);
      if (!mounted) return;
      final nav = Navigator.of(context);
      nav.pop();
      nav.push(MaterialPageRoute(builder: (_) => GroupScreen(groupId: id)));
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        toast(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Join a group', style: hs(22)),
        const SizedBox(height: 6),
        Text('Ask the group admin for the 6-character invite code (Group settings).', style: bs(13, c: PV.muted)),
        _label('Invite code'),
        PvField(controller: _code, hint: 'e.g. K7P2QX', icon: Icons.vpn_key_outlined),
        const SizedBox(height: 22),
        PrimaryButton(label: 'Join group', loading: _busy, onPressed: _go),
      ]);
}

// ---------------- add money ----------------
void showAddMoneySheet(BuildContext context, Group g) => _sheet(context, _AddMoney(g));

class _AddMoney extends StatefulWidget {
  final Group g;
  const _AddMoney(this.g);
  @override
  State<_AddMoney> createState() => _AddMoneyState();
}

class _AddMoneyState extends State<_AddMoney> {
  final _amt = TextEditingController();
  bool _busy = false;

  Future<void> _go() async {
    setState(() => _busy = true);
    try {
      await Db.addMoney(widget.g.id, _num(_amt.text));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        toast(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Add money to pool', style: hs(22)),
        _label('Amount'),
        PvField(controller: _amt, hint: '0', prefixText: '₹ ', keyboard: TextInputType.number),
        const SizedBox(height: 12),
        _chips(['500', '1000', '2000', '5000'], '', (v) => setState(() => _amt.text = v)),
        const SizedBox(height: 12),
        Text('This records your contribution in the group ledger. Move the actual money to your group account/UPI separately.',
            style: bs(12, c: PV.muted)),
        const SizedBox(height: 18),
        PrimaryButton(label: 'Add to pool', loading: _busy, onPressed: _go),
      ]);
}

// ---------------- split calculator ----------------
void showSplitSheet(BuildContext context, Group g) => _sheet(context, _Split(g));

class _Split extends StatefulWidget {
  final Group g;
  const _Split(this.g);
  @override
  State<_Split> createState() => _SplitState();
}

class _SplitState extends State<_Split> {
  final _amt = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final a = _num(_amt.text);
    final n = widget.g.members.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Split a bill', style: hs(22)),
      _label('Total amount'),
      PvField(controller: _amt, hint: '0', prefixText: '₹ ', keyboard: TextInputType.number, onChanged: (_) => setState(() {})),
      const SizedBox(height: 16),
      PvCard(
        child: Column(children: [
          Text('Each of $n members pays', style: bs(13, c: PV.muted)),
          const SizedBox(height: 6),
          Text(inr(n == 0 ? 0 : a / n, decimals: true), style: hs(30)),
        ]),
      ),
      const SizedBox(height: 14),
      Text('Bills paid from the pool are split automatically after approval (see Pay).', style: bs(12, c: PV.muted)),
    ]);
  }
}

// ---------------- custom pay ----------------
void showCustomPaySheet(BuildContext context, Group g) => _sheet(context, _CustomPay(g));

class _CustomPay extends StatefulWidget {
  final Group g;
  const _CustomPay(this.g);
  @override
  State<_CustomPay> createState() => _CustomPayState();
}

class _CustomPayState extends State<_CustomPay> {
  final _title = TextEditingController();
  final _merchant = TextEditingController();
  final _amt = TextEditingController();
  String _cat = 'Food';

  void _go() {
    final a = _num(_amt.text);
    if (_title.text.trim().isEmpty || a <= 0) return toast(context, 'Enter what you are paying for and the amount.');
    final nav = Navigator.of(context);
    nav.pop();
    nav.push(MaterialPageRoute(
      builder: (_) => OptimizerScreen(
        group: widget.g,
        title: _title.text.trim(),
        merchant: _merchant.text.trim().isEmpty ? 'Merchant' : _merchant.text.trim(),
        category: _cat,
        amount: a,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('New payment', style: hs(22)),
        _label('What are you paying for?'),
        PvField(controller: _title, hint: 'Hotel booking, Dinner bill'),
        _label('Merchant (optional)'),
        PvField(controller: _merchant, hint: 'MakeMyTrip, Dineout'),
        _label('Amount'),
        PvField(controller: _amt, hint: '0', prefixText: '₹ ', keyboard: TextInputType.number),
        _label('Category'),
        _chips(['Travel', 'Food', 'Shopping', 'Stay', 'Bills', 'Other'], _cat, (c) => setState(() => _cat = c)),
        const SizedBox(height: 22),
        PrimaryButton(label: 'Find cheapest way to pay', onPressed: _go),
      ]);
}

// ---------------- group settings ----------------
void showGroupSettingsSheet(BuildContext context, Group g) => _sheet(context, _Settings(g));

class _Settings extends StatefulWidget {
  final Group g;
  const _Settings(this.g);
  @override
  State<_Settings> createState() => _SettingsState();
}

class _SettingsState extends State<_Settings> {
  late final _budget = TextEditingController(text: widget.g.budgetLimit.round().toString());
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final admin = widget.g.adminId == Db.uid;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Group settings', style: hs(22)),
      _label('Invite code'),
      PvCard(
        child: Row(children: [
          Expanded(child: Text(widget.g.inviteCode, style: hs(24))),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.g.inviteCode));
              toast(context, 'Invite code copied. Share it with your friends.');
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy'),
          ),
        ]),
      ),
      if (admin) ...[
        _label('Spending limit'),
        PvField(controller: _budget, hint: '0', prefixText: '₹ ', keyboard: TextInputType.number),
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Save limit',
          loading: _busy,
          onPressed: () async {
            setState(() => _busy = true);
            try {
              await Db.setBudget(widget.g.id, _num(_budget.text));
              if (mounted) Navigator.of(context).pop();
            } catch (e) {
              if (mounted) {
                setState(() => _busy = false);
                toast(context, e.toString());
              }
            }
          },
        ),
      ] else
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Text('Only the group admin can change the spending limit.', style: bs(12, c: PV.muted)),
        ),
    ]);
  }
}

// ---------------- profile ----------------
void showProfileSheet(BuildContext context) {
  final u = FirebaseAuth.instance.currentUser;
  _sheet(
    context,
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Avatar((u?.displayName ?? u?.email ?? '?').trim().isEmpty ? '?' : (u?.displayName ?? u?.email ?? '?').trim()[0].toUpperCase(), size: 54),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u?.displayName ?? 'Member', style: hs(18)),
            Text(u?.email ?? '', style: bs(13, c: PV.muted)),
          ]),
        ),
      ]),
      const SizedBox(height: 22),
      OutlineBtn(
        label: 'Sign out',
        leading: const Icon(Icons.logout, size: 18),
        onPressed: () async {
          Navigator.of(context).pop();
          await AuthService.signOut();
        },
      ),
    ]),
  );
}
