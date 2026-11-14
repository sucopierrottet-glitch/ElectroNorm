import '../catalogs/raceway_catalog.dart';
import 'raceway.dart';

/// Supported primary regulatory country profiles.
enum NormativeCountry {
  mexico,
  usa,
}

/// Supported display measurement unit systems.
enum MeasurementUnitSystem {
  metric,
  imperial,
}

extension NormativeCountryExtension on NormativeCountry {
  String get codeBadge {
    switch (this) {
      case NormativeCountry.mexico:
        return 'NOM-001-SEDE';
      case NormativeCountry.usa:
        return 'NEC (NFPA 70)';
    }
  }

  String get shortCode {
    switch (this) {
      case NormativeCountry.mexico:
        return 'NOM-001';
      case NormativeCountry.usa:
        return 'NEC';
    }
  }

  String get flagEmoji {
    switch (this) {
      case NormativeCountry.mexico:
        return '🇲🇽';
      case NormativeCountry.usa:
        return '🇺🇸';
    }
  }

  MeasurementUnitSystem get defaultUnitSystem {
    switch (this) {
      case NormativeCountry.mexico:
        return MeasurementUnitSystem.metric;
      case NormativeCountry.usa:
        return MeasurementUnitSystem.imperial;
    }
  }

  String localizedName(String localeCode) {
    final lang = localeCode.toLowerCase();
    switch (this) {
      case NormativeCountry.mexico:
        if (lang.startsWith('en')) return 'Mexico (NOM-001-SEDE)';
        if (lang.startsWith('pt')) return 'México (NOM-001-SEDE)';
        return 'México (NOM-001-SEDE)';
      case NormativeCountry.usa:
        if (lang.startsWith('en')) return 'USA (NEC / NFPA 70)';
        if (lang.startsWith('pt')) return 'EUA (NEC / NFPA 70)';
        return 'Estados Unidos (NEC / NFPA 70)';
    }
  }

  /// Standard nominal system voltages ordered for the country profile.
  List<double> get preferredVoltages {
    switch (this) {
      case NormativeCountry.mexico:
        return const [127.0, 220.0, 240.0, 440.0, 480.0];
      case NormativeCountry.usa:
        return const [120.0, 208.0, 240.0, 480.0];
    }
  }

  /// Full superset of supported voltages so loading saved runs or switching
  /// profiles never invalidates DropdownButton selected values.
  static const List<double> allSupportedVoltages = [
    120.0,
    127.0,
    208.0,
    220.0,
    240.0,
    440.0,
    480.0,
  ];

  double get defaultSinglePhaseVoltage =>
      this == NormativeCountry.mexico ? 127.0 : 120.0;

  double get defaultThreePhaseVoltage =>
      this == NormativeCountry.mexico ? 220.0 : 208.0;

  String get fillStandardRef => this == NormativeCountry.mexico
      ? 'NOM-001-SEDE Cap. 10 Tablas 1 y 4'
      : 'NEC Ch. 9 Tables 1 & 4';

  String get jamRatioRef => this == NormativeCountry.mexico
      ? 'NOM-001-SEDE Cap. 10 Tabla 1 Nota 2'
      : 'NEC Ch 9 Table 1 Note 2';

  String get voltageDropRef => this == NormativeCountry.mexico
      ? 'NOM-001 Art. 210-19(a) / 215-2(a)'
      : 'NEC 210.19 / 215.2';

  String get deratingRef => this == NormativeCountry.mexico
      ? 'NOM-001-SEDE Art. 310-15 / Tabla 310-15'
      : 'NEC 310.15 & Table 310.16';

  String get terminalRatingRef => this == NormativeCountry.mexico
      ? 'NOM-001 Art. 110-14(c)'
      : 'NEC 110.14(C)';

  String get smallOcpdRef => this == NormativeCountry.mexico
      ? 'NOM-001 Art. 240-4(d)'
      : 'NEC 240.4(D)';

  String get groundingEgcRef => this == NormativeCountry.mexico
      ? 'NOM-001-SEDE Tabla 250-122'
      : 'NEC Table 250.122';

  String get groundingGecRef => this == NormativeCountry.mexico
      ? 'NOM-001-SEDE Tabla 250-66'
      : 'NEC Table 250.66';

  String get inspectionAuthorityShort =>
      this == NormativeCountry.mexico ? 'UVIE / PEC' : 'AHJ';

  String defaultInspectorLabel(String localeCode) {
    if (this == NormativeCountry.mexico) {
      return localeCode.startsWith('en')
          ? 'Verification Unit (UVIE) / Engineer'
          : 'Unidad de Verificación (UVIE)';
    }
    return 'Authority Having Jurisdiction (AHJ)';
  }

  String defaultAgencyLabel(String localeCode) {
    if (this == NormativeCountry.mexico) {
      return localeCode.startsWith('en')
          ? 'Accredited Electrical Verification Unit (UVIE)'
          : 'Unidad de Verificación de Instalaciones Eléctricas (UVIE)';
    }
    return 'City Electrical Inspection Bureau';
  }
}

class NormativeFormatters {
  NormativeFormatters._();

  static const double feetToMeters = 0.3048;
  static const double inchesToCm = 2.54;
  static const double sqInchesToSqMm = 645.16;
  static const double inchesToMm = 25.4;
  static const double circularMilsToSqMm = 0.000506707479;

  /// Formats raceway trade size nicely for Metric (DN) vs Imperial (").
  static String formatRacewaySize(
    String tradeSize, {
    RacewayType? type,
    String? metricDesignator,
    required bool isMetric,
  }) {
    String? dn = metricDesignator;
    if (dn == null && type != null) {
      dn = RacewayCatalog.getProfile(type, tradeSize).metricDesignator;
    }
    dn ??= RacewayCatalog.getProfile(RacewayType.emt, tradeSize).metricDesignator;
    if (isMetric) {
      return 'DN $dn ($tradeSize")';
    }
    return '$tradeSize"';
  }

  /// Formats AWG/kcmil gauge with nominal mm² cross section for Mexico/metric users.
  static String formatAwgWithMetric(String gauge, {required bool isMetric}) {
    if (!isMetric) return gauge;
    final cm = _circularMilsByGauge[gauge];
    if (cm == null) return gauge;
    final mm2 = cm * circularMilsToSqMm;
    final decimals = mm2 < 10 ? 2 : 1;
    return '$gauge (${mm2.toStringAsFixed(decimals)} mm²)';
  }

  static const Map<String, double> _circularMilsByGauge = {
    '14 AWG': 4110,
    '12 AWG': 6530,
    '10 AWG': 10380,
    '8 AWG': 16510,
    '6 AWG': 26240,
    '4 AWG': 41740,
    '3 AWG': 52620,
    '2 AWG': 66360,
    '1 AWG': 83690,
    '1/0 AWG': 105600,
    '2/0 AWG': 133100,
    '3/0 AWG': 167800,
    '4/0 AWG': 211600,
    '250 kcmil': 250000,
    '300 kcmil': 300000,
    '350 kcmil': 350000,
    '400 kcmil': 400000,
    '500 kcmil': 500000,
    '600 kcmil': 600000,
    '700 kcmil': 700000,
    '750 kcmil': 750000,
    '800 kcmil': 800000,
    '1000 kcmil': 1000000,
    '1200 kcmil': 1200000,
    '1500 kcmil': 1500000,
    '1750 kcmil': 1750000,
    '2000 kcmil': 2000000,
  };
}
