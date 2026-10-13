import 'package:flutter_test/flutter_test.dart';
import 'package:electronorm/models/raceway.dart';
import 'package:electronorm/models/conductor.dart';
import 'package:electronorm/models/calculation_results.dart';
import 'package:electronorm/catalogs/raceway_catalog.dart';
import 'package:electronorm/catalogs/conductor_catalog.dart';
import 'package:electronorm/calculators/conduit_fill_calculator.dart';
import 'package:electronorm/calculators/jam_ratio_calculator.dart';
import 'package:electronorm/calculators/voltage_drop_calculator.dart';
import 'package:electronorm/calculators/derating_calculator.dart';

void main() {
  group('Conduit Fill Normative Benchmarks (CF-01 through CF-08)', () {
    test('CF-01: Single Large Feeder (1" EMT, 1x 4/0 AWG THHN)', () {
      final emt1 = RacewayCatalog.getProfile(RacewayType.emt, '1');
      final wire40 = ConductorCatalog.getSpec(
        gauge: '4/0 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final result = ConduitFillCalculator.calculate(
        raceway: emt1,
        conductorGroups: [
          ConductorGroup(id: '1', spec: wire40, count: 1, role: 'phaseA'),
        ],
      );

      expect(result.totalConductorArea, closeTo(0.3237, 0.0001));
      expect(result.allowedFillPercentage, equals(53.0));
      expect(result.fillPercentage, closeTo(37.47, 0.01));
      expect(result.isCompliant, isTrue);
      expect(result.jamRiskLevel, equals(JamRiskLevel.safeSingle));
    });

    test('CF-02: Dual Conductor Feeder (3/4" EMT, 2x #8 AWG THHN)', () {
      final emt34 = RacewayCatalog.getProfile(RacewayType.emt, '3/4');
      final wire8 = ConductorCatalog.getSpec(
        gauge: '8 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final result = ConduitFillCalculator.calculate(
        raceway: emt34,
        conductorGroups: [
          ConductorGroup(id: '1', spec: wire8, count: 2, role: 'phaseA'),
        ],
      );

      expect(result.totalConductorArea, closeTo(0.0732, 0.0001));
      expect(result.allowedFillPercentage, equals(31.0));
      expect(result.fillPercentage, closeTo(13.73, 0.01));
      expect(result.isCompliant, isTrue);
      expect(result.jamRiskLevel, equals(JamRiskLevel.safeDual));
    });

    test('CF-03: Standard Branch Group (3/4" EMT, 3x #10 THHN + 1x #12 THHN)', () {
      final emt34 = RacewayCatalog.getProfile(RacewayType.emt, '3/4');
      final wire10 = ConductorCatalog.getSpec(
        gauge: '10 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );
      final wire12 = ConductorCatalog.getSpec(
        gauge: '12 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final result = ConduitFillCalculator.calculate(
        raceway: emt34,
        conductorGroups: [
          ConductorGroup(id: '1', spec: wire10, count: 3, role: 'phase'),
          ConductorGroup(id: '2', spec: wire12, count: 1, role: 'ground'),
        ],
      );

      expect(result.totalConductorArea, closeTo(0.0766, 0.0001));
      expect(result.allowedFillPercentage, equals(40.0));
      expect(result.fillPercentage, closeTo(14.37, 0.01));
      expect(result.isCompliant, isTrue);
      expect(result.jamRatio, isNotNull);
      expect(result.jamRatio!, closeTo(5.02, 0.01));
      expect(result.jamRiskLevel, equals(JamRiskLevel.safeClearance));
    });

    test('CF-04: Max #12 THHN in 1/2" EMT (9x #12 THHN)', () {
      final emt12 = RacewayCatalog.getProfile(RacewayType.emt, '1/2');
      final wire12 = ConductorCatalog.getSpec(
        gauge: '12 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final result = ConduitFillCalculator.calculate(
        raceway: emt12,
        conductorGroups: [
          ConductorGroup(id: '1', spec: wire12, count: 9, role: 'phase'),
        ],
      );

      expect(result.totalConductorArea, closeTo(0.1197, 0.0001));
      expect(result.allowedFillPercentage, equals(40.0));
      expect(result.fillPercentage, closeTo(39.38, 0.01));
      expect(result.isCompliant, isTrue);

      final maxCount = ConduitFillCalculator.calculateMaxConductors(
        conduitArea: emt12.internalAreaSqInches,
        wireArea: wire12.areaSqInches,
      );
      expect(maxCount, equals(9));
    });

    test('CF-05: Overfilled 1/2" EMT (10x #12 THHN) with Upsize Recommendation', () {
      final emt12 = RacewayCatalog.getProfile(RacewayType.emt, '1/2');
      final wire12 = ConductorCatalog.getSpec(
        gauge: '12 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final result = ConduitFillCalculator.calculate(
        raceway: emt12,
        conductorGroups: [
          ConductorGroup(id: '1', spec: wire12, count: 10, role: 'phase'),
        ],
      );

      expect(result.totalConductorArea, closeTo(0.1330, 0.0001));
      expect(result.allowedFillPercentage, equals(40.0));
      expect(result.fillPercentage, closeTo(43.75, 0.01));
      expect(result.isCompliant, isFalse);
      expect(result.recommendedUpsizeTradeSize, equals('3/4'));
    });

    test('CF-06: 24" Conduit Nipple (1/2" EMT, 13x #12 THHN, 60% fill limit)', () {
      final emt12 = RacewayCatalog.getProfile(RacewayType.emt, '1/2');
      final wire12 = ConductorCatalog.getSpec(
        gauge: '12 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final result = ConduitFillCalculator.calculate(
        raceway: emt12,
        isNipple: true,
        conductorGroups: [
          ConductorGroup(id: '1', spec: wire12, count: 13, role: 'phase'),
        ],
      );

      expect(result.totalConductorArea, closeTo(0.1729, 0.0001));
      expect(result.allowedFillPercentage, equals(60.0));
      expect(result.fillPercentage, closeTo(56.88, 0.01));
      expect(result.isCompliant, isTrue);

      final maxNipple = ConduitFillCalculator.calculateMaxConductors(
        conduitArea: emt12.internalAreaSqInches,
        wireArea: wire12.areaSqInches,
        isNipple: true,
      );
      expect(maxNipple, equals(13));
    });

    test('CF-07: Critical Jam Ratio Pull (2" EMT, 3x 250 kcmil THHN)', () {
      final emt2 = RacewayCatalog.getProfile(RacewayType.emt, '2');
      final wire250 = ConductorCatalog.getSpec(
        gauge: '250 kcmil',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final result = ConduitFillCalculator.calculate(
        raceway: emt2,
        conductorGroups: [
          ConductorGroup(id: '1', spec: wire250, count: 3, role: 'phase'),
        ],
      );

      expect(result.totalConductorArea, closeTo(1.1910, 0.0001));
      expect(result.allowedFillPercentage, equals(40.0));
      expect(result.fillPercentage, closeTo(35.49, 0.01));
      expect(result.isCompliant, isTrue);
      expect(result.jamRatio, isNotNull);
      expect(result.jamRatio!, closeTo(2.907, 0.001));
      expect(result.jamRiskLevel, equals(JamRiskLevel.highJamRisk));
      expect(result.hasJamRisk, isTrue);
    });

    test('CF-08: Heavy Mixed Industrial (3" RMC, 3x 350 kcmil XHHW + 1x 1/0 XHHW)', () {
      final rmc3 = RacewayCatalog.getProfile(RacewayType.rmc, '3');
      final wire350 = ConductorCatalog.getSpec(
        gauge: '350 kcmil',
        insulation: ConductorInsulation.xhhw,
        material: ConductorMaterial.copper,
      );
      final wire10 = ConductorCatalog.getSpec(
        gauge: '1/0 AWG',
        insulation: ConductorInsulation.xhhw,
        material: ConductorMaterial.copper,
      );

      final result = ConduitFillCalculator.calculate(
        raceway: rmc3,
        conductorGroups: [
          ConductorGroup(id: '1', spec: wire350, count: 3, role: 'phase'),
          ConductorGroup(id: '2', spec: wire10, count: 1, role: 'neutral'),
        ],
      );

      expect(result.totalConductorArea, closeTo(1.7398, 0.0001));
      expect(result.allowedFillPercentage, equals(40.0));
      expect(result.fillPercentage, closeTo(23.20, 0.01));
      expect(result.isCompliant, isTrue);
      expect(result.jamRatio!, closeTo(3.80, 0.01));
      expect(result.jamRiskLevel, equals(JamRiskLevel.safeClearance));
    });
  });

  group('Voltage Drop Normative Benchmarks (VD-01 through VD-08)', () {
    test('VD-01: 120V 1-Phase 16A 75ft #12 AWG Cu in Steel EMT (PF 0.95)', () {
      final wire12 = ConductorCatalog.getSpec(
        gauge: '12 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final result = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 120.0,
        phase: CircuitPhase.singlePhase,
        currentAmps: 16.0,
        lengthFeet: 75.0,
        conductorSpec: wire12,
        isSteelConduit: true,
        powerFactor: 0.95,
      );

      expect(result.effectiveImpedance, closeTo(1.8979, 0.001));
      expect(result.voltageDropVolts, closeTo(4.555, 0.005));
      expect(result.percentageDrop, closeTo(3.80, 0.01));
      expect(result.complianceStatus, equals(VoltageDropComplianceStatus.caution));
      expect(result.isCompliantBranch, isFalse);
      expect(result.isCompliantTotal, isTrue);
    });

    test('VD-02: 120V 1-Phase 12A 50ft #12 AWG Cu in Steel EMT (PF 1.00)', () {
      final wire12 = ConductorCatalog.getSpec(
        gauge: '12 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final result = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 120.0,
        phase: CircuitPhase.singlePhase,
        currentAmps: 12.0,
        lengthFeet: 50.0,
        conductorSpec: wire12,
        isSteelConduit: true,
        powerFactor: 1.00,
      );

      expect(result.effectiveImpedance, closeTo(1.9800, 0.0001));
      expect(result.voltageDropVolts, closeTo(2.376, 0.005));
      expect(result.percentageDrop, closeTo(1.98, 0.01));
      expect(result.complianceStatus, equals(VoltageDropComplianceStatus.pass));
      expect(result.isCompliantBranch, isTrue);
      expect(result.isCompliantTotal, isTrue);
    });

    test('VD-03: 208V 3-Phase 100A 150ft #1 AWG Cu in PVC Conduit (PF 0.90)', () {
      final wire1 = ConductorCatalog.getSpec(
        gauge: '1 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final result = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 208.0,
        phase: CircuitPhase.threePhase,
        currentAmps: 100.0,
        lengthFeet: 150.0,
        conductorSpec: wire1,
        isSteelConduit: false,
        powerFactor: 0.90,
      );

      expect(result.effectiveImpedance, closeTo(0.1578, 0.001));
      expect(result.voltageDropVolts, closeTo(4.099, 0.01));
      expect(result.percentageDrop, closeTo(1.97, 0.01));
      expect(result.complianceStatus, equals(VoltageDropComplianceStatus.pass));
      expect(result.isCompliantBranch, isTrue);
    });

    test('VD-04: 240V 1-Phase 40A 120ft #8 AWG Cu in Steel EMT (PF 0.90)', () {
      final wire8 = ConductorCatalog.getSpec(
        gauge: '8 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final result = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 240.0,
        phase: CircuitPhase.singlePhase,
        currentAmps: 40.0,
        lengthFeet: 120.0,
        conductorSpec: wire8,
        isSteelConduit: true,
        powerFactor: 0.90,
      );

      expect(result.effectiveImpedance, closeTo(0.7247, 0.001));
      expect(result.voltageDropVolts, closeTo(6.957, 0.01));
      expect(result.percentageDrop, closeTo(2.90, 0.01));
      expect(result.complianceStatus, equals(VoltageDropComplianceStatus.pass));
    });

    test('VD-05: 480V 3-Phase 250A 400ft 350 kcmil Al in Steel (PF 0.85)', () {
      final wire350Al = ConductorCatalog.getSpec(
        gauge: '350 kcmil',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.aluminum,
      );

      final result = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 480.0,
        phase: CircuitPhase.threePhase,
        currentAmps: 250.0,
        lengthFeet: 400.0,
        conductorSpec: wire350Al,
        isSteelConduit: true,
        powerFactor: 0.85,
      );

      expect(result.effectiveImpedance, closeTo(0.0771, 0.001));
      expect(result.voltageDropVolts, closeTo(13.360, 0.02));
      expect(result.percentageDrop, closeTo(2.78, 0.02));
      expect(result.complianceStatus, equals(VoltageDropComplianceStatus.pass));
    });

    test('VD-06: 480V 3-Phase 250A 800ft 350 kcmil Al in Steel (PF 0.85) - Fail', () {
      final wire350Al = ConductorCatalog.getSpec(
        gauge: '350 kcmil',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.aluminum,
      );

      final result = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 480.0,
        phase: CircuitPhase.threePhase,
        currentAmps: 250.0,
        lengthFeet: 800.0,
        conductorSpec: wire350Al,
        isSteelConduit: true,
        powerFactor: 0.85,
      );

      expect(result.effectiveImpedance, closeTo(0.0771, 0.001));
      expect(result.voltageDropVolts, closeTo(26.720, 0.03));
      expect(result.percentageDrop, closeTo(5.57, 0.02));
      expect(result.complianceStatus, equals(VoltageDropComplianceStatus.fail));
      expect(result.isCompliantBranch, isFalse);
      expect(result.isCompliantTotal, isFalse);
    });

    test('VD-07 (Metric): 230V 1-Phase 16A 25m 2.5 mm² Cu (Resistive)', () {
      final result = VoltageDropCalculator.calculateMetric(
        nominalVoltage: 230.0,
        phase: CircuitPhase.singlePhase,
        currentAmps: 16.0,
        lengthMeters: 25.0,
        areaMm2: 2.5,
        isCopper: true,
      );

      expect(result.voltageDropVolts, closeTo(7.200, 0.005));
      expect(result.percentageDrop, closeTo(3.13, 0.01));
      expect(result.complianceStatus, equals(VoltageDropComplianceStatus.caution));
    });

    test('VD-08 (Metric): 400V 3-Phase 32A 50m 10.0 mm² Cu (Resistive)', () {
      final result = VoltageDropCalculator.calculateMetric(
        nominalVoltage: 400.0,
        phase: CircuitPhase.threePhase,
        currentAmps: 32.0,
        lengthMeters: 50.0,
        areaMm2: 10.0,
        isCopper: true,
      );

      expect(result.voltageDropVolts, closeTo(6.235, 0.01));
      expect(result.percentageDrop, closeTo(1.56, 0.01));
      expect(result.complianceStatus, equals(VoltageDropComplianceStatus.pass));
    });
  });

  group('Ampacity Derating Normative Benchmarks (DR-01 through DR-07)', () {
    test('DR-01: #10 AWG THHN Cu (40°C ambient, 6 CCC)', () {
      final wire10 = ConductorCatalog.getSpec(
        gauge: '10 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final result = DeratingCalculator.calculate(
        conductorSpec: wire10,
        ambientTempC: 40.0,
        currentCarryingConductorsCount: 6,
        terminalRatingC: 75.0,
      );

      expect(result.baseAmpacity, equals(40.0));
      expect(result.temperatureCorrectionFactor, equals(0.91));
      expect(result.bundlingAdjustmentFactor, equals(0.80));
      expect(result.deratedAmpacity, closeTo(29.12, 0.01));
      expect(result.terminalRatingLimit, equals(35.0));
      expect(result.allowableAmpacity, closeTo(29.12, 0.01));
      expect(result.smallWireOcpdLimit, equals(30));
    });

    test('DR-02: #2 AWG THHN Cu (45°C ambient, 9 CCC)', () {
      final wire2 = ConductorCatalog.getSpec(
        gauge: '2 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final result = DeratingCalculator.calculate(
        conductorSpec: wire2,
        ambientTempC: 45.0,
        currentCarryingConductorsCount: 9,
        terminalRatingC: 75.0,
      );

      expect(result.baseAmpacity, equals(130.0));
      expect(result.temperatureCorrectionFactor, equals(0.87));
      expect(result.bundlingAdjustmentFactor, equals(0.70));
      expect(result.deratedAmpacity, closeTo(79.17, 0.01));
      expect(result.terminalRatingLimit, equals(115.0));
      expect(result.allowableAmpacity, closeTo(79.17, 0.01));
      expect(result.smallWireOcpdLimit, isNull);
    });

    test('DR-03: 4/0 AWG THHN Cu (30°C ambient, 3 CCC, 75°C terminal clamp)', () {
      final wire40 = ConductorCatalog.getSpec(
        gauge: '4/0 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final result = DeratingCalculator.calculate(
        conductorSpec: wire40,
        ambientTempC: 30.0,
        currentCarryingConductorsCount: 3,
        terminalRatingC: 75.0,
      );

      expect(result.baseAmpacity, equals(260.0));
      expect(result.temperatureCorrectionFactor, equals(1.00));
      expect(result.bundlingAdjustmentFactor, equals(1.00));
      expect(result.deratedAmpacity, equals(260.0));
      expect(result.terminalRatingLimit, equals(230.0));
      expect(result.allowableAmpacity, equals(230.0)); // Clamped to 75°C terminal rating
    });

    test('DR-04: #12 AWG XHHW-2 Cu (50°C ambient, 4 CCC)', () {
      final wire12 = ConductorCatalog.getSpec(
        gauge: '12 AWG',
        insulation: ConductorInsulation.xhhw,
        material: ConductorMaterial.copper,
      );

      final result = DeratingCalculator.calculate(
        conductorSpec: wire12,
        ambientTempC: 50.0,
        currentCarryingConductorsCount: 4,
        terminalRatingC: 75.0,
      );

      expect(result.baseAmpacity, equals(30.0));
      expect(result.temperatureCorrectionFactor, equals(0.82));
      expect(result.bundlingAdjustmentFactor, equals(0.80));
      expect(result.deratedAmpacity, closeTo(19.68, 0.01));
      expect(result.terminalRatingLimit, equals(25.0));
      expect(result.allowableAmpacity, closeTo(19.68, 0.01));
      expect(result.smallWireOcpdLimit, equals(20));
    });

    test('DR-05: 250 kcmil THHN Al (38°C ambient, 6 CCC)', () {
      final wire250Al = ConductorCatalog.getSpec(
        gauge: '250 kcmil',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.aluminum,
      );

      final result = DeratingCalculator.calculate(
        conductorSpec: wire250Al,
        ambientTempC: 38.0,
        currentCarryingConductorsCount: 6,
        terminalRatingC: 75.0,
      );

      expect(result.baseAmpacity, equals(230.0));
      expect(result.temperatureCorrectionFactor, equals(0.91));
      expect(result.bundlingAdjustmentFactor, equals(0.80));
      expect(result.deratedAmpacity, closeTo(167.44, 0.01));
      expect(result.terminalRatingLimit, equals(205.0));
      expect(result.allowableAmpacity, closeTo(167.44, 0.01));
    });

    test('DR-06: #10 AWG 60°C Conductor (42°C ambient, 3 CCC)', () {
      final spec60C = ConductorSpec(
        gauge: '10 AWG',
        insulation: ConductorInsulation.thwn, // rated up to 75C, but testing 60C base
        material: ConductorMaterial.copper,
        outerDiameterInches: 0.164,
        outerDiameterMm: 4.17,
        areaSqInches: 0.0211,
        areaSqMm: 13.61,
        ampacity60C: 30.0,
        ampacity75C: 35.0,
        ampacity90C: 40.0,
        maxOcpdAmps: 30,
      );

      // We test DeratingCalculator helper methods directly for 60C column
      final cfTemp = DeratingCalculator.getTemperatureCorrectionFactor(
        ambientTempC: 42.0,
        conductorRatingC: 60.0,
      );
      final afBundle = DeratingCalculator.getBundlingAdjustmentFactor(
        currentCarryingConductorsCount: 3,
      );

      expect(cfTemp, equals(0.71));
      expect(afBundle, equals(1.00));
      final derated = spec60C.ampacity60C * cfTemp * afBundle;
      expect(derated, closeTo(21.30, 0.01));
    });

    test('DR-07: #14 AWG THHN Cu in Nipple <= 24" (30°C ambient, 8 CCC - Exempt)', () {
      final wire14 = ConductorCatalog.getSpec(
        gauge: '14 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final result = DeratingCalculator.calculate(
        conductorSpec: wire14,
        ambientTempC: 30.0,
        currentCarryingConductorsCount: 8,
        terminalRatingC: 75.0,
        isNipple: true,
      );

      expect(result.baseAmpacity, equals(25.0));
      expect(result.temperatureCorrectionFactor, equals(1.00));
      expect(result.bundlingAdjustmentFactor, equals(1.00)); // Exempt from bundling derating!
      expect(result.deratedAmpacity, equals(25.0));
      expect(result.terminalRatingLimit, equals(20.0));
      expect(result.allowableAmpacity, equals(20.0)); // Clamped to 75°C limit
      expect(result.smallWireOcpdLimit, equals(15));
    });
  });

  group('Mathematical Edge Cases & NEC Note 7 Rounding', () {
    test('NEC Note 7: Round up when decimal fraction is >= 0.80', () {
      // 9.80 raw capacity should round up to 10
      final countRoundUp = ConduitFillCalculator.calculateMaxConductors(
        conduitArea: 10.0,
        wireArea: 0.408163265, // 10 * 0.40 / 0.408163265 = 9.800
      );
      expect(countRoundUp, equals(10));

      // 9.79 raw capacity should truncate to 9
      final countTruncate = ConduitFillCalculator.calculateMaxConductors(
        conduitArea: 10.0,
        wireArea: 0.4085799, // 10 * 0.40 / 0.4085799 = 9.790
      );
      expect(countTruncate, equals(9));
    });

    test('Jam Ratio Threshold Boundary Classifications', () {
      // 3.21 -> safeClearance
      expect(JamRatioCalculator.calculate(conduitInsideDiameter: 3.21, wireOutsideDiameter: 1.0).riskLevel,
          equals(JamRiskLevel.safeClearance));

      // 3.20 -> highJamRisk
      expect(JamRatioCalculator.calculate(conduitInsideDiameter: 3.20, wireOutsideDiameter: 1.0).riskLevel,
          equals(JamRiskLevel.highJamRisk));

      // 2.80 -> highJamRisk
      expect(JamRatioCalculator.calculate(conduitInsideDiameter: 2.80, wireOutsideDiameter: 1.0).riskLevel,
          equals(JamRiskLevel.highJamRisk));

      // 2.79 -> moderateRisk
      expect(JamRatioCalculator.calculate(conduitInsideDiameter: 2.79, wireOutsideDiameter: 1.0).riskLevel,
          equals(JamRiskLevel.moderateRisk));

      // 2.50 -> moderateRisk
      expect(JamRatioCalculator.calculate(conduitInsideDiameter: 2.50, wireOutsideDiameter: 1.0).riskLevel,
          equals(JamRiskLevel.moderateRisk));

      // 2.49 -> safeConstrained
      expect(JamRatioCalculator.calculate(conduitInsideDiameter: 2.49, wireOutsideDiameter: 1.0).riskLevel,
          equals(JamRiskLevel.safeConstrained));
    });

    test('Ambient Temperature exceeding insulation thermal rating produces 0.00 factor', () {
      expect(DeratingCalculator.getTemperatureCorrectionFactor(ambientTempC: 62.0, conductorRatingC: 60.0),
          equals(0.00));
      expect(DeratingCalculator.getTemperatureCorrectionFactor(ambientTempC: 72.0, conductorRatingC: 75.0),
          equals(0.00));
      expect(DeratingCalculator.getTemperatureCorrectionFactor(ambientTempC: 86.0, conductorRatingC: 90.0),
          equals(0.00));
    });

    test('Raceway Catalog contains exactly 60 normative profiles', () {
      expect(RacewayCatalog.profiles.length, equals(60));
      for (final type in RacewayType.values) {
        final profilesForType = RacewayCatalog.getProfilesForType(type);
        expect(profilesForType.length, equals(10),
            reason: 'Each raceway type must have 10 standard trade sizes');
      }
    });
  });
}
