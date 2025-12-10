import 'dart:convert';
import 'dart:math';

/// ====== 基础枚举 ======
enum WuXing { metal, wood, water, fire, earth }

enum Gender { male, female, other }

/// ====== 输入/输出结构 ======
class NameProfile {
  final String fullName; // 全名
  final String surname; // 姓（支持复姓）
  final String givenName; // 名
  final List<int> strokes; // 逐字笔画
  final List<String> radicals; // 逐字部首（与映射表“部首”一致）
  final List<String> pinyin; // 逐字拼音（小写无声调）
  final DateTime birthDateTime; // 出生时间
  final String? zodiacZh; // 生肖
  final Gender gender; // 性别
  final int? personalityNumber; // 生日性格数字 (1-9等)

  NameProfile({
    required this.fullName,
    required this.surname,
    required this.givenName,
    required this.strokes,
    required this.radicals,
    required this.pinyin,
    required this.birthDateTime,
    this.zodiacZh,
    this.gender = Gender.other,
    this.personalityNumber,
  }) : assert(
         fullName.runes.length == strokes.length &&
             strokes.length == radicals.length &&
             radicals.length == pinyin.length,
         'strokes/radicals/pinyin 长度必须等于姓名字符数',
       );
}

class NameScore {
  final double total; // 0..100
  final Map<String, double> components; // 各项 0..100
  final Map<String, dynamic> notes;

  NameScore(this.total, this.components, this.notes);

  @override
  String toString() =>
      'Total ${total.toStringAsFixed(1)} / 100\n$components\n$notes';
}

/// ====== 部首→五行映射提供器 ======
class RadicalProvider {
  final Map<String, WuXing> map;
  final Set<String> wildcards;

  RadicalProvider(this.map, this.wildcards);

  factory RadicalProvider.fromMap(Map<String, String> raw) {
    final m = <String, WuXing>{};
    final w = <String>{};
    raw.forEach((rad, elm) {
      final e = _parseElement(elm);
      if (e == null) {
        w.add(rad);
      } else {
        m[rad] = e;
      }
    });
    return RadicalProvider(m, w);
  }

  static WuXing? _parseElement(String s) {
    switch (s.trim()) {
      case '金':
        return WuXing.metal;
      case '木':
        return WuXing.wood;
      case '水':
        return WuXing.water;
      case '火':
        return WuXing.fire;
      case '土':
        return WuXing.earth;
      default:
        return null;
    }
  }
}

/// ====== 子时(23–01)跨日安全处理 ======
class Shichen {
  static const _ranges = <String, (int, int)>{
    '子': (23, 1),
    '丑': (1, 3),
    '寅': (3, 5),
    '卯': (5, 7),
    '辰': (7, 9),
    '巳': (9, 11),
    '午': (11, 13),
    '未': (13, 15),
    '申': (15, 17),
    '酉': (17, 19),
    '戌': (19, 21),
    '亥': (21, 23),
  };

  static DateTime toDateTime({
    required DateTime birthDate,
    required String shichenOrRange,
  }) {
    final (sh, eh) = _parseHours(shichenOrRange);
    final hour = (sh == 23 && eh == 1) ? 23 : _mid(sh, eh);
    return DateTime(birthDate.year, birthDate.month, birthDate.day, hour, 30);
  }

  static (int, int) _parseHours(String s) {
    final t = s.trim();
    if (_ranges.containsKey(t)) return _ranges[t]!;
    final m = RegExp(r'^(\d{1,2})\s*-\s*(\d{1,2})$').firstMatch(t);
    if (m != null) {
      final a = int.parse(m.group(1)!);
      final b = int.parse(m.group(2)!);
      return (a % 24, b % 24);
    }
    return (0, 0);
  }

  static int _mid(int s, int e) {
    var span = e - s;
    if (span <= 0) span += 24;
    return ((s + span / 2) % 24).round();
  }
}

/// ====== 配置 ======
class ScoringConfig {
  Map<String, double> weights = const {
    'grid': 0.10,
    'elements': 0.18,
    'coherence': 0.28,
    'harmony': 0.15,
    'phonetics': 0.05,
    'genderStyle': 0.04,
    'balance': 0.05,
    'zodiac': 0.30,
    'personality': 0.18,
    'calibration': 0.0,
  };

