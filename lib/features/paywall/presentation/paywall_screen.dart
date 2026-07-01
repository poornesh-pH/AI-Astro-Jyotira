import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/config.dart';
import '../../../core/payments/subscription_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
 
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});
  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}
 
class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  late Future<Offerings?> _future;
  bool _busy = false;
 
  @override
  void initState() {
    super.initState();
    _future = ref.read(subscriptionProvider.notifier).offerings();
  }
 
  static const _benefits = [
    'Full life kundli report',
    'Dosha detection + personalised remedies',
    'Compatibility reasoning (Guna Milan)',
    'Ask AI Jyotish — unlimited questions',
    'Daily personalised guidance & muhurat',
  ];
 
  Future<void> _buy(Package pkg) async {
    setState(() => _busy = true);
    final err = await ref.read(subscriptionProvider.notifier).purchase(pkg);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null) {
      if (ref.read(subscriptionProvider).valueOrNull == true) {
        context.pop();
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    }
  }
 
  Future<void> _restore() async {
    setState(() => _busy = true);
    final err = await ref.read(subscriptionProvider.notifier).restore();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Purchases restored.')),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jyotira Premium')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.workspace_premium,
                size: 56, color: AppTheme.gold),
            const SizedBox(height: 12),
            Text('Unlock the complete guidance',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            for (final b in _benefits)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppTheme.saffron, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(b)),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            if (!AppConfig.billingConfigured)
              const EmptyView(
                icon: Icons.info_outline,
                message:
                    'Store billing is not configured in this build.\nAdd REVENUECAT_ANDROID_KEY to enable purchases.',
              )
            else
              FutureBuilder<Offerings?>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const LoadingView();
                  }
                  if (snap.hasError) {
                    return ErrorView(
                      message: snap.error.toString(),
                      onRetry: () => setState(() {
                        _future = ref
                            .read(subscriptionProvider.notifier)
                            .offerings();
                      }),
                    );
                  }
                  final pkgs = snap.data?.current?.availablePackages ??
                      const <Package>[];
                  if (pkgs.isEmpty) {
                    return const EmptyView(
                      icon: Icons.info_outline,
                      message: 'No plans available right now.',
                    );
                  }
                  return Column(
                    children: [
                      for (final p in pkgs) _PlanTile(pkg: p, onBuy: _buy),
                    ],
                  );
                },
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _restore,
              child: const Text('Restore purchases'),
            ),
            if (_busy) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
 
class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.pkg, required this.onBuy});
  final Package pkg;
  final void Function(Package) onBuy;
 
  @override
  Widget build(BuildContext context) {
    final product = pkg.storeProduct;
    return Card(
      child: ListTile(
        title: Text(product.title),
        subtitle: Text(product.description),
        trailing: FilledButton(
          onPressed: () => onBuy(pkg),
          child: Text(product.priceString),
        ),
      ),
    );
  }
}
