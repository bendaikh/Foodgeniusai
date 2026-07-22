import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-selectable measurement preference.
enum MeasurementPreference {
  automatic,
  metric,
  us,
}

/// Resolved system used for display.
enum MeasurementSystem {
  metric,
  us,
}

/// One reusable measurement service for locale detection, preference,
/// parsing, conversion, and readable formatting.
class MeasurementService extends ChangeNotifier {
  MeasurementService._();

  static final MeasurementService instance = MeasurementService._();

  static const _prefsKey = 'measurement_preference_v1';

  MeasurementPreference _preference = MeasurementPreference.automatic;
  bool _ready = false;

  MeasurementPreference get preference => _preference;
  bool get isReady => _ready;

  /// Effective system after applying preference + device region.
  MeasurementSystem get effectiveSystem {
    switch (_preference) {
      case MeasurementPreference.metric:
        return MeasurementSystem.metric;
      case MeasurementPreference.us:
        return MeasurementSystem.us;
      case MeasurementPreference.automatic:
        return _systemFromDeviceLocale();
    }
  }

  Future<void> init() async {
    if (_ready) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      _preference = _preferenceFromStorage(raw);
    } catch (e) {
      debugPrint('MeasurementService init error: $e');
      _preference = MeasurementPreference.automatic;
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> setPreference(MeasurementPreference value) async {
    if (_preference == value) return;
    _preference = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, value.name);
    } catch (e) {
      debugPrint('MeasurementService save error: $e');
    }
  }

  MeasurementSystem _systemFromDeviceLocale() {
    final locale = PlatformDispatcher.instance.locale;
    final region = (locale.countryCode ?? '').toUpperCase().trim();

    // Only the United States defaults to US customary.
    // en_GB / en_CA / en_AU and all other regions use metric.
    if (region == 'US') return MeasurementSystem.us;
    return MeasurementSystem.metric;
  }

  MeasurementPreference _preferenceFromStorage(String? raw) {
    switch (raw) {
      case 'metric':
        return MeasurementPreference.metric;
      case 'us':
        return MeasurementPreference.us;
      case 'automatic':
      default:
        return MeasurementPreference.automatic;
    }
  }

  /// Formats `amount unit name` for display without mutating stored values.
  String formatIngredient({
    required dynamic amount,
    required dynamic unit,
    required dynamic name,
  }) {
    final amountStr = '${amount ?? ''}'.trim();
    final unitStr = '${unit ?? ''}'.trim();
    final nameStr = '${name ?? ''}'.trim();

    if (amountStr.isEmpty && unitStr.isEmpty) {
      return nameStr;
    }

    final converted = _convertQuantity(amountStr, unitStr);
    if (converted == null) {
      return [amountStr, unitStr, nameStr]
          .where((s) => s.isNotEmpty)
          .join(' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    return [
      converted.amountLabel,
      converted.unitLabel,
      nameStr,
    ].where((s) => s.isNotEmpty).join(' ').trim();
  }

  /// Converts temperatures inside instruction text for display.
  String formatInstructionText(String text) {
    if (text.trim().isEmpty) return text;

    final target = effectiveSystem;
    var result = text;

    // °C / C → °F when US
    if (target == MeasurementSystem.us) {
      result = result.replaceAllMapped(
        RegExp(
          r'(\d+(?:\.\d+)?)\s*(?:°\s*)?C\b',
          caseSensitive: false,
        ),
        (m) {
          final c = double.tryParse(m.group(1)!);
          if (c == null) return m.group(0)!;
          final f = (c * 9 / 5) + 32;
          return '${_roundWhole(f)}°F';
        },
      );
      result = result.replaceAllMapped(
        RegExp(
          r'(\d+(?:\.\d+)?)\s*degrees?\s*c(?:elsius)?\b',
          caseSensitive: false,
        ),
        (m) {
          final c = double.tryParse(m.group(1)!);
          if (c == null) return m.group(0)!;
          final f = (c * 9 / 5) + 32;
          return '${_roundWhole(f)}°F';
        },
      );
    }

    // °F / F → °C when Metric
    if (target == MeasurementSystem.metric) {
      result = result.replaceAllMapped(
        RegExp(
          r'(\d+(?:\.\d+)?)\s*(?:°\s*)?F\b',
          caseSensitive: false,
        ),
        (m) {
          final f = double.tryParse(m.group(1)!);
          if (f == null) return m.group(0)!;
          final c = (f - 32) * 5 / 9;
          return '${_roundWhole(c)}°C';
        },
      );
      result = result.replaceAllMapped(
        RegExp(
          r'(\d+(?:\.\d+)?)\s*degrees?\s*f(?:ahrenheit)?\b',
          caseSensitive: false,
        ),
        (m) {
          final f = double.tryParse(m.group(1)!);
          if (f == null) return m.group(0)!;
          final c = (f - 32) * 5 / 9;
          return '${_roundWhole(c)}°C';
        },
      );
    }

    return result;
  }

  /// Returns null when the quantity should be left unchanged.
  _ConvertedQuantity? _convertQuantity(String amountRaw, String unitRaw) {
    final descriptive = _isDescriptiveUnit(unitRaw) ||
        _isDescriptivePhrase(amountRaw) ||
        _isCountUnit(unitRaw);
    if (descriptive) return null;

    final value = _parseAmount(amountRaw);
    if (value == null) return null;

    final unit = _normalizeUnit(unitRaw);
    if (unit == null) return null;

    final target = effectiveSystem;

    switch (unit.kind) {
      case _UnitKind.weight:
        return _convertWeight(value, unit.base, target);
      case _UnitKind.volume:
        return _convertVolume(value, unit.base, target);
      case _UnitKind.temperature:
        return _convertTemperature(value, unit.base, target);
    }
  }

  // ---------------------------------------------------------------------------
  // Conversion
  // ---------------------------------------------------------------------------

  static const double _gPerOz = 28.3495;
  static const double _gPerLb = 453.592;
  static const double _mlPerCup = 236.588;
  static const double _mlPerTbsp = 14.7868;
  static const double _mlPerTsp = 4.92892;
  static const double _mlPerFlOz = 29.5735;

  _ConvertedQuantity _convertWeight(
    double value,
    _BaseUnit from,
    MeasurementSystem target,
  ) {
    final grams = switch (from) {
      _BaseUnit.g => value,
      _BaseUnit.kg => value * 1000,
      _BaseUnit.oz => value * _gPerOz,
      _BaseUnit.lb => value * _gPerLb,
      _ => value,
    };

    if (target == MeasurementSystem.metric) {
      if (grams >= 1000) {
        return _ConvertedQuantity(
          amountLabel: _formatMetricLarge(grams / 1000),
          unitLabel: 'kg',
        );
      }
      return _ConvertedQuantity(
        amountLabel: _formatMetricSmall(grams),
        unitLabel: 'g',
      );
    }

    // US customary
    if (grams >= _gPerLb * 0.9) {
      final lb = grams / _gPerLb;
      if ((lb - lb.round()).abs() < 0.08) {
        return _ConvertedQuantity(
          amountLabel: '${lb.round()}',
          unitLabel: lb.round() == 1 ? 'lb' : 'lb',
        );
      }
      return _ConvertedQuantity(
        amountLabel: _formatUsLb(lb),
        unitLabel: 'lb',
      );
    }

    final oz = grams / _gPerOz;
    return _ConvertedQuantity(
      amountLabel: _formatUsOz(oz),
      unitLabel: 'oz',
    );
  }

  _ConvertedQuantity _convertVolume(
    double value,
    _BaseUnit from,
    MeasurementSystem target,
  ) {
    final ml = switch (from) {
      _BaseUnit.ml => value,
      _BaseUnit.l => value * 1000,
      _BaseUnit.cup => value * _mlPerCup,
      _BaseUnit.tbsp => value * _mlPerTbsp,
      _BaseUnit.tsp => value * _mlPerTsp,
      _BaseUnit.flOz => value * _mlPerFlOz,
      _ => value,
    };

    if (target == MeasurementSystem.metric) {
      if (ml >= 1000) {
        return _ConvertedQuantity(
          amountLabel: _formatMetricLarge(ml / 1000),
          unitLabel: 'L',
        );
      }
      return _ConvertedQuantity(
        amountLabel: _formatMetricSmall(ml),
        unitLabel: 'ml',
      );
    }

    return _formatUsVolume(ml);
  }

  _ConvertedQuantity _convertTemperature(
    double value,
    _BaseUnit from,
    MeasurementSystem target,
  ) {
    if (target == MeasurementSystem.us) {
      final f = from == _BaseUnit.f ? value : (value * 9 / 5) + 32;
      return _ConvertedQuantity(
        amountLabel: '${_roundWhole(f)}',
        unitLabel: '°F',
      );
    }
    final c = from == _BaseUnit.c ? value : (value - 32) * 5 / 9;
    return _ConvertedQuantity(
      amountLabel: '${_roundWhole(c)}',
      unitLabel: '°C',
    );
  }

  _ConvertedQuantity _formatUsVolume(double ml) {
    // Prefer tsp / tbsp / cups for kitchen-readable values.
    final tsp = ml / _mlPerTsp;
    final tbsp = ml / _mlPerTbsp;
    final cup = ml / _mlPerCup;

    if (ml <= 7.5) {
      final nearest = _nearestFraction(tsp, const [0.25, 0.5, 0.75, 1, 1.5, 2]);
      if (nearest != null) {
        return _ConvertedQuantity(
          amountLabel: _fractionLabel(nearest),
          unitLabel: nearest == 1 ? 'tsp' : 'tsp',
        );
      }
      return _ConvertedQuantity(
        amountLabel: _formatUsOz(tsp),
        unitLabel: 'tsp',
      );
    }

    if (ml <= 45) {
      final nearest = _nearestFraction(
        tbsp,
        const [0.5, 1, 1.5, 2, 2.5, 3],
      );
      if (nearest != null) {
        return _ConvertedQuantity(
          amountLabel: _fractionLabel(nearest),
          unitLabel: 'tbsp',
        );
      }
    }

    // Cups and common cup fractions
    final cupFractions = <double>[
      0.25,
      1 / 3,
      0.5,
      2 / 3,
      0.75,
      1,
      1.25,
      1.5,
      1.75,
      2,
      2.5,
      3,
      3.5,
      4,
    ];
    final nearestCup = _nearestFraction(cup, cupFractions, tolerance: 0.08);
    if (nearestCup != null && cup >= 0.2) {
      return _ConvertedQuantity(
        amountLabel: _fractionLabel(nearestCup),
        unitLabel: nearestCup == 1 ? 'cup' : 'cups',
      );
    }

    if (cup >= 0.2) {
      return _ConvertedQuantity(
        amountLabel: _formatUsOz(cup),
        unitLabel: cup >= 1.05 ? 'cups' : 'cup',
      );
    }

    // Fall back to tbsp
    final nearestTbsp = _nearestFraction(tbsp, const [1, 1.5, 2, 2.5, 3, 4]);
    if (nearestTbsp != null) {
      return _ConvertedQuantity(
        amountLabel: _fractionLabel(nearestTbsp),
        unitLabel: 'tbsp',
      );
    }

    final flOz = ml / _mlPerFlOz;
    return _ConvertedQuantity(
      amountLabel: _formatUsOz(flOz),
      unitLabel: 'fl oz',
    );
  }

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  double? _parseAmount(String raw) {
    final cleaned = raw.trim().toLowerCase();
    if (cleaned.isEmpty) return null;
    if (_isDescriptivePhrase(cleaned)) return null;

    // Mixed fraction: 1 1/2
    final mixed = RegExp(r'^(\d+)\s+(\d+)\s*/\s*(\d+)$').firstMatch(cleaned);
    if (mixed != null) {
      final whole = double.parse(mixed.group(1)!);
      final num = double.parse(mixed.group(2)!);
      final den = double.parse(mixed.group(3)!);
      if (den == 0) return null;
      return whole + (num / den);
    }

    // Simple fraction: 1/2
    final frac = RegExp(r'^(\d+)\s*/\s*(\d+)$').firstMatch(cleaned);
    if (frac != null) {
      final num = double.parse(frac.group(1)!);
      final den = double.parse(frac.group(2)!);
      if (den == 0) return null;
      return num / den;
    }

    // Unicode fractions
    const unicode = {
      '¼': 0.25,
      '½': 0.5,
      '¾': 0.75,
      '⅓': 1 / 3,
      '⅔': 2 / 3,
      '⅛': 0.125,
      '⅜': 0.375,
      '⅝': 0.625,
      '⅞': 0.875,
    };
    if (unicode.containsKey(cleaned)) return unicode[cleaned];

    final mixedUnicode =
        RegExp(r'^(\d+)\s*([¼½¾⅓⅔⅛⅜⅝⅞])$').firstMatch(cleaned);
    if (mixedUnicode != null) {
      final whole = double.parse(mixedUnicode.group(1)!);
      final part = unicode[mixedUnicode.group(2)!] ?? 0;
      return whole + part;
    }

    return double.tryParse(cleaned.replaceAll(',', '.'));
  }

  _NormalizedUnit? _normalizeUnit(String raw) {
    final u = raw.trim().toLowerCase().replaceAll('.', '');
    if (u.isEmpty) return null;

    switch (u) {
      case 'g':
      case 'gram':
      case 'grams':
      case 'gr':
        return const _NormalizedUnit(_UnitKind.weight, _BaseUnit.g);
      case 'kg':
      case 'kilogram':
      case 'kilograms':
        return const _NormalizedUnit(_UnitKind.weight, _BaseUnit.kg);
      case 'oz':
      case 'ounce':
      case 'ounces':
        return const _NormalizedUnit(_UnitKind.weight, _BaseUnit.oz);
      case 'lb':
      case 'lbs':
      case 'pound':
      case 'pounds':
        return const _NormalizedUnit(_UnitKind.weight, _BaseUnit.lb);

      case 'ml':
      case 'milliliter':
      case 'milliliters':
      case 'millilitre':
      case 'millilitres':
        return const _NormalizedUnit(_UnitKind.volume, _BaseUnit.ml);
      case 'l':
      case 'liter':
      case 'liters':
      case 'litre':
      case 'litres':
        return const _NormalizedUnit(_UnitKind.volume, _BaseUnit.l);
      case 'cup':
      case 'cups':
        return const _NormalizedUnit(_UnitKind.volume, _BaseUnit.cup);
      case 'tbsp':
      case 'tbs':
      case 'tablespoon':
      case 'tablespoons':
        return const _NormalizedUnit(_UnitKind.volume, _BaseUnit.tbsp);
      case 'tsp':
      case 'teaspoon':
      case 'teaspoons':
        return const _NormalizedUnit(_UnitKind.volume, _BaseUnit.tsp);
      case 'fl oz':
      case 'floz':
      case 'fluid ounce':
      case 'fluid ounces':
        return const _NormalizedUnit(_UnitKind.volume, _BaseUnit.flOz);

      case 'c':
      case '°c':
      case 'celsius':
        return const _NormalizedUnit(_UnitKind.temperature, _BaseUnit.c);
      case 'f':
      case '°f':
      case 'fahrenheit':
        return const _NormalizedUnit(_UnitKind.temperature, _BaseUnit.f);
      default:
        return null;
    }
  }

  bool _isCountUnit(String unit) {
    final u = unit.trim().toLowerCase();
    const count = {
      'piece',
      'pieces',
      'pc',
      'pcs',
      'clove',
      'cloves',
      'egg',
      'eggs',
      'onion',
      'onions',
      'tomato',
      'tomatoes',
      'lemon',
      'lemons',
      'lime',
      'limes',
      'slice',
      'slices',
      'leaf',
      'leaves',
      'sprig',
      'sprigs',
      'stalk',
      'stalks',
      'bunch',
      'bunches',
      'can',
      'cans',
      'package',
      'packages',
      'pack',
      'packs',
      'whole',
      'each',
      'unit',
      'units',
      'large',
      'medium',
      'small',
      'head',
      'heads',
      'fillet',
      'fillets',
      'strip',
      'strips',
    };
    return count.contains(u);
  }

  bool _isDescriptiveUnit(String unit) {
    final u = unit.trim().toLowerCase();
    const descriptive = {
      'pinch',
      'pinches',
      'dash',
      'dashes',
      'handful',
      'handfuls',
      'to taste',
      'as needed',
      'as desired',
      'taste',
      'garnish',
    };
    return descriptive.contains(u);
  }

  bool _isDescriptivePhrase(String amount) {
    final a = amount.trim().toLowerCase();
    return a.contains('to taste') ||
        a.contains('as needed') ||
        a.contains('a pinch') ||
        a.contains('a handful') ||
        a.contains('as desired') ||
        a == 'pinch' ||
        a == 'handful';
  }

  // ---------------------------------------------------------------------------
  // Formatting helpers
  // ---------------------------------------------------------------------------

  String _formatMetricSmall(double value) {
    if (value < 10) {
      final rounded = (value * 10).round() / 10;
      if ((rounded - rounded.round()).abs() < 0.05) {
        return '${rounded.round()}';
      }
      return rounded.toStringAsFixed(1);
    }
    return '${value.round()}';
  }

  String _formatMetricLarge(double value) {
    final rounded = (value * 100).round() / 100;
    if ((rounded - rounded.round()).abs() < 0.005) {
      return '${rounded.round()}';
    }
    if ((rounded * 10 - (rounded * 10).round()).abs() < 0.05) {
      return rounded.toStringAsFixed(1);
    }
    return rounded.toStringAsFixed(2);
  }

  String _formatUsOz(double value) {
    final rounded = (value * 10).round() / 10;
    if ((rounded - rounded.round()).abs() < 0.05) {
      return '${rounded.round()}';
    }
    return rounded.toStringAsFixed(1);
  }

  String _formatUsLb(double value) {
    final rounded = (value * 100).round() / 100;
    if ((rounded - rounded.round()).abs() < 0.005) {
      return '${rounded.round()}';
    }
    if ((rounded * 10 - (rounded * 10).round()).abs() < 0.05) {
      return rounded.toStringAsFixed(1);
    }
    return rounded.toStringAsFixed(2);
  }

  int _roundWhole(double value) => value.round();

  double? _nearestFraction(
    double value,
    List<double> candidates, {
    double tolerance = 0.12,
  }) {
    double? best;
    var bestDelta = double.infinity;
    for (final c in candidates) {
      final d = (value - c).abs();
      if (d < bestDelta) {
        bestDelta = d;
        best = c;
      }
    }
    if (best == null) return null;
    if (bestDelta > tolerance) return null;
    return best;
  }

  String _fractionLabel(double value) {
    final map = <double, String>{
      0.25: '1/4',
      1 / 3: '1/3',
      0.5: '1/2',
      2 / 3: '2/3',
      0.75: '3/4',
      1.0: '1',
      1.25: '1 1/4',
      1.5: '1 1/2',
      1.75: '1 3/4',
      2.0: '2',
      2.5: '2 1/2',
      3.0: '3',
      3.5: '3 1/2',
      4.0: '4',
    };

    for (final entry in map.entries) {
      if ((entry.key - value).abs() < 0.02) return entry.value;
    }

    if ((value - value.round()).abs() < 0.05) {
      return '${value.round()}';
    }
    return _formatUsOz(value);
  }
}

class _ConvertedQuantity {
  final String amountLabel;
  final String unitLabel;

  const _ConvertedQuantity({
    required this.amountLabel,
    required this.unitLabel,
  });
}

enum _UnitKind { weight, volume, temperature }

enum _BaseUnit { g, kg, oz, lb, ml, l, cup, tbsp, tsp, flOz, c, f }

class _NormalizedUnit {
  final _UnitKind kind;
  final _BaseUnit base;

  const _NormalizedUnit(this.kind, this.base);
}