  final Map<int, double> gridLuck = const {
    1: 1,
    3: 0.6,
    5: 0.6,
    6: 0.8,
    7: 0.7,
    8: 1,
    11: 1,
    13: 0.8,
    15: 1,
    16: 0.7,
    17: 0.7,
    18: 0.6,
    21: 1,
    23: 0.9,
    24: 0.6,
    25: 0.8,
    29: 0.8,
    31: 1,
    32: 0.6,
    33: 0.9,
    35: 0.8,
    37: 0.7,
    39: 1,
    41: 0.8,
    45: 0.7,
    47: 0.8,
    48: 0.6,
    52: 0.6,
    57: 0.7,
    61: 0.8,
    63: 0.7,
    65: 0.6,
    67: 0.8,
    68: 0.6,
    81: 1,
    2: -0.7,
    4: -0.6,
    10: -0.5,
    12: -0.7,
    14: -0.6,
    19: -0.7,
    20: -0.6,
    22: -0.8,
    26: -0.6,
    28: -0.5,
    34: -0.7,
    38: -0.6,
    42: -0.6,
    44: -0.7,
    49: -0.6,
    51: -0.6,
    54: -0.7,
    55: -0.6,
    58: -0.7,
    59: -0.6,
    60: -0.6,
    64: -0.7,
    69: -0.6,
    73: -0.7,
    74: -0.6,
    76: -0.7,
    79: -0.6,
    80: -0.5,
  };
  final Map<String, WuXing> initialElement = const {
    'b': WuXing.water,
    'p': WuXing.water,
    'm': WuXing.water,
    'f': WuXing.water,
    'd': WuXing.wood,
    't': WuXing.wood,
    'n': WuXing.wood,
    'l': WuXing.wood,
    'g': WuXing.metal,
    'k': WuXing.metal,
    'h': WuXing.metal,
    'j': WuXing.fire,
    'q': WuXing.fire,
    'x': WuXing.fire,
    'r': WuXing.fire,
    'zh': WuXing.earth,
    'ch': WuXing.earth,
    'sh': WuXing.earth,
    'z': WuXing.earth,
    'c': WuXing.earth,
    's': WuXing.earth,
    'y': WuXing.wood,
    'w': WuXing.water,
  };
  final Map<int, List<WuXing>> seasonPreference = const {
    1: [WuXing.water, WuXing.metal, WuXing.wood],
    2: [WuXing.wood, WuXing.fire, WuXing.water],
    3: [WuXing.wood, WuXing.fire, WuXing.earth],
    4: [WuXing.wood, WuXing.fire, WuXing.earth],
    5: [WuXing.fire, WuXing.earth, WuXing.wood],
    6: [WuXing.fire, WuXing.earth, WuXing.metal],
    7: [WuXing.fire, WuXing.earth, WuXing.metal],
    8: [WuXing.earth, WuXing.metal, WuXing.water],
    9: [WuXing.metal, WuXing.earth, WuXing.water],
    10: [WuXing.metal, WuXing.water, WuXing.earth],
    11: [WuXing.metal, WuXing.water, WuXing.wood],
    12: [WuXing.water, WuXing.metal, WuXing.wood],
  };

  final Map<int, WuXing> hourTint = {
    0: WuXing.water,
    1: WuXing.earth,
    2: WuXing.earth,
    3: WuXing.wood,
    4: WuXing.wood,
    5: WuXing.wood,
    6: WuXing.wood,
    7: WuXing.fire,
    8: WuXing.fire,
    9: WuXing.fire,
    10: WuXing.fire,
    11: WuXing.earth,
    12: WuXing.earth,
    13: WuXing.earth,
    14: WuXing.metal,
    15: WuXing.metal,
    16: WuXing.metal,
    17: WuXing.metal,
    18: WuXing.metal,
    19: WuXing.water,
    20: WuXing.water,
    21: WuXing.water,
    22: WuXing.water,
  };
}

/// ====== 生肖辅助 ======
const List<String> _zodiacOrder = [
  '鼠',
  '牛',
  '虎',
  '兔',
  '龙',
  '蛇',
  '马',
  '羊',
  '猴',
  '鸡',
  '狗',
  '猪',
];

String _zodiacFromGregorianYear(int year) {
  final idx = (year - 1900) % 12;
  return _zodiacOrder[(idx + 12) % 12];
}

