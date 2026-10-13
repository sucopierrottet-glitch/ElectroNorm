// test/challenger_m1_2_test.dart
// Adversarial Empirical Challenger Verification Suite for Milestone 1
// Covers:
// 1. AC Voltage drop formulas for 1-phase (120V, 240V) and 3-phase (208V, 480V) vs independent textbook oracles
// 2. Copper vs Aluminum material resistance and power factor scaling
// 3. Temperature correction factors (10°C to 80°C) and bundling multipliers (4 to 40+)
// 4. Terminal rating clamping invariant verification (NEC 110.14(C))
// 5. Adversarial edge cases and stress tests

import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:electronorm/models/conductor.dart';
import 'package:electronorm/models/calculation_results.dart';
import 'package:electronorm/catalogs/conductor_catalog.dart';
import 'package:electronorm/calculators/voltage_drop_calculator.dart';
import 'package:electronorm/calculators/derating_calculator.dart';

void main() {
  const double sqrt3 = 1.7320508075688772;

  // Independent Textbook Calculation Oracle
  double oracleEffectiveImpedance(double r, double xl, double pf) {
    final clampedPf = pf.clamp(0.0, 1.0);
    final sinTheta = math.sqrt(math.max(0.0, 1.0 - clampedPf * clampedPf));
    return (r * clampedPf) + (xl * sinTheta);
  }

  double oracleVoltageDrop({
    required bool isThreePhase,
    required double currentAmps,
    required double lengthFeet,
    required double zEff,
  }) {
    final mult = isThreePhase ? sqrt3 : 2.0;
    return mult * currentAmps * (lengthFeet / 1000.0) * zEff;
  }

  group('Challenger: AC Voltage Drop 1-Phase & 3-Phase vs Independent Textbook Oracles', () {
    test('120V Single-Phase: 15A, 50ft, #14 Cu in Steel EMT (PF 0.95)', () {
      final spec = ConductorCatalog.getSpec(gauge: '14 AWG', material: ConductorMaterial.copper);
      final res = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 120.0,
        phase: CircuitPhase.singlePhase,
        currentAmps: 15.0,
        lengthFeet: 50.0,
        conductorSpec: spec,
        isSteelConduit: true,
        powerFactor: 0.95,
      );

      final expectedZEff = oracleEffectiveImpedance(3.10, 0.058, 0.95);
      final expectedDrop = oracleVoltageDrop(
        isThreePhase: false,
        currentAmps: 15.0,
        lengthFeet: 50.0,
        zEff: expectedZEff,
      );

      expect(res.effectiveImpedance, closeTo(expectedZEff, 0.0001));
      expect(res.voltageDropVolts, closeTo(expectedDrop, 0.001));
      expect(res.percentageDrop, closeTo((expectedDrop / 120.0) * 100.0, 0.01));
      expect(res.endVoltage, closeTo(120.0 - expectedDrop, 0.001));
      expect(res.complianceStatus, equals(VoltageDropComplianceStatus.caution));
      expect(res.isCompliantBranch, isFalse);
      expect(res.isCompliantTotal, isTrue);
    });

    test('120V Single-Phase: 20A, 100ft, #10 Cu in PVC (PF 0.85)', () {
      final spec = ConductorCatalog.getSpec(gauge: '10 AWG', material: ConductorMaterial.copper);
      final res = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 120.0,
        phase: CircuitPhase.singlePhase,
        currentAmps: 20.0,
        lengthFeet: 100.0,
        conductorSpec: spec,
        isSteelConduit: false,
        powerFactor: 0.85,
      );

      final expectedZEff = oracleEffectiveImpedance(1.24, 0.050, 0.85);
      final expectedDrop = oracleVoltageDrop(
        isThreePhase: false,
        currentAmps: 20.0,
        lengthFeet: 100.0,
        zEff: expectedZEff,
      );

      expect(res.effectiveImpedance, closeTo(expectedZEff, 0.0001));
      expect(res.voltageDropVolts, closeTo(expectedDrop, 0.001));
      expect(res.percentageDrop, closeTo(3.60, 0.01));
      expect(res.complianceStatus, equals(VoltageDropComplianceStatus.caution));
    });

    test('240V Single-Phase: 50A, 200ft, #6 Cu in Steel EMT (PF 0.85)', () {
      final spec = ConductorCatalog.getSpec(gauge: '6 AWG', material: ConductorMaterial.copper);
      final res = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 240.0,
        phase: CircuitPhase.singlePhase,
        currentAmps: 50.0,
        lengthFeet: 200.0,
        conductorSpec: spec,
        isSteelConduit: true,
        powerFactor: 0.85,
      );

      final expectedZEff = oracleEffectiveImpedance(0.49, 0.051, 0.85);
      final expectedDrop = oracleVoltageDrop(
        isThreePhase: false,
        currentAmps: 50.0,
        lengthFeet: 200.0,
        zEff: expectedZEff,
      );

      expect(res.effectiveImpedance, closeTo(expectedZEff, 0.0001));
      expect(res.voltageDropVolts, closeTo(expectedDrop, 0.001));
      expect(res.percentageDrop, closeTo((expectedDrop / 240.0) * 100.0, 0.01));
      expect(res.complianceStatus, equals(VoltageDropComplianceStatus.caution));
      expect(res.isCompliantBranch, isFalse);
      expect(res.isCompliantTotal, isTrue);
    });

    test('208V Three-Phase: 150A, 250ft, 2/0 AWG Cu in Steel EMT (PF 0.80)', () {
      final spec = ConductorCatalog.getSpec(gauge: '2/0 AWG', material: ConductorMaterial.copper);
      final res = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 208.0,
        phase: CircuitPhase.threePhase,
        currentAmps: 150.0,
        lengthFeet: 250.0,
        conductorSpec: spec,
        isSteelConduit: true,
        powerFactor: 0.80,
      );

      final expectedZEff = oracleEffectiveImpedance(0.101, 0.042, 0.80);
      final expectedDrop = oracleVoltageDrop(
        isThreePhase: true,
        currentAmps: 150.0,
        lengthFeet: 250.0,
        zEff: expectedZEff,
      );

      expect(res.effectiveImpedance, closeTo(expectedZEff, 0.0001));
      expect(res.voltageDropVolts, closeTo(expectedDrop, 0.001));
      expect(res.percentageDrop, closeTo(3.31, 0.01));
      expect(res.complianceStatus, equals(VoltageDropComplianceStatus.caution));
    });

    test('480V Three-Phase: 350A, 600ft, 500 kcmil Cu in PVC (PF 0.85)', () {
      final spec = ConductorCatalog.getSpec(gauge: '500 kcmil', material: ConductorMaterial.copper);
      final res = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 480.0,
        phase: CircuitPhase.threePhase,
        currentAmps: 350.0,
        lengthFeet: 600.0,
        conductorSpec: spec,
        isSteelConduit: false,
        powerFactor: 0.85,
      );

      final expectedZEff = oracleEffectiveImpedance(0.027, 0.039, 0.85);
      final expectedDrop = oracleVoltageDrop(
        isThreePhase: true,
        currentAmps: 350.0,
        lengthFeet: 600.0,
        zEff: expectedZEff,
      );

      expect(res.effectiveImpedance, closeTo(expectedZEff, 0.0001));
      expect(res.voltageDropVolts, closeTo(expectedDrop, 0.001));
      expect(res.percentageDrop, closeTo((expectedDrop / 480.0) * 100.0, 0.01));
      expect(res.complianceStatus, equals(VoltageDropComplianceStatus.caution));
      expect(res.isCompliantBranch, isFalse);
      expect(res.isCompliantTotal, isTrue);
    });

    test('Three-Phase vs Single-Phase Analytical Multiplier Ratio is strictly sqrt(3)/2', () {
      final spec = ConductorCatalog.getSpec(gauge: '1/0 AWG', material: ConductorMaterial.copper);

      final drop1Ph = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 240.0,
        phase: CircuitPhase.singlePhase,
        currentAmps: 100.0,
        lengthFeet: 200.0,
        conductorSpec: spec,
        isSteelConduit: true,
        powerFactor: 0.90,
      );

      final drop3Ph = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 240.0,
        phase: CircuitPhase.threePhase,
        currentAmps: 100.0,
        lengthFeet: 200.0,
        conductorSpec: spec,
        isSteelConduit: true,
        powerFactor: 0.90,
      );

      final ratio = drop3Ph.voltageDropVolts / drop1Ph.voltageDropVolts;
      expect(ratio, closeTo(sqrt3 / 2.0, 0.000001));
    });
  });

  group('Challenger: Copper vs Aluminum Material & Power Factor Scaling', () {
    test('DC Resistance ratio Al/Cu across all AWG sizes is consistently 1.63 - 1.66', () {
      const sizes = [
        '12 AWG', '10 AWG', '8 AWG', '6 AWG', '4 AWG', '3 AWG',
        '2 AWG', '1 AWG', '1/0 AWG', '2/0 AWG', '3/0 AWG', '4/0 AWG',
        '250 kcmil', '300 kcmil', '350 kcmil', '400 kcmil', '500 kcmil',
      ];

      for (final s in sizes) {
        final cu = ConductorCatalog.getSpec(gauge: s, material: ConductorMaterial.copper);
        final al = ConductorCatalog.getSpec(gauge: s, material: ConductorMaterial.aluminum);

        final ratio = al.dcResistanceAl75C / cu.dcResistanceCu75C;
        expect(ratio, inInclusiveRange(1.63, 1.66),
            reason: 'Gauge $s must adhere to physical Al/Cu resistivity ratio');
      }
    });

    test('Power Factor Scaling: Unity PF (PF=1.0) eliminates XL and equals AC resistance ratio', () {
      final cu = ConductorCatalog.getSpec(gauge: '4/0 AWG', material: ConductorMaterial.copper);
      final al = ConductorCatalog.getSpec(gauge: '4/0 AWG', material: ConductorMaterial.aluminum);

      final cuDrop = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 480.0,
        phase: CircuitPhase.threePhase,
        currentAmps: 100.0,
        lengthFeet: 500.0,
        conductorSpec: cu,
        isSteelConduit: true,
        powerFactor: 1.0,
      );

      final alDrop = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 480.0,
        phase: CircuitPhase.threePhase,
        currentAmps: 100.0,
        lengthFeet: 500.0,
        conductorSpec: al,
        isSteelConduit: true,
        powerFactor: 1.0,
      );

      expect(cuDrop.effectiveImpedance, equals(0.067));
      expect(alDrop.effectiveImpedance, equals(0.110));
      expect(alDrop.effectiveImpedance / cuDrop.effectiveImpedance, closeTo(0.110 / 0.067, 0.0001));
    });

    test('Power Factor Scaling: Zero PF (PF=0.0) inductive convergence (Z_eff = X_L)', () {
      final cu = ConductorCatalog.getSpec(gauge: '250 kcmil', material: ConductorMaterial.copper);
      final al = ConductorCatalog.getSpec(gauge: '250 kcmil', material: ConductorMaterial.aluminum);

      final cuDrop = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 480.0,
        phase: CircuitPhase.threePhase,
        currentAmps: 100.0,
        lengthFeet: 500.0,
        conductorSpec: cu,
        isSteelConduit: true,
        powerFactor: 0.0,
      );

      final alDrop = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 480.0,
        phase: CircuitPhase.threePhase,
        currentAmps: 100.0,
        lengthFeet: 500.0,
        conductorSpec: al,
        isSteelConduit: true,
        powerFactor: 0.0,
      );

      // Both must converge exactly to X_L = 0.041
      expect(cuDrop.effectiveImpedance, closeTo(0.041, 0.0001));
      expect(alDrop.effectiveImpedance, closeTo(0.041, 0.0001));
      expect(cuDrop.voltageDropVolts, closeTo(alDrop.voltageDropVolts, 0.0001));
    });
  });

  group('Challenger: Temperature Correction Factors (10°C to 80°C)', () {
    test('Boundary sweeps across 60°C, 75°C, and 90°C conductor columns', () {
      final testPoints = [
        // (temp, exp60, exp75, exp90)
        [10.0, 1.29, 1.20, 1.15],
        [15.0, 1.22, 1.15, 1.12],
        [20.0, 1.15, 1.11, 1.08],
        [25.0, 1.08, 1.05, 1.04],
        [30.0, 1.00, 1.00, 1.00],
        [35.0, 0.91, 0.94, 0.96],
        [40.0, 0.82, 0.88, 0.91],
        [45.0, 0.71, 0.82, 0.87],
        [50.0, 0.58, 0.75, 0.82],
        [55.0, 0.41, 0.67, 0.76],
        [60.0, 0.00, 0.58, 0.71],
        [65.0, 0.00, 0.47, 0.65],
        [70.0, 0.00, 0.33, 0.58],
        [75.0, 0.00, 0.00, 0.50],
        [80.0, 0.00, 0.00, 0.41],
        [85.0, 0.00, 0.00, 0.29],
        [88.0, 0.00, 0.00, 0.00],
      ];

      for (final pt in testPoints) {
        final t = (pt[0] as num).toDouble();
        final exp60 = (pt[1] as num).toDouble();
        final exp75 = (pt[2] as num).toDouble();
        final exp90 = (pt[3] as num).toDouble();

        expect(DeratingCalculator.getTemperatureCorrectionFactor(ambientTempC: t, conductorRatingC: 60.0),
            equals(exp60), reason: 'Failed 60C column at $t°C');
        expect(DeratingCalculator.getTemperatureCorrectionFactor(ambientTempC: t, conductorRatingC: 75.0),
            equals(exp75), reason: 'Failed 75C column at $t°C');
        expect(DeratingCalculator.getTemperatureCorrectionFactor(ambientTempC: t, conductorRatingC: 90.0),
            equals(exp90), reason: 'Failed 90C column at $t°C');
      }
    });

    test('Sub-zero ambient temperature maintains valid conservative ceiling', () {
      expect(DeratingCalculator.getTemperatureCorrectionFactor(ambientTempC: -20.0, conductorRatingC: 60.0), equals(1.29));
      expect(DeratingCalculator.getTemperatureCorrectionFactor(ambientTempC: -20.0, conductorRatingC: 75.0), equals(1.20));
      expect(DeratingCalculator.getTemperatureCorrectionFactor(ambientTempC: -20.0, conductorRatingC: 90.0), equals(1.15));
    });
  });

  group('Challenger: Bundling Multipliers (4 to 40+ Conductors)', () {
    test('Exact Table 310.15(C)(1) step progression', () {
      final cases = [
        [1, 1.00],
        [3, 1.00],
        [4, 0.80],
        [6, 0.80],
        [7, 0.70],
        [9, 0.70],
        [10, 0.50],
        [20, 0.50],
        [21, 0.45],
        [30, 0.45],
        [31, 0.40],
        [40, 0.40],
        [41, 0.35],
        [100, 0.35],
      ];

      for (final c in cases) {
        final count = c[0] as int;
        final expected = c[1] as double;
        expect(DeratingCalculator.getBundlingAdjustmentFactor(currentCarryingConductorsCount: count),
            equals(expected), reason: 'Failed bundling for count $count');
      }
    });

    test('Nipple exemption strictly returns 1.00 regardless of conductor count', () {
      for (final n in [4, 7, 10, 25, 41, 100]) {
        expect(
          DeratingCalculator.getBundlingAdjustmentFactor(currentCarryingConductorsCount: n, isNipple: true),
          equals(1.00),
          reason: 'Nipple with $n conductors must be exempt',
        );
      }
    });
  });

  group('Challenger: Terminal Rating Clamping Invariant (NEC 110.14(C))', () {
    test('INVARIANT: allowableAmpacity == min(deratedAmpacity, terminalRatingLimit) for all AWG sizes', () {
      const sizes = [
        '14 AWG', '12 AWG', '10 AWG', '8 AWG', '6 AWG', '4 AWG', '3 AWG',
        '2 AWG', '1 AWG', '1/0 AWG', '2/0 AWG', '3/0 AWG', '4/0 AWG',
        '250 kcmil', '300 kcmil', '350 kcmil', '400 kcmil', '500 kcmil',
      ];

      for (final size in sizes) {
        final spec = ConductorCatalog.getSpec(gauge: size, insulation: ConductorInsulation.thhn);

        // Case 1: Un-derated at 30°C, 3 CCC
        final resUnderated = DeratingCalculator.calculate(
          conductorSpec: spec,
          ambientTempC: 30.0,
          currentCarryingConductorsCount: 3,
          terminalRatingC: 75.0,
        );
        expect(resUnderated.allowableAmpacity, equals(spec.ampacity75C),
            reason: '$size allowable must clamp to 75°C limit');
        expect(resUnderated.allowableAmpacity, lessThanOrEqualTo(resUnderated.deratedAmpacity));
        expect(resUnderated.allowableAmpacity, equals(resUnderated.terminalRatingLimit));

        // Case 2: Heavy derating at 50°C, 10 CCC
        final resHeavy = DeratingCalculator.calculate(
          conductorSpec: spec,
          ambientTempC: 50.0,
          currentCarryingConductorsCount: 10,
          terminalRatingC: 75.0,
        );
        final expectedDerated = spec.ampacity90C * 0.82 * 0.50;
        expect(resHeavy.deratedAmpacity, closeTo(expectedDerated, 0.01));
        // Derated is lower than 75C terminal rating, so allowable MUST be derated!
        expect(resHeavy.allowableAmpacity, closeTo(expectedDerated, 0.01));
        expect(resHeavy.allowableAmpacity, lessThanOrEqualTo(resHeavy.terminalRatingLimit));

        // Case 3: 60°C terminal rating
        final res60 = DeratingCalculator.calculate(
          conductorSpec: spec,
          ambientTempC: 30.0,
          currentCarryingConductorsCount: 3,
          terminalRatingC: 60.0,
        );
        expect(res60.allowableAmpacity, equals(spec.ampacity60C));
      }
    });

    test('Small wire OCPD limits are reported correctly per NEC 240.4(D)', () {
      final spec14Cu = ConductorCatalog.getSpec(gauge: '14 AWG', material: ConductorMaterial.copper);
      final spec12Cu = ConductorCatalog.getSpec(gauge: '12 AWG', material: ConductorMaterial.copper);
      final spec10Cu = ConductorCatalog.getSpec(gauge: '10 AWG', material: ConductorMaterial.copper);
      final spec12Al = ConductorCatalog.getSpec(gauge: '12 AWG', material: ConductorMaterial.aluminum);
      final spec10Al = ConductorCatalog.getSpec(gauge: '10 AWG', material: ConductorMaterial.aluminum);
      final spec8Cu = ConductorCatalog.getSpec(gauge: '8 AWG', material: ConductorMaterial.copper);

      expect(spec14Cu.maxOcpdAmps, equals(15));
      expect(spec12Cu.maxOcpdAmps, equals(20));
      expect(spec10Cu.maxOcpdAmps, equals(30));
      expect(spec12Al.maxOcpdAmps, equals(15));
      expect(spec10Al.maxOcpdAmps, equals(25));
      expect(spec8Cu.maxOcpdAmps, isNull);
    });
  });

  group('Challenger: Adversarial Edge Cases & Boundary Inputs', () {
    test('Zero Amps results in 0V drop, 100% voltage retention, and Pass status', () {
      final spec = ConductorCatalog.getSpec(gauge: '12 AWG');
      final res = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 120.0,
        phase: CircuitPhase.singlePhase,
        currentAmps: 0.0,
        lengthFeet: 100.0,
        conductorSpec: spec,
        isSteelConduit: true,
      );

      expect(res.voltageDropVolts, equals(0.0));
      expect(res.percentageDrop, equals(0.0));
      expect(res.endVoltage, equals(120.0));
      expect(res.complianceStatus, equals(VoltageDropComplianceStatus.pass));
      expect(res.isCompliantBranch, isTrue);
      expect(res.isCompliantTotal, isTrue);
    });

    test('Invalid negative inputs throw ArgumentError', () {
      final spec = ConductorCatalog.getSpec(gauge: '12 AWG');

      expect(
        () => VoltageDropCalculator.calculateEffectiveImpedance(
          nominalVoltage: -120.0,
          phase: CircuitPhase.singlePhase,
          currentAmps: 10.0,
          lengthFeet: 50.0,
          conductorSpec: spec,
          isSteelConduit: true,
        ),
        throwsArgumentError,
      );

      expect(
        () => VoltageDropCalculator.calculateEffectiveImpedance(
          nominalVoltage: 120.0,
          phase: CircuitPhase.singlePhase,
          currentAmps: -10.0,
          lengthFeet: 50.0,
          conductorSpec: spec,
          isSteelConduit: true,
        ),
        throwsArgumentError,
      );

      expect(
        () => VoltageDropCalculator.calculateEffectiveImpedance(
          nominalVoltage: 120.0,
          phase: CircuitPhase.singlePhase,
          currentAmps: 10.0,
          lengthFeet: -50.0,
          conductorSpec: spec,
          isSteelConduit: true,
        ),
        throwsArgumentError,
      );
    });

    test('Extreme ambient temperature exceeding insulation produces zero ampacity', () {
      final spec = ConductorCatalog.getSpec(gauge: '1/0 AWG', insulation: ConductorInsulation.thhn);
      final res = DeratingCalculator.calculate(
        conductorSpec: spec,
        ambientTempC: 90.0,
        currentCarryingConductorsCount: 3,
        terminalRatingC: 75.0,
      );

      expect(res.temperatureCorrectionFactor, equals(0.0));
      expect(res.deratedAmpacity, equals(0.0));
      expect(res.allowableAmpacity, equals(0.0));
    });
  });
}
