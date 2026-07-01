/// Runtime configuration. Provide values at build time via --dart-define:
///   flutter build apk --dart-define=API_BASE_URL=https://api.example.com \
///       --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx
///
/// The app builds and runs without these; network-backed features will show a
/// friendly "service not configured" state until set. Secrets never ship in the
/// client — the LLM key lives only on the server.
class AppConfig {
  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');
 
  static const String revenueCatAndroidKey =
      String.fromEnvironment('REVENUECAT_ANDROID_KEY', defaultValue: '');
 
  static const String premiumEntitlement = 'premium';
 
  static bool get apiConfigured => apiBaseUrl.isNotEmpty;
  static bool get billingConfigured => revenueCatAndroidKey.isNotEmpty;
}