final Map<String, WuXing> _zodiacNative = {
  '鼠': WuXing.water,
  '牛': WuXing.earth,
  '虎': WuXing.wood,
  '兔': WuXing.wood,
  '龙': WuXing.earth,
  '蛇': WuXing.fire,
  '马': WuXing.fire,
  '羊': WuXing.earth,
  '猴': WuXing.metal,
  '鸡': WuXing.metal,
  '狗': WuXing.earth,
  '猪': WuXing.water,
};
final Map<String, List<WuXing>> _zodiacFav = {
  '鼠': [WuXing.water, WuXing.metal],
  '牛': [WuXing.earth, WuXing.metal, WuXing.water],
  '虎': [WuXing.wood, WuXing.fire],
  '兔': [WuXing.wood, WuXing.water],
  '龙': [WuXing.earth, WuXing.water],
  '蛇': [WuXing.fire, WuXing.earth],
  '马': [WuXing.fire, WuXing.wood],
  '羊': [WuXing.earth, WuXing.wood],
  '猴': [WuXing.metal, WuXing.water],
  '鸡': [WuXing.metal, WuXing.earth],
  '狗': [WuXing.earth, WuXing.fire],
  '猪': [WuXing.water, WuXing.wood],
};

WuXing _avoidedOf(String animal) {
  final n = _zodiacNative[animal];
  switch (n) {
    case WuXing.wood:
      return WuXing.metal;
    case WuXing.fire:
      return WuXing.water;
    case WuXing.earth:
      return WuXing.wood;
    case WuXing.metal:
      return WuXing.fire;
    case WuXing.water:
      return WuXing.earth;
    default:
      return WuXing.earth;
  }
}

/// ====== 评分核心 ======
class NameScorer {
  final ScoringConfig cfg;
  final RadicalProvider radicals;

  NameScorer({required this.cfg, required this.radicals});

  double _scoreGrid(NameProfile p) {
    const gw = {'天': 0.18, '人': 0.30, '地': 0.22, '外': 0.10, '总': 0.20};
    final g = _fiveGrids(p);
    double s = 0, wsum = 0;
    g.forEach((k, v) {
      final luck = cfg.gridLuck[v] ?? 0.0;
      final scaled = ((luck + 1) / 2).clamp(0, 1);
      final w = gw[k] ?? 0.2;
      s += scaled * w;
      wsum += w;
    });
    return 100 * (wsum == 0 ? 0.5 : s / wsum);
  }

  double _scoreElements(NameProfile p) {
    final prefs = _preferredElements(p);
    final hour = cfg.hourTint[p.birthDateTime.hour];
    final initials = p.pinyin.map(_extractInitial).toList();
    double hits = 0, total = 0;
    for (int i = 0; i < p.fullName.runes.length; i++) {
      final r = p.radicals[i];
      if (radicals.wildcards.contains(r)) {
        hits += 1;
        total += 1;
      } else {
        final re = radicals.map[r];
        if (re != null) {
          total += 1;
          if (prefs.contains(re)) hits += 1;
          if (prefs.isNotEmpty && re == prefs[0]) hits += 0.25;
        }
      }
      final ie = cfg.initialElement[initials[i]];
      if (ie != null) {
        total += 0.7;
        if (prefs.contains(ie)) hits += 0.7;
      }
    }
    final lastRad = p.radicals.last;
    final lastElem = radicals.wildcards.contains(lastRad)
        ? hour
        : radicals.map[lastRad];
    if (hour != null) {
      total += 0.4;
      if (lastElem == hour) hits += 0.4;
    }
    if (total == 0) return 50;
    return (100 * (hits / total)).clamp(0, 100);
  }

  double _scoreCoherence(NameProfile p) {
    final prefs = _preferredElements(p);
    final zodiac = _resolveZodiac(p);
    final native = _zodiacNative[zodiac];
    final favored = _zodiacFav[zodiac] ?? const <WuXing>[];
    final initials = p.pinyin.map(_extractInitial).toList();
    final elems = <WuXing>[];
    for (int i = 0; i < p.fullName.runes.length; i++) {
      final r = p.radicals[i];
      if (radicals.wildcards.contains(r)) continue;
      final re = radicals.map[r];
      if (re != null) {
        elems.add(re);
        continue;
      }
      final ie = cfg.initialElement[initials[i]];
      if (ie != null) elems.add(ie);
    }
    if (elems.isEmpty) return 50;
    final cnt = <WuXing, int>{};
    for (final e in elems) {
      cnt[e] = (cnt[e] ?? 0) + 1;
    }
    final total = elems.length;
    final main = cnt.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final ratio = (cnt[main]! / total).clamp(0.0, 1.0);
    double s = ratio * 100;
    if (prefs.contains(main)) {
      final idx = prefs.indexOf(main);
      s += (idx == 0
          ? 10
          : idx == 1
          ? 6
          : 3);
    }
    if (native != null && main == native) s += 8;
    if (favored.contains(main)) s += 6;
    if (cnt[main] == total && total == 3) s += 10;
    return s.clamp(0, 100);
  }

