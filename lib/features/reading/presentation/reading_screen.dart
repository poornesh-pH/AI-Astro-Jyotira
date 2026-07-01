import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/payments/subscription_service.dart';
import '../../../core/prefs/birth_store.dart';
import '../../../core/widgets/state_views.dart';
import '../../kundli/application/kundli_providers.dart';
import '../../kundli/data/interpretation_repo.dart';
 
/// One screen powering every long-form premium reading (full report, dosha &
/// remedies, shubh muhurat). DRY: behaviour differs only by [type] + title.
class ReadingScreen extends ConsumerWidget {
  const ReadingScreen({
    super.key,
    required this.type,
    required this.title,
    this.premium = true,
  });
 
  final ReadingType type;
  final String title;
  final bool premium;
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
 final sub = ref.watch(subscriptionProvider);
    final lang = ref.watch(localeStoreProvider).valueOrNull ?? 'en';
 
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: sub.when(
          loading: () => const LoadingView(),
          error: (_, __) => _gateOrBody(context, ref, lang, locked: premium),
          data: (active) =>
              _gateOrBody(context, ref, lang, locked: premium && !active),
        ),
      ),
    );
  }
 
  Widget _gateOrBody(
    BuildContext context,
    WidgetRef ref,
    String lang, {
    required bool locked,
  }) {
    if (locked) {
      return PremiumLock(onUnlock: () => context.push('/paywall'));
    }
    final key = (type: type, lang: lang);
    final async = ref.watch(readingProvider(key));
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(readingProvider(key)),
      child: async.when(
        loading: () => const LoadingView(label: 'Preparing your reading…'),
        error: (e, _) => ListView(
          children: [
            const SizedBox(height: 120),
            ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(readingProvider(key)),
            ),
          ],
        ),
        data: (text) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SelectableText(
              text,
              style: const TextStyle(height: 1.5, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
