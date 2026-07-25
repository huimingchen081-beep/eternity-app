import 'package:in_app_purchase/in_app_purchase.dart';
import '../utils/constants.dart';

class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;
  bool _isAvailable = false;
  bool _isPurchased = false;
  List<ProductDetails> _products = [];
  bool _initialized = false;

  bool get isAvailable => _isAvailable;
  bool get isPurchased => _isPurchased;
  List<ProductDetails> get products => _products;
  bool get initialized => _initialized;

  Future<void> init() async {
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) return;

    const Set<String> productIds = {
      AppConstants.iapAppleProductId,
      AppConstants.iapGoogleProductId,
    };

    final response = await _iap.queryProductDetails(productIds);
    _products = response.productDetails;

    // Check if already purchased (non-consumable)
    await _restorePurchases();

    // Listen for purchase updates
    _iap.purchaseStream.listen(_onPurchaseUpdate);

    _initialized = true;
  }

  Future<void> _restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (_) {}
  }

  void _onPurchaseUpdate(List<PurchaseDetails> details) {
    for (final purchase in details) {
      _handlePurchase(purchase);
    }
  }

  void _handlePurchase(PurchaseDetails purchase) {
    switch (purchase.status) {
      case PurchaseStatus.purchased:
        _isPurchased = true;
        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      case PurchaseStatus.restored:
        _isPurchased = true;
        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      case PurchaseStatus.error:
        break;
      case PurchaseStatus.pending:
        break;
      case PurchaseStatus.canceled:
        break;
    }
  }

  Future<bool> purchase() async {
    if (_products.isEmpty || !_isAvailable) return false;

    try {
      final product = _products.firstWhere(
        (p) =>
            p.id == AppConstants.iapAppleProductId ||
            p.id == AppConstants.iapGoogleProductId,
      );

      final param = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: param);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> restore() async {
    try {
      await _iap.restorePurchases();
      return _isPurchased;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _initialized = false;
  }
}
