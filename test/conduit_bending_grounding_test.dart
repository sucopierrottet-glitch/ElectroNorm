import 'package:flutter_test/flutter_test.dart';
import 'package:electronorm/calculators/conduit_bending_calculator.dart';
import 'package:electronorm/calculators/grounding_calculator.dart';

void main() {
  group('Conduit Bending Calculator Tests', () {
    test('formatFraction returns accurate fractions for tape measure', () {
      expect(ConduitBendingCalculator.formatFraction(0.0), equals('0"'));
      expect(ConduitBendingCalculator.formatFraction(0.0625), equals('1/16"'));
      expect(ConduitBendingCalculator.formatFraction(0.25), equals('1/4"'));
      expect(ConduitBendingCalculator.formatFraction(0.5), equals('1/2"'));
      expect(ConduitBendingCalculator.formatFraction(0.75), equals('3/4"'));
      expect(ConduitBendingCalculator.formatFraction(10.25), equals('10 1/4"'));
      expect(ConduitBendingCalculator.formatFraction(6.125), equals('6 1/8"'));
    });

    test('calculateOffset calculates distance and shrink accurately for 30 deg', () {
      // For 4" obstacle at 30 degrees:
      // Multiplier = 2.0 -> Distance = 8.0"
      // Shrink = 0.25 * 4 = 1.0"
      final result = ConduitBendingCalculator.calculateOffset(
        offsetHeight: 4.0,
        angle: BendAngle.deg30,
      );

      expect(result.distanceBetweenMarks, closeTo(8.0, 0.01));
      expect(result.totalShrink, closeTo(1.0, 0.01));
      expect(result.distanceFraction, equals('8"'));
      expect(result.shrinkFraction, equals('1"'));
    });

    test('calculateOffset calculates distance and shrink for 45 deg', () {
      // For 5" obstacle at 45 degrees:
      // Multiplier = 1.414 -> Distance = 7.07"
      // Shrink = 0.375 * 5 = 1.875" (1 7/8")
      final result = ConduitBendingCalculator.calculateOffset(
        offsetHeight: 5.0,
        angle: BendAngle.deg45,
      );

      expect(result.distanceBetweenMarks, closeTo(7.07, 0.05));
      expect(result.totalShrink, closeTo(1.875, 0.01));
      expect(result.shrinkFraction, equals('1 7/8"'));
    });

    test('calculateStub90 calculates bender deduction for EMT', () {
      // 3/4" EMT has 6" take-up deduction
      final result = ConduitBendingCalculator.calculateStub90(
        desiredStubHeight: 14.0,
        conduitType: BendingConduitType.emt,
        tradeSize: '3/4',
      );

      expect(result.takeUpDeduction, equals(6.0));
      expect(result.distanceToArrow, equals(8.0));
      expect(result.distanceToArrowFraction, equals('8"'));
      expect(result.isValid, isTrue);
    });

    test('calculateStub90 calculates bender deduction for 1" EMT', () {
      // 1" EMT has 8" take-up deduction
      final result = ConduitBendingCalculator.calculateStub90(
        desiredStubHeight: 20.0,
        conduitType: BendingConduitType.emt,
        tradeSize: '1',
      );

      expect(result.takeUpDeduction, equals(8.0));
      expect(result.distanceToArrow, equals(12.0));
      expect(result.distanceToArrowFraction, equals('12"'));
      expect(result.isValid, isTrue);
    });

    test('calculate3BendSaddle returns correct distance and shrink', () {
      // 2" obstacle at 45 deg center:
      // Side bends = 22.5 deg. Distance center to side = 2 * 2.5 = 5.0"
      // Shrink = 2 * 3/16 = 0.375" (3/8")
      final result = ConduitBendingCalculator.calculate3BendSaddle(
        obstructionHeight: 2.0,
        centerAngle: 45.0,
      );

      expect(result.centerAngle, equals(45.0));
      expect(result.sideAngle, equals(22.5));
      expect(result.distanceCenterToSide, closeTo(5.0, 0.05));
      expect(result.totalShrink, closeTo(0.375, 0.01));
      expect(result.shrinkFraction, equals('3/8"'));
    });

    test('calculate4BendSaddle returns correct measurements', () {
      // 3" height, 6" width at 30 deg:
      // Offset dist = 3 * 2.0 = 6.0"
      // Shrink = 2 * (3 * 0.25) = 1.5"
      final result = ConduitBendingCalculator.calculate4BendSaddle(
        obstructionHeight: 3.0,
        obstructionWidth: 6.0,
        angle: BendAngle.deg30,
      );

      expect(result.distanceBetweenOffsetMarks, closeTo(6.0, 0.01));
      expect(result.totalShrink, closeTo(1.5, 0.01));
      expect(result.totalShrinkFraction, equals('1 1/2"'));
    });
  });

  group('Grounding Calculator Tests (NEC 250)', () {
    test('NEC Table 250.122 calculates standard EGC sizes', () {
      // 20A OCPD -> 12 Cu, 10 Al
      final egc20 = GroundingCalculator.calculateEGC(ocpdRating: 20);
      expect(egc20.cuSize, equals('12 AWG'));
      expect(egc20.alSize, equals('10 AWG'));
      expect(egc20.isAdjustedForVoltageDrop, isFalse);

      // 60A OCPD -> 10 Cu, 8 Al
      final egc60 = GroundingCalculator.calculateEGC(ocpdRating: 60);
      expect(egc60.cuSize, equals('10 AWG'));
      expect(egc60.alSize, equals('8 AWG'));

      // 100A OCPD -> 8 Cu, 6 Al
      final egc100 = GroundingCalculator.calculateEGC(ocpdRating: 100);
      expect(egc100.cuSize, equals('8 AWG'));
      expect(egc100.alSize, equals('6 AWG'));

      // 200A OCPD -> 6 Cu, 4 Al
      final egc200 = GroundingCalculator.calculateEGC(ocpdRating: 200);
      expect(egc200.cuSize, equals('6 AWG'));
      expect(egc200.alSize, equals('4 AWG'));

      // 400A OCPD -> 3 Cu, 1 Al
      final egc400 = GroundingCalculator.calculateEGC(ocpdRating: 400);
      expect(egc400.cuSize, equals('3 AWG'));
      expect(egc400.alSize, equals('1 AWG'));
    });

    test('NEC 250.122(B) proportional increase when phase conductors are upsized', () {
      // 100A OCPD standard phase is 3 AWG (52,620 cm).
      // Base EGC is 8 AWG (16,510 cm).
      // If upsized to 1/0 AWG (105,600 cm), ratio is 105,600 / 52,620 = 2.0068x.
      // Required EGC cm = 16,510 * 2.0068 = ~33,133 cm -> 4 AWG (41,740 cm).
      final result = GroundingCalculator.calculateEGC(
        ocpdRating: 100,
        standardPhase: '3 AWG',
        upsizedPhase: '1/0 AWG',
      );

      expect(result.isAdjustedForVoltageDrop, isTrue);
      expect(result.cuSize, equals('4 AWG'));
      expect(result.adjustmentNote, contains('NEC 250.122(B)'));
    });

    test('NEC Table 250.66 calculates GEC sizes without caps', () {
      // 2/0 AWG Cu Service -> 4 AWG Cu / 2 AWG Al
      final gec2_0 = GroundingCalculator.calculateGEC(
        serviceSize: '2/0 AWG',
        serviceMaterial: GroundingConductorMaterial.copper,
        electrodeType: ElectrodeType.waterPipeOrBuildingSteel,
      );
      expect(gec2_0.cuSize, equals('4 AWG'));
      expect(gec2_0.alSize, equals('2 AWG'));

      // 500 kcmil Cu Service -> 1/0 AWG Cu / 3/0 AWG Al
      final gec500 = GroundingCalculator.calculateGEC(
        serviceSize: '500 kcmil',
        serviceMaterial: GroundingConductorMaterial.copper,
        electrodeType: ElectrodeType.waterPipeOrBuildingSteel,
      );
      expect(gec500.cuSize, equals('1/0 AWG'));
      expect(gec500.alSize, equals('3/0 AWG'));
    });

    test('NEC 250.66(A) limits rod/pipe/plate electrode to 6 AWG Cu max', () {
      // Even with 500 kcmil service (which normally requires 1/0 Cu),
      // rod electrode caps at 6 AWG Cu
      final gec = GroundingCalculator.calculateGEC(
        serviceSize: '500 kcmil',
        serviceMaterial: GroundingConductorMaterial.copper,
        electrodeType: ElectrodeType.rodPipePlate,
      );

      expect(gec.cuSize, equals('6 AWG'));
      expect(gec.alSize, equals('4 AWG'));
      expect(gec.appliedException, contains('NEC 250.66(A)'));
    });

    test('NEC 250.66(B) limits concrete-encased (Ufer) to 4 AWG Cu max', () {
      // With 500 kcmil service, Ufer caps at 4 AWG Cu
      final gec = GroundingCalculator.calculateGEC(
        serviceSize: '500 kcmil',
        serviceMaterial: GroundingConductorMaterial.copper,
        electrodeType: ElectrodeType.concreteEncasedUfer,
      );

      expect(gec.cuSize, equals('4 AWG'));
      expect(gec.alSize, equals('2 AWG'));
      expect(gec.appliedException, contains('NEC 250.66(B)'));
    });
  });
}
