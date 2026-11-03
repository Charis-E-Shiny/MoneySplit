import '../env.dart';
import '../models.dart';

/// Payment gateway hook.
///
/// PAYMENT_MODE=demo  -> simulates a successful payment (no real money moves).
/// PAYMENT_MODE=live  -> put your Razorpay / Cashfree / PhonePe PG call here.
///                       Create the order on YOUR SERVER (never ship secret keys
///                       in the app) and verify the signature server-side.
class PaymentGateway {
  static Future<String> charge({required double amount, required String description}) async {
    if (Env.paymentMode == 'live') {
      throw PvError('Live payments are not set up yet. See README, "Going live".');
    }
    await Future.delayed(const Duration(milliseconds: 900));
    return 'demo';
  }
}
