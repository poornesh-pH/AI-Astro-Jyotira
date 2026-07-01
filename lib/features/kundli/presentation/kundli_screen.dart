import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/prefs/birth_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../application/kundli_providers.dart';
import '../data/interpretation_repo.dart';
import '../domain/kundli.dart';
import 'chart_painter.dart';
 
class KundliScreen extends ConsumerWidget {
  const KundliScreen({super.key});
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kundliAsync = ref.watch(kundliProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Kundli'),
        actions: [
          IconButton(
            tooltip: 'Edit details',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/kundli/edit'),
          ),
        ],
      ),
      body: SafeArea(
        child: kundliAsync.when(
          loading: () => const LoadingView(label: 'Computing your chart…'),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(kundliProvider),
          ),
          data: (kundli) {
            if (kundli == null) {
              return EmptyView(
                message: 'Add your birth details to generate your kundli.',
                actionLabel: 'Add details',
                onAction: () => context.push('/kundli/edit'),
              );
            }
            return _KundliBody(kundli: kundli);
          },
        ),
      ),
    );
  }
}
 
class _KundliBody extends ConsumerWidget {
  const _KundliBody({required this.kundli});
  final Kundli kundli;
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeStoreProvider).valueOrNull ?? 'en';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lagna (Ascendant): ${rashis[kundli.lagnaSign]}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Moon: ${rashis[kundli.moon.signIndex]} '
                  '(${nakshatras[kundli.moon.nakshatraIndex]})',
                ),
                const SizedBox(height: 16),
                AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(painter: NorthChartPainter(kundli)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _PlanetTable(kundli: kundli),
        const SizedBox(height: 16),
        _DashaCard(kundli: kundli),
        const SizedBox(height: 16),
        _DailyNarration(lang: lang),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => context.push('/report'),
          icon: const Icon(Icons.menu_book),
          label: const Text('Read full premium report'),
        ),
      ],
    );
  }
}
 
class _PlanetTable extends StatelessWidget {
  const _PlanetTable({required this.kundli});
  final Kundli kundli;
 
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: DataTable(
          headingRowHeight: 36,
          dataRowMinHeight: 34,
          dataRowMaxHeight: 40,
          columns: const [
            DataColumn(label: Text('Planet')),
            DataColumn(label: Text('Sign')),
            DataColumn(label: Text('House')),
            DataColumn(label: Text('Nakshatra')),
          ],
          rows: [
            for (final p in kundli.planets)
              DataRow(cells: [
                DataCell(Text(_name(p.planet))),
                DataCell(Text(rashis[p.signIndex])),
                DataCell(Text('${kundli.houseOf(p)}')),
                DataCell(Text(
                  '${nakshatras[p.nakshatraIndex]} (${p.pada})',
                )),
              ]),
          ],
        ),
      ),
    );
  }
 
  String _name(Planet p) =>
      p.name[0].toUpperCase() + p.name.substring(1);
}
 
class _DashaCard extends StatelessWidget {
  const _DashaCard({required this.kundli});
  final Kundli kundli;
 
  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMM();
    final current = kundli.currentDasha;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vimshottari Mahadasha',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final d in kundli.dashas.take(4))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      d == current
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color: d == current ? AppTheme.saffron : AppTheme.gold,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_cap(d.lord.name)}  ·  '
                        '${df.format(d.start)} – ${df.format(d.end)}',
                        style: TextStyle(
                          fontWeight:
                              d == current ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
 
  String _cap(String s) => s[0].toUpperCase() + s.substring(1);
}
 
class _DailyNarration extends ConsumerWidget {
  const _DailyNarration({required this.lang});
  final String lang;
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (type: ReadingType.daily, lang: lang);
    final async = ref.watch(readingProvider(key));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny_outlined, color: AppTheme.saffron),
                const SizedBox(width: 8),
                Text("Today's guidance",
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            async.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: LoadingView(),
              ),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(readingProvider(key)),
              ),
              data: (text) => Text(
                text,
                style: const TextStyle(height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
