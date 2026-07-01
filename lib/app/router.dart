import 'package:go_router/go_router.dart';
import '../features/ask/presentation/ask_screen.dart';
import '../features/compat/presentation/compat_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/kundli/data/interpretation_repo.dart';
import '../features/kundli/presentation/birth_form.dart';
import '../features/kundli/presentation/kundli_screen.dart';
import '../features/paywall/presentation/paywall_screen.dart';
import '../features/reading/presentation/reading_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
 
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/kundli', builder: (_, __) => const KundliScreen()),
    GoRoute(
      path: '/kundli/edit',
      builder: (_, state) => BirthForm(
        redirectTo: state.uri.queryParameters['next'] ?? '/kundli',
      ),
    ),
    GoRoute(
      path: '/report',
      builder: (_, __) => const ReadingScreen(
        type: ReadingType.report,
        title: 'Full Report',
      ),
    ),
    GoRoute(
      path: '/dosha',
      builder: (_, __) => const ReadingScreen(
        type: ReadingType.dosha,
        title: 'Dosha & Remedies',
      ),
    ),
    GoRoute(
      path: '/muhurat',
      builder: (_, __) => const ReadingScreen(
        type: ReadingType.muhurat,
        title: 'Shubh Muhurat',
      ),
    ),
    GoRoute(path: '/compat', builder: (_, __) => const CompatScreen()),
    GoRoute(path: '/ask', builder: (_, __) => const AskScreen()),
    GoRoute(path: '/paywall', builder: (_, __) => const PaywallScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
);
