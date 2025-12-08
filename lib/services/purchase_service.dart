import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import '../utils/config.dart';
import 'api_service.dart';

class PurchaseService {
  static const String _productId = 'remove_ads';
  
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  
  // Callbacks
  Function(PurchaseDetails)? onPurchaseSuccess;
  Function(String)? onPurchaseError;
  Function()? onPurchasePending;

  PurchaseService() {
    _initialize();
  }

  void _initialize() {
    // Écouter les mises à jour d'achat
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () {
        debugPrint('💳 [PURCHASE] Stream terminé');
      },
      onError: (error) {
        debugPrint('❌ [PURCHASE] Erreur stream: $error');
      },
    );
  }

  Future<bool> isAvailable() async {
    _isAvailable = await _inAppPurchase.isAvailable();
    debugPrint('💳 [PURCHASE] Disponible: $_isAvailable');
    return _isAvailable;
  }

  Future<void> loadProducts() async {
    if (!_isAvailable) {
      await isAvailable();
    }

    if (!_isAvailable) {
      debugPrint('⚠️ [PURCHASE] Les achats in-app ne sont pas disponibles');
      return;
    }

    try {
      final Set<String> productIds = {_productId};
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.error != null) {
        debugPrint('❌ [PURCHASE] Erreur queryProductDetails: ${response.error}');
        return;
      }

      if (response.productDetails.isEmpty) {
        debugPrint('⚠️ [PURCHASE] Aucun produit trouvé');
        return;
      }

      _products = response.productDetails;
      debugPrint('✅ [PURCHASE] Produits chargés: ${_products.length}');
      
      for (var product in _products) {
        debugPrint('  - ${product.id}: ${product.title} - ${product.price}');
      }
    } catch (e) {
      debugPrint('❌ [PURCHASE] Exception loadProducts: $e');
    }
  }

  ProductDetails? getProduct() {
    if (_products.isEmpty) return null;
    return _products.firstWhere(
      (product) => product.id == _productId,
      orElse: () => _products.first,
    );
  }

  Future<void> purchaseRemoveAds() async {
    if (!_isAvailable) {
      onPurchaseError?.call('Les achats in-app ne sont pas disponibles');
      return;
    }

    if (_products.isEmpty) {
      await loadProducts();
    }

    final product = getProduct();
    if (product == null) {
      onPurchaseError?.call('Produit non disponible');
      return;
    }

    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      if (Platform.isAndroid) {
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else if (Platform.isIOS) {
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        onPurchaseError?.call('Plateforme non supportée');
      }
    } catch (e) {
      debugPrint('❌ [PURCHASE] Exception purchaseRemoveAds: $e');
      onPurchaseError?.call('Erreur lors de l\'achat: $e');
    }
  }

  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      onPurchaseError?.call('Les achats in-app ne sont pas disponibles');
      return;
    }

    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('✅ [PURCHASE] Restauration des achats lancée');
    } catch (e) {
      debugPrint('❌ [PURCHASE] Exception restorePurchases: $e');
      onPurchaseError?.call('Erreur lors de la restauration: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      debugPrint('💳 [PURCHASE] Mise à jour achat: ${purchaseDetails.status}');
      
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('⏳ [PURCHASE] Achat en attente');
        onPurchasePending?.call();
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint('❌ [PURCHASE] Erreur achat: ${purchaseDetails.error}');
        onPurchaseError?.call(purchaseDetails.error?.message ?? 'Erreur inconnue');
        _completePurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        debugPrint('✅ [PURCHASE] Achat réussi ou restauré');
        _handleSuccessfulPurchase(purchaseDetails);
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    try {
      // Vérifier l'achat côté serveur
      final platform = Platform.isAndroid ? 'android' : 'ios';
      final purchaseToken = purchaseDetails.verificationData.serverVerificationData;
      
      debugPrint('💳 [PURCHASE] Vérification côté serveur...');
      debugPrint('  Product ID: ${purchaseDetails.productID}');
      debugPrint('  Transaction ID: ${purchaseDetails.purchaseID}');
      debugPrint('  Platform: $platform');
      
      await ApiService.verifyPurchase(
        productId: purchaseDetails.productID,
        transactionId: purchaseDetails.purchaseID ?? '',
        platform: platform,
        purchaseToken: Platform.isAndroid ? purchaseToken : null,
        receiptData: Platform.isIOS ? purchaseToken : null,
      );
      
      debugPrint('✅ [PURCHASE] Achat vérifié côté serveur');
      onPurchaseSuccess?.call(purchaseDetails);
    } catch (e) {
      debugPrint('❌ [PURCHASE] Erreur vérification serveur: $e');
      onPurchaseError?.call('Erreur de vérification: $e');
    } finally {
      _completePurchase(purchaseDetails);
    }
  }

  void _completePurchase(PurchaseDetails purchaseDetails) {
    if (purchaseDetails.pendingCompletePurchase) {
      _inAppPurchase.completePurchase(purchaseDetails);
      debugPrint('✅ [PURCHASE] Achat complété');
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}

