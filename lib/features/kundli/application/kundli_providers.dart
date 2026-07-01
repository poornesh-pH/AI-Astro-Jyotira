import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/prefs/birth_store.dart';
import '../data/interpretation_repo.dart';
import '../domain/birth_details.dart';
import '../domain/kundli.dart';
import '../domain/kundli_engine.dart';
 
/// Single shared HTTP client; closed when the provider is disposed.
final apiClientProvider = Provider<ApiClient>((ref) {
  final c = ApiClient();
  ref.onDispose(c.dispose);
  return c;
});
 
final interpretationRepoProvider = Provider<InterpretationRepo>(
  (ref) => InterpretationRepo(ref.watch(apiClientProvider)),
);
 
/// Computes the primary user's chart from saved birth details. Pure +
/// deterministic; recomputed only when birth details change.
final kundliProvider = FutureProvider<Kundli?>((ref) async {
  final birth = await ref.watch(birthStoreProvider.future);
  if (birth == null) return null;
  return _computeFor(birth);
});
 
Future<Kundli> _computeFor(BirthDetails b) => KundliEngine.instance.compute(
      birthUtc: b.toUtc(),
      lat: b.lat,
      lng: b.lng,
    );
 
/// Computes a chart for an arbitrary person (used by compatibility).
final chartForProvider =
    FutureProvider.family<Kundli, BirthDetails>((ref, b) => _computeFor(b));
 
/// Fetches an interpretation for the primary chart + a given reading type.
/// Family key includes type + lang so each variant caches independently.
typedef ReadingKey = ({ReadingType type, String lang});
 
final readingProvider =
    FutureProvider.family<String, ReadingKey>((ref, key) async {
  final kundli = await ref.watch(kundliProvider.future);
  if (kundli == null) {
    throw const InterpretationException('Add your birth details first.');
  }
  final repo = ref.watch(interpretationRepoProvider);
  return repo.interpret(
    chartHash: kundli.hash,
    ground: kundli.toGroundTruth(),
    type: key.type,
    lang: key.lang,
  );
});
