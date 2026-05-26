import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._();
  factory SubscriptionService() => _instance;
  SubscriptionService._();

  static const String _proEntitlementId = 'pro';

  bool _isPro = false;
  bool get isPro => _isPro;

  final _isProController = StreamController<bool>.broadcast();
  Stream<bool> get isProStream => _isProController.stream;

  bool _initialized = false;

  Future<void> init({required String apiKey, String? appUserId}) async {
    if (_initialized) return;
    await Purchases.setLogLevel(LogLevel.debug);
    final config = PurchasesConfiguration(apiKey);
    config.appUserID = appUserId;
    await Purchases.configure(config);
    _initialized = true;
    final info = await Purchases.getCustomerInfo();
    _updateStatus(info);
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      _updateStatus(customerInfo);
    });
  }

  void _updateStatus(CustomerInfo info) {
    _isPro = info.entitlements.all[_proEntitlementId]?.isActive == true;
    _isProController.add(_isPro);
  }

  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('Failed to load offerings: $e');
      return null;
    }
  }

  Future<CustomerInfo> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      _updateStatus(result.customerInfo);
      return result.customerInfo;
    } catch (e) {
      debugPrint('Purchase failed: $e');
      rethrow;
    }
  }

  Future<CustomerInfo?> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      _updateStatus(info);
      return info;
    } catch (e) {
      debugPrint('Restore purchases failed: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('RevenueCat logout failed: $e');
    }
    _isPro = false;
    _isProController.add(false);
  }

  Future<void> login(String appUserId) async {
    try {
      final result = await Purchases.logIn(appUserId);
      _updateStatus(result.customerInfo);
    } catch (e) {
      debugPrint('RevenueCat login failed: $e');
    }
  }

  void dispose() {
    _isProController.close();
  }
}