  double _scoreHarmony(NameProfile p) {
    final sl = p.surname.runes.length;
    final surRad = p.radicals[sl - 1];
    final lastRad = p.radicals.last;
    WuXing? a = radicals.wildcards.contains(surRad)
        ? null
        : radicals.map[surRad];
    WuXing? b = radicals.wildcards.contains(lastRad)
        ? null
        : radicals.map[lastRad];
    a ??= cfg.initialElement[_extractInitial(p.pinyin[sl - 1])];
    b ??= cfg.initialElement[_extractInitial(p.pinyin.last)];
    if (a == null || b == null) return 60;
    if (_generates(a, b)) return 95;
    if (_same(a, b)) return 85;
    if (_generates(b, a)) return 78;
    if (_overcomes(a, b)) return 58;
    if (_overcomes(b, a)) return 68;
    return 70;
  }

  double _scorePhonetics(NameProfile p) {
    final syll = p.pinyin.map((s) => s.toLowerCase()).toList();
    final inits = syll.map(_extractInitial).toList();
    final n = syll.length;
    double s = 70;
    if (n == 2 || n == 3) s += 10;
    if (n >= 4) s -= 10;
    for (int i = 1; i < n; i++) {
      if (syll[i] == syll[i - 1]) s -= 10;
    }
    s += min(10, 4.0 * (inits.toSet().length - 1));
    if (inits.every((i) => i.isEmpty)) s -= 8;
    return s.clamp(0, 100);
  }

  double _scoreBalance(NameProfile p) {
    final xs = p.strokes.map((e) => e.toDouble()).toList();
    final mean = xs.reduce((a, b) => a + b) / xs.length;
    final varr =
        xs.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / xs.length;
    final sd = sqrt(varr);
    double s = 75;
    if (sd <= 2)
      s += 10;
    else if (sd <= 4)
      s += 5;
    else if (sd >= 8)
      s -= 8;
    final tot = xs.reduce((a, b) => a + b);
    if (tot > 50) s -= min(10, (tot - 50) * 0.3);
    if (p.givenName.runes.length == 2) s += 5;
    return s.clamp(0, 100);
  }

  double _scoreCalibration(NameProfile p) {
    return 50.0;
  }

  double _scorePersonality(NameProfile p) {
    if (p.personalityNumber == null) return 50.0;
    final birthNum = p.personalityNumber! % 10;
    const Map<int, WuXing> numElementMap = {
      1: WuXing.metal,
      6: WuXing.metal,
      2: WuXing.water,
      7: WuXing.water,
      3: WuXing.fire,
      8: WuXing.fire,
      4: WuXing.wood,
      9: WuXing.wood,
      5: WuXing.earth,
      0: WuXing.earth,
    };
    final birthElement = numElementMap[birthNum];
    final nameElement = _mainElementOf(p);
    if (birthElement == null || nameElement == null) return 50.0;
    if (_generates(nameElement, birthElement)) return 95.0;
    if (_same(nameElement, birthElement)) return 85.0;
    if (_generates(birthElement, nameElement)) return 75.0;
    if (_overcomes(birthElement, nameElement)) return 60.0;
    if (_overcomes(nameElement, birthElement)) return 40.0;
    return 50.0;
  }

  // <<<< 1. 这是修改后的“性别契合度”函数，基础分改为80
  double _scoreGenderStyle(NameProfile p) {
    if (p.gender == Gender.other) return 50;
    final inits = p.pinyin.map(_extractInitial).toList();
    final hard = {'g', 'k', 'd', 'b', 'zh', 'ch', 'sh', 'r'};
    final soft = {'x', 'q', 'sh', 'y'};
    int h = 0, sf = 0, vowel = 0;
    for (final i in inits) {
      if (i.isEmpty) vowel++;
      if (hard.contains(i)) h++;
      if (soft.contains(i)) sf++;
    }
    double s = 80; // <<<< 采纳您的建议，将基础分从50改为80
    if (p.gender == Gender.male) {
      s += min(8.0, h * 3.0);
      s -= min(5.0, vowel * 2.0);
    } else {
      s += min(8.0, sf * 3.0);
      if (h >= inits.length && inits.isNotEmpty) s -= 5.0;
    }
    return s.clamp(0, 100);
  }

