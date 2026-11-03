import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'env.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/setup_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}
  final missing = Env.missing;
  String? initError;
  if (missing.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: Env.firebaseApiKey,
          appId: Env.firebaseAppId,
          messagingSenderId: Env.firebaseSenderId,
          projectId: Env.firebaseProjectId,
          storageBucket: Env.firebaseStorageBucket.isEmpty ? null : Env.firebaseStorageBucket,
        ),
      );
    } catch (e) {
      initError = e.toString();
    }
  }
  runApp(PvApp(missing: missing, initError: initError));
}

class PvApp extends StatelessWidget {
  final List<String> missing;
  final String? initError;
  const PvApp({super.key, required this.missing, this.initError});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Paisa Vasool',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: (missing.isNotEmpty || initError != null)
            ? SetupScreen(missing: missing, error: initError)
            : const AuthGate(),
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator(color: PV.navy)));
          }
          return snap.data != null ? const HomeScreen() : const OnboardingScreen();
        },
      );
}
