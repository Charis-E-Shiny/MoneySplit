import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models.dart';
import '../theme.dart';
import 'optimizer.dart';
import 'payment_gateway.dart';

class Db {
  static final _fs = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _groups => _fs.collection('groups');

  static String get uid => FirebaseAuth.instance.currentUser!.uid;
  static String get userName {
    final u = FirebaseAuth.instance.currentUser!;
    final n = (u.displayName ?? '').trim();
    return n.isNotEmpty ? n : (u.email ?? 'Member').split('@').first;
  }

  static String _rand(int n, {String chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'}) {
    final r = Random.secure();
    return List.generate(n, (_) => chars[r.nextInt(chars.length)]).join();
  }

  // ---------- streams ----------
  static Stream<List<Group>> myGroups() => _groups.where('memberIds', arrayContains: uid).snapshots().map((s) {
        final l = s.docs.map(Group.fromDoc).toList();
        l.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return l;
      });

  static Stream<Group?> group(String id) =>
      _groups.doc(id).snapshots().map((d) => d.exists ? Group.fromDoc(d) : null);

  static Stream<List<PayRequest>> openRequests(String gid) => _groups
      .doc(gid)
      .collection('requests')
      .where('status', whereIn: ['pending', 'approved'])
      .snapshots()
      .map((s) {
        final l = s.docs.map(PayRequest.fromDoc).toList();
        l.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return l;
      });

  static Stream<PayRequest?> request(String gid, String rid) => _groups
      .doc(gid)
      .collection('requests')
      .doc(rid)
      .snapshots()
      .map((d) => d.exists ? PayRequest.fromDoc(d) : null);

  static Stream<List<Txn>> transactions(String gid) => _groups
      .doc(gid)
      .collection('transactions')
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Txn.fromDoc).toList());

  static Future<Txn?> txnOnce(String gid, String id) async {
    final d = await _groups.doc(gid).collection('transactions').doc(id).get();
    return d.exists ? Txn.fromDoc(d) : null;
  }

  static Future<Group?> groupOnce(String gid) async {
    final d = await _groups.doc(gid).get();
    return d.exists ? Group.fromDoc(d) : null;
  }

  // ---------- groups ----------
  static Future<String> createGroup(String name, String category, double budget) async {
    if (name.trim().isEmpty) throw PvError('Give your group a name.');
    if (!budget.isFinite || budget < 0) throw PvError('The spending limit cannot be negative.');
    final ref = _groups.doc();
    await ref.set({
      'name': name.trim(),
      'category': category,
      'budgetLimit': budget,
      'adminId': uid,
      'inviteCode': _rand(6),
      'memberIds': [uid],
      'members': {
        uid: {'name': userName, 'role': 'Admin', 'contributed': 0}
      },
      'spent': 0,
      'saved': 0,
      'pendingAmount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<String> joinGroup(String code) async {
    final q = await _groups.where('inviteCode', isEqualTo: code.trim().toUpperCase()).limit(1).get();
    if (q.docs.isEmpty) throw PvError('No group found for that code. Check it and try again.');
    final d = q.docs.first;
    final g = Group.fromDoc(d);
    if (g.memberIds.contains(uid)) return g.id;
    await d.reference.update({
      'memberIds': FieldValue.arrayUnion([uid]),
      'members.$uid': {'name': userName, 'role': 'Member', 'contributed': 0},
    });
    return g.id;
  }

  static Future<void> setBudget(String gid, double budget) {
    if (!budget.isFinite || budget < 0) throw PvError('The spending limit cannot be negative.');
    return _groups.doc(gid).update({'budgetLimit': budget});
  }

  // ---------- money ----------
  /// Records the current user's contribution to the pool.
  /// (Demo: bookkeeping only. Real collection needs a payment gateway + licensed partner.)
  static Future<void> addMoney(String gid, double amount) async {
    if (!amount.isFinite || amount <= 0) throw PvError('Enter an amount greater than zero.');
    await _groups.doc(gid).update({'members.$uid.contributed': FieldValue.increment(amount)});
  }

  // ---------- approval flow ----------
  static Future<String> createRequest(
    Group g, {
    required String title,
    required String merchant,
    required String category,
    required double original,
    required PayOption option,
  }) async {
    if (!original.isFinite || original <= 0 ||
        !option.effective.isFinite || option.effective <= 0 ||
        option.effective > original || !option.savings.isFinite || option.savings < 0) {
      throw PvError('Enter a valid payment amount.');
    }
    final ref = _groups.doc(g.id).collection('requests').doc();
    final need = g.memberIds.length ~/ 2 + 1;
    final batch = _fs.batch();
    batch.set(ref, {
      'title': title,
      'merchant': merchant,
      'category': category,
      'original': original,
      'optimized': option.effective,
      'saved': option.savings,
      'method': option.name,
      'status': need <= 1 ? 'approved' : 'pending',
      'votes': {uid: 'approve'},
      'createdBy': uid,
      'txnDocId': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_groups.doc(g.id), {'pendingAmount': FieldValue.increment(option.effective)});
    await batch.commit();
    return ref.id;
  }

  /// Majority approval releases the payment; majority rejection cancels it.
  static Future<void> vote(String gid, String rid, bool approve) async {
    final gRef = _groups.doc(gid);
    final rRef = gRef.collection('requests').doc(rid);
    await _fs.runTransaction((tx) async {
      final gs = await tx.get(gRef);
      final rs = await tx.get(rRef);
      final grp = Group.fromDoc(gs);
      final req = PayRequest.fromDoc(rs);
      if (req.status != 'pending') throw PvError('Voting on this request is closed.');
      final votes = Map<String, String>.from(req.votes)..[uid] = approve ? 'approve' : 'reject';
      final n = grp.memberIds.length;
      final need = n ~/ 2 + 1;
      final yes = votes.values.where((v) => v == 'approve').length;
      final no = votes.values.where((v) => v == 'reject').length;
      var status = 'pending';
      if (yes >= need) {
        status = 'approved';
      } else if (no > n - need) {
        status = 'rejected';
      }
      tx.update(rRef, {'votes.$uid': approve ? 'approve' : 'reject', 'status': status});
      if (status == 'rejected') {
        tx.update(gRef, {'pendingAmount': FieldValue.increment(-req.optimized)});
      }
    });
  }

  /// Admin releases an approved payment from the pool. Returns the transaction doc id.
  static Future<String> executePayment(String gid, String rid) async {
    final gRef = _groups.doc(gid);
    final rRef = gRef.collection('requests').doc(rid);
    final preGroupSnapshot = await gRef.get();
    final preRequestSnapshot = await rRef.get();
    if (!preGroupSnapshot.exists || !preRequestSnapshot.exists) {
      throw PvError('This group or payment request no longer exists.');
    }
    final preGroup = Group.fromDoc(preGroupSnapshot);
    final preRequest = PayRequest.fromDoc(preRequestSnapshot);
    if (preGroup.adminId != uid) throw PvError('Only the group admin can release the payment.');
    if (preRequest.status != 'approved') throw PvError('This request was already processed.');
    if (preGroup.balance < preRequest.optimized) {
      throw PvError('Pool balance is ${inr(preGroup.balance)}, but ${inr(preRequest.optimized)} is needed. Add money first.');
    }
    await PaymentGateway.charge(amount: preRequest.optimized, description: preRequest.title);

    final tRef = gRef.collection('transactions').doc();
    final code = 'PV-${_rand(6, chars: '0123456789ABCDEF')}';
    await _fs.runTransaction((tx) async {
      final gs = await tx.get(gRef);
      final rs = await tx.get(rRef);
      if (!gs.exists || !rs.exists) throw PvError('This group or payment request no longer exists.');
      final grp = Group.fromDoc(gs);
      final req = PayRequest.fromDoc(rs);
      if (grp.adminId != uid) throw PvError('Only the group admin can release the payment.');
      if (req.status != 'approved') throw PvError('This request was already processed.');
      if (grp.balance < req.optimized) {
        throw PvError('Pool balance is ${inr(grp.balance)}, but ${inr(req.optimized)} is needed. Add money first.');
      }
      tx.update(rRef, {'status': 'paid', 'txnDocId': tRef.id});
      tx.set(tRef, {
        'txnCode': code,
        'type': 'payment',
        'title': req.title,
        'merchant': req.merchant,
        'category': req.category,
        'method': req.method,
        'original': req.original,
        'paid': req.optimized,
        'saved': req.saved,
        'date': FieldValue.serverTimestamp(),
        'by': uid,
      });
      tx.update(gRef, {
        'spent': FieldValue.increment(req.optimized),
        'saved': FieldValue.increment(req.saved),
        'pendingAmount': FieldValue.increment(-req.optimized),
      });
    });
    return tRef.id;
  }
}
