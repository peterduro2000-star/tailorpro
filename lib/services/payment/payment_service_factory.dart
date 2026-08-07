import 'payment_service.dart';
import 'paystack_payment_service.dart';
import 'play_billing_payment_service.dart';

const bool kIsPlayStoreBuild = bool.fromEnvironment(
  'PLAY_STORE_BUILD',
  defaultValue: false,
);

class PaymentServiceFactory {
  static PaymentService create() {
    if (kIsPlayStoreBuild) {
      return PlayBillingPaymentService();
    }
    return PaystackPaymentService();
  }
}
