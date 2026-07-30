/// One convertible unit within a [UnitCategory]. Conversion always goes
/// through the category's base unit (e.g. meters for Length), so adding a
/// new unit only ever needs its own conversion to/from that one base unit —
/// not a conversion function to every other unit in the category.
class UnitDef {
  const UnitDef(this.key, this.labelAr, this.symbol, this.toBase, this.fromBase);

  final String key;
  final String labelAr;
  final String symbol;
  final double Function(double value) toBase;
  final double Function(double value) fromBase;
}

UnitDef _linear(String key, String labelAr, String symbol, double factor) {
  return UnitDef(key, labelAr, symbol, (v) => v * factor, (v) => v / factor);
}

class UnitCategory {
  const UnitCategory(this.key, this.labelAr, this.icon, this.units);

  final String key;
  final String labelAr;
  final String icon; // Material icon name reference, resolved in the UI
  final List<UnitDef> units;

  double convert(double value, String fromKey, String toKey) {
    final from = units.firstWhere((u) => u.key == fromKey);
    final to = units.firstWhere((u) => u.key == toKey);
    return to.fromBase(from.toBase(value));
  }
}

class UnitConverterData {
  UnitConverterData._();

  // Length — base: meter
  static final length = UnitCategory('length', 'الطول', 'straighten', [
    _linear('mm', 'ملم', 'mm', 0.001),
    _linear('cm', 'سم', 'cm', 0.01),
    _linear('m', 'متر', 'm', 1),
    _linear('km', 'كم', 'km', 1000),
    _linear('in', 'إنش', 'in', 0.0254),
    _linear('ft', 'قدم', 'ft', 0.3048),
    _linear('yd', 'ياردة', 'yd', 0.9144),
    _linear('mi', 'ميل', 'mi', 1609.344),
    _linear('nmi', 'ميل بحري', 'nmi', 1852),
  ]);

  // Area — base: square meter
  static final area = UnitCategory('area', 'المساحة', 'crop_square', [
    _linear('mm2', 'ملم²', 'mm²', 0.000001),
    _linear('cm2', 'سم²', 'cm²', 0.0001),
    _linear('m2', 'م²', 'm²', 1),
    _linear('ha', 'هكتار', 'ha', 10000),
    _linear('km2', 'كم²', 'km²', 1000000),
    _linear('in2', 'إنش²', 'in²', 0.00064516),
    _linear('ft2', 'قدم²', 'ft²', 0.09290304),
    _linear('ac', 'فدان إنجليزي', 'ac', 4046.8564224),
    _linear('mi2', 'ميل²', 'mi²', 2589988.110336),
  ]);

  // Volume — base: liter
  static final volume = UnitCategory('volume', 'الحجم', 'water_drop', [
    _linear('ml', 'مل', 'ml', 0.001),
    _linear('l', 'لتر', 'L', 1),
    _linear('m3', 'م³', 'm³', 1000),
    _linear('tsp', 'ملعقة صغيرة', 'tsp', 0.00492892),
    _linear('tbsp', 'ملعقة كبيرة', 'tbsp', 0.0147868),
    _linear('cup', 'كوب', 'cup', 0.24),
    _linear('flOz', 'أونصة سائلة', 'fl oz', 0.0295735),
    _linear('pt', 'باينت', 'pt', 0.473176),
    _linear('qt', 'كوارت', 'qt', 0.946353),
    _linear('gal', 'غالون', 'gal', 3.78541),
  ]);

  // Weight/Mass — base: kilogram
  static final weight = UnitCategory('weight', 'الوزن', 'scale', [
    _linear('mg', 'ملغم', 'mg', 0.000001),
    _linear('g', 'غرام', 'g', 0.001),
    _linear('kg', 'كغم', 'kg', 1),
    _linear('tonne', 'طن متري', 't', 1000),
    _linear('oz', 'أونصة', 'oz', 0.0283495),
    _linear('lb', 'رطل', 'lb', 0.453592),
    _linear('st', 'ستون', 'st', 6.35029),
  ]);

