import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/kundli/domain/birth_details.dart';
 
/// Persists the primary user's birth details + chosen language locally.
class BirthStore extends AsyncNotifier<BirthDetails?> {
  static const _kBirth = 'birth_details_v1';
 
  @override
  Future<BirthDetails?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kBirth);
    if (raw == null) return null;
    try {
      return BirthDetails.decode(raw);
    } catch (_) {
      return null; // corrupt entry -> treat as empty
    }
  }
 
  Future<void> save(BirthDetails details) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBirth, details.encode());
    state = AsyncData(details);
  }
 
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBirth);
    state = const AsyncData(null);
  }
}
 
final birthStoreProvider =
    AsyncNotifierProvider<BirthStore, BirthDetails?>(BirthStore.new);
 
/// App language code (ISO 639-1). Defaults to English; persisted.
class LocaleStore extends AsyncNotifier<String> {
  static const _kLang = 'lang_v1';
 
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLang) ?? 'en';
  }
 
  Future<void> set(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLang, code);
    state = AsyncData(code);
  }
}
 
final localeStoreProvider =
    AsyncNotifierProvider<LocaleStore, String>(LocaleStore.new);