  // <<<< 2. 这是全新优化的“生肖适配”函数，加入了“功过相抵”逻辑
  double _scoreZodiac(NameProfile p) {
    final z = _resolveZodiac(p);
    if (z.isEmpty) return 50;
    final native = _zodiacNative[z];
    final favored = _zodiacFav[z] ?? const <WuXing>[];
    final avoided = _avoidedOf(z);

    final initials = p.pinyin.map(_extractInitial).toList();
    final nameElements = <WuXing>[];
    for (int i = 0; i < p.fullName.runes.length; i++) {
      final radEl = radicals.map[p.radicals[i]];
      if (radEl != null) nameElements.add(radEl);
      final pinEl = cfg.initialElement[initials[i]];
      if (pinEl != null) nameElements.add(pinEl);
    }
    if (nameElements.isEmpty) return 50;

    int nativeCount = 0;
    int favoredCount = 0;
    int avoidedCount = 0;
    for (final el in nameElements) {
      if (el == native)
        nativeCount++;
      else if (favored.contains(el))
        favoredCount++;
      else if (el == avoided)
        avoidedCount++;
    }

    double positiveScore =
        100 * (nativeCount * 1.0 + favoredCount * 0.5) / nameElements.length;

    double penalty = 0;
    if (avoidedCount > 0) {
      double basePenalty = avoidedCount * 0.4;
      double mitigation = (positiveScore / 100) * 0.7;
      penalty = basePenalty * (1 - mitigation);
    }

    double finalScore = positiveScore * (1 - penalty);

    final main = _mainElementOf(p);
    if (native != null && main != null && main == native) {
      finalScore += 10;
    }

    return finalScore.clamp(0, 100);
  }

  NameScore score(NameProfile p) {
    final comps = <String, double>{
      'grid': _scoreGrid(p),
      'elements': _scoreElements(p),
      'coherence': _scoreCoherence(p),
      'harmony': _scoreHarmony(p),
      'phonetics': _scorePhonetics(p),
      'genderStyle': _scoreGenderStyle(p),
      'balance': _scoreBalance(p),
      'zodiac': _scoreZodiac(p),
      'personality': _scorePersonality(p),
      'calibration': _scoreCalibration(p),
    };
    double sum = 0, wsum = 0;
    cfg.weights.forEach((k, w) {
      sum += (comps[k] ?? 0) * w;
      wsum += w;
    });

    final double rawTotal = (sum / (wsum == 0 ? 1 : wsum));

    // <<<< 3. 应用最终的“总分美化曲线”
    final double finalTotal = rawTotal + (100 - rawTotal) * 0.15;

    final birthElement = p.personalityNumber != null
        ? const {
            1: WuXing.metal,
            6: WuXing.metal,
            2: WuXing.water,
            7: WuXing.water,
            3: WuXing.fire,
            8: WuXing.fire,
            4: WuXing.wood,
            9: WuXing.wood,
            5: WuXing.earth,
            0: WuXing.earth,
          }[p.personalityNumber! % 10]
        : null;
    return NameScore(
      finalTotal.clamp(0, 100),
      comps.map((k, v) => MapEntry(k, v.clamp(0, 100))),
      {
        'fiveGrids': _fiveGrids(p),
        'preferredElements': _preferredElements(p),
        'zodiac': _resolveZodiac(p),
        'mainElement': _mainElementOf(p),
        'personalityNumber': p.personalityNumber,
        'birthElement': birthElement,
      },
    );
  }

  String _resolveZodiac(NameProfile p) {
    if (p.zodiacZh != null && p.zodiacZh!.trim().isNotEmpty) {
      final t = p.zodiacZh!.trim();
      for (final a in _zodiacOrder) {
        if (t.contains(a)) return a;
      }
      return t;
    }
    return _zodiacFromGregorianYear(p.birthDateTime.year);
  }

