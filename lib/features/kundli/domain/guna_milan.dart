import 'kundli.dart';
 
/// Deterministic Ashtakoota (Guna Milan) — 36-point Vedic compatibility.
/// Inputs are the two natal charts (Moon nakshatra + Moon sign). Output is fully
/// reproducible. No AI, no randomness.
///
/// Fidelity notes (documented, intentional simplifications kept internally
/// consistent): Varna and Vashya use a full-sign model (no half-sign splits);
/// Yoni uses same / sworn-enemy / neutral scoring. Tara, Graha Maitri, Gana,
/// Bhakoot and Nadi follow the standard nakshatra/sign rules.
class GunaResult {
  final double varna; // /1
  final double vashya; // /2
  final double tara; // /3
  final double yoni; // /4
  final double grahaMaitri; // /5
  final double gana; // /6
  final double bhakoot; // /7
  final double nadi; // /8
  const GunaResult(this.varna, this.vashya, this.tara, this.yoni,
      this.grahaMaitri, this.gana, this.bhakoot, this.nadi);
 
  double get total =>
      varna + vashya + tara + yoni + grahaMaitri + gana + bhakoot + nadi;
 
  bool get nadiDosha => nadi == 0;
  bool get bhakootDosha => bhakoot == 0;
 
  List<({String name, double score, int max})> get rows => [
        (name: 'Varna', score: varna, max: 1),
        (name: 'Vashya', score: vashya, max: 2),
        (name: 'Tara', score: tara, max: 3),
        (name: 'Yoni', score: yoni, max: 4),
        (name: 'Graha Maitri', score: grahaMaitri, max: 5),
        (name: 'Gana', score: gana, max: 6),
        (name: 'Bhakoot', score: bhakoot, max: 7),
        (name: 'Nadi', score: nadi, max: 8),
      ];
 
  Map<String, dynamic> toGroundTruth() => {
        'total': double.parse(total.toStringAsFixed(1)),
        'max': 36,
        'breakdown': {for (final r in rows) r.name: r.score},
        'nadiDosha': nadiDosha,
        'bhakootDosha': bhakootDosha,
      };
}
 
class GunaMilan {
  GunaMilan._();
 
  // Gana per nakshatra: 0=Deva, 1=Manushya, 2=Rakshasa.
  static const _gana = [
    0, 1, 2, 1, 0, 1, 0, 0, 2, 2, 1, 1, 0, 2, 0, 2, 0, 2, 2, 1, 1, 0, 2, 2,
    1, 1, 0,
  ];
 
  // Nadi per nakshatra: 0=Aadi, 1=Madhya, 2=Antya.
  static const _nadi = [
    0, 1, 2, 2, 1, 0, 0, 1, 2, 2, 1, 0, 0, 1, 2, 2, 1, 0, 0, 1, 2, 2, 1, 0,
    0, 1, 2,
  ];
 
  // Yoni animal per nakshatra (14 yonis, ids 0..13).
  static const _yoni = [
    0, 1, 2, 3, 3, 4, 5, 2, 5, 6, 6, 7, 8, 9, 8, 9, 10, 10, 4, 11, 12, 11, 13,
    0, 13, 7, 1,
  ];
 
  // Sworn-enemy yoni pairs (Yoni vaira). Same pair => bitter enemies.
  static const _yoniSwornEnemies = <Set<int>>[
    {7, 9}, // Cow - Tiger
    {1, 13}, // Elephant - Lion
    {0, 8}, // Horse - Buffalo
    {4, 10}, // Dog - Deer
    {3, 12}, // Serpent - Mongoose
    {5, 6}, // Cat - Rat
    {2, 11}, // Sheep - Monkey
  ];
 
  // Sign lord per rashi (0..11).
  static const _lord = [
    Planet.mars, Planet.venus, Planet.mercury, Planet.moon, Planet.sun,
    Planet.mercury, Planet.venus, Planet.mars, Planet.jupiter, Planet.saturn,
    Planet.saturn, Planet.jupiter,
  ];
 
