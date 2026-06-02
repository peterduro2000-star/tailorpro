import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/license_model.dart';

class InAppPurchaseService {
  static const Set<String> productIds = <String>{
    'tailorpro_pro',
  };

  final InAppPurchase _iap = InAppPurchase.instance;

  bool available = false;
  bool loading = false;
  String? lastError;
  List<ProductDetails> products = [];

  Stream<List<PurchaseDetails>> get purchaseUpdates => _iap.purchaseStream;

  Future<void> init() async {
    loading = true;
    lastError = null;

    available = await _iap.isAvailable();
    if (!available) {
      loading = false;
      return;
    }

    final response = await _iap.queryProductDetails(productIds);
    if (response.error != null) {
      lastError = response.error!.message;
    }

    products = response.productDetails;
    loading = false;
  }

  Future<void> buyProduct(ProductDetails product) async {
    if (!available) {
      throw Exception('In-app purchases are not available');
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    if (!available) {
      throw Exception('In-app purchases are not available');
    }
    await _iap.restorePurchases();
  }

  LicenseTier? tierForProductId(String productId) {
    switch (productId) {
      case 'tailorpro_pro':
        return LicenseTier.pro;
      default:
        return null;
    }
  }

  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }
}
