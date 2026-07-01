import 'dart:convert';
 
enum Planet { sun, moon, mars, mercury, jupiter, venus, saturn, rahu, ketu }
 
const List<String> rashis = [
  'Mesha', 'Vrishabha', 'Mithuna', 'Karka', 'Simha', 'Kanya',
  'Tula', 'Vrishchika', 'Dhanu', 'Makara', 'Kumbha', 'Meena',
];
 
const List<String> nakshatras = [
  'Ashwini', 'Bharani', 'Krittika', 'Rohini', 'Mrigashira', 'Ardra',
  'Punarvasu', 'Pushya', 'Ashlesha', 'Magha', 'Purva Phalguni',
  'Uttara Phalguni', 'Hasta', 'Chitra', 'Swati', 'Vishakha', 'Anuradha',
  'Jyeshtha', 'Mula', 'Purva Ashadha', 'Uttara Ashadha', 'Shravana',
  'Dhanishta', 'Shatabhisha', 'Purva Bhadrapada', 'Uttara Bhadrapada', 'Revati',
];
 
const double _nakSpan = 360 / 27; // 13°20'
 
class PlanetPos {
  final Planet planet;
  final double longitude; // sidereal 0..360
  final bool retrograde;
  const PlanetPos(this.planet, this.longitude, this.retrograde);
 
  int get signIndex => (longitude ~/ 30) % 12;
  int get nakshatraIndex => (longitude ~/ _nakSpan) % 27;
  int get pada => ((longitude % _nakSpan) ~/ (_nakSpan / 4)).toInt() + 1;
  double get degInSign => longitude % 30;
 
  Map<String, dynamic> toJson() => {
        'p': planet.name,
        'sign': rashis[signIndex],
        'deg': double.parse(degInSign.toStringAsFixed(2)),
        'nak': nakshatras[nakshatraIndex],
        'pada': pada,
        'retro': retrograde,
      };
}
 
class DashaPeriod {
  final Planet lord;
  final DateTime start;
  final DateTime end;
  const DashaPeriod(this.lord, this.start, this.end);
 
  bool get isCurrent {
 final now = DateTime.now().toUtc();
    return now.isAfter(start) && now.isBefore(end);
  }
 
  Map<String, dynamic> toJson() => {
        'lord': lord.name,
        'start': start.toIso8601String().substring(0, 10),
        'end': end.toIso8601String().substring(0, 10),
      };
}
 
/// Fully deterministic chart. No randomness, no AI. Identical input always
/// yields an identical chart and an identical [hash].
class Kundli {
  final int lagnaSign; // 0..11
  final List<PlanetPos> planets;
  final List<DashaPeriod> dashas;
 
  const Kundli({
    required this.lagnaSign,
    required this.planets,
    required this.dashas,
  });
 
  PlanetPos byPlanet(Planet p) => planets.firstWhere((e) => e.planet == p);
  PlanetPos get moon => byPlanet(Planet.moon);
  PlanetPos get sun => byPlanet(Planet.sun);
 
  /// Whole-sign house (1..12) of a planet relative to the lagna.
  int houseOf(PlanetPos p) => ((p.signIndex - lagnaSign + 12) % 12) + 1;
 
  /// Planets that fall in a given sign index (0..11).
  List<PlanetPos> inSign(int signIndex) =>
      planets.where((p) => p.signIndex == signIndex).toList();
 
  DashaPeriod get currentDasha =>
      dashas.firstWhere((d) => d.isCurrent, orElse: () => dashas.first);
 
  /// Stable cache key. Same chart => same key => one LLM generation reused.
  String get hash {
    final s = '$lagnaSign|'
        '${planets.map((p) => '${p.planet.name}:${p.longitude.toStringAsFixed(2)}').join(',')}';
    return base64Url.encode(utf8.encode(s)).substring(0, 22);
  }
 
  /// Compact ground truth handed to the LLM. Facts only; never prose.
  Map<String, dynamic> toGroundTruth() => {
        'lagna': rashis[lagnaSign],
        'moonSign': rashis[moon.signIndex],
        'moonNakshatra': nakshatras[moon.nakshatraIndex],
        'sunSign': rashis[sun.signIndex],
        'planets': [
          for (final p in planets) {...p.toJson(), 'house': houseOf(p)},
        ],
        'mahadasha': currentDasha.toJson(),
      };
}
