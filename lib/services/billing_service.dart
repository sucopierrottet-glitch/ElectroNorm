import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'storage_service.dart';

class BillingService extends ChangeNotifier {
  static const String monthlyProductId = 'electronorm_pro_monthly';
  static const String yearlyProductId = 'electronorm_pro_yearly';
  static const Set<String> productIds = {monthlyProductId, yearlyProductId};

  final StorageService storageService;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Map<String, ProductDetails> _displayProducts = {};
  Map<String, ProductDetails> _purchaseProducts = {};

  bool _isStoreAvailable = false;
  bool _isLoadingProducts = true;
  bool _isPurchasePending = false;
  String? _lastError;
  bool _purchaseSucceeded = false;

  BillingService({required this.storageService});

  InAppPurchase get _iap => InAppPurchase.instance;

  bool get isStoreAvailable => _isStoreAvailable;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isPurchasePending => _isPurchasePending;
  String? get lastError => _lastError;
  bool get purchaseSucceeded => _purchaseSucceeded;

  /// Recurring base plan product details used for displaying regular prices.
  ProductDetails? get monthlyProduct => _displayProducts[monthlyProductId];
  ProductDetails? get yearlyProduct => _displayProducts[yearlyProductId];

  /// Preferred product details used at checkout (prioritizes free-trial offers).
  ProductDetails? get monthlyPurchaseProduct =>
      _purchaseProducts[monthlyProductId] ?? _displayProducts[monthlyProductId];
  ProductDetails? get yearlyPurchaseProduct =>
      _purchaseProducts[yearlyProductId] ?? _displayProducts[yearlyProductId];

  /// Whether Google Play returned a free-trial offer (`rawPrice == 0`) for the
  /// requested subscription tier. Defaults to `true` before catalog load or
  /// in test mode so standard trial messaging renders consistently.
  bool hasFreeTrialOffer({required bool isYearly}) {
    final targetId = isYearly ? yearlyProductId : monthlyProductId;
    final purchaseProduct = _purchaseProducts[targetId];
    if (purchaseProduct == null) {
      return true;
    }
    return purchaseProduct.rawPrice == 0;
  }

  /// Indexes Google Play product details into display (recurring base price)
  /// and purchase (lowest/free-trial offer) maps.
  ///
  /// Google Play Billing returns one entry per eligible offer plus one for the
  /// base plan under the exact same [ProductDetails.id]. Keeping both roles
  /// separate guarantees the UI always displays the recurring price while checkout
  /// always attaches the free-trial offer token when eligible.
  @visibleForTesting
  void indexProductDetails(List<ProductDetails> productDetails) {
    final display = <String, ProductDetails>{};
    final purchase = <String, ProductDetails>{};

    for (final product in productDetails) {
      final existingPurchase = purchase[product.id];
      if (existingPurchase == null || product.rawPrice < existingPurchase.rawPrice) {
        purchase[product.id] = product;
      }

      if (product.rawPrice > 0) {
        final existingDisplay = display[product.id];
        if (existingDisplay == null || product.rawPrice > existingDisplay.rawPrice) {
          display[product.id] = product;
        }
      }
    }

    _displayProducts = display;
    _purchaseProducts = purchase;
  }

  Future<void> init() async {
    if (StorageService.isTestEnvironment) {
      _isLoadingProducts = false;
      _isStoreAvailable = false;
      notifyListeners();
      return;
    }

    try {
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (Object error) {
          _isPurchasePending = false;
          _lastError = error.toString();
          notifyListeners();
        },
      );
      await loadProducts();
    } catch (e) {
      _isLoadingProducts = false;
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadProducts() async {
    if (StorageService.isTestEnvironment) {
      _isLoadingProducts = false;
      notifyListeners();
      return;
    }

    _isLoadingProducts = true;
    _lastError = null;
    notifyListeners();

    try {
      _isStoreAvailable = await _iap.isAvailable();
      if (!_isStoreAvailable) {
        _isLoadingProducts = false;
        notifyListeners();
        return;
      }

      final response = await _iap.queryProductDetails(productIds);
      if (response.error != null) {
        _lastError = response.error!.message;
      }
      indexProductDetails(response.productDetails);
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  Future<String?> buySubscription({required bool isYearly}) async {
    _lastError = null;
    _purchaseSucceeded = false;
    notifyListeners();

    if (StorageService.isTestEnvironment) {
      return 'store_unavailable';
    }

    final available = await _iap.isAvailable();
    if (!available) {
      return 'store_unavailable';
    }

    final targetId = isYearly ? yearlyProductId : monthlyProductId;
    var product = _purchaseProducts[targetId] ?? _displayProducts[targetId];

    if (product == null) {
      await loadProducts();
      product = _purchaseProducts[targetId] ?? _displayProducts[targetId];
    }

    if (product == null) {
      return 'product_not_found';
    }

    try {
      _isPurchasePending = true;
      notifyListeners();

      final purchaseParam = PurchaseParam(productDetails: product);
      final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!started) {
        _isPurchasePending = false;
        notifyListeners();
        return 'purchase_not_started';
      }
      return null;
    } catch (e) {
      _isPurchasePending = false;
      _lastError = e.toString();
      notifyListeners();
      return 'purchase_error';
    }
  }

  Future<String?> restorePurchases() async {
    _lastError = null;
    _purchaseSucceeded = false;
    notifyListeners();

    if (StorageService.isTestEnvironment) {
      return 'store_unavailable';
    }

    final available = await _iap.isAvailable();
    if (!available) {
      return 'store_unavailable';
    }

    try {
      _isPurchasePending = true;
      notifyListeners();
      await _iap.restorePurchases();
      // Give stream a short window if there are no previous purchases to emit
      Future.delayed(const Duration(seconds: 2), () {
        if (_isPurchasePending) {
          _isPurchasePending = false;
          notifyListeners();
        }
      });
      return null;
    } catch (e) {
      _isPurchasePending = false;
      _lastError = e.toString();
      notifyListeners();
      return 'restore_error';
    }
  }

  Future<void> _onPurchaseUpdate(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _isPurchasePending = true;
          notifyListeners();
          break;

        case PurchaseStatus.error:
          _isPurchasePending = false;
          _lastError = purchaseDetails.error?.message ?? 'Error';
          if (purchaseDetails.pendingCompletePurchase) {
            await _iap.completePurchase(purchaseDetails);
          }
          notifyListeners();
          break;

        case PurchaseStatus.canceled:
          _isPurchasePending = false;
          if (purchaseDetails.pendingCompletePurchase) {
            await _iap.completePurchase(purchaseDetails);
          }
          notifyListeners();
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await storageService.setProSubscriber(true);
          if (purchaseDetails.productID == yearlyProductId) {
            await storageService.setSubscriptionTier('annual');
          } else if (purchaseDetails.productID == monthlyProductId) {
            await storageService.setSubscriptionTier('monthly');
          }
          if (purchaseDetails.pendingCompletePurchase) {
            await _iap.completePurchase(purchaseDetails);
          }
          _isPurchasePending = false;
          _purchaseSucceeded = true;
          notifyListeners();
          break;
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
