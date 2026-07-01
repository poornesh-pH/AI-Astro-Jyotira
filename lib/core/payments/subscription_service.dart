import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../config.dart';
 
/// Premium entitlement state, backed by RevenueCat (Google Play Billing).
/// `true` => premium active. Configures lazily and is a no-op (always false)
/// when billing is not configured, so the app still builds and runs.
class SubscriptionService extends AsyncNotifier<bool> {
  bool _configured = false;
 
  @override
  Future<bool> build() async {
    if (!AppConfig.billingConfigured) return false;
    if (!_configured) {
      await Purchases.configure(
        PurchasesConfiguration(AppConfig.revenueCatAndroidKey),
      );
      Purchases.addCustomerInfoUpdateListener((info) {
        state = AsyncData(_active(info));
      });
      _configured = true;
    }
    return _active(await Purchases.getCustomerInfo());
  }
 
  bool _active(CustomerInfo info) =>
      info.entitlements.active.containsKey(AppConfig.premiumEntitlement);
 
  Future<Offerings?> offerings() async {
    if (!AppConfig.billingConfigured) return null;
    return Purchases.getOfferings();
  }
 
  /// Returns null on success, or a human-readable error message.
  Future<String?> purchase(Package pkg) async {
    if (!AppConfig.billingConfigured) return 'Billing not configured.';
    state = const AsyncLoading();
    try {
      final info = await Purchases.purchasePackage(pkg);
      state = AsyncData(_active(info));
      return null;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      state = AsyncData(state.valueOrNull ?? false);
      if (code == PurchasesErrorCode.purchaseCancelledError) return null;
      return e.message ?? 'Purchase failed.';
    } catch (e) {
      state = AsyncData(state.valueOrNull ?? false);
      return e.toString();
    }
  }
 
  Future<String?> restore() async {
    if (!AppConfig.billingConfigured) return 'Billing not configured.';
    state = const AsyncLoading();
    try {
      final info = await Purchases.restorePurchases();
      state = AsyncData(_active(info));
      return null;
    } on PlatformException catch (e) {
      state = AsyncData(state.valueOrNull ?? false);
      return e.message ?? 'Restore failed.';
    }
  }
}
 
final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionService, bool>(SubscriptionService.new);
