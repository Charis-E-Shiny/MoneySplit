import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PV {
  static const navy = Color(0xFF0B2542);
  static const indigo = Color(0xFF1E2A78);
  static const green = Color(0xFF059669);
  static const mint = Color(0xFFDDF3E8);
  static const bg = Color(0xFFF7F9FC);
  static const border = Color(0xFFD9DFE8);
  static const muted = Color(0xFF64748B);
  static const ink = Color(0xFF0F172A);
  static const red = Color(0xFFDC2626);
  static const amber = Color(0xFFFBBF24);
  static const slate = Color(0xFF6F7F90);
  static const chip = Color(0xFFE8ECF2);
}

/// Headline font (Plus Jakarta Sans).
TextStyle hs(double size, {FontWeight w = FontWeight.w700, Color c = PV.ink}) =>
    GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: w, color: c);

/// Body font (Inter).
TextStyle bs(double size, {FontWeight w = FontWeight.w400, Color c = PV.ink}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: w, color: c);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: PV.navy, primary: PV.navy),
    scaffoldBackgroundColor: PV.bg,
  );
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

// ---------- helpers ----------
double r2(double x) => (x * 100).round() / 100;

String inr(num n, {bool decimals = false}) {
  final neg = n < 0;
  final s = (decimals ? n.abs().toDouble() : n.abs().roundToDouble()).toStringAsFixed(decimals ? 2 : 0);
  final parts = s.split('.');
  final i = parts[0];
  var out = i.length > 3 ? i.substring(i.length - 3) : i;
  var rest = i.length > 3 ? i.substring(0, i.length - 3) : '';
  while (rest.isNotEmpty) {
    final take = rest.length >= 2 ? 2 : rest.length;
    out = '${rest.substring(rest.length - take)},$out';
    rest = rest.substring(0, rest.length - take);
  }
  return '${neg ? '-' : ''}₹$out${decimals ? '.${parts[1]}' : ''}';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String monthName(int m) => _months[(m - 1) % 12];

String fmtDate(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final mm = d.minute.toString().padLeft(2, '0');
  final ap = d.hour >= 12 ? 'PM' : 'AM';
  final now = DateTime.now();
  final today = now.year == d.year && now.month == d.month && now.day == d.day;
  final day = today ? 'Today' : '${d.day} ${monthName(d.month)}';
  return '$day, ${h.toString().padLeft(2, '0')}:$mm $ap';
}

IconData catIcon(String c) {
  switch (c) {
    case 'Travel':
      return Icons.flight;
    case 'Food':
      return Icons.restaurant;
    case 'Shopping':
      return Icons.shopping_bag_outlined;
    case 'Stay':
      return Icons.hotel_outlined;
    case 'Bills':
      return Icons.receipt_long_outlined;
    default:
      return Icons.local_offer_outlined;
  }
}

Color catColor(String c) {
  switch (c) {
    case 'Travel':
      return const Color(0xFFE0F0FF);
    case 'Food':
      return const Color(0xFFE6F4D9);
    case 'Shopping':
      return const Color(0xFFFFEBD6);
    default:
      return const Color(0xFFEDE7FA);
  }
}

IconData groupIcon(String c) {
  switch (c) {
    case 'Travel':
      return Icons.flight;
    case 'Flatmates':
      return Icons.home_outlined;
    case 'Event':
      return Icons.celebration_outlined;
    default:
      return Icons.groups_outlined;
  }
}
