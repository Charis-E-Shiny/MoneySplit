import 'package:cloud_firestore/cloud_firestore.dart';

class PvError implements Exception {
  final String message;
  PvError(this.message);
  @override
  String toString() => message;
}

double _n(dynamic v) => v is num ? v.toDouble() : 0.0;
DateTime _t(dynamic v) => v is Timestamp ? v.toDate() : DateTime.now();

class Member {
  final String uid, name, role;
  final double contributed;
  const Member({required this.uid, required this.name, required this.role, required this.contributed});
  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();
}

class Group {
  final String id, name, category, adminId, inviteCode;
  final double budgetLimit, spent, saved, pendingAmount;
  final List<String> memberIds;
  final List<Member> members;
  final DateTime createdAt;

  const Group({
    required this.id, required this.name, required this.category, required this.adminId,
    required this.inviteCode, required this.budgetLimit, required this.spent, required this.saved,
    required this.pendingAmount, required this.memberIds, required this.members, required this.createdAt,
  });

  double get contributed => members.fold(0.0, (a, m) => a + m.contributed);
  double get balance => contributed - spent;
  Member? member(String uid) {
    for (final m in members) {
      if (m.uid == uid) return m;
    }
    return null;
  }

  factory Group.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    final raw = Map<String, dynamic>.from((m['members'] as Map?) ?? {});
    final members = raw.entries.map((e) {
      final v = Map<String, dynamic>.from(e.value as Map);
      return Member(
        uid: e.key,
        name: (v['name'] ?? 'Member').toString(),
        role: (v['role'] ?? 'Member').toString(),
        contributed: _n(v['contributed']),
      );
    }).toList();
    members.sort((a, b) {
      if (a.role == 'Admin' && b.role != 'Admin') return -1;
      if (b.role == 'Admin' && a.role != 'Admin') return 1;
      return a.name.compareTo(b.name);
    });
    return Group(
      id: d.id,
      name: (m['name'] ?? 'Group').toString(),
      category: (m['category'] ?? 'Other').toString(),
      adminId: (m['adminId'] ?? '').toString(),
      inviteCode: (m['inviteCode'] ?? '').toString(),
      budgetLimit: _n(m['budgetLimit']),
      spent: _n(m['spent']),
      saved: _n(m['saved']),
      pendingAmount: _n(m['pendingAmount']),
      memberIds: List<String>.from((m['memberIds'] as List?) ?? const []),
      members: members,
      createdAt: _t(m['createdAt']),
    );
  }
}

class PayRequest {
  final String id, title, merchant, category, method, status, createdBy, txnDocId;
  final double original, optimized, saved;
  final Map<String, String> votes;
  final DateTime createdAt;

  const PayRequest({
    required this.id, required this.title, required this.merchant, required this.category,
    required this.method, required this.status, required this.createdBy, required this.txnDocId,
    required this.original, required this.optimized, required this.saved, required this.votes,
    required this.createdAt,
  });

  int get approvals => votes.values.where((v) => v == 'approve').length;
  int get rejections => votes.values.where((v) => v == 'reject').length;

  factory PayRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    final v = Map<String, dynamic>.from((m['votes'] as Map?) ?? {});
    return PayRequest(
      id: d.id,
      title: (m['title'] ?? '').toString(),
      merchant: (m['merchant'] ?? '').toString(),
      category: (m['category'] ?? 'Other').toString(),
      method: (m['method'] ?? '').toString(),
      status: (m['status'] ?? 'pending').toString(),
      createdBy: (m['createdBy'] ?? '').toString(),
      txnDocId: (m['txnDocId'] ?? '').toString(),
      original: _n(m['original']),
      optimized: _n(m['optimized']),
      saved: _n(m['saved']),
      votes: v.map((k, val) => MapEntry(k, val.toString())),
      createdAt: _t(m['createdAt']),
    );
  }
}

class Txn {
  final String id, txnCode, title, merchant, category, method;
  final double original, paid, saved;
  final DateTime date;

  const Txn({
    required this.id, required this.txnCode, required this.title, required this.merchant,
    required this.category, required this.method, required this.original, required this.paid,
    required this.saved, required this.date,
  });

  factory Txn.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    return Txn(
      id: d.id,
      txnCode: (m['txnCode'] ?? '').toString(),
      title: (m['title'] ?? '').toString(),
      merchant: (m['merchant'] ?? '').toString(),
      category: (m['category'] ?? 'Other').toString(),
      method: (m['method'] ?? '').toString(),
      original: _n(m['original']),
      paid: _n(m['paid']),
      saved: _n(m['saved']),
      date: _t(m['date']),
    );
  }
}
