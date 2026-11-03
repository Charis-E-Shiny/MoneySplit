import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';

/// Shown instead of the app when `.env` still has placeholder keys.
class SetupScreen extends StatelessWidget {
  final List<String> missing;
  final String? error;
  const SetupScreen({super.key, required this.missing, this.error});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
            const AppLogo(size: 60),
            const SizedBox(height: 20),
            Text('Add your API keys', style: hs(26)),
            const SizedBox(height: 8),
            Text('Open the .env file in the project root, paste your keys, then stop and re-run the app.',
                style: bs(14, c: PV.muted)),
            const SizedBox(height: 20),
            if (missing.isNotEmpty)
              PvCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Still missing', style: hs(15)),
                  const SizedBox(height: 8),
                  for (final k in missing) Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: PV.red, size: 18),
                      const SizedBox(width: 8),
                      Text(k, style: bs(13, w: FontWeight.w600)),
                    ]),
                  ),
                ]),
              ),
            if (error != null) ...[
              const SizedBox(height: 12),
              PvCard(child: Text('Firebase could not start:\n$error', style: bs(13, c: PV.red))),
            ],
            const SizedBox(height: 16),
            Text('README.md, Step 1 and Step 2, shows where to find each value.', style: bs(13, c: PV.muted)),
          ]),
        ),
      );
}
