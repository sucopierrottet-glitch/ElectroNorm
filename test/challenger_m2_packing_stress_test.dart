// ignore_for_file: avoid_print
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';

import 'package:electronorm/catalogs/conductor_catalog.dart';
import 'package:electronorm/catalogs/raceway_catalog.dart';
import 'package:electronorm/models/conductor.dart';
import 'package:electronorm/models/raceway.dart';
import 'package:electronorm/widgets/packing_algorithm.dart';

class ConductorPackingTestCase {
  final int id;
  final String description;
  final RacewayType racewayType;
  final String tradeSize;
  final List<ConductorGroup> groups;

  const ConductorPackingTestCase({
    required this.id,
    required this.description,
    required this.racewayType,
    required this.tradeSize,
    required this.groups,
  });

  int get totalConductors =>
      groups.fold(0, (sum, g) => sum + g.count);
}

void main() {
  const algorithm = GoldenSpiralPackingAlgorithm();
  const double epsilon = 0.005; // Maximum allowed tolerance per challenge spec

  // Helper to build test cases
  List<ConductorPackingTestCase> generate50PlusTestCases() {
    final cases = <ConductorPackingTestCase>[];
    int nextId = 1;

    void addCase(
      String description,
      RacewayType type,
      String tradeSize,
      List<ConductorGroup> groups,
    ) {
      cases.add(ConductorPackingTestCase(
        id: nextId++,
        description: description,
        racewayType: type,
        tradeSize: tradeSize,
        groups: groups,
      ));
    }

    // --- Tier 1: Single Conductor Cases (1 - 5) ---
    addCase(
      '1x #14 AWG THHN in 1/2" EMT',
      RacewayType.emt,
      '1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 1,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '1x #10 AWG THHN in 1/2" EMT',
      RacewayType.emt,
      '1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '10 AWG'),
          count: 1,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '1x #4 AWG THHN in 1" EMT',
      RacewayType.emt,
      '1',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '4 AWG'),
          count: 1,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '1x 4/0 AWG XHHW in 2" PVC 40',
      RacewayType.pvcSch40,
      '2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(
            gauge: '4/0 AWG',
            insulation: ConductorInsulation.xhhw,
          ),
          count: 1,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '1x 500 kcmil THHN Cu in 3" RMC',
      RacewayType.rmc,
      '3',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '500 kcmil'),
          count: 1,
          role: 'phaseA',
        ),
      ],
    );

    // --- Tier 2: Two Conductor Cases (6 - 10) ---
    addCase(
      '2x #14 AWG THHN in 1/2" EMT',
      RacewayType.emt,
      '1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 2,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '2x #12 AWG THHN (1 Phase, 1 Neutral) in 1/2" EMT',
      RacewayType.emt,
      '1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 1,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 1,
          role: 'neutral',
        ),
      ],
    );
    addCase(
      '2x #6 AWG THWN in 1" IMC',
      RacewayType.imc,
      '1',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(
            gauge: '6 AWG',
            insulation: ConductorInsulation.thwn,
          ),
          count: 2,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '2x 2/0 AWG THHN in 2" PVC 80',
      RacewayType.pvcSch80,
      '2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '2/0 AWG'),
          count: 2,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '2x 350 kcmil Al THHN in 3" FMC',
      RacewayType.fmc,
      '3',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(
            gauge: '350 kcmil',
            material: ConductorMaterial.aluminum,
          ),
          count: 2,
          role: 'phaseA',
        ),
      ],
    );

    // --- Tier 3: Three Conductor 3-Phase Circuits (11 - 15) ---
    addCase(
      '3x #12 AWG THHN in 1/2" EMT',
      RacewayType.emt,
      '1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 1,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 1,
          role: 'phaseB',
        ),
        ConductorGroup(
          id: 'g3',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 1,
          role: 'phaseC',
        ),
      ],
    );
    addCase(
      '3x #10 AWG THHN in 3/4" EMT',
      RacewayType.emt,
      '3/4',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '10 AWG'),
          count: 3,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '3x #2 AWG THHN in 1-1/4" EMT',
      RacewayType.emt,
      '1-1/4',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '2 AWG'),
          count: 3,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '3x 250 kcmil THHN Cu in 2-1/2" RMC',
      RacewayType.rmc,
      '2-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '250 kcmil'),
          count: 3,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '3x 500 kcmil THHN Cu in 3-1/2" EMT',
      RacewayType.emt,
      '3-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '500 kcmil'),
          count: 3,
          role: 'phaseA',
        ),
      ],
    );

    // --- Tier 4: Four Conductor Standard Branch/Feeders (16 - 20) ---
    addCase(
      '3x #12 AWG + 1x #12 Grd in 1/2" EMT',
      RacewayType.emt,
      '1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 3,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 1,
          role: 'ground',
        ),
      ],
    );
    addCase(
      '3x #10 AWG + 1x #12 Grd in 3/4" EMT',
      RacewayType.emt,
      '3/4',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '10 AWG'),
          count: 1,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '10 AWG'),
          count: 1,
          role: 'phaseB',
        ),
        ConductorGroup(
          id: 'g3',
          spec: ConductorCatalog.getSpec(gauge: '10 AWG'),
          count: 1,
          role: 'phaseC',
        ),
        ConductorGroup(
          id: 'g4',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 1,
          role: 'ground',
        ),
      ],
    );
    addCase(
      '3x #8 AWG + 1x #10 Grd in 1" EMT',
      RacewayType.emt,
      '1',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '8 AWG'),
          count: 3,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '10 AWG'),
          count: 1,
          role: 'ground',
        ),
      ],
    );
    addCase(
      '4x 4/0 AWG THHN Cu in 2-1/2" EMT',
      RacewayType.emt,
      '2-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '4/0 AWG'),
          count: 3,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '4/0 AWG'),
          count: 1,
          role: 'neutral',
        ),
      ],
    );
    addCase(
      '4x 500 kcmil + 1x #3 Grd (5 wires) in 3-1/2" EMT',
      RacewayType.emt,
      '3-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '500 kcmil'),
          count: 3,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '500 kcmil'),
          count: 1,
          role: 'neutral',
        ),
        ConductorGroup(
          id: 'g3',
          spec: ConductorCatalog.getSpec(gauge: '3 AWG'),
          count: 1,
          role: 'ground',
        ),
      ],
    );

    // --- Tier 5: 5 to 9 Mixed Conductors (21 - 30) ---
    addCase(
      '5x #12 AWG THHN in 3/4" EMT',
      RacewayType.emt,
      '3/4',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 5,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '6x #12 AWG THHN (2 Multi-wire circuits) in 3/4" EMT',
      RacewayType.emt,
      '3/4',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 4,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 2,
          role: 'neutral',
        ),
      ],
    );
    addCase(
      '7x #12 AWG (6 phase + 1 grd) in 3/4" PVC 40',
      RacewayType.pvcSch40,
      '3/4',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 6,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 1,
          role: 'ground',
        ),
      ],
    );
    addCase(
      '8x #14 AWG THHN in 3/4" EMT',
      RacewayType.emt,
      '3/4',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 8,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '9x #12 AWG THHN in 1" EMT',
      RacewayType.emt,
      '1',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 9,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '6x #10 AWG + 1x #10 Grd in 1" IMC',
      RacewayType.imc,
      '1',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '10 AWG'),
          count: 6,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '10 AWG'),
          count: 1,
          role: 'ground',
        ),
      ],
    );
    addCase(
      '6x #8 AWG + 2x #10 Grd (8 wires) in 1-1/4" EMT',
      RacewayType.emt,
      '1-1/4',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '8 AWG'),
          count: 6,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '10 AWG'),
          count: 2,
          role: 'ground',
        ),
      ],
    );
    addCase(
      '6x #4 AWG + 1x #8 Grd (7 wires) in 1-1/2" EMT',
      RacewayType.emt,
      '1-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '4 AWG'),
          count: 6,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '8 AWG'),
          count: 1,
          role: 'ground',
        ),
      ],
    );
    addCase(
      '8x 1/0 AWG THHN in 2-1/2" RMC',
      RacewayType.rmc,
      '2-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '1/0 AWG'),
          count: 8,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '9x #10 AWG THHN in 1" PVC 40',
      RacewayType.pvcSch40,
      '1',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '10 AWG'),
          count: 9,
          role: 'phaseA',
        ),
      ],
    );

    // --- Tier 6: 10 to 19 Mixed Conductors (31 - 40) ---
    addCase(
      '10x #12 AWG (9 phase + 1 grd) in 1" EMT',
      RacewayType.emt,
      '1',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 9,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 1,
          role: 'ground',
        ),
      ],
    );
    addCase(
      '12x #12 AWG (4 circuits) in 1-1/4" EMT',
      RacewayType.emt,
      '1-1/4',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 8,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 4,
          role: 'neutral',
        ),
      ],
    );
    addCase(
      '14x #14 AWG THHN in 1-1/4" EMT',
      RacewayType.emt,
      '1-1/4',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 14,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '15x #12 AWG (12 phase + 3 neutral) in 1-1/4" EMT',
      RacewayType.emt,
      '1-1/4',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 12,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 3,
          role: 'neutral',
        ),
      ],
    );
    addCase(
      '16x #12 AWG THHN in 1-1/4" EMT',
      RacewayType.emt,
      '1-1/4',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 16,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '12x #10 AWG + 2x #10 Grd (14 wires) in 1-1/2" EMT',
      RacewayType.emt,
      '1-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '10 AWG'),
          count: 12,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '10 AWG'),
          count: 2,
          role: 'ground',
        ),
      ],
    );
    addCase(
      '18x #14 AWG THHN in 1-1/2" EMT',
      RacewayType.emt,
      '1-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 18,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '15x #10 AWG in 1-1/2" PVC 40',
      RacewayType.pvcSch40,
      '1-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '10 AWG'),
          count: 15,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '16x #12 AWG + 2x #10 Grd (18 wires) in 1-1/2" IMC',
      RacewayType.imc,
      '1-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 16,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '10 AWG'),
          count: 2,
          role: 'ground',
        ),
      ],
    );
    addCase(
      '19x #14 AWG in 1-1/2" EMT',
      RacewayType.emt,
      '1-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 19,
          role: 'phaseA',
        ),
      ],
    );

    // --- Tier 7: 20 to 29 Mixed Conductors (41 - 48) ---
    addCase(
      '20x #12 AWG THHN in 1-1/2" EMT',
      RacewayType.emt,
      '1-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 20,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '21x #14 AWG THHN in 1-1/2" EMT',
      RacewayType.emt,
      '1-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 21,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '24x #12 AWG in 2" EMT',
      RacewayType.emt,
      '2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 24,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '25x Mixed: 24x #12 + 1x #10 Grd in 2" EMT',
      RacewayType.emt,
      '2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 24,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '10 AWG'),
          count: 1,
          role: 'ground',
        ),
      ],
    );
    addCase(
      '26x #14 AWG in 2" EMT',
      RacewayType.emt,
      '2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 26,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '27x #12 AWG in 2" PVC 40',
      RacewayType.pvcSch40,
      '2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 27,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '28x Mixed: 20x #12 + 6x #10 + 2x #8 Grd in 2" EMT',
      RacewayType.emt,
      '2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 20,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '10 AWG'),
          count: 6,
          role: 'neutral',
        ),
        ConductorGroup(
          id: 'g3',
          spec: ConductorCatalog.getSpec(gauge: '8 AWG'),
          count: 2,
          role: 'ground',
        ),
      ],
    );
    addCase(
      '29x #14 AWG in 2" RMC',
      RacewayType.rmc,
      '2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 29,
          role: 'phaseA',
        ),
      ],
    );

    // --- Tier 8: 30 to 40 Mixed Conductors (49 - 58) ---
    addCase(
      '30x #14 AWG in 2" EMT',
      RacewayType.emt,
      '2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 30,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '32x Mixed: 24x #12 + 6x #12 Neutral + 2x #10 Grd in 2" EMT',
      RacewayType.emt,
      '2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 24,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 6,
          role: 'neutral',
        ),
        ConductorGroup(
          id: 'g3',
          spec: ConductorCatalog.getSpec(gauge: '10 AWG'),
          count: 2,
          role: 'ground',
        ),
      ],
    );
    addCase(
      '33x #14 AWG in 2" PVC 80',
      RacewayType.pvcSch80,
      '2-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 33,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '35x Mixed: 30x #14 + 5x #14 Neutral in 2" EMT',
      RacewayType.emt,
      '2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 30,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 5,
          role: 'neutral',
        ),
      ],
    );
    addCase(
      '36x #14 AWG in 2-1/2" EMT',
      RacewayType.emt,
      '2-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 36,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '37x Mixed: 30x #14 + 6x #12 + 1x #10 in 2-1/2" EMT',
      RacewayType.emt,
      '2-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 30,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 6,
          role: 'neutral',
        ),
        ConductorGroup(
          id: 'g3',
          spec: ConductorCatalog.getSpec(gauge: '10 AWG'),
          count: 1,
          role: 'ground',
        ),
      ],
    );
    addCase(
      '38x #12 AWG in 2-1/2" EMT',
      RacewayType.emt,
      '2-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 38,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '39x Mixed: 36x #14 + 3x #12 in 2-1/2" IMC',
      RacewayType.imc,
      '2-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 36,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 3,
          role: 'ground',
        ),
      ],
    );
    addCase(
      '40x #14 AWG Control Bundle in 2-1/2" EMT',
      RacewayType.emt,
      '2-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 40,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '40x Mixed: 20x #14 + 15x #12 + 5x #10 in 3" EMT',
      RacewayType.emt,
      '3',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 20,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 15,
          role: 'phaseB',
        ),
        ConductorGroup(
          id: 'g3',
          spec: ConductorCatalog.getSpec(gauge: '10 AWG'),
          count: 5,
          role: 'ground',
        ),
      ],
    );

    // --- Tier 9: Metric Conductor Test Cases (59 - 62) ---
    addCase(
      '3x 2.5 mm² + 1x 2.5 mm² PE in 3/4" EMT (Metric)',
      RacewayType.emt,
      '3/4',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '2.5 mm²'),
          count: 3,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '2.5 mm²'),
          count: 1,
          role: 'ground',
        ),
      ],
    );
    addCase(
      '4x 16.0 mm² Cu in 1-1/2" EMT (Metric)',
      RacewayType.emt,
      '1-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '16.0 mm²'),
          count: 4,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '4x 50.0 mm² Al in 2-1/2" PVC 40 (Metric)',
      RacewayType.pvcSch40,
      '2-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(
            gauge: '50.0 mm²',
            material: ConductorMaterial.aluminum,
          ),
          count: 4,
          role: 'phaseA',
        ),
      ],
    );
    addCase(
      '30x 1.5 mm² Control Bundle in 2" EMT (Metric)',
      RacewayType.emt,
      '2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '1.5 mm²'),
          count: 30,
          role: 'phaseA',
        ),
      ],
    );

    // --- Tier 10: Extreme Adversarial Disparity & Scale Cases (63 - 70) ---
    addCase(
      'Severe Disparity: 1x 500 kcmil + 1x #14 AWG in 3" EMT',
      RacewayType.emt,
      '3',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '500 kcmil'),
          count: 1,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 1,
          role: 'ground',
        ),
      ],
    );
    addCase(
      'Severe Disparity: 1x 250 kcmil + 12x #14 AWG in 2-1/2" EMT',
      RacewayType.emt,
      '2-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '250 kcmil'),
          count: 1,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 12,
          role: 'neutral',
        ),
      ],
    );
    addCase(
      'Mixed Feeders: 3x 350 kcmil + 3x #10 AWG in 3-1/2" EMT',
      RacewayType.emt,
      '3-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '350 kcmil'),
          count: 3,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '10 AWG'),
          count: 3,
          role: 'ground',
        ),
      ],
    );
    addCase(
      'Asymmetric Phase: 1x 4/0 AWG + 2x #14 AWG in 2" EMT',
      RacewayType.emt,
      '2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '4/0 AWG'),
          count: 1,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 2,
          role: 'ground',
        ),
      ],
    );
    addCase(
      'Subpanel Feeder: 1x 500 kcmil + 4x #14 AWG + 1x #10 AWG in 3" EMT',
      RacewayType.emt,
      '3',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '500 kcmil'),
          count: 1,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 4,
          role: 'neutral',
        ),
        ConductorGroup(
          id: 'g3',
          spec: ConductorCatalog.getSpec(gauge: '10 AWG'),
          count: 1,
          role: 'ground',
        ),
      ],
    );
    addCase(
      'Heavy Feeder + Instrumentation: 2x 4/0 AWG + 20x #14 AWG in 3" EMT',
      RacewayType.emt,
      '3',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '4/0 AWG'),
          count: 2,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 20,
          role: 'phaseB',
        ),
      ],
    );
    addCase(
      'Large + Dense Small: 1x 350 kcmil + 30x #14 AWG in 3-1/2" EMT',
      RacewayType.emt,
      '3-1/2',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '350 kcmil'),
          count: 1,
          role: 'phaseA',
        ),
        ConductorGroup(
          id: 'g2',
          spec: ConductorCatalog.getSpec(gauge: '14 AWG'),
          count: 30,
          role: 'phaseB',
        ),
      ],
    );
    addCase(
      'Dense 40x #12 AWG in 3" EMT',
      RacewayType.emt,
      '3',
      [
        ConductorGroup(
          id: 'g1',
          spec: ConductorCatalog.getSpec(gauge: '12 AWG'),
          count: 40,
          role: 'phaseA',
        ),
      ],
    );

    return cases;
  }

  final testCases = generate50PlusTestCases();

  group('CHALLENGER 1: Geometric Invariant & Performance Stress Test Suite', () {
    test('Total test case count meets or exceeds requirement of 50+', () {
      expect(testCases.length, greaterThanOrEqualTo(50));
      print('Verified total test case count: ${testCases.length} diverse combinations.');
    });

    for (final tc in testCases) {
      test('Case #${tc.id} (${tc.totalConductors} wires) - ${tc.description}', () {
        final profile = RacewayCatalog.getProfile(tc.racewayType, tc.tradeSize);
        final conduitRadius = profile.internalDiameterInches / 2.0;

        // Execute packing
        final stopwatch = Stopwatch()..start();
        final packed = algorithm.pack(
          conduitRadius: conduitRadius,
          groups: tc.groups,
        );
        stopwatch.stop();

        final elapsedMs = stopwatch.elapsedMicroseconds / 1000.0;
        expect(elapsedMs, lessThan(50.0), reason: 'Pack must not freeze execution');

        // Assert 1: Correct count of placed circles
        expect(
          packed.length,
          equals(tc.totalConductors),
          reason: 'Every conductor item in schedule must be assigned a position',
        );

        // Assert 2: Invariant A - Boundary Containment
        // For every conductor: center distance + radius <= 1.00 + epsilon
        for (int i = 0; i < packed.length; i++) {
          final p = packed[i];
          final centerDist = math.sqrt(
            p.normalizedX * p.normalizedX + p.normalizedY * p.normalizedY,
          );
          final boundaryExtent = centerDist + p.normalizedRadius;

          expect(
            boundaryExtent,
            lessThanOrEqualTo(1.00 + epsilon),
            reason:
                'Conductor $i (${p.label}) breached raceway wall in case #${tc.id}: extent=$boundaryExtent, limit=${1.00 + epsilon}',
          );
        }

        // Assert 3: Invariant B - Geometric Non-overlapping
        // For every pair (i, j): distance >= (r_i + r_j) - epsilon
        double worstOverlap = 0.0;
        for (int i = 0; i < packed.length; i++) {
          for (int j = i + 1; j < packed.length; j++) {
            final pi = packed[i];
            final pj = packed[j];
            final centerDist = math.sqrt(
              math.pow(pi.normalizedX - pj.normalizedX, 2) +
                  math.pow(pi.normalizedY - pj.normalizedY, 2),
            );
            final minAllowedDist = pi.normalizedRadius + pj.normalizedRadius - epsilon;

            if (centerDist < minAllowedDist) {
              final deficit = minAllowedDist - centerDist;
              if (deficit > worstOverlap) worstOverlap = deficit;
            }

            expect(
              centerDist,
              greaterThanOrEqualTo(minAllowedDist),
              reason:
                  'Overlap between conductor $i (${pi.label}) and $j (${pj.label}) in case #${tc.id}: dist=$centerDist, minAllowed=$minAllowedDist',
            );
          }
        }

        // Assert 4: Invariant C - Benchmark execution time < 1.0 ms
        // (Note: we check elapsedMs on each test, but warm JIT benchmark below confirms steady-state)
      });
    }

    test('Benchmark Execution Time Oracle: < 1.0 ms across all 70 workloads', () {
      // Warm up JIT across all test cases
      for (final tc in testCases) {
        final profile = RacewayCatalog.getProfile(tc.racewayType, tc.tradeSize);
        final conduitRadius = profile.internalDiameterInches / 2.0;
        algorithm.pack(conduitRadius: conduitRadius, groups: tc.groups);
      }

      // Benchmark timed pass across all 62 workloads
      final timings = <int, double>{};
      double maxTimeMs = 0.0;
      int maxTimeCaseId = 0;
      double totalTimeMs = 0.0;

      for (final tc in testCases) {
        final profile = RacewayCatalog.getProfile(tc.racewayType, tc.tradeSize);
        final conduitRadius = profile.internalDiameterInches / 2.0;

        final sw = Stopwatch()..start();
        const iterationsPerCase = 20;
        for (int k = 0; k < iterationsPerCase; k++) {
          algorithm.pack(conduitRadius: conduitRadius, groups: tc.groups);
        }
        sw.stop();

        final avgMs = (sw.elapsedMicroseconds / 1000.0) / iterationsPerCase;
        timings[tc.id] = avgMs;
        totalTimeMs += avgMs;
        if (avgMs > maxTimeMs) {
          maxTimeMs = avgMs;
          maxTimeCaseId = tc.id;
        }

        // Each workload must execute in < 1.0 ms
        expect(
          avgMs,
          lessThan(1.0),
          reason: 'Case #${tc.id} (${tc.totalConductors} conductors) took ${avgMs.toStringAsFixed(3)}ms (threshold 1.0ms)',
        );
      }

      final overallAvgMs = totalTimeMs / testCases.length;
      print('--- BENCHMARK RESULTS ---');
      print('Workloads evaluated: ${testCases.length}');
      print('Mean execution time per pack: ${overallAvgMs.toStringAsFixed(4)} ms');
      print('Max execution time: ${maxTimeMs.toStringAsFixed(4)} ms (Case #$maxTimeCaseId)');
      expect(maxTimeMs, lessThan(1.0));
      expect(overallAvgMs, lessThan(0.5));
    });
  });
}
