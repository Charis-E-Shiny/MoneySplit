import 'package:flutter/material.dart';
import '../theme.dart';

/// A payment-method offer rule. EDIT THESE to match real offers you have
/// (or load them from Firestore / your backend instead).
class Rule {
  final String id, name, subtitle;
  final IconData icon;
  final double pct, cap, min;
  final List<String> categories; // empty = all categories
  const Rule({
    required this.id, required this.name, required this.subtitle, required this.icon,
    required this.pct, required this.cap, required this.min, this.categories = const [],
  });
}

const offerRules = <Rule>[
  Rule(id: 'gift', name: 'Gift Card + UPI', subtitle: 'Using Group Gift Cards', icon: Icons.card_giftcard, pct: 6, cap: 600, min: 500),
  Rule(id: 'card', name: 'Credit Card Offer', subtitle: 'HDFC Bank Special', icon: Icons.credit_card, pct: 2.5, cap: 300, min: 1000),
  Rule(id: 'upi', name: 'Direct UPI', subtitle: 'Standard Transfer', icon: Icons.payments_outlined, pct: 0, cap: 0, min: 0),
];

class PayOption {
  final String id, name, subtitle;
  final IconData icon;
  final double original, effective, savings;
  final bool isBest;
  const PayOption({
    required this.id, required this.name, required this.subtitle, required this.icon,
    required this.original, required this.effective, required this.savings, required this.isBest,
  });
}

class Optimizer {
  /// Compares every rule for this amount and returns options, cheapest first.
  static List<PayOption> compare({required double amount, required String category}) {
    final list = <PayOption>[];
    for (final r in offerRules) {
      final eligible = amount >= r.min && (r.categories.isEmpty || r.categories.contains(category));
      var saving = 0.0;
      if (eligible && r.pct > 0) {
        saving = amount * r.pct / 100;
        if (r.cap > 0 && saving > r.cap) saving = r.cap;
      }
      saving = r2(saving);
      list.add(PayOption(
        id: r.id, name: r.name, subtitle: r.subtitle, icon: r.icon,
        original: amount, effective: r2(amount - saving), savings: saving, isBest: false,
      ));
    }
    final order = {for (var i = 0; i < list.length; i++) list[i].id: i};
    list.sort((a, b) {
      final c = a.effective.compareTo(b.effective);
      return c != 0 ? c : order[a.id]!.compareTo(order[b.id]!);
    });
    return [
      for (var i = 0; i < list.length; i++)
        PayOption(
          id: list[i].id, name: list[i].name, subtitle: list[i].subtitle, icon: list[i].icon,
          original: list[i].original, effective: list[i].effective, savings: list[i].savings, isBest: i == 0,
        )
    ];
  }
}