  Map<String, int> _fiveGrids(NameProfile p) {
    final sl = p.surname.runes.length;
    final st = p.strokes;
    final total = st.reduce((a, b) => a + b);
    final sSt = st.sublist(0, sl);
    final gSt = st.sublist(sl);
    final tiange = (sl >= 2) ? sSt.reduce((a, b) => a + b) : (sSt.first + 1);
    final renge = sSt.last + (gSt.isNotEmpty ? gSt.first : 1);
    final dige = (gSt.isEmpty)
        ? 1
        : (gSt.length == 1 ? gSt.first + 1 : gSt.reduce((a, b) => a + b));
    final waige = total - renge;
    final zongge = total;
    return {'天': tiange, '人': renge, '地': dige, '外': waige, '总': zongge};
  }

  List<WuXing> _preferredElements(NameProfile p) {
    final list = cfg.seasonPreference[p.birthDateTime.month] ?? [WuXing.earth];
    final hour = cfg.hourTint[p.birthDateTime.hour];
    final out = <WuXing>[...list];
    if (hour != null && !out.contains(hour)) out.add(hour);
    return out;
  }

  WuXing? _mainElementOf(NameProfile p) {
    final initials = p.pinyin.map(_extractInitial).toList();
    final elems = <WuXing>[];
    for (int i = 0; i < p.fullName.runes.length; i++) {
      final r = p.radicals[i];
      if (radicals.wildcards.contains(r)) continue;
      final re = radicals.map[r];
      if (re != null) {
        elems.add(re);
        continue;
      }
      final ie = cfg.initialElement[initials[i]];
      if (ie != null) elems.add(ie);
    }
    if (elems.isEmpty) return null;
    final cnt = <WuXing, int>{};
    for (final e in elems) {
      cnt[e] = (cnt[e] ?? 0) + 1;
    }
    return cnt.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

/// ====== 段落式中文报告 ======
class NameReport {
  static String generateParagraphs(NameProfile p, NameScore s) {
    final sb = StringBuffer();
    // 工具
    String wx(WuXing e) => const {
      WuXing.metal: '金',
      WuXing.wood: '木',
      WuXing.water: '水',
      WuXing.fire: '火',
      WuXing.earth: '土',
    }[e]!;
    String wxList(List<WuXing> es) => es.map(wx).join('、');
    String scoreLevel(int v) {
      final x = v;
      if (x >= 80) return '上佳';
      if (x >= 60) return '良好';
      if (x >= 40) return '中等';
      if (x >= 20) return '欠佳';
      return '下佳';
    }

    String scoreLevelNote(String level) {
      String levelNote = '';
      if (level == '上佳') {
        levelNote = '名字格局完整，寓意吉祥，五行流通顺畅，可安心使用，无须特别调整或名正言顺';
      }
      if (level == '良好') {
        levelNote = '名字整体较为和谐，但仍有提升空间去进行名正言顺。可在日常生活或后天环境上增加相应五行元素，以进一步增强运势';
      }
      if (level == '中等') {
        levelNote = '名字表现普通，虽无大碍，但助益有限。若能在用字部首或笔画上进行优化或名正言顺，会更趋理想';
      }
      if (level == '欠佳') {
        levelNote = '名字存在一定不足，可能在五行或数理上不够平衡。建议结合生辰八字重新调整或名正言顺，以免带来阻碍';
      }
      if (level == '下佳') {
        levelNote = '名字整体格局不佳，可能带来较明显的负面影响。强烈建议名正言顺，或在生活中积极补救五行缺陷，以化解不利';
      }
      return levelNote;
    }

    int score = s.total.round();
    String levelName = scoreLevel(score);
    String levelNote = scoreLevelNote(levelName);
    sb.writeln('此名字总分为 $score分，属于$levelName。建议$levelNote。');
    sb.writeln();

    final grids =
        (s.notes['fiveGrids'] ?? const <String, int>{}) as Map<String, int>;
    if (grids.isNotEmpty) {
      final tg = grids['天'];
      final rg = grids['人'];
      final dg = grids['地'];
      final wg = grids['外'];
      final zg = grids['总'];
      sb.writeln(
        '五格数理方面，天格${tg ?? '-'}、人格${rg ?? '-'}、地格${dg ?? '-'}、外格${wg ?? '-'}、总格${zg ?? '-'}。'
        '整体表现${scoreLevel(s.components['grid']?.round() ?? 0)}，若组合中存在凶数，建议在重要决策与人际合作上保持稳健节奏。',
      );
      sb.writeln();
    }

    final prefs =
        (s.notes['preferredElements'] ?? const <WuXing>[]) as List<WuXing>;
    final mainElm = s.notes['mainElement'] as WuXing?;
    final zodiac = (s.notes['zodiac'] ?? '') as String;
    final pNum = s.notes['personalityNumber'] as int?;
    final bElm = s.notes['birthElement'] as WuXing?;

    final wuxingReport = StringBuffer();
    wuxingReport.write(
      '名字五行元素方面，主元素为“${mainElm == null ? '未知' : wx(mainElm)}”；'
      '依据出生月份与小时推断的偏好元素为：${prefs.isEmpty ? '（无）' : wxList(prefs)}。',
    );
    if (pNum != null && bElm != null && mainElm != null) {
      String relationText = '';
      if (_generates(mainElm, bElm)) {
        relationText = '名字五行(${wx(mainElm)})生助生日元素(${wx(bElm)})，为大吉大利的组合';
      } else if (_same(mainElm, bElm)) {
        relationText = '名字五行与生日元素同为(${wx(mainElm)})，为相互帮扶的组合';
      } else if (_generates(bElm, mainElm)) {
        relationText = '生日元素(${wx(bElm)})生助名字五行(${wx(mainElm)})，为本人可驾驭的组合';
      } else if (_overcomes(bElm, mainElm)) {
        relationText = '生日元素(${wx(bElm)})克制名字五行(${wx(mainElm)})，为本人可掌控的组合';
      } else if (_overcomes(mainElm, bElm)) {
        relationText = '名字五行(${wx(mainElm)})克制生日元素(${wx(bElm)})，为运势受压的组合，需注意';
      }
      wuxingReport.write('你是属于${pNum}号人，你的生日元素与名字关系为：${relationText}。');
    }
    wuxingReport.writeln(
      '名字五行一致性得分 ${s.components['coherence']?.round() ?? 0} 分，评价${scoreLevel(s.components['coherence']?.round() ?? 0)}。',
    );
    sb.writeln(wuxingReport);

    sb.writeln(
      '生肖方面，${zodiac.isEmpty ? '生肖信息未知' : '生肖为“$zodiac”'}，'
      '生肖适配得分 ${s.components['zodiac']?.round() ?? 0} 分，评价 ${scoreLevel(s.components['zodiac']?.round() ?? 0)}。'
      '音律与性别契合方面，拼音美感得分 ${s.components['phonetics']?.round() ?? 0} 分，'
      '性别契合度得分 ${s.components['genderStyle']?.round() ?? 0} 分，整体音律表现${scoreLevel(s.components['phonetics']?.round() ?? 0)}。'
      '笔画均衡方面，得分 ${s.components['balance']?.round() ?? 0} 分，整体均衡度评价${scoreLevel(s.components['balance']?.round() ?? 0)}。',
    );
    sb.writeln();
    sb.write(
      '姓名学博大精深，除了字根，数理格局等的元素，还需要根据每个字的形态做总评分。建议用户咨询导师以获得最准确的批算。',
    );
    return sb.toString();
  }
}

/// ====== 拼音与五行关系、相生相克 ======
String _extractInitial(String syl) {
  final s = syl.toLowerCase();
  if (s.startsWith('zh')) return 'zh';
  if (s.startsWith('ch')) return 'ch';
  if (s.startsWith('sh')) return 'sh';
  if (s.isEmpty) return '';
  const initials = {
    'b',
    'p',
    'm',
    'f',
    'd',
    't',
    'n',
    'l',
    'g',
    'k',
    'h',
    'j',
    'q',
    'x',
    'r',
    'z',
    'c',
    's',
    'y',
    'w',
  };
  return initials.contains(s[0]) ? s[0] : '';
}

bool _same(WuXing a, WuXing b) => _idx(a) == _idx(b);

bool _generates(WuXing a, WuXing b) => (_idx(a) + 1) % 5 == _idx(b);

bool _overcomes(WuXing a, WuXing b) => (_idx(a) + 2) % 5 == _idx(b);

int _idx(WuXing e) => {
  WuXing.wood: 0,
  WuXing.fire: 1,
  WuXing.earth: 2,
  WuXing.metal: 3,
  WuXing.water: 4,
}[e]!;
