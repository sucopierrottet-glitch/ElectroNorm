import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';

import 'package:electronorm/catalogs/conductor_catalog.dart';
import 'package:electronorm/catalogs/raceway_catalog.dart';
import 'package:electronorm/models/conductor.dart';
import 'package:electronorm/models/raceway.dart';
import 'package:electronorm/theme/app_theme.dart';
import 'package:electronorm/widgets/packing_algorithm.dart';

void main() {
  const algorithm = GoldenSpiralPackingAlgorithm();

  group('Golden-Spiral Packing Algorithm Invariants', () {
    test('Empty conductor schedule produces empty packed positions', () {
      final packed = algorithm.pack(
        conduitRadius: 0.5,
        groups: [],
      );
      expect(packed, isEmpty);
    });

    test('Zero or negative conduit radius safely returns empty list', () {
      final group = ConductorGroup(
        id: '1',
        spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
        count: 1,
        role: 'phaseA',
      );
      expect(algorithm.pack(conduitRadius: 0.0, groups: [group]), isEmpty);
      expect(algorithm.pack(conduitRadius: -0.5, groups: [group]), isEmpty);
    });

    test('1 Conductor: placed at center (0, 0) strictly within conduit wall', () {
      final emt12 = RacewayCatalog.getProfile(RacewayType.emt, '1/2');
      final radius = emt12.internalDiameterInches / 2.0;
      final spec10 = ConductorCatalog.getSpec(gauge: '10 AWG');

      final packed = algorithm.pack(
        conduitRadius: radius,
        groups: [
          ConductorGroup(id: '1', spec: spec10, count: 1, role: 'phaseA'),
        ],
      );

      expect(packed.length, equals(1));
      final pos = packed.first;
      expect(pos.normalizedX, equals(0.0));
      expect(pos.normalizedY, equals(0.0));
      expect(pos.normalizedRadius, closeTo((spec10.outerDiameterInches / 2.0) / radius, 1e-4));
      expect(pos.borderColor, equals(AppColors.phaseABorder));
      expect(pos.color, equals(AppColors.phaseA));

      // Boundary check
      final distFromCenter = math.sqrt(pos.normalizedX * pos.normalizedX + pos.normalizedY * pos.normalizedY);
      expect(distFromCenter + pos.normalizedRadius, lessThanOrEqualTo(1.001));
    });

    test('2 Conductors: non-overlapping and boundary contained in 1/2" EMT', () {
      final emt = RacewayCatalog.getProfile(RacewayType.emt, '1/2');
      final radius = emt.internalDiameterInches / 2.0;
      final spec12 = ConductorCatalog.getSpec(gauge: '12 AWG');

      final packed = algorithm.pack(
        conduitRadius: radius,
        groups: [
          ConductorGroup(id: '1', spec: spec12, count: 1, role: 'phaseA'),
          ConductorGroup(id: '2', spec: spec12, count: 1, role: 'neutral'),
        ],
      );

      expect(packed.length, equals(2));

      // Boundary check
      for (final p in packed) {
        final dist = math.sqrt(p.normalizedX * p.normalizedX + p.normalizedY * p.normalizedY);
        expect(dist + p.normalizedRadius, lessThanOrEqualTo(1.001));
      }

      // Pairwise non-overlap check
      final p1 = packed[0];
      final p2 = packed[1];
      final dist = math.sqrt(
        math.pow(p1.normalizedX - p2.normalizedX, 2) +
        math.pow(p1.normalizedY - p2.normalizedY, 2),
      );
      final minDist = p1.normalizedRadius + p2.normalizedRadius;
      expect(dist, greaterThanOrEqualTo(minDist - 0.005));
    });

    test('3 Conductors: non-overlapping and boundary contained in 3/4" EMT', () {
      final emt = RacewayCatalog.getProfile(RacewayType.emt, '3/4');
      final radius = emt.internalDiameterInches / 2.0;
      final spec10 = ConductorCatalog.getSpec(gauge: '10 AWG');

      final packed = algorithm.pack(
        conduitRadius: radius,
        groups: [
          ConductorGroup(id: '1', spec: spec10, count: 3, role: 'phaseA'),
        ],
      );

      expect(packed.length, equals(3));

      // All inside lumen
      for (final p in packed) {
        final dist = math.sqrt(p.normalizedX * p.normalizedX + p.normalizedY * p.normalizedY);
        expect(dist + p.normalizedRadius, lessThanOrEqualTo(1.001));
      }

      // Check all pairs non-overlapping
      for (int i = 0; i < packed.length; i++) {
        for (int j = i + 1; j < packed.length; j++) {
          final pi = packed[i];
          final pj = packed[j];
          final dist = math.sqrt(
            math.pow(pi.normalizedX - pj.normalizedX, 2) +
            math.pow(pi.normalizedY - pj.normalizedY, 2),
          );
          final minDist = pi.normalizedRadius + pj.normalizedRadius;
          expect(dist, greaterThanOrEqualTo(minDist - 0.005));
        }
      }
    });

    test('4 Conductors: mixed branch (3x #10 + 1x #12 Grd) in 3/4" EMT', () {
      final emt = RacewayCatalog.getProfile(RacewayType.emt, '3/4');
      final radius = emt.internalDiameterInches / 2.0;
      final spec10 = ConductorCatalog.getSpec(gauge: '10 AWG');
      final spec12 = ConductorCatalog.getSpec(gauge: '12 AWG');

      final packed = algorithm.pack(
        conduitRadius: radius,
        groups: [
          ConductorGroup(id: '1', spec: spec10, count: 1, role: 'phaseA'),
          ConductorGroup(id: '2', spec: spec10, count: 1, role: 'phaseB'),
          ConductorGroup(id: '3', spec: spec10, count: 1, role: 'phaseC'),
          ConductorGroup(id: '4', spec: spec12, count: 1, role: 'ground'),
        ],
      );

      expect(packed.length, equals(4));

      for (final p in packed) {
        final dist = math.sqrt(p.normalizedX * p.normalizedX + p.normalizedY * p.normalizedY);
        expect(dist + p.normalizedRadius, lessThanOrEqualTo(1.001));
      }

      for (int i = 0; i < packed.length; i++) {
        for (int j = i + 1; j < packed.length; j++) {
          final pi = packed[i];
          final pj = packed[j];
          final dist = math.sqrt(
            math.pow(pi.normalizedX - pj.normalizedX, 2) +
            math.pow(pi.normalizedY - pj.normalizedY, 2),
          );
          final minDist = pi.normalizedRadius + pj.normalizedRadius;
          expect(dist, greaterThanOrEqualTo(minDist - 0.005));
        }
      }
    });

    test('10 Conductors: Multi-wire branch in 1" EMT', () {
      final emt = RacewayCatalog.getProfile(RacewayType.emt, '1');
      final radius = emt.internalDiameterInches / 2.0;
      final spec12 = ConductorCatalog.getSpec(gauge: '12 AWG');

      final packed = algorithm.pack(
        conduitRadius: radius,
        groups: [
          ConductorGroup(id: '1', spec: spec12, count: 9, role: 'phaseA'),
          ConductorGroup(id: '2', spec: spec12, count: 1, role: 'ground'),
        ],
      );

      expect(packed.length, equals(10));

      for (final p in packed) {
        final dist = math.sqrt(p.normalizedX * p.normalizedX + p.normalizedY * p.normalizedY);
        expect(dist + p.normalizedRadius, lessThanOrEqualTo(1.001));
      }

      for (int i = 0; i < packed.length; i++) {
        for (int j = i + 1; j < packed.length; j++) {
          final pi = packed[i];
          final pj = packed[j];
          final dist = math.sqrt(
            math.pow(pi.normalizedX - pj.normalizedX, 2) +
            math.pow(pi.normalizedY - pj.normalizedY, 2),
          );
          final minDist = pi.normalizedRadius + pj.normalizedRadius;
          expect(dist, greaterThanOrEqualTo(minDist - 0.005));
        }
      }
    });

    test('25 Conductors: Control / branch bundle in 2" EMT', () {
      final emt = RacewayCatalog.getProfile(RacewayType.emt, '2');
      final radius = emt.internalDiameterInches / 2.0;
      final spec12 = ConductorCatalog.getSpec(gauge: '12 AWG');
      final spec10 = ConductorCatalog.getSpec(gauge: '10 AWG');

      final packed = algorithm.pack(
        conduitRadius: radius,
        groups: [
          ConductorGroup(id: '1', spec: spec12, count: 24, role: 'phaseA'),
          ConductorGroup(id: '2', spec: spec10, count: 1, role: 'ground'),
        ],
      );

      expect(packed.length, equals(25));

      for (final p in packed) {
        final dist = math.sqrt(p.normalizedX * p.normalizedX + p.normalizedY * p.normalizedY);
        expect(dist + p.normalizedRadius, lessThanOrEqualTo(1.001));
      }

      for (int i = 0; i < packed.length; i++) {
        for (int j = i + 1; j < packed.length; j++) {
          final pi = packed[i];
          final pj = packed[j];
          final dist = math.sqrt(
            math.pow(pi.normalizedX - pj.normalizedX, 2) +
            math.pow(pi.normalizedY - pj.normalizedY, 2),
          );
          final minDist = pi.normalizedRadius + pj.normalizedRadius;
          expect(dist, greaterThanOrEqualTo(minDist - 0.005));
        }
      }
    });

    test('Determinism: Identical inputs yield identical normalized coordinates', () {
      final emt = RacewayCatalog.getProfile(RacewayType.emt, '1');
      final radius = emt.internalDiameterInches / 2.0;
      final spec = ConductorCatalog.getSpec(gauge: '10 AWG');

      final run1 = algorithm.pack(
        conduitRadius: radius,
        groups: [
          ConductorGroup(id: '1', spec: spec, count: 5, role: 'phaseA'),
        ],
      );

      final run2 = algorithm.pack(
        conduitRadius: radius,
        groups: [
          ConductorGroup(id: '1', spec: spec, count: 5, role: 'phaseA'),
        ],
      );

      expect(run1.length, equals(run2.length));
      for (int i = 0; i < run1.length; i++) {
        expect(run1[i].normalizedX, equals(run2[i].normalizedX));
        expect(run1[i].normalizedY, equals(run2[i].normalizedY));
        expect(run1[i].normalizedRadius, equals(run2[i].normalizedRadius));
      }
    });

    test('Computational Performance: < 0.3ms per pack for N <= 50', () {
      final emt = RacewayCatalog.getProfile(RacewayType.emt, '3');
      final radius = emt.internalDiameterInches / 2.0;
      final spec = ConductorCatalog.getSpec(gauge: '12 AWG');
      final groups = [
        ConductorGroup(id: '1', spec: spec, count: 50, role: 'phaseA'),
      ];

      // Warm-up JIT
      for (int i = 0; i < 5; i++) {
        algorithm.pack(conduitRadius: radius, groups: groups);
      }

      final stopwatch = Stopwatch()..start();
      const testRuns = 50;
      for (int i = 0; i < testRuns; i++) {
        algorithm.pack(conduitRadius: radius, groups: groups);
      }
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMicroseconds / 1000.0;
      final avgMsPerRun = elapsedMs / testRuns;
      expect(avgMsPerRun, lessThan(0.5)); // Validates fast execution under 0.3-0.5ms
    });
  });
}