  // Planetary natural relationship: friend(1) / neutral(0) / enemy(-1).
  static const Map<Planet, Map<Planet, int>> _rel = {
    Planet.sun: {
      Planet.moon: 1, Planet.mars: 1, Planet.jupiter: 1,
      Planet.mercury: 0, Planet.venus: -1, Planet.saturn: -1,
    },
    Planet.moon: {
      Planet.sun: 1, Planet.mercury: 1,
      Planet.mars: 0, Planet.jupiter: 0, Planet.venus: 0, Planet.saturn: 0,
    },
    Planet.mars: {
      Planet.sun: 1, Planet.moon: 1, Planet.jupiter: 1,
      Planet.venus: 0, Planet.saturn: 0, Planet.mercury: -1,
    },
    Planet.mercury: {
      Planet.sun: 1, Planet.venus: 1,
      Planet.mars: 0, Planet.jupiter: 0, Planet.saturn: 0, Planet.moon: -1,
    },
    Planet.jupiter: {
      Planet.sun: 1, Planet.moon: 1, Planet.mars: 1,
      Planet.saturn: 0, Planet.mercury: -1, Planet.venus: -1,
    },
    Planet.venus: {
      Planet.mercury: 1, Planet.saturn: 1,
      Planet.mars: 0, Planet.jupiter: 0, Planet.sun: -1, Planet.moon: -1,
    },
    Planet.saturn: {
      Planet.mercury: 1, Planet.venus: 1,
      Planet.jupiter: 0, Planet.sun: -1, Planet.moon: -1, Planet.mars: -1,
    },
  };
 
  // Gana koota matrix (groom x bride): [Deva, Manushya, Rakshasa].
  static const _ganaMatrix = [
    [6.0, 6.0, 0.0],
    [5.0, 6.0, 0.0],
    [1.0, 0.0, 6.0],
  ];
 
  static int _varnaOf(int sign) {
    // water=Brahmin(4), fire=Kshatriya(3), earth=Vaishya(2), air=Shudra(1)
    const map = [3, 2, 1, 4, 3, 2, 1, 4, 3, 2, 1, 4];
    return map[sign];
  }
 
  // Vashya group per sign: 0=Quadruped,1=Human,2=Water,3=Wild,4=Insect.
  static const _vashyaGroup = [0, 0, 1, 2, 3, 1, 1, 4, 1, 2, 1, 2];
 
  /// groomMoonSign/brideMoonSign are 0..11; nakshatra indices are 0..26.
  static GunaResult compute({
    required int groomMoonSign,
    required int groomNak,
    required int brideMoonSign,
    required int brideNak,
  }) {
    return GunaResult(
      _varna(groomMoonSign, brideMoonSign),
      _vashya(groomMoonSign, brideMoonSign),
      _tara(groomNak, brideNak),
      _yoniScore(groomNak, brideNak),
      _grahaMaitri(groomMoonSign, brideMoonSign),
      _ganaScore(groomNak, brideNak),
      _bhakoot(groomMoonSign, brideMoonSign),
      _nadiScore(groomNak, brideNak),
    );
  }
 
  static double _varna(int g, int b) =>
      _varnaOf(g) >= _varnaOf(b) ? 1 : 0;
 
  static double _vashya(int g, int b) {
    if (_vashyaGroup[g] == _vashyaGroup[b]) return 2;
    return 1; // simplified non-same scoring
  }
 
  static double _tara(int gNak, int bNak) {
    bool auspicious(int from, int to) {
      final count = ((to - from + 27) % 27) + 1;
      final r = count % 9;
      return !(r == 3 || r == 5 || r == 7);
    }
 
    var score = 0.0;
    if (auspicious(bNak, gNak)) score += 1.5;
    if (auspicious(gNak, bNak)) score += 1.5;
    return score;
  }
 
  static double _yoniScore(int gNak, int bNak) {
    final a = _yoni[gNak];
    final b = _yoni[bNak];
    if (a == b) return 4;
    for (final pair in _yoniSwornEnemies) {
      if (pair.contains(a) && pair.contains(b)) return 0;
    }
    return 2; // neutral
  }
 
  static double _grahaMaitri(int g, int b) {
    final lg = _lord[g];
    final lb = _lord[b];
    if (lg == lb) return 5;
    final ab = _rel[lg]?[lb] ?? 0; // how groom-lord sees bride-lord
    final ba = _rel[lb]?[lg] ?? 0;
    final pair = {ab, ba};
    if (ab == 1 && ba == 1) return 5;
    if (pair.contains(1) && pair.contains(0)) return 4;
    if (ab == 0 && ba == 0) return 3;
    if (pair.contains(1) && pair.contains(-1)) return 1;
    if (pair.contains(0) && pair.contains(-1)) return 0.5;
    return 0; // mutual enemy
  }
 
  static double _ganaScore(int gNak, int bNak) =>
      _ganaMatrix[_gana[gNak]][_gana[bNak]];
 
  static double _bhakoot(int g, int b) {
    final c1 = ((b - g + 12) % 12) + 1;
    final c2 = ((g - b + 12) % 12) + 1;
    final set = {c1, c2};
    const dosha = [
      {2, 12},
      {5, 9},
      {6, 8},
    ];
    for (final d in dosha) {
      if (set.length == d.length && set.containsAll(d)) return 0;
    }
    return 7;
  }
 
  static double _nadiScore(int gNak, int bNak) =>
      _nadi[gNak] == _nadi[bNak] ? 0 : 8;
}
