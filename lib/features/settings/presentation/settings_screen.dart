import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/payments/subscription_service.dart';
import '../../../core/prefs/birth_store.dart';
import '../../kundli/application/kundli_providers.dart';
 
const supportedLanguages = <({String code, String label})>[
  (code: 'en', label: 'English'),
  (code: 'hi', label: 'हिन्दी'),
  (code: 'ta', label: 'தமிழ்'),
  (code: 'te', label: 'తెలుగు'),
  (code: 'bn', label: 'বাংলা'),
  (code: 'mr', label: 'मराठी'),
];
 
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeStoreProvider).valueOrNull ?? 'en';
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          children: [
            const _SectionHeader('Language'),
            for (final l in supportedLanguages)
              RadioListTile<String>(
                value: l.code,
                groupValue: lang,
                title: Text(l.label),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(localeStoreProvider.notifier).set(v);
                  }
                },
              ),
            const Divider(),
            const _SectionHeader('Account'),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore purchases'),
              onTap: () async {
                final err =
                    await ref.read(subscriptionProvider.notifier).restore();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err ?? 'Purchases restored.')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.workspace_premium),
              title: const Text('Manage subscription'),
              onTap: () => context.push('/paywall'),
            ),
            const Divider(),
            const _SectionHeader('Data'),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit birth details'),
              onTap: () => context.push('/kundli/edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete my birth data'),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Delete birth data?'),
                    content: const Text(
                        'This removes your saved birth details from this device.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref.read(birthStoreProvider.notifier).clear();
                  ref.invalidate(kundliProvider);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
 
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium,
        ),
      );
}
