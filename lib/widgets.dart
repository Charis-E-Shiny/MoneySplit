import 'package:flutter/material.dart';
import 'theme.dart';

void toast(BuildContext c, String m) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));
}

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 56});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: PV.navy, borderRadius: BorderRadius.circular(size * 0.28)),
        child: Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: size * 0.52),
      );
}

class PvCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color color;
  final double radius;
  const PvCard({
    super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap,
    this.borderColor, this.color = Colors.white, this.radius = 20,
  });
  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return Material(
      color: color,
      borderRadius: br,
      child: InkWell(
        borderRadius: br,
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(borderRadius: br, border: Border.all(color: borderColor ?? PV.border)),
          child: child,
        ),
      ),
    );
  }
}

class GradientCard extends StatelessWidget {
  final Widget child;
  const GradientCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [PV.indigo, PV.navy]),
        ),
        child: child,
      );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color color;
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.loading = false, this.color = PV.navy});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color, foregroundColor: Colors.white,
            disabledBackgroundColor: color.withOpacity(0.6), disabledForegroundColor: Colors.white70,
            padding: const EdgeInsets.symmetric(vertical: 17), elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
              : Text(label, style: hs(15, c: Colors.white)),
        ),
      );
}

class OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  const OutlineBtn({super.key, required this.label, required this.onPressed, this.leading});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: PV.ink, side: const BorderSide(color: PV.border),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Text(label, style: bs(15, w: FontWeight.w600)),
          ]),
        ),
      );
}

class Pill extends StatelessWidget {
  final String text;
  final Color fg, bg;
  final IconData? icon;
  const Pill(this.text, {super.key, this.fg = Colors.white, this.bg = PV.green, this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
          Text(text, style: bs(11, w: FontWeight.w700, c: fg)),
        ]),
      );
}

class Avatar extends StatelessWidget {
  final String letter;
  final double size;
  const Avatar(this.letter, {super.key, this.size = 44});
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size, alignment: Alignment.center,
        decoration: const BoxDecoration(color: PV.chip, shape: BoxShape.circle),
        child: Text(letter, style: hs(size * 0.38)),
      );
}

class IconBox extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;
  const IconBox(this.icon, {super.key, this.bg = PV.chip, this.fg = PV.navy, this.size = 50});
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.3)),
        child: Icon(icon, color: fg, size: size * 0.48),
      );
}

class PvField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboard;
  final String? prefixText;
  final ValueChanged<String>? onChanged;
  const PvField({
    super.key, required this.controller, required this.hint, this.icon, this.obscure = false,
    this.keyboard, this.prefixText, this.onChanged,
  });
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        onChanged: onChanged,
        style: bs(15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: bs(15, c: const Color(0xFF9AA5B4)),
          prefixIcon: icon == null ? null : Icon(icon, color: PV.ink, size: 20),
          prefixText: prefixText,
          prefixStyle: bs(15),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: PV.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: PV.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: PV.navy, width: 1.4)),
        ),
      );
}

/// Back arrow + centered title (+ optional right widget).
class TopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? right;
  final bool canBack;
  const TopBar({super.key, required this.title, this.subtitle, this.right, this.canBack = true});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Row(children: [
          SizedBox(
            width: 48,
            child: canBack ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).maybePop()) : null,
          ),
          Expanded(
            child: Column(children: [
              Text(title, style: hs(17), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (subtitle != null) Text(subtitle!, style: bs(11, c: PV.muted)),
            ]),
          ),
          SizedBox(width: 48, child: right),
        ]),
      );
}

class Progress extends StatelessWidget {
  final double value;
  final Color color;
  const Progress(this.value, {super.key, this.color = PV.navy});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0), minHeight: 9, backgroundColor: PV.border, color: color),
      );
}

Widget sectionTitle(String t, {Widget? trailing}) => Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(t, style: hs(20)),
        if (trailing != null) trailing,
      ]),
    );
