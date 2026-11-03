import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets.dart';

class AuthScreen extends StatefulWidget {
  final bool startOnSignUp;
  const AuthScreen({super.key, this.startOnSignUp = false});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _signUp = widget.startOnSignUp;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() job) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await job();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    if (_email.text.trim().isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    if (_signUp && _name.text.trim().isEmpty) {
      setState(() => _error = 'Enter your name.');
      return;
    }
    _run(() => _signUp
        ? AuthService.signUp(_name.text, _email.text, _pass.text)
        : AuthService.signIn(_email.text, _pass.text));
  }

  Future<void> _forgot() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = 'Type your email above, then tap Forgot Password.');
      return;
    }
    try {
      await AuthService.resetPassword(_email.text);
      if (mounted) toast(context, 'Password reset link sent to ${_email.text.trim()}');
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.friendly(e));
    }
  }

  Widget _tab(String label, bool on) => Expanded(
        child: GestureDetector(
          onTap: _busy ? null : () => setState(() {
            _signUp = label == 'Sign Up';
            _error = null;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: on ? PV.navy : Colors.transparent, width: 2))),
            child: Text(label, textAlign: TextAlign.center,
                style: bs(15, w: on ? FontWeight.w700 : FontWeight.w500, c: on ? PV.ink : PV.muted)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).maybePop()),
            ),
            const Center(child: AppLogo(size: 84)),
            const SizedBox(height: 14),
            Center(child: Text('PAISA VASOOL', style: hs(28))),
            Center(child: Text('Pool. Optimize. Pay. Together.', style: bs(12, c: PV.muted))),
            const SizedBox(height: 24),
            PvCard(
              radius: 26,
              padding: const EdgeInsets.all(22),
              borderColor: Colors.transparent,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [_tab('Login', !_signUp), _tab('Sign Up', _signUp)]),
                const SizedBox(height: 20),
                if (_signUp) ...[
                  Text('Full Name', style: bs(14, w: FontWeight.w600)),
                  const SizedBox(height: 8),
                  PvField(controller: _name, hint: 'Your name', icon: Icons.person_outline),
                  const SizedBox(height: 16),
                ],
                Text('Email Address', style: bs(14, w: FontWeight.w600)),
                const SizedBox(height: 8),
                PvField(controller: _email, hint: 'name@example.com', icon: Icons.mail_outline, keyboard: TextInputType.emailAddress),
                const SizedBox(height: 16),
                Text('Password', style: bs(14, w: FontWeight.w600)),
                const SizedBox(height: 8),
                PvField(controller: _pass, hint: '••••••••', icon: Icons.lock_outline, obscure: true),
                if (!_signUp)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: _forgot, child: Text('Forgot Password?', style: bs(12, w: FontWeight.w600))),
                  ),
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFFDE8E8), borderRadius: BorderRadius.circular(12)),
                    child: Text(_error!, style: bs(13, c: PV.red)),
                  ),
                const SizedBox(height: 10),
                PrimaryButton(label: _signUp ? 'Create My Account' : 'Login to My Account', loading: _busy, onPressed: _submit),
                const SizedBox(height: 18),
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: bs(11, w: FontWeight.w600))),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 18),
                OutlineBtn(
                  label: 'Continue with Google',
                  leading: Text('G', style: hs(22, c: const Color(0xFF4285F4))),
                  onPressed: _busy ? null : () => _run(AuthService.google),
                ),
                const SizedBox(height: 12),
                OutlineBtn(
                  label: 'Continue with Apple',
                  leading: const Icon(Icons.apple, color: Colors.black),
                  onPressed: _busy ? null : () => _run(AuthService.apple),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.verified_user, size: 13, color: PV.navy),
              const SizedBox(width: 6),
              Text('Bank-grade 256-bit encryption', style: bs(11, w: FontWeight.w600, c: PV.muted)),
            ]),
          ]),
        ),
      );
}
