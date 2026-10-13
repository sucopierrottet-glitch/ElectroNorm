import '../models/calculation_results.dart';

class JamRatioResult {
  final double ratio;
  final JamRiskLevel riskLevel;
  final bool isHighRisk;

  const JamRatioResult({
    required this.ratio,
    required this.riskLevel,
    required this.isHighRisk,
  });
}

class JamRatioCalculator {
  JamRatioCalculator._();

  /// Calculates the jam ratio R_jam = D_conduit / d_wire
  /// for conductors being pulled together around conduit bends.
  static JamRatioResult calculate({
    required double conduitInsideDiameter,
    required double wireOutsideDiameter,
  }) {
    if (wireOutsideDiameter <= 0 || conduitInsideDiameter <= 0) {
      return const JamRatioResult(
        ratio: 0.0,
        riskLevel: JamRiskLevel.notApplicable,
        isHighRisk: false,
      );
    }

    final ratio = conduitInsideDiameter / wireOutsideDiameter;
    JamRiskLevel level;

    if (ratio > 3.20) {
      level = JamRiskLevel.safeClearance;
    } else if (ratio >= 2.80) {
      level = JamRiskLevel.highJamRisk;
    } else if (ratio >= 2.50) {
      level = JamRiskLevel.moderateRisk;
    } else {
      level = JamRiskLevel.safeConstrained;
    }

    return JamRatioResult(
      ratio: ratio,
      riskLevel: level,
      isHighRisk: level == JamRiskLevel.highJamRisk,
    );
  }
}
