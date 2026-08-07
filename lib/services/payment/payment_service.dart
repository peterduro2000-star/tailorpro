abstract class PaymentService {
  Future<String?> purchasePro({required String email});
  Future<bool> verifyPayment(String reference);
  Future<String?> getDisplayPrice();
}
