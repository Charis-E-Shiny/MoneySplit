import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    ('Pool Your Resources', 'Create shared wallets for trips, events, or daily expenses. One place for all group funds.', Icons.account_balance_wallet_outlined),
    ('Optimize Every Payment', 'We compare gift cards, bank cards and UPI offers so your group always pays the least.', Icons.auto_awesome),
    ('Decide Together', 'Every payment goes to a group vote first. Full transparency, no awkward follow-ups.', Icons.how_to_vote_outlined),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _auth(bool signUp) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AuthScreen(startOnSignUp: signUp)));

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(children: [
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const AppLogo(size: 40),
              const SizedBox(width: 10),
              Text('PAISA VASOOL', style: hs(20)),
            ]),
            const SizedBox(height: 4),
            Text('Pool. Optimize. Pay. Together.', style: bs(12, w: FontWeight.w600, c: PV.muted)),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(children: [
                      const SizedBox(height: 20),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                              colors: [Color(0xFF3B4B66), PV.navy]),
                          ),
                          child: Center(child: Icon(p.$3, size: 110, color: Colors.white.withOpacity(0.92))),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(p.$1, style: hs(26), textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      Text(p.$2, style: bs(15, c: PV.muted).copyWith(height: 1.45), textAlign: TextAlign.center),
                    ]),
                  );
                },
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < _pages.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 14),
                  width: i == _page ? 24 : 7, height: 7,
                  decoration: BoxDecoration(color: i == _page ? PV.navy : PV.border, borderRadius: BorderRadius.circular(8)),
                ),
            ]),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: PrimaryButton(label: 'Get Started', onPressed: () => _auth(true)),
            ),
            TextButton(onPressed: () => _auth(false), child: Text('Sign In', style: bs(14, w: FontWeight.w600))),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.verified_user, size: 14, color: PV.navy),
                const SizedBox(width: 6),
                Text('Secure & Transparent Treasury', style: bs(11, w: FontWeight.w600, c: PV.muted)),
              ]),
            ),
          ]),
        ),
      );
}
