import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/payments/subscription_service.dart';
import '../../../core/prefs/birth_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../kundli/application/kundli_providers.dart';
import '../../kundli/domain/kundli.dart';
 
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider);
    final kundli = ref.watch(kundliProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ज्योतिरा'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(subscriptionProvider);
            ref.invalidate(kundliProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _DailyCard(kundli: kundli.valueOrNull),
              const SizedBox(height: 16),
              const _ActionGrid(),
              const SizedBox(height: 16),
              sub.when(
                loading: () => const _PremiumSkeleton(),
                error: (_, __) => const _PremiumBanner(locked: true),
                data: (active) => _PremiumBanner(locked: !active),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) {
          if (i == 1) context.push('/kundli');
          if (i == 2) context.push('/ask');
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.wb_sunny_outlined), label: 'Today'),
          NavigationDestination(
              icon: Icon(Icons.auto_awesome), label: 'Kundli'),
          NavigationDestination(
              icon: Icon(Icons.forum_outlined), label: 'Ask'),
        ],
      ),
    );
  }
}
 
class _DailyCard extends StatelessWidget {
  const _DailyCard({this.kundli});
  final Kundli? kundli;
 
  @override
  Widget build(BuildContext context) {
    final hasChart = kundli != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.brightness_5, color: AppTheme.saffron),
                const SizedBox(width: 8),
                Text('आज का राशिफल',
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              hasChart
                  ? 'Your ${rashis[kundli!.moon.signIndex]} moon guidance is ready for today.'
                  : 'Set your birth details to unlock today’s personalised guidance.',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  context.push(hasChart ? '/kundli' : '/kundli/edit'),
              icon: Icon(hasChart ? Icons.visibility : Icons.add),
              label: Text(hasChart ? 'View today' : 'Get my reading'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: .06);
  }
}
 
class _ActionGrid extends StatelessWidget {
  const _ActionGrid();
 
  static const _items = [
    (Icons.favorite, 'Compatibility', '/compat'),
    (Icons.shield_moon_outlined, 'Dosha & Remedies', '/dosha'),
    (Icons.event_available, 'Shubh Muhurat', '/muhurat'),
    (Icons.menu_book, 'Full Report', '/report'),
  ];
 
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        for (final (icon, label, route) in _items)
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.push(route),
            child: Card(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: AppTheme.maroon, size: 30),
                    const SizedBox(height: 8),
                    Text(label, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
 
class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner({required this.locked});
  final bool locked;
 
  @override
  Widget build(BuildContext context) {
    if (!locked) {
      return Card(
        color: AppTheme.gold.withValues(alpha: .12),
        child: const ListTile(
          leading: Icon(Icons.verified, color: AppTheme.gold),
          title: Text('Jyotira Premium active'),
          subtitle: Text('All readings & remedies unlocked.'),
        ),
      );
    }
    return Card(
      color: AppTheme.maroon,
      child: ListTile(
        leading: const Icon(Icons.workspace_premium, color: AppTheme.gold),
        title: const Text('Unlock Premium',
            style: TextStyle(color: AppTheme.cream)),
        subtitle: const Text('Full reports, remedies & Ask AI Jyotish',
            style: TextStyle(color: AppTheme.cream)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.gold),
        onTap: () => context.push('/paywall'),
      ),
    );
  }
}
 
class _PremiumSkeleton extends StatelessWidget {
  const _PremiumSkeleton();
  @override
  Widget build(BuildContext context) => const Card(
        child: SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
}
