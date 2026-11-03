import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads API keys from the bundled `.env` file.
class Env {
  static String _g(String k) => (dotenv.maybeGet(k) ?? '').trim();

  static String get firebaseApiKey => _g('FIREBASE_API_KEY');
  static String get firebaseAppId => _g('FIREBASE_APP_ID');
  static String get firebaseSenderId => _g('FIREBASE_MESSAGING_SENDER_ID');
  static String get firebaseProjectId => _g('FIREBASE_PROJECT_ID');
  static String get firebaseStorageBucket => _g('FIREBASE_STORAGE_BUCKET');
  static String get googleWebClientId => _g('GOOGLE_WEB_CLIENT_ID');
  static String get geminiApiKey => _g('GEMINI_API_KEY');
  static String get geminiModel {
    final m = _g('GEMINI_MODEL');
    return m.isEmpty ? 'gemini-2.0-flash' : m;
  }
  static String get paymentMode {
    final m = _g('PAYMENT_MODE');
    return m.isEmpty ? 'demo' : m;
  }

  static const requiredKeys = [
    'FIREBASE_API_KEY',
    'FIREBASE_APP_ID',
    'FIREBASE_MESSAGING_SENDER_ID',
    'FIREBASE_PROJECT_ID',
  ];

  /// Required keys that are empty or still contain the placeholder text.
  static List<String> get missing =>
      requiredKeys.where((k) => _g(k).isEmpty || _g(k).startsWith('YOUR_')).toList();

  static bool get hasGemini => geminiApiKey.isNotEmpty && !geminiApiKey.startsWith('YOUR_');
  static bool get hasGoogleClientId =>
      googleWebClientId.isNotEmpty && !googleWebClientId.startsWith('YOUR_');
}
