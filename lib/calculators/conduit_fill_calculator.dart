import '../catalogs/raceway_catalog.dart';
import '../models/calculation_results.dart';
import '../models/conductor.dart';
import '../models/raceway.dart';
import 'jam_ratio_calculator.dart';

class ConduitFillCalculator {
  ConduitFillCalculator._();

  /// Determine allowed fill percentage per NEC Chapter 9 Table 1 & Note 4
  static double getAllowedFillPercentage({
    required int totalConductorCount,
    bool isNipple = false,
  }) {
    if (isNipple) return 60.0;
    if (totalConductorCount <= 0) return 0.0;
    if (totalConductorCount == 1) return 53.0;
    if (totalConductorCount == 2) return 31.0;
    return 40.0; // 3 or more conductors
  }

  /// Calculates maximum number of uniform conductors permitted in conduit
  /// applying NEC Chapter 9 Note 7 rounding rule (>= 0.8 rounds up).
  static int calculateMaxConductors({
    required double conduitArea,
    required double wireArea,
    bool isNipple = false,
  }) {
    if (wireArea <= 0 || conduitArea <= 0) return 0;

    if (isNipple) {
      final raw = (conduitArea * 0.60) / wireArea;
      final decimal = raw - raw.floor();
      return (decimal >= 0.80) ? raw.ceil() : raw.floor();
    }

    // Check 1 conductor (53% limit)
    if (wireArea > conduitArea * 0.53) return 0;

    // Check 2 conductors (31% limit)
    final raw2 = (conduitArea * 0.31) / wireArea;
    if (raw2 < 2.0) return 1;

    // 3 or more conductors (40% limit)
    final raw3 = (conduitArea * 0.40) / wireArea;
    if (raw3 < 3.0) return 2;

    // Apply Note 7 rounding rule (>= 0.80 rounds up to next whole number)
    final decimal = raw3 - raw3.floor();
    return (decimal >= 0.80) ? raw3.ceil() : raw3.floor();
  }

  /// Comprehensive conduit fill calculation for a raceway and conductor schedule
  static ConduitFillResult calculate({
    required RacewayProfile raceway,
    required List<ConductorGroup> conductorGroups,
    bool isNipple = false,
  }) {
    double totalArea = 0.0;
    int totalCount = 0;

    for (final group in conductorGroups) {
      totalArea += group.totalAreaSqInches;
      totalCount += group.count;
    }

    final allowedPercentage = getAllowedFillPercentage(
      totalConductorCount: totalCount,
      isNipple: isNipple,
    );

    final allowedArea = raceway.internalAreaSqInches * (allowedPercentage / 100.0);
    final fillPercentage = raceway.internalAreaSqInches > 0
        ? (totalArea / raceway.internalAreaSqInches) * 100.0
        : 0.0;

    // Direct area comparison with floating point tolerance
    final isCompliant = totalArea <= allowedArea + 0.000001;

    // Evaluate Jam Ratio
    // Per IEEE / NEC Informational note: check if exactly 3 conductors or if there is a dominant group of 3 conductors of equal diameter
    double? jamRatio;
    JamRiskLevel jamRiskLevel = JamRiskLevel.notApplicable;
    bool hasJamRisk = false;

    // Find any group with exactly 3 conductors, or if total conductors == 3 of same diameter
    ConductorGroup? groupOf3;
    for (final g in conductorGroups) {
      if (g.count == 3) {
        groupOf3 = g;
        break;
      }
    }

    if (groupOf3 != null) {
      final jamResult = JamRatioCalculator.calculate(
        conduitInsideDiameter: raceway.internalDiameterInches,
        wireOutsideDiameter: groupOf3.spec.outerDiameterInches,
      );
      jamRatio = jamResult.ratio;
      jamRiskLevel = jamResult.riskLevel;
      hasJamRisk = jamResult.isHighRisk;
    } else if (totalCount == 1) {
      jamRiskLevel = JamRiskLevel.safeSingle;
    } else if (totalCount == 2) {
      jamRiskLevel = JamRiskLevel.safeDual;
    }

    // Determine upsize recommendation if not compliant
    String? recommendedUpsize;
    if (!isCompliant) {
      final upsizeProfiles = RacewayCatalog.getUpsizeProfiles(
        raceway.type,
        raceway.tradeSize,
      );

      for (final candidate in upsizeProfiles) {
        final candidateAllowed = candidate.internalAreaSqInches * (allowedPercentage / 100.0);
        if (totalArea <= candidateAllowed + 0.000001) {
          recommendedUpsize = candidate.tradeSize;
          break;
        }
      }
    }

    return ConduitFillResult(
      totalConductorArea: totalArea,
      racewayInternalArea: raceway.internalAreaSqInches,
      fillPercentage: fillPercentage,
      allowedFillPercentage: allowedPercentage,
      allowedFillArea: allowedArea,
      isCompliant: isCompliant,
      jamRatio: jamRatio,
      hasJamRisk: hasJamRisk,
      jamRiskLevel: jamRiskLevel,
      recommendedUpsizeTradeSize: recommendedUpsize,
      totalConductorCount: totalCount,
      isNipple: isNipple,
    );
  }
}
