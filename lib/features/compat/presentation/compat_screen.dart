import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/payments/subscription_service.dart';
import '../../../core/prefs/birth_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../kundli/application/kundli_providers.dart';
import '../../kundli/domain/birth_details.dart';
import '../../kundli/domain/guna_milan.dart';
import '../../kundli/domain/kundli.dart';
 
/// Collects partner birth details, computes deterministic Ashtakoota (36 pts)
/// against the saved primary chart, then shows the score breakdown. Result is
/// premium-gated. Score is reproducible; never random.
class CompatScreen extends ConsumerStatefulWidget {
  const CompatScreen({super.key});
  @override
  ConsumerState<CompatScreen> createState() => _CompatScreenState();
}
 
class _CompatScreenState extends ConsumerState<CompatScreen> {
  DateTime? _date;
  TimeOfDay? _time;
  GunaResult? _result;
  bool _computing = false;
  String? _error;
 
  Future<void> _compute() async {
    setState(() {
      _error = null;
      _computing = true;
    });
    try {
      final me = await ref.read(kundliProvider.future);
      if (me == null) {
        setState(() => _error = 'Add your own birth details first.');
        return;
      }
      if (_date == null || _time == null) {
        setState(() => _error = 'Select partner date and time of birth.');
        return;
      }
      // Partner chart uses the user's birth place tz for time conversion
      // (place-agnostic for Moon sign/nakshatra-based Guna Milan).
      final my = await ref.read(birthStoreProvider.future);
      final partner = BirthDetails(
        name: 'Partner',
        gender: 'other',
        date: _date!,
        hour: _time!.hour,
        minute: _time!.minute,
        placeName: my!.placeName,
        lat: my.lat,
        lng: my.lng,
        tzId: my.tzId,
      );
      final partnerChart =
          await ref.read(chartForProvider(partner).future);
 
      final res = GunaMilan.compute(
        groomMoonSign: me.moon.signIndex,
        groomNak: me.moon.nakshatraIndex,
        brideMoonSign: partnerChart.moon.signIndex,
        brideNak: partnerChart.moon.nakshatraIndex,
      );
      setState(() => _result = res);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _computing = false);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final sub = ref.watch(subscriptionProvider);
    final premium = sub.valueOrNull ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Compatibility (Guna Milan)')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Partner birth details',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date of birth'),
                    subtitle: Text(_date == null
                        ? 'Select'
                        : DateFormat.yMMMMd().format(_date!)),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setState(() => _date = d);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Time of birth'),
                    subtitle: Text(_time == null
                        ? 'Select'
                        : _time!.format(context)),
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 12, minute: 0),
                      );
                      if (t != null) setState(() => _time = t);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _computing ? null : _compute,
              icon: const Icon(Icons.favorite),
              label: const Text('Match horoscopes'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              ErrorView(message: _error!),
            ],
            if (_computing) ...[
              const SizedBox(height: 24),
              const LoadingView(),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              _ScoreView(result: _result!, premium: premium),
            ],
          ],
        ),
      ),
    );
  }
}
 
class _ScoreView extends StatelessWidget {
  const _ScoreView({required this.result, required this.premium});
  final GunaResult result;
  final bool premium;
 
  @override
  Widget build(BuildContext context) {
    final pct = result.total / 36;
    final verdict = result.total >= 18 ? 'Favourable' : 'Needs caution';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${result.total.toStringAsFixed(1)} / 36',
                    style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                Chip(
                  label: Text(verdict),
                  backgroundColor: pct >= .5
                      ? AppTheme.gold.withValues(alpha: .2)
                      : AppTheme.error.withValues(alpha: .15),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: pct, minHeight: 8),
            const SizedBox(height: 16),
            for (final r in result.rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(child: Text(r.name)),
                    Text('${r.score.toStringAsFixed(1)} / ${r.max}'),
                  ],
                ),
              ),
            if (result.nadiDosha || result.bhakootDosha) ...[
              const SizedBox(height: 12),
              Text(
                [
                  if (result.nadiDosha) 'Nadi dosha present',
                  if (result.bhakootDosha) 'Bhakoot dosha present',
                ].join(' · '),
                style: const TextStyle(color: AppTheme.error),
              ),
            ],
            if (!premium) ...[
              const Divider(height: 28),
              PremiumLock(
                message:
                    'Unlock the detailed reasoning and remedies for this match.',
                onUnlock: () => context.push('/paywall'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
