import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:electronorm/models/raceway.dart';
import 'package:electronorm/models/conductor.dart';
import 'package:electronorm/models/calculation_results.dart';
import 'package:electronorm/catalogs/raceway_catalog.dart';
import 'package:electronorm/catalogs/conductor_catalog.dart';
import 'package:electronorm/calculators/conduit_fill_calculator.dart';
import 'package:electronorm/calculators/jam_ratio_calculator.dart';

void main() {
  group('STRESS SUITE 1: 60-Raceway Dimensional & Theoretical Area Oracle', () {
    test('Oracle 1.1: Every profile total internal area matches theoretical pi/4 * ID^2 within NEC rounding', () {
      expect(RacewayCatalog.profiles.length, equals(60),
          reason: 'Raceway catalog must contain exactly 60 normative profiles');

      for (final profile in RacewayCatalog.profiles) {
        final id = profile.internalDiameterInches;
        final theoreticalArea = (math.pi / 4.0) * id * id;

        // NEC Chapter 9 Table 4 publishes areas rounded to 3 decimal places.
        // Theoretical vs published should match within 0.006 sq in.
        expect(
          profile.internalAreaSqInches,
          closeTo(theoreticalArea, 0.006),
          reason: 'Profile ${profile.type.name} ${profile.tradeSize} published area (${profile.internalAreaSqInches}) '
              'deviates significantly from theoretical pi/4 * ID^2 ($theoreticalArea)',
        );

        // Metric cross-sectional area check: A_mm2 approx A_in2 * 645.16
        final convertedMm2 = profile.internalAreaSqInches * 645.16;
        expect(
          profile.internalAreaSqMm,
          closeTo(convertedMm2, 2.5),
          reason: 'Profile ${profile.type.name} ${profile.tradeSize} metric area (${profile.internalAreaSqMm}) '
              'inconsistent with imperial area',
        );

        // Metric ID check: ID_mm approx ID_in * 25.4
        final convertedMm = profile.internalDiameterInches * 25.4;
        expect(
          profile.internalDiameterMm,
          closeTo(convertedMm, 0.15),
          reason: 'Profile ${profile.type.name} ${profile.tradeSize} metric diameter (${profile.internalDiameterMm}) '
              'inconsistent with imperial diameter',
        );
      }
    });

    test('Oracle 1.2: Every profile fill areas match exact NEC percentage multipliers (53%, 31%, 40%, 60%)', () {
      for (final p in RacewayCatalog.profiles) {
        final a = p.internalAreaSqInches;

        // Published 40% area in NEC Table 4 is rounded to 3 decimal places.
        expect(p.fill40AreaSqInches, closeTo(a * 0.40, 0.003),
            reason: '${p.type.name} ${p.tradeSize} 40% fill area mismatch');

        // Published 53% area
        expect(p.fill53AreaSqInches, closeTo(a * 0.53, 0.003),
            reason: '${p.type.name} ${p.tradeSize} 53% fill area mismatch');

        // Published 31% area
        expect(p.fill31AreaSqInches, closeTo(a * 0.31, 0.003),
            reason: '${p.type.name} ${p.tradeSize} 31% fill area mismatch');

        // Published 60% area (nipple)
        expect(p.fill60AreaSqInches, closeTo(a * 0.60, 0.003),
            reason: '${p.type.name} ${p.tradeSize} 60% fill area mismatch');
      }
    });

    test('Oracle 1.3: Monotonic area increase across all trade sizes for every raceway family', () {
      for (final type in RacewayType.values) {
        final family = RacewayCatalog.getProfilesForType(type);
        expect(family.length, equals(10),
            reason: '${type.name} should have 10 standard sizes (1/2" through 4")');

        for (int i = 0; i < family.length - 1; i++) {
          final current = family[i];
          final next = family[i + 1];

          expect(
            next.internalDiameterInches,
            greaterThan(current.internalDiameterInches),
            reason: '${type.name} ID at index ${i + 1} (${next.tradeSize}) must be strictly greater than index $i (${current.tradeSize})',
          );

          expect(
            next.internalAreaSqInches,
            greaterThan(current.internalAreaSqInches),
            reason: '${type.name} Area at index ${i + 1} (${next.tradeSize}) must be strictly greater than index $i (${current.tradeSize})',
          );
        }
      }
    });
  });

  group('STRESS SUITE 2: Strict NEC Chapter 9 Table 1 Fill Limits (53%, 31%, 40%, 60%)', () {
    test('Oracle 2.1: Allowed percentage function strictly returns 53%, 31%, 40%, and 60% for all N', () {
      // 0 conductors: 0% allowed
      expect(ConduitFillCalculator.getAllowedFillPercentage(totalConductorCount: 0), equals(0.0));
      expect(ConduitFillCalculator.getAllowedFillPercentage(totalConductorCount: -1), equals(0.0));

      // 1 conductor: 53.0%
      expect(ConduitFillCalculator.getAllowedFillPercentage(totalConductorCount: 1), equals(53.0));

      // 2 conductors: 31.0%
      expect(ConduitFillCalculator.getAllowedFillPercentage(totalConductorCount: 2), equals(31.0));

      // 3 to 100 conductors: strictly 40.0%
      for (int count = 3; count <= 100; count++) {
        expect(
          ConduitFillCalculator.getAllowedFillPercentage(totalConductorCount: count),
          equals(40.0),
          reason: 'Count $count must have allowedFillPercentage == 40.0',
        );
      }

      // Nipple exemption: strictly 60.0% for any positive conductor count
      for (int count = 1; count <= 50; count++) {
        expect(
          ConduitFillCalculator.getAllowedFillPercentage(totalConductorCount: count, isNipple: true),
          equals(60.0),
          reason: 'Nipple with count $count must have allowedFillPercentage == 60.0',
        );
      }
    });

    test('Oracle 2.2: Adversarial Boundary Fuzzing — 1 conductor strict 53% compliance threshold', () {
      final raceway = RacewayCatalog.getProfile(RacewayType.emt, '1'); // A = 0.864
      final allowedArea = raceway.internalAreaSqInches * 0.53; // 0.45792

      // Custom synthetic wire at 52.999% fill (compliant)
      final wireUnder = ConductorSpec(
        gauge: 'CustomUnder',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
        outerDiameterInches: 0.5,
        outerDiameterMm: 12.7,
        areaSqInches: allowedArea - 0.0001,
        areaSqMm: (allowedArea - 0.0001) * 645.16,
        ampacity60C: 100,
        ampacity75C: 100,
        ampacity90C: 100,
      );

      final resUnder = ConduitFillCalculator.calculate(
        raceway: raceway,
        conductorGroups: [ConductorGroup(id: '1', spec: wireUnder, count: 1, role: 'phaseA')],
      );
      expect(resUnder.isCompliant, isTrue);
      expect(resUnder.allowedFillPercentage, equals(53.0));

      // Wire at exactly 53.000% fill (compliant)
      final wireExact = ConductorSpec(
        gauge: 'CustomExact',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
        outerDiameterInches: 0.5,
        outerDiameterMm: 12.7,
        areaSqInches: allowedArea,
        areaSqMm: allowedArea * 645.16,
        ampacity60C: 100,
        ampacity75C: 100,
        ampacity90C: 100,
      );

      final resExact = ConduitFillCalculator.calculate(
        raceway: raceway,
        conductorGroups: [ConductorGroup(id: '1', spec: wireExact, count: 1, role: 'phaseA')],
      );
      expect(resExact.isCompliant, isTrue);

      // Wire at 53.002% fill (non-compliant)
      final wireOver = ConductorSpec(
        gauge: 'CustomOver',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
        outerDiameterInches: 0.5,
        outerDiameterMm: 12.7,
        areaSqInches: allowedArea + 0.0005,
        areaSqMm: (allowedArea + 0.0005) * 645.16,
        ampacity60C: 100,
        ampacity75C: 100,
        ampacity90C: 100,
      );

      final resOver = ConduitFillCalculator.calculate(
        raceway: raceway,
        conductorGroups: [ConductorGroup(id: '1', spec: wireOver, count: 1, role: 'phaseA')],
      );
      expect(resOver.isCompliant, isFalse);
    });

    test('Oracle 2.3: Adversarial Boundary Fuzzing — 2 conductors strict 31% compliance threshold', () {
      final raceway = RacewayCatalog.getProfile(RacewayType.emt, '1'); // A = 0.864
      final allowedArea = raceway.internalAreaSqInches * 0.31; // 0.26784
      final singleWireArea = allowedArea / 2.0;

      // 2 wires under 31%
      final wireUnder = ConductorSpec(
        gauge: 'Custom2Under',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
        outerDiameterInches: 0.4,
        outerDiameterMm: 10.0,
        areaSqInches: singleWireArea - 0.0001,
        areaSqMm: 50.0,
        ampacity60C: 50,
        ampacity75C: 50,
        ampacity90C: 50,
      );

      final resUnder = ConduitFillCalculator.calculate(
        raceway: raceway,
        conductorGroups: [ConductorGroup(id: '1', spec: wireUnder, count: 2, role: 'phase')],
      );
      expect(resUnder.isCompliant, isTrue);
      expect(resUnder.allowedFillPercentage, equals(31.0));

      // 2 wires over 31%
      final wireOver = ConductorSpec(
        gauge: 'Custom2Over',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
        outerDiameterInches: 0.4,
        outerDiameterMm: 10.0,
        areaSqInches: singleWireArea + 0.0003,
        areaSqMm: 50.0,
        ampacity60C: 50,
        ampacity75C: 50,
        ampacity90C: 50,
      );

      final resOver = ConduitFillCalculator.calculate(
        raceway: raceway,
        conductorGroups: [ConductorGroup(id: '1', spec: wireOver, count: 2, role: 'phase')],
      );
      expect(resOver.isCompliant, isFalse);
    });

    test('Oracle 2.4: Adversarial Boundary Fuzzing — 3+ conductors strict 40% compliance threshold', () {
      final raceway = RacewayCatalog.getProfile(RacewayType.emt, '1'); // A = 0.864
      final allowedArea = raceway.internalAreaSqInches * 0.40; // 0.3456

      for (final wireCount in [3, 4, 7, 12]) {
        final singleUnder = (allowedArea - 0.0002) / wireCount;
        final wireUnder = ConductorSpec(
          gauge: 'Custom${wireCount}Under',
          insulation: ConductorInsulation.thhn,
          material: ConductorMaterial.copper,
          outerDiameterInches: 0.2,
          outerDiameterMm: 5.0,
          areaSqInches: singleUnder,
          areaSqMm: singleUnder * 645.16,
          ampacity60C: 30,
          ampacity75C: 30,
          ampacity90C: 30,
        );

        final resUnder = ConduitFillCalculator.calculate(
          raceway: raceway,
          conductorGroups: [ConductorGroup(id: '1', spec: wireUnder, count: wireCount, role: 'phase')],
        );
        expect(resUnder.isCompliant, isTrue,
            reason: 'Count $wireCount under 40% must be compliant');
        expect(resUnder.allowedFillPercentage, equals(40.0));

        final singleOver = (allowedArea + 0.0005) / wireCount;
        final wireOver = ConductorSpec(
          gauge: 'Custom${wireCount}Over',
          insulation: ConductorInsulation.thhn,
          material: ConductorMaterial.copper,
          outerDiameterInches: 0.2,
          outerDiameterMm: 5.0,
          areaSqInches: singleOver,
          areaSqMm: singleOver * 645.16,
          ampacity60C: 30,
          ampacity75C: 30,
          ampacity90C: 30,
        );

        final resOver = ConduitFillCalculator.calculate(
          raceway: raceway,
          conductorGroups: [ConductorGroup(id: '1', spec: wireOver, count: wireCount, role: 'phase')],
        );
        expect(resOver.isCompliant, isFalse,
            reason: 'Count $wireCount over 40% must be non-compliant');
      }
    });

    test('Oracle 2.5: The Ground Wire Paradox — Adding 3rd wire flips overfilled (35% fill) to compliant', () {
      // In 1" EMT (A = 0.864 in²), 2 wires occupying 0.150 in² each = 0.300 in² (34.72% fill)
      final emt1 = RacewayCatalog.getProfile(RacewayType.emt, '1');
      final wirePhase = ConductorSpec(
        gauge: 'SpecialPhase',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
        outerDiameterInches: 0.40,
        outerDiameterMm: 10.16,
        areaSqInches: 0.150,
        areaSqMm: 96.77,
        ampacity60C: 100,
        ampacity75C: 100,
        ampacity90C: 100,
      );

      final result2Wires = ConduitFillCalculator.calculate(
        raceway: emt1,
        conductorGroups: [
          ConductorGroup(id: '1', spec: wirePhase, count: 2, role: 'phase'),
        ],
      );

      // 2 wires is limited to 31% -> 34.72% must FAIL
      expect(result2Wires.allowedFillPercentage, equals(31.0));
      expect(result2Wires.fillPercentage, closeTo(34.72, 0.05));
      expect(result2Wires.isCompliant, isFalse,
          reason: '2 conductors occupying 34.7% exceeds 31% limit and MUST fail');

      // Now add a small #14 AWG Ground wire (area = 0.0097 in²)
      final wireGround = ConductorCatalog.getSpec(
        gauge: '14 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final result3Wires = ConduitFillCalculator.calculate(
        raceway: emt1,
        conductorGroups: [
          ConductorGroup(id: '1', spec: wirePhase, count: 2, role: 'phase'),
          ConductorGroup(id: '2', spec: wireGround, count: 1, role: 'ground'),
        ],
      );

      // Total count is now 3 -> Allowed limit jumps to 40%
      // Total area = 0.300 + 0.0097 = 0.3097 in² -> Fill % = 0.3097 / 0.864 = 35.84%
      // 35.84% is strictly below 40.0% -> PASS!
      expect(result3Wires.allowedFillPercentage, equals(40.0));
      expect(result3Wires.fillPercentage, closeTo(35.84, 0.05));
      expect(result3Wires.isCompliant, isTrue,
          reason: 'Adding 3rd wire must raise limit to 40% and render conduit compliant');
    });

    test('Oracle 2.6: Zero Conductors and Empty Schedule Handled Safely', () {
      final emt1 = RacewayCatalog.getProfile(RacewayType.emt, '1');
      final result = ConduitFillCalculator.calculate(
        raceway: emt1,
        conductorGroups: [],
      );

      expect(result.totalConductorArea, equals(0.0));
      expect(result.fillPercentage, equals(0.0));
      expect(result.allowedFillPercentage, equals(0.0));
      expect(result.isCompliant, isTrue);
      expect(result.recommendedUpsizeTradeSize, isNull);
    });
  });

  group('STRESS SUITE 3: Jam Ratio Safety Oracle (2.80 <= D/d <= 3.20)', () {
    test('Oracle 3.1: Mathematical Range & Strict Boundary Transitions', () {
      const conduitD = 3.0;

      // Safe Clearance: D/d > 3.20 -> d < 3.0 / 3.20 = 0.9375
      final resClearance = JamRatioCalculator.calculate(
        conduitInsideDiameter: conduitD,
        wireOutsideDiameter: 0.9370, // ratio = 3.2017
      );
      expect(resClearance.ratio, greaterThan(3.20));
      expect(resClearance.riskLevel, equals(JamRiskLevel.safeClearance));
      expect(resClearance.isHighRisk, isFalse);

      // Upper Boundary High Jam Risk: ratio == 3.200
      final resBoundaryUpper = JamRatioCalculator.calculate(
        conduitInsideDiameter: 3.20,
        wireOutsideDiameter: 1.00,
      );
      expect(resBoundaryUpper.ratio, equals(3.20));
      expect(resBoundaryUpper.riskLevel, equals(JamRiskLevel.highJamRisk));
      expect(resBoundaryUpper.isHighRisk, isTrue);

      // Mid-Zone High Jam Risk: ratio == 3.00
      final resMid = JamRatioCalculator.calculate(
        conduitInsideDiameter: 3.00,
        wireOutsideDiameter: 1.00,
      );
      expect(resMid.ratio, equals(3.00));
      expect(resMid.riskLevel, equals(JamRiskLevel.highJamRisk));
      expect(resMid.isHighRisk, isTrue);

      // Lower Boundary High Jam Risk: ratio == 2.800
      final resBoundaryLower = JamRatioCalculator.calculate(
        conduitInsideDiameter: 2.80,
        wireOutsideDiameter: 1.00,
      );
      expect(resBoundaryLower.ratio, equals(2.80));
      expect(resBoundaryLower.riskLevel, equals(JamRiskLevel.highJamRisk));
      expect(resBoundaryLower.isHighRisk, isTrue);

      // Moderate Risk Upper: ratio == 2.799
      final resModUpper = JamRatioCalculator.calculate(
        conduitInsideDiameter: 2.799,
        wireOutsideDiameter: 1.00,
      );
      expect(resModUpper.ratio, closeTo(2.799, 0.001));
      expect(resModUpper.riskLevel, equals(JamRiskLevel.moderateRisk));
      expect(resModUpper.isHighRisk, isFalse);

      // Moderate Risk Lower Boundary: ratio == 2.500
      final resModLower = JamRatioCalculator.calculate(
        conduitInsideDiameter: 2.50,
        wireOutsideDiameter: 1.00,
      );
      expect(resModLower.ratio, equals(2.50));
      expect(resModLower.riskLevel, equals(JamRiskLevel.moderateRisk));
      expect(resModLower.isHighRisk, isFalse);

      // Constrained Safe: ratio < 2.500
      final resConstrained = JamRatioCalculator.calculate(
        conduitInsideDiameter: 2.49,
        wireOutsideDiameter: 1.00,
      );
      expect(resConstrained.ratio, closeTo(2.49, 0.001));
      expect(resConstrained.riskLevel, equals(JamRiskLevel.safeConstrained));
      expect(resConstrained.isHighRisk, isFalse);
    });

    test('Oracle 3.2: Comprehensive Industrial Pull Scenarios for 3-Conductor Pulls', () {
      // Scenario A: 3x 250 kcmil THHN (OD = 0.711") in 2" EMT (ID = 2.067") -> R = 2.907 (HIGH JAM RISK)
      final emt2 = RacewayCatalog.getProfile(RacewayType.emt, '2');
      final wire250 = ConductorCatalog.getSpec(
        gauge: '250 kcmil',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );
      final resA = ConduitFillCalculator.calculate(
        raceway: emt2,
        conductorGroups: [ConductorGroup(id: '1', spec: wire250, count: 3, role: 'phase')],
      );
      expect(resA.jamRatio, closeTo(2.907, 0.001));
      expect(resA.hasJamRisk, isTrue);
      expect(resA.jamRiskLevel, equals(JamRiskLevel.highJamRisk));

      // Scenario B: 3x 4/0 AWG THHN (OD = 0.642") in 2" PVC Sch 40 (ID = 2.047")
      // R = 2.047 / 0.642 = 3.1885 -> (HIGH JAM RISK, just below 3.20!)
      final pvc2 = RacewayCatalog.getProfile(RacewayType.pvcSch40, '2');
      final wire40 = ConductorCatalog.getSpec(
        gauge: '4/0 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );
      final resB = ConduitFillCalculator.calculate(
        raceway: pvc2,
        conductorGroups: [ConductorGroup(id: '1', spec: wire40, count: 3, role: 'phase')],
      );
      expect(resB.jamRatio, closeTo(3.1885, 0.001));
      expect(resB.hasJamRisk, isTrue);
      expect(resB.jamRiskLevel, equals(JamRiskLevel.highJamRisk));

      // Scenario C: Same 3x 4/0 AWG THHN in 2" EMT (ID = 2.067")
      // R = 2.067 / 0.642 = 3.2196 -> (SAFE CLEARANCE, just above 3.20!)
      final resC = ConduitFillCalculator.calculate(
        raceway: emt2,
        conductorGroups: [ConductorGroup(id: '1', spec: wire40, count: 3, role: 'phase')],
      );
      expect(resC.jamRatio, closeTo(3.2196, 0.001));
      expect(resC.hasJamRisk, isFalse);
      expect(resC.jamRiskLevel, equals(JamRiskLevel.safeClearance));

      // Scenario D: 3x 3/0 AWG THHN (OD = 0.584") in 1-1/2" IMC (ID = 1.683")
      // R = 1.683 / 0.584 = 2.8818 -> (HIGH JAM RISK!)
      final imc15 = RacewayCatalog.getProfile(RacewayType.imc, '1-1/2');
      final wire30 = ConductorCatalog.getSpec(
        gauge: '3/0 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );
      final resD = ConduitFillCalculator.calculate(
        raceway: imc15,
        conductorGroups: [ConductorGroup(id: '1', spec: wire30, count: 3, role: 'phase')],
      );
      expect(resD.jamRatio, closeTo(2.8818, 0.001));
      expect(resD.hasJamRisk, isTrue);
      expect(resD.jamRiskLevel, equals(JamRiskLevel.highJamRisk));
    });

    test('Oracle 3.3: Adversarial Grouping Edge Case Analysis (Identical conductors across separate groups)', () {
      // If an electrician enters 3 identical conductors as a single group with count=3, jam risk is flagged.
      final emt2 = RacewayCatalog.getProfile(RacewayType.emt, '2');
      final wire250 = ConductorCatalog.getSpec(
        gauge: '250 kcmil',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final singleGroupOf3 = ConduitFillCalculator.calculate(
        raceway: emt2,
        conductorGroups: [
          ConductorGroup(id: '1', spec: wire250, count: 3, role: 'phase'),
        ],
      );
      expect(singleGroupOf3.hasJamRisk, isTrue);
      expect(singleGroupOf3.jamRiskLevel, equals(JamRiskLevel.highJamRisk));

      // Adversarial Check: What if user enters Phase A (1), Phase B (1), Phase C (1) as 3 distinct groups?
      final splitGroupOf3 = ConduitFillCalculator.calculate(
        raceway: emt2,
        conductorGroups: [
          ConductorGroup(id: '1', spec: wire250, count: 1, role: 'phaseA'),
          ConductorGroup(id: '2', spec: wire250, count: 1, role: 'phaseB'),
          ConductorGroup(id: '3', spec: wire250, count: 1, role: 'phaseC'),
        ],
      );

      // Verify the observed engine behavior:
      // In conduit_fill_calculator.dart, jam check looks for `g.count == 3`.
      // When entered as 3 separate 1-wire groups, g.count is 1 for each, so groupOf3 is null.
      // Total count is 3, so neither totalCount==1 nor totalCount==2 matches.
      // We document this boundary behavior:
      expect(splitGroupOf3.totalConductorCount, equals(3));
      // Notice: splitGroupOf3.hasJamRisk will be false unless the engine aggregates identical wire groups!
      // This is a valuable finding for our handoff report.
    });
  });

  group('STRESS SUITE 4: Automatic Raceway Upsizing Recommendation Oracle', () {
    test('Oracle 4.1: Exhaustive Upsize Oracle across all 6 raceway families and trade sizes', () {
      final tradeSizes = RacewayCatalog.standardTradeSizes;

      for (final type in RacewayType.values) {
        for (int i = 0; i < tradeSizes.length - 1; i++) {
          final currentSize = tradeSizes[i];
          final currentProfile = RacewayCatalog.getProfile(type, currentSize);

          // Force an overfill that exceeds current size 40% area by 15%
          // but fits within the next size's 40% area
          final nextSize = tradeSizes[i + 1];
          final nextProfile = RacewayCatalog.getProfile(type, nextSize);

          // Choose target area halfway between current 40% limit and next 40% limit
          final targetArea = (currentProfile.fill40AreaSqInches + nextProfile.fill40AreaSqInches) / 2.0;

          final syntheticWire = ConductorSpec(
            gauge: 'SyntheticWire',
            insulation: ConductorInsulation.thhn,
            material: ConductorMaterial.copper,
            outerDiameterInches: 0.25,
            outerDiameterMm: 6.35,
            areaSqInches: targetArea / 4.0,
            areaSqMm: (targetArea / 4.0) * 645.16,
            ampacity60C: 50,
            ampacity75C: 50,
            ampacity90C: 50,
          );

          final result = ConduitFillCalculator.calculate(
            raceway: currentProfile,
            conductorGroups: [
              ConductorGroup(id: '1', spec: syntheticWire, count: 4, role: 'phase'),
            ],
          );

          expect(result.isCompliant, isFalse,
              reason: '${type.name} $currentSize should be overfilled');
          expect(result.recommendedUpsizeTradeSize, equals(nextSize),
              reason: 'Overfilled ${type.name} $currentSize must recommend immediate next valid size $nextSize');
        }
      }
    });

    test('Oracle 4.2: Multi-Step Jump Upsize Oracle (Skipping multiple intermediate undersized trade sizes)', () {
      // Start in 1/2" EMT (40% area = 0.122 in²)
      final emt12 = RacewayCatalog.getProfile(RacewayType.emt, '1/2');

      // Total conductor area = 1.00 in²
      // 1/2" (0.122) -> Fail
      // 3/4" (0.213) -> Fail
      // 1"   (0.346) -> Fail
      // 1-1/4" (0.598) -> Fail
      // 1-1/2" (0.814) -> Fail
      // 2"   (1.342) -> PASS! (1.00 <= 1.342)
      final largeWire = ConductorSpec(
        gauge: 'LargeWire',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
        outerDiameterInches: 0.5,
        outerDiameterMm: 12.7,
        areaSqInches: 0.25,
        areaSqMm: 161.29,
        ampacity60C: 150,
        ampacity75C: 150,
        ampacity90C: 150,
      );

      final result = ConduitFillCalculator.calculate(
        raceway: emt12,
        conductorGroups: [
          ConductorGroup(id: '1', spec: largeWire, count: 4, role: 'phase'),
        ],
      );

      expect(result.totalConductorArea, closeTo(1.00, 0.001));
      expect(result.isCompliant, isFalse);
      expect(result.recommendedUpsizeTradeSize, equals('2'),
          reason: 'Engine must jump directly across 5 intermediate sizes to 2" EMT');
    });

    test('Oracle 4.3: Conductor-Count Adaptive Upsize Limits (1 wire at 53% vs 2 wires at 31%)', () {
      // Test 1 Conductor: 4/0 AWG THHN (Area = 0.3237 in²) in 3/4" EMT (Total Area = 0.533 in²)
      // 3/4" EMT: 53% area = 0.533 * 0.53 = 0.28249 in² < 0.3237 in² -> Overfilled!
      // 1" EMT: 53% area = 0.864 * 0.53 = 0.45792 in² >= 0.3237 in² -> Fits!
      final emt34 = RacewayCatalog.getProfile(RacewayType.emt, '3/4');
      final wire40 = ConductorCatalog.getSpec(
        gauge: '4/0 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final res1Wire = ConduitFillCalculator.calculate(
        raceway: emt34,
        conductorGroups: [
          ConductorGroup(id: '1', spec: wire40, count: 1, role: 'feeder'),
        ],
      );

      expect(res1Wire.isCompliant, isFalse);
      expect(res1Wire.allowedFillPercentage, equals(53.0));
      // Upsize recommendation must use the 53% limit for candidate comparison!
      expect(res1Wire.recommendedUpsizeTradeSize, equals('1'));

      // Test 2 Conductors: 2x 2/0 AWG THHN (Area = 0.2223 * 2 = 0.4446 in²) in 1" EMT
      // 1" EMT Total Area = 0.864 in²
      // 31% allowed area = 0.864 * 0.31 = 0.2678 in² < 0.4446 in² -> Overfilled!
      // 1-1/4" EMT: Total Area = 1.496 in² -> 31% = 0.46376 in² >= 0.4446 in² -> Fits!
      // Notice: If the engine wrongly evaluated 40% for candidate upsize, 1-1/4" would have 0.598 in²,
      // but because the schedule has 2 wires, candidate MUST satisfy 31%!
      final emt1 = RacewayCatalog.getProfile(RacewayType.emt, '1');
      final wire20 = ConductorCatalog.getSpec(
        gauge: '2/0 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final res2Wires = ConduitFillCalculator.calculate(
        raceway: emt1,
        conductorGroups: [
          ConductorGroup(id: '1', spec: wire20, count: 2, role: 'feeder'),
        ],
      );

      expect(res2Wires.isCompliant, isFalse);
      expect(res2Wires.allowedFillPercentage, equals(31.0));
      expect(res2Wires.recommendedUpsizeTradeSize, equals('1-1/4'));
    });

    test('Oracle 4.4: Boundary Conditions — Overfill beyond 4" raceway returns null', () {
      final emt12 = RacewayCatalog.getProfile(RacewayType.emt, '1/2');

      // Huge load: 10.0 sq in (exceeds 4" EMT 40% capacity of 5.901 sq in)
      final massiveWire = ConductorSpec(
        gauge: 'MassiveWire',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
        outerDiameterInches: 1.0,
        outerDiameterMm: 25.4,
        areaSqInches: 2.50,
        areaSqMm: 1612.9,
        ampacity60C: 500,
        ampacity75C: 500,
        ampacity90C: 500,
      );

      final result = ConduitFillCalculator.calculate(
        raceway: emt12,
        conductorGroups: [
          ConductorGroup(id: '1', spec: massiveWire, count: 4, role: 'phase'),
        ],
      );

      expect(result.totalConductorArea, equals(10.0));
      expect(result.isCompliant, isFalse);
      expect(result.recommendedUpsizeTradeSize, isNull,
          reason: 'No standard trade size up to 4" can accommodate 10.0 sq in, so recommendation must be null');
    });

    test('Oracle 4.5: Already compliant raceway returns null upsize recommendation', () {
      final emt1 = RacewayCatalog.getProfile(RacewayType.emt, '1');
      final wire12 = ConductorCatalog.getSpec(
        gauge: '12 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final result = ConduitFillCalculator.calculate(
        raceway: emt1,
        conductorGroups: [
          ConductorGroup(id: '1', spec: wire12, count: 3, role: 'phase'),
        ],
      );

      expect(result.isCompliant, isTrue);
      expect(result.recommendedUpsizeTradeSize, isNull);
    });
  });

  group('STRESS SUITE 5: Realistic Heavy Commercial & Mixed-Conductor Schedules', () {
    test('Stress 5.1: 480V 400A Heavy Feeder in EMT (4x 500 kcmil THHN + 1x #3 Ground)', () {
      // 4x 500 kcmil THHN (4 * 0.7073 = 2.8292 in²) + 1x #3 THHN (0.0973 in²)
      // Total area = 2.9265 in² (5 conductors -> 40% fill limit)
      // Check trade sizes:
      // 2-1/2" EMT (40% = 2.343 in²) -> Fails (124.9% of allowed)
      // 3" EMT (40% = 3.538 in²) -> Compliant (82.7% of allowed)
      final emt25 = RacewayCatalog.getProfile(RacewayType.emt, '2-1/2');
      final emt3 = RacewayCatalog.getProfile(RacewayType.emt, '3');
      final wire500 = ConductorCatalog.getSpec(
        gauge: '500 kcmil',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );
      final wire3 = ConductorCatalog.getSpec(
        gauge: '3 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final res25 = ConduitFillCalculator.calculate(
        raceway: emt25,
        conductorGroups: [
          ConductorGroup(id: '1', spec: wire500, count: 4, role: 'phase'),
          ConductorGroup(id: '2', spec: wire3, count: 1, role: 'ground'),
        ],
      );
      expect(res25.isCompliant, isFalse);
      expect(res25.recommendedUpsizeTradeSize, equals('3'));

      final res3 = ConduitFillCalculator.calculate(
        raceway: emt3,
        conductorGroups: [
          ConductorGroup(id: '1', spec: wire500, count: 4, role: 'phase'),
          ConductorGroup(id: '2', spec: wire3, count: 1, role: 'ground'),
        ],
      );
      expect(res3.isCompliant, isTrue);
      expect(res3.fillPercentage, closeTo(33.08, 0.05));
    });

    test('Stress 5.2: 12-Circuit Branch Home Run in 1" EMT (Mixed #12 THHN & #10 THHN)', () {
      // 18x #12 AWG THHN (18 * 0.0133 = 0.2394) + 6x #10 AWG THHN (6 * 0.0211 = 0.1266)
      // Total area = 0.3660 in² (24 conductors -> 40% fill limit)
      // 1" EMT (40% = 0.346 in²) -> Fails by just 0.020 in²! (Overfilled at 42.36%)
      // Recommended: 1-1/4" EMT (40% = 0.598 in²)
      final emt1 = RacewayCatalog.getProfile(RacewayType.emt, '1');
      final wire12 = ConductorCatalog.getSpec(
        gauge: '12 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );
      final wire10 = ConductorCatalog.getSpec(
        gauge: '10 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final result = ConduitFillCalculator.calculate(
        raceway: emt1,
        conductorGroups: [
          ConductorGroup(id: '1', spec: wire12, count: 18, role: 'phase'),
          ConductorGroup(id: '2', spec: wire10, count: 6, role: 'phase'),
        ],
      );

      expect(result.totalConductorArea, closeTo(0.3660, 0.0001));
      expect(result.fillPercentage, closeTo(42.36, 0.05));
      expect(result.isCompliant, isFalse);
      expect(result.recommendedUpsizeTradeSize, equals('1-1/4'));
    });
  });
}
