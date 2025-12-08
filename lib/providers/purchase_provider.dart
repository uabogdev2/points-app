import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/purchase_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class PurchaseProvider with ChangeNotifier {
  final PurchaseService _purchaseService = PurchaseService();
  bool _isLoading = false;
  bool _isPurchasing = false;
  bool _isRestoring = false;
  String? _error;
  ProductDetails? _product;
  bool _adsRemoved = false;

  bool get isLoading => _isLoading;
  bool get isPurchasing => _isPurchasing;
  bool get isRestoring => _isRestoring;
  String? get error => _error;
  ProductDetails? get product => _product;
  bool get adsRemoved => _adsRemoved;

  PurchaseProvider() {
    _initialize();
  }

  void _initialize() {
    // Configurer les callbacks du service
    _purchaseService.onPurchaseSuccess = (purchaseDetails) {
      debugPrint('✅ [PURCHASE_PROVIDER] Achat réussi');
      _isPurchasing = false;
      _checkPurchaseStatus();
      notifyListeners();
    };

    _purchaseService.onPurchaseError = (error) {
      debugPrint('❌ [PURCHASE_PROVIDER] Erreur achat: $error');
      _error = error;
      _isPurchasing = false;
      notifyListeners();
    };

    _purchaseService.onPurchasePending = () {
      debugPrint('⏳ [PURCHASE_PROVIDER] Achat en attente');
      _isPurchasing = true;
      notifyListeners();
    };
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Vérifier la disponibilité
      await _purchaseService.isAvailable();
      
      // Charger les produits
      await _purchaseService.loadProducts();
      _product = _purchaseService.getProduct();
      
      // Vérifier le statut actuel
      await _checkPurchaseStatus();
    } catch (e) {
      debugPrint('❌ [PURCHASE_PROVIDER] Erreur initialisation: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkPurchaseStatus() async {
    try {
      final status = await ApiService.getPurchaseStatus();
      _adsRemoved = status['ads_removed'] as bool? ?? false;
      debugPrint('💳 [PURCHASE_PROVIDER] Statut: ads_removed=$_adsRemoved');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [PURCHASE_PROVIDER] Erreur vérification statut: $e');
    }
  }

  Future<void> purchaseRemoveAds() async {
    if (_isPurchasing) return;

    _isPurchasing = true;
    _error = null;
    notifyListeners();

    try {
      await _purchaseService.purchaseRemoveAds();
    } catch (e) {
      debugPrint('❌ [PURCHASE_PROVIDER] Erreur achat: $e');
      _error = e.toString();
      _isPurchasing = false;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    if (_isRestoring) return;

    _isRestoring = true;
    _error = null;
    notifyListeners();

    try {
      await _purchaseService.restorePurchases();
      
      // Attendre un peu pour que la restauration se termine
      await Future.delayed(const Duration(seconds: 2));
      
      // Vérifier le statut après restauration
      await _checkPurchaseStatus();
      
      _error = null;
    } catch (e) {
      debugPrint('❌ [PURCHASE_PROVIDER] Erreur restauration: $e');
      _error = e.toString();
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> refreshStatus() async {
    await _checkPurchaseStatus();
  }

  void updateFromUser(User user) {
    if (_adsRemoved != user.adsRemoved) {
      _adsRemoved = user.adsRemoved;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _purchaseService.dispose();
    super.dispose();
  }
}

