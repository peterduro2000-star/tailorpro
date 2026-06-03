import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/license_model.dart';

class InAppPurchaseService {
  static const Set<String> productIds = <String>{
    'poultry_pro', // Must match Play Console product ID exactly
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

    if (response.notFoundIDs.isNotEmpty) {
      lastError =
          'Products not found in Play Store: ${response.notFoundIDs.join(', ')}. '
          'Ensure the app is installed via the internal testing link.';
    }

    products = response.productDetails;
    loading = false;
  }

  Future<void> buyProduct(ProductDetails product) async {
    if (!available) {
      throw Exception('In-app purchases are not available');
    }

    // Play Billing detects the SKU type automatically —
    // buyNonConsumable works for both subscriptions and one-time products.
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    if (!available) {
      throw Exception('In-app purchases are not available');
    }
    await _iap.restorePurchases();
  }

  /// Maps a Play Store product ID to the corresponding [LicenseTier].
  LicenseTier? tierForProductId(String productId) {
    switch (productId) {
      case 'poultry_pro':
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