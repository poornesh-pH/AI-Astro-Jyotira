import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'app/router.dart';
import 'core/prefs/birth_store.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
 
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones(); // required before any birth-time conversion
  runApp(const ProviderScope(child: JyotiraApp()));
}
 
class JyotiraApp extends ConsumerWidget {
  const JyotiraApp({super.key});
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeStoreProvider).valueOrNull ?? 'en';
    return MaterialApp.router(
      title: 'Jyotira',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
      locale: Locale(lang),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