  // Temperature — base: Celsius (affine, not linear-through-zero)
  static final temperature = UnitCategory('temperature', 'الحرارة', 'thermostat', [
    UnitDef('c', 'مئوية', '°C', (v) => v, (v) => v),
    UnitDef('f', 'فهرنهايت', '°F', (v) => (v - 32) * 5 / 9, (v) => v * 9 / 5 + 32),
    UnitDef('k', 'كلفن', 'K', (v) => v - 273.15, (v) => v + 273.15),
  ]);

  // Pressure — base: pascal
  static final pressure = UnitCategory('pressure', 'الضغط', 'compress', [
    _linear('pa', 'باسكال', 'Pa', 1),
    _linear('kpa', 'كيلوباسكال', 'kPa', 1000),
    _linear('bar', 'بار', 'bar', 100000),
    _linear('atm', 'ضغط جوي', 'atm', 101325),
    _linear('psi', 'رطل/إنش²', 'psi', 6894.76),
    _linear('mmhg', 'ملم زئبق', 'mmHg', 133.322),
  ]);

  // Energy — base: joule
  static final energy = UnitCategory('energy', 'الطاقة', 'bolt', [
    _linear('j', 'جول', 'J', 1),
    _linear('kj', 'كيلوجول', 'kJ', 1000),
    _linear('cal', 'سعرة صغيرة', 'cal', 4.184),
    _linear('kcal', 'سعرة حرارية', 'kcal', 4184),
    _linear('wh', 'واط ساعة', 'Wh', 3600),
    _linear('kwh', 'كيلوواط ساعة', 'kWh', 3600000),
  ]);

  // Speed — base: meters/second
  static final speed = UnitCategory('speed', 'السرعة', 'speed', [
    _linear('mps', 'م/ث', 'm/s', 1),
    _linear('kmh', 'كم/س', 'km/h', 0.277778),
    _linear('mph', 'ميل/س', 'mph', 0.44704),
    _linear('knot', 'عقدة', 'kn', 0.514444),
  ]);

  // Time — base: second
  static final time = UnitCategory('time', 'الزمن', 'schedule', [
    _linear('ms', 'ملي ثانية', 'ms', 0.001),
    _linear('s', 'ثانية', 's', 1),
    _linear('min', 'دقيقة', 'min', 60),
    _linear('hr', 'ساعة', 'hr', 3600),
    _linear('day', 'يوم', 'day', 86400),
    _linear('week', 'أسبوع', 'week', 604800),
    _linear('month', 'شهر (تقريبي)', 'mo', 2629800),
    _linear('year', 'سنة', 'yr', 31557600),
  ]);

  // Angle — base: degree
  static final angle = UnitCategory('angle', 'الزوايا', 'architecture', [
    _linear('deg', 'درجة', '°', 1),
    _linear('rad', 'راديان', 'rad', 57.29577951),
    _linear('grad', 'غراد', 'grad', 0.9),
    _linear('rev', 'دورة كاملة', 'rev', 360),
  ]);

  // Digital storage — base: byte
  static final digitalStorage = UnitCategory('digital', 'البيانات الرقمية', 'storage', [
    _linear('bit', 'بت', 'bit', 0.125),
    _linear('byte', 'بايت', 'B', 1),
    _linear('kb', 'كيلوبايت', 'KB', 1024),
    _linear('mb', 'ميغابايت', 'MB', 1048576),
    _linear('gb', 'غيغابايت', 'GB', 1073741824),
    _linear('tb', 'تيرابايت', 'TB', 1099511627776),
  ]);

  static final List<UnitCategory> all = [
    length,
    area,
    volume,
    weight,
    temperature,
    pressure,
    energy,
    speed,
    time,
    angle,
    digitalStorage,
  ];
}
