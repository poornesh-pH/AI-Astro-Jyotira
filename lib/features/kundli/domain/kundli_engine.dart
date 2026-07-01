import 'package:sweph/sweph.dart';
import 'kundli.dart';
 
/// Deterministic Vedic chart engine.
///
/// All astronomy is computed by the Swiss Ephemeris with the Lahiri (Chitrapaksha)
/// sidereal ayanamsa and whole-sign houses. There is NO randomness and NO AI in
/// this file: the same birth instant + coordinates always produce the exact same
/// chart. The AI layer only narrates the output of this engine — it never invents
/// positions.
///
/// NOTE (single point to verify against the pinned package): the `sweph` Dart
/// package is a native port; method/enum names are stable across the pinned 2.10.x
/// but are the only API surface in this project that depends on the bundled native
/// library. The ephemeris `.se1` data files must be present in assets/ephe/.
class KundliEngine {
  KundliEngine._();
  static final KundliEngine instance = KundliEngine._();
 
  bool _ready = false;
 
  Future<void> ensureReady() async {
    if (_ready) return;
    // If the .se1 assets are missing, Sweph falls back to the built-in Moshier
    // model (lower precision) rather than crashing.
    await Sweph.init(
      epheAssets: const [
        'packages/sweph/assets/ephe/seas_18.se1',
      ],
    );
   Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI, SiderealModeFlag.none, SiderealModeFlag.none); 
    _ready = true;
  }
 
  /// [birthUtc] MUST already be UTC. [lat]/[lng] in decimal degrees.
  Future<Kundli> compute({
    required DateTime birthUtc,
    required double lat,
    required double lng,
  }) async {
    await ensureReady();
 
    final u = birthUtc.toUtc();
    final hourDec = u.hour + u.minute / 60.0 + u.second / 3600.0;
    final jd = Sweph.swe_julday(
      u.year,
      u.month,
      u.day,
      hourDec,
      CalendarType.SE_GREG_CAL,
    );
 
    const flags = SwephFlag.SEFLG_SIDEREAL |
        SwephFlag.SEFLG_SWIEPH |
        SwephFlag.SEFLG_SPEED;
 
    const bodies = <Planet, HeavenlyBody>{
      Planet.sun: HeavenlyBody.SE_SUN,
      Planet.moon: HeavenlyBody.SE_MOON,
      Planet.mars: HeavenlyBody.SE_MARS,
      Planet.mercury: HeavenlyBody.SE_MERCURY,
      Planet.jupiter: HeavenlyBody.SE_JUPITER,
      Planet.venus: HeavenlyBody.SE_VENUS,
      Planet.saturn: HeavenlyBody.SE_SATURN,
    };
 
    final planets = <PlanetPos>[];
    for (final e in bodies.entries) {
      final r = Sweph.swe_calc_ut(jd, e.value, flags);
      planets.add(
        PlanetPos(e.key, _norm(r.longitude), r.speedInLongitude < 0),
      );
    }
 
    // Mean lunar node = Rahu; Ketu exactly opposite. Both treated retrograde.
    final node = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MEAN_NODE, flags);
    final rahuLon = _norm(node.longitude);
    planets.add(PlanetPos(Planet.rahu, rahuLon, true));
    planets.add(PlanetPos(Planet.ketu, _norm(rahuLon + 180), true));
 
    final asc = _ascendant(jd, lat, lng, flags);
    final lagnaSign = (asc ~/ 30) % 12;
 
    final moon = planets.firstWhere((p) => p.planet == Planet.moon);
    final dashas = _vimshottari(moon.longitude, u);
 
    return Kundli(lagnaSign: lagnaSign, planets: planets, dashas: dashas);
  }
 
  double _ascendant(double jd, double lat, double lng, int flags) {
    final h = Sweph.swe_houses_ex(jd, flags, lat, lng, Hsys.W);
    // ascmc[0] is the ascendant per Swiss Ephemeris convention.
    return _norm(h.ascmc[0]);
  }
 
  double _norm(double d) => ((d % 360) + 360) % 360;
 
  // ---------- Vimshottari Mahadasha (deterministic) ----------
  static const List<Planet> _seq = [
    Planet.ketu, Planet.venus, Planet.sun, Planet.moon, Planet.mars,
    Planet.rahu, Planet.jupiter, Planet.saturn, Planet.mercury,
  ];
  static const List<int> _years = [7, 20, 6, 10, 7, 18, 16, 19, 17]; // 120 yrs
 
  List<DashaPeriod> _vimshottari(double moonLon, DateTime birthUtc) {
    const span = 360 / 27;
    final nak = (moonLon ~/ span).toInt() % 27;
    final lordIdx = nak % 9;
    final fraction = (moonLon % span) / span; // elapsed within nakshatra
 
    final out = <DashaPeriod>[];
    var cursor = birthUtc;
 
    final balanceYears = _years[lordIdx] * (1 - fraction);
    final firstEnd = _addYears(cursor, balanceYears);
    out.add(DashaPeriod(_seq[lordIdx], birthUtc, firstEnd));
    cursor = firstEnd;
 
    // Extend across ~120 years so the current mahadasha is always covered.
    for (var i = 1; i <= 9; i++) {
      final idx = (lordIdx + i) % 9;
      final end = _addYears(cursor, _years[idx].toDouble());
      out.add(DashaPeriod(_seq[idx], cursor, end));
      cursor = end;
    }
    return out;
  }
 
  DateTime _addYears(DateTime d, double years) =>
      d.add(Duration(seconds: (years * 365.2425 * 86400).round()));
}
