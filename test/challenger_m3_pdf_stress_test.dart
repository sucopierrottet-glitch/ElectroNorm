// ignore_for_file: avoid_print
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:electronorm/calculators/conduit_fill_calculator.dart';
import 'package:electronorm/calculators/derating_calculator.dart';
import 'package:electronorm/calculators/voltage_drop_calculator.dart';
import 'package:electronorm/catalogs/conductor_catalog.dart';
import 'package:electronorm/catalogs/raceway_catalog.dart';
import 'package:electronorm/models/conductor.dart';
import 'package:electronorm/models/raceway.dart';
import 'package:electronorm/services/pdf_report_service.dart';

/// Transparent 1x1 pixel RGBA PNG bytes for digital signature validation
final Uint8List kChallengerTestSignatureBytes = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 dimensions
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, // 8-bit truecolor RGBA
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, // IDAT chunk
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, // IEND chunk
  0x42, 0x60, 0x82,
]);

/// Definition of an empirical PDF stress test configuration
class PdfStressConfig {
  final int id;
  final String category;
  final String description;
  final ComplianceReportData Function() builder;

  const PdfStressConfig({
    required this.id,
    required this.category,
    required this.description,
    required this.builder,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Build the exhaustive 32-configuration adversarial matrix
  List<PdfStressConfig> buildAdversarialConfigs() {
    final list = <PdfStressConfig>[];

    // Common catalog helper references
    final emt4 = RacewayCatalog.getProfile(RacewayType.emt, '4');
    final emt312 = RacewayCatalog.getProfile(RacewayType.emt, '3-1/2');
    final emt3 = RacewayCatalog.getProfile(RacewayType.emt, '3');
    final emt212 = RacewayCatalog.getProfile(RacewayType.emt, '2-1/2');
    final emt2 = RacewayCatalog.getProfile(RacewayType.emt, '2');
    final emt112 = RacewayCatalog.getProfile(RacewayType.emt, '1-1/2');
    final emt114 = RacewayCatalog.getProfile(RacewayType.emt, '1-1/4');
    final emt1 = RacewayCatalog.getProfile(RacewayType.emt, '1');
    final emt34 = RacewayCatalog.getProfile(RacewayType.emt, '3/4');

    final pvc40_4 = RacewayCatalog.getProfile(RacewayType.pvcSch40, '4');
    final pvc40_3 = RacewayCatalog.getProfile(RacewayType.pvcSch40, '3');
    final pvc40_114 = RacewayCatalog.getProfile(RacewayType.pvcSch40, '1-1/4');

    final pvc80_212 = RacewayCatalog.getProfile(RacewayType.pvcSch80, '2-1/2');
    final imc312 = RacewayCatalog.getProfile(RacewayType.imc, '3-1/2');
    final imc114 = RacewayCatalog.getProfile(RacewayType.imc, '1-1/4');
    final rmc4 = RacewayCatalog.getProfile(RacewayType.rmc, '4');
    final rmc2 = RacewayCatalog.getProfile(RacewayType.rmc, '2');
    final rmc1 = RacewayCatalog.getProfile(RacewayType.rmc, '1');
    final fmc4 = RacewayCatalog.getProfile(RacewayType.fmc, '4');

    // Conductor specs
    final spec500ThhnCu = ConductorCatalog.getSpec(gauge: '500 kcmil', insulation: ConductorInsulation.thhn, material: ConductorMaterial.copper);
    final spec500XhhwCu = ConductorCatalog.getSpec(gauge: '500 kcmil', insulation: ConductorInsulation.xhhw, material: ConductorMaterial.copper);
    final spec500ThhnAl = ConductorCatalog.getSpec(gauge: '500 kcmil', insulation: ConductorInsulation.thhn, material: ConductorMaterial.aluminum);
    final spec400ThhnCu = ConductorCatalog.getSpec(gauge: '400 kcmil', insulation: ConductorInsulation.thhn, material: ConductorMaterial.copper);
    final spec350ThhnCu = ConductorCatalog.getSpec(gauge: '350 kcmil', insulation: ConductorInsulation.thhn, material: ConductorMaterial.copper);
    final spec350ThwnCu = ConductorCatalog.getSpec(gauge: '350 kcmil', insulation: ConductorInsulation.thwn, material: ConductorMaterial.copper);
    final spec350ThhnAl = ConductorCatalog.getSpec(gauge: '350 kcmil', insulation: ConductorInsulation.thhn, material: ConductorMaterial.aluminum);
    final spec250ThhnCu = ConductorCatalog.getSpec(gauge: '250 kcmil', insulation: ConductorInsulation.thhn, material: ConductorMaterial.copper);
    final spec40ThhnCu = ConductorCatalog.getSpec(gauge: '4/0 AWG', insulation: ConductorInsulation.thhn, material: ConductorMaterial.copper);
    final spec40XhhwCu = ConductorCatalog.getSpec(gauge: '4/0 AWG', insulation: ConductorInsulation.xhhw, material: ConductorMaterial.copper);
    final spec30ThhnCu = ConductorCatalog.getSpec(gauge: '3/0 AWG', insulation: ConductorInsulation.thhn, material: ConductorMaterial.copper);
    final spec20ThhnCu = ConductorCatalog.getSpec(gauge: '2/0 AWG', insulation: ConductorInsulation.thhn, material: ConductorMaterial.copper);
    final spec10ThhnCu = ConductorCatalog.getSpec(gauge: '1/0 AWG', insulation: ConductorInsulation.thhn, material: ConductorMaterial.copper);
    final spec2ThhnCu = ConductorCatalog.getSpec(gauge: '2 AWG', insulation: ConductorInsulation.thhn, material: ConductorMaterial.copper);
    final spec4ThhnCu = ConductorCatalog.getSpec(gauge: '4 AWG', insulation: ConductorInsulation.thhn, material: ConductorMaterial.copper);
    final spec4Use2Cu = ConductorCatalog.getSpec(gauge: '4 AWG', insulation: ConductorInsulation.use2, material: ConductorMaterial.copper);
    final spec6ThhnCu = ConductorCatalog.getSpec(gauge: '6 AWG', insulation: ConductorInsulation.thhn, material: ConductorMaterial.copper);
    final spec6ThhnAl = ConductorCatalog.getSpec(gauge: '6 AWG', insulation: ConductorInsulation.thhn, material: ConductorMaterial.aluminum);
    final spec8ThhnCu = ConductorCatalog.getSpec(gauge: '8 AWG', insulation: ConductorInsulation.thhn, material: ConductorMaterial.copper);
    final spec8XhhwCu = ConductorCatalog.getSpec(gauge: '8 AWG', insulation: ConductorInsulation.xhhw, material: ConductorMaterial.copper);
    final spec10ThhnCuW = ConductorCatalog.getSpec(gauge: '10 AWG', insulation: ConductorInsulation.thhn, material: ConductorMaterial.copper);
    final spec12ThhnCuW = ConductorCatalog.getSpec(gauge: '12 AWG', insulation: ConductorInsulation.thhn, material: ConductorMaterial.copper);

    // =========================================================================
    // Category 1: Heavy Schedule Pagination & Multi-Conductor Packing (1 - 6)
    // =========================================================================

    // 1. 40 mixed conductors in 4" EMT (5 diverse groups: 10x#12, 10x#10, 10x#8, 5x#6, 5x#4)
    list.add(PdfStressConfig(
      id: 1,
      category: 'Heavy Schedule Pagination',
      description: '40 mixed conductors in 4" EMT (5 groups)',
      builder: () {
        final groups = [
          ConductorGroup(id: 'g1', spec: spec12ThhnCuW, count: 10, role: 'phaseA'),
          ConductorGroup(id: 'g2', spec: spec10ThhnCuW, count: 10, role: 'phaseB'),
          ConductorGroup(id: 'g3', spec: spec8ThhnCu, count: 10, role: 'phaseC'),
          ConductorGroup(id: 'g4', spec: spec6ThhnCu, count: 5, role: 'neutral'),
          ConductorGroup(id: 'g5', spec: spec4ThhnCu, count: 5, role: 'ground'),
        ];
        final fill = ConduitFillCalculator.calculate(raceway: emt4, conductorGroups: groups);
        return ComplianceReportData(
          projectTitle: 'Substation Control Auxiliary Feeder',
          clientName: 'Pacific Power & Light',
          siteAddress: 'Station 14, Yard Bay 2',
          technicianName: 'Marcus Vance',
          companyName: 'High Volt Engineering LLC',
          date: DateTime(2026, 10, 13),
          raceway: emt4,
          conductors: groups,
          fillResult: fill,
        );
      },
    ));

    // 2. 40 distinct conductor groups (40 separate schedule table rows forcing heavy multi-page flow)
    list.add(PdfStressConfig(
      id: 2,
      category: 'Heavy Schedule Pagination',
      description: '40 distinct conductor groups (40 table rows) in 4" EMT',
      builder: () {
        final groups = List.generate(40, (i) {
          final spec = (i < 10) ? spec12ThhnCuW : (i < 20) ? spec10ThhnCuW : (i < 30) ? spec8ThhnCu : spec6ThhnCu;
          final role = (i % 4 == 0) ? 'phaseA' : (i % 4 == 1) ? 'phaseB' : (i % 4 == 2) ? 'phaseC' : 'neutral';
          return ConductorGroup(id: 'row_$i', spec: spec, count: 1, role: role);
        });
        final fill = ConduitFillCalculator.calculate(raceway: emt4, conductorGroups: groups);
        return ComplianceReportData(
          projectTitle: 'Massive Multi-Circuit Home Run Run',
          clientName: 'Industrial Distribution Hub',
          siteAddress: 'Warehouse Terminal 8',
          technicianName: 'Sara Lin',
          companyName: 'VoltCorp Solutions',
          date: DateTime(2026, 10, 13),
          raceway: emt4,
          conductors: groups,
          fillResult: fill,
        );
      },
    ));

    // 3. 50 mixed conductors in 4" PVC Sch 40 (10 groups of 5)
    list.add(PdfStressConfig(
      id: 3,
      category: 'Heavy Schedule Pagination',
      description: '50 mixed conductors in 4" PVC Sch 40 (10 groups)',
      builder: () {
        final groups = List.generate(10, (i) {
          final spec = (i % 2 == 0) ? spec12ThhnCuW : spec10ThhnCuW;
          return ConductorGroup(id: 'grp_$i', spec: spec, count: 5, role: 'phaseA');
        });
        final fill = ConduitFillCalculator.calculate(raceway: pvc40_4, conductorGroups: groups);
        return ComplianceReportData(
          projectTitle: 'Underground Duct Bank 50-Wire Feeder',
          clientName: 'Metro Transit Authority',
          siteAddress: 'Subway Junction Box 4',
          technicianName: 'Dave Kowalski',
          companyName: 'Transit Electrics',
          date: DateTime(2026, 10, 13),
          raceway: pvc40_4,
          conductors: groups,
          fillResult: fill,
        );
      },
    ));

    // 4. 36 conductors in 3-1/2" IMC (6 groups of 6, three-phase lighting branch home-runs)
    list.add(PdfStressConfig(
      id: 4,
      category: 'Heavy Schedule Pagination',
      description: '36 conductors in 3-1/2" IMC (6 groups of 6)',
      builder: () {
        final groups = [
          ConductorGroup(id: 'g1', spec: spec12ThhnCuW, count: 6, role: 'phaseA'),
          ConductorGroup(id: 'g2', spec: spec12ThhnCuW, count: 6, role: 'phaseB'),
          ConductorGroup(id: 'g3', spec: spec12ThhnCuW, count: 6, role: 'phaseC'),
          ConductorGroup(id: 'g4', spec: spec10ThhnCuW, count: 6, role: 'neutral'),
          ConductorGroup(id: 'g5', spec: spec10ThhnCuW, count: 6, role: 'phaseA'),
          ConductorGroup(id: 'g6', spec: spec8ThhnCu, count: 6, role: 'ground'),
        ];
        final fill = ConduitFillCalculator.calculate(raceway: imc312, conductorGroups: groups);
        return ComplianceReportData(
          projectTitle: 'High-Bay Lighting Homeruns',
          clientName: 'Logistics Facility 12',
          siteAddress: 'Dock 4 North Corridor',
          technicianName: 'Carlos M.',
          companyName: 'VoltPro Electrical',
          date: DateTime(2026, 10, 13),
          raceway: imc312,
          conductors: groups,
          fillResult: fill,
        );
      },
    ));

    // 5. Heavy industrial feeder: 24 mixed large conductors in 4" RMC
    list.add(PdfStressConfig(
      id: 5,
      category: 'Heavy Schedule Pagination',
      description: '24 mixed heavy conductors in 4" RMC (4 groups)',
      builder: () {
        final groups = [
          ConductorGroup(id: 'g1', spec: spec250ThhnCu, count: 4, role: 'phaseA'),
          ConductorGroup(id: 'g2', spec: spec30ThhnCu, count: 8, role: 'phaseB'),
          ConductorGroup(id: 'g3', spec: spec10ThhnCu, count: 8, role: 'phaseC'),
          ConductorGroup(id: 'g4', spec: spec2ThhnCu, count: 4, role: 'ground'),
        ];
        final fill = ConduitFillCalculator.calculate(raceway: rmc4, conductorGroups: groups);
        return ComplianceReportData(
          projectTitle: 'Refinery Main Distribution Duct',
          clientName: 'Gulf Coast Petrochem',
          siteAddress: 'Cracker Unit B-3',
          technicianName: 'Robert Vance',
          companyName: 'Industrial Power Services',
          date: DateTime(2026, 10, 13),
          raceway: rmc4,
          conductors: groups,
          fillResult: fill,
        );
      },
    ));

    // 6. 48 conductors in 4" FMC (12 groups of 4)
    list.add(PdfStressConfig(
      id: 6,
      category: 'Heavy Schedule Pagination',
      description: '48 conductors in 4" FMC (12 groups of 4)',
      builder: () {
        final groups = List.generate(12, (i) {
          return ConductorGroup(id: 'fmc_g$i', spec: spec12ThhnCuW, count: 4, role: (i % 2 == 0) ? 'phaseA' : 'neutral');
        });
        final fill = ConduitFillCalculator.calculate(raceway: fmc4, conductorGroups: groups);
        return ComplianceReportData(
          projectTitle: 'Flex Conduit Vibration Isolation Riser',
          clientName: 'Seismic Test Facility',
          siteAddress: 'Building 14 Basement',
          technicianName: 'James Taylor',
          companyName: 'Apex Electrics',
          date: DateTime(2026, 10, 13),
          raceway: fmc4,
          conductors: groups,
          fillResult: fill,
        );
      },
    ));

    // =========================================================================
    // Category 2: Single Large Feeder at 53% Fill Limit (7 - 12)
    // =========================================================================

    // 7. Single 500 kcmil THHN Cu in 1-1/4" EMT (0.7073 in² wire in 1.496 in² conduit = 47.28% <= 53.0% PASS)
    list.add(PdfStressConfig(
      id: 7,
      category: 'Single Feeder at 53% Limit',
      description: 'Single 500 kcmil THHN Cu in 1-1/4" EMT (47.3% fill vs 53% limit)',
      builder: () {
        final groups = [ConductorGroup(id: 's1', spec: spec500ThhnCu, count: 1, role: 'phaseA')];
        final fill = ConduitFillCalculator.calculate(raceway: emt114, conductorGroups: groups);
        return ComplianceReportData(
          projectTitle: 'Single Feeder Run 500 kcmil',
          clientName: 'City Hospital Emergency Power',
          siteAddress: 'Generator Vault G-1',
          technicianName: 'Elena Rostova',
          companyName: 'Prime Electric',
          date: DateTime(2026, 10, 13),
          raceway: emt114,
          conductors: groups,
          fillResult: fill,
        );
      },
    ));

    // 8. Single 500 kcmil XHHW Cu in 1-1/4" EMT (0.8252 in² wire in 1.496 in² conduit = 55.16% > 53.0% VIOLATION)
    list.add(PdfStressConfig(
      id: 8,
      category: 'Single Feeder at 53% Limit',
      description: 'Single 500 kcmil XHHW Cu in 1-1/4" EMT (55.2% fill - VIOLATION)',
      builder: () {
        final groups = [ConductorGroup(id: 's2', spec: spec500XhhwCu, count: 1, role: 'phaseA')];
        final fill = ConduitFillCalculator.calculate(raceway: emt114, conductorGroups: groups);
        return ComplianceReportData(
          projectTitle: 'Heavy Insulation Feeder Overfill Check',
          clientName: 'Data Center Chillers',
          siteAddress: 'Row C Rack Feeders',
          technicianName: 'Mark Chen',
          companyName: 'DataPower Contracting',
          date: DateTime(2026, 10, 13),
          raceway: emt114,
          conductors: groups,
          fillResult: fill,
        );
      },
    ));

    // 9. Single 500 kcmil THHN Al in 1-1/4" PVC Sch 40
    list.add(PdfStressConfig(
      id: 9,
      category: 'Single Feeder at 53% Limit',
      description: 'Single 500 kcmil THHN Al in 1-1/4" PVC Sch 40 (47.3% fill)',
      builder: () {
        final groups = [ConductorGroup(id: 's3', spec: spec500ThhnAl, count: 1, role: 'phaseA')];
        final fill = ConduitFillCalculator.calculate(raceway: pvc40_114, conductorGroups: groups);
        return ComplianceReportData(
          projectTitle: 'Aluminum Service Entrance Feeder',
          clientName: 'Solar Farm Inverter Station',
          siteAddress: 'Array 3 Padmount',
          technicianName: 'Lucas Grey',
          companyName: 'SunTech Power Solutions',
          date: DateTime(2026, 10, 13),
          raceway: pvc40_114,
          conductors: groups,
          fillResult: fill,
        );
      },
    ));

    // 10. Single 350 kcmil THWN Cu in 1-1/4" IMC (single wire fill ~36.4% <= 53%)
    list.add(PdfStressConfig(
      id: 10,
      category: 'Single Feeder at 53% Limit',
      description: 'Single 350 kcmil THWN Cu in 1-1/4" IMC (36.4% fill)',
      builder: () {
        final groups = [ConductorGroup(id: 's4', spec: spec350ThwnCu, count: 1, role: 'phaseA')];
        final fill = ConduitFillCalculator.calculate(raceway: imc114, conductorGroups: groups);
        return ComplianceReportData(
          projectTitle: 'Industrial Pump Single Feeder',
          clientName: 'Municipal Water District',
          siteAddress: 'Pump Station #2',
          technicianName: 'Dan Kelly',
          companyName: 'Metro Utilities',
          date: DateTime(2026, 10, 13),
          raceway: imc114,
          conductors: groups,
          fillResult: fill,
        );
      },
    ));

    // 11. Single 250 kcmil THHN Cu in 1" EMT (wire 0.3970 in² in 0.864 in² conduit = 45.95% <= 53.0% PASS)
    list.add(PdfStressConfig(
      id: 11,
      category: 'Single Feeder at 53% Limit',
      description: 'Single 250 kcmil THHN Cu in 1" EMT (45.95% fill)',
      builder: () {
        final groups = [ConductorGroup(id: 's5', spec: spec250ThhnCu, count: 1, role: 'phaseA')];
        final fill = ConduitFillCalculator.calculate(raceway: emt1, conductorGroups: groups);
        return ComplianceReportData(
          projectTitle: 'Single Feeder 250 kcmil Run',
          clientName: 'Commercial Office Tower',
          siteAddress: 'Penthouse Elevator Machine Room',
          technicianName: 'Victor Cruz',
          companyName: 'Apex Electric',
          date: DateTime(2026, 10, 13),
          raceway: emt1,
          conductors: groups,
          fillResult: fill,
        );
      },
    ));

    // 12. Single 4/0 AWG XHHW Cu in 1" RMC
    list.add(PdfStressConfig(
      id: 12,
      category: 'Single Feeder at 53% Limit',
      description: 'Single 4/0 AWG XHHW Cu in 1" RMC (37.2% fill)',
      builder: () {
        final groups = [ConductorGroup(id: 's6', spec: spec40XhhwCu, count: 1, role: 'phaseA')];
        final fill = ConduitFillCalculator.calculate(raceway: rmc1, conductorGroups: groups);
        return ComplianceReportData(
          projectTitle: 'Mining Conveyor Motor Feeder',
          clientName: 'Eagle Mining LLC',
          siteAddress: 'Shaft 2 Sub-surface',
          technicianName: 'Hank Schrader',
          companyName: 'Heavy Power Electric',
          date: DateTime(2026, 10, 13),
          raceway: rmc1,
          conductors: groups,
          fillResult: fill,
        );
      },
    ));

    // =========================================================================
    // Category 3: Critical Jam Ratio Condition (2.80 <= R_jam <= 3.20) (13 - 17)
    // =========================================================================

    // 13. 3x 250 kcmil THHN Cu in 2" EMT (R_jam = 2.067 / 0.711 = 2.907 -> HAZARD)
    list.add(PdfStressConfig(
      id: 13,
      category: 'Critical Jam Ratio Condition',
      description: '3x 250 kcmil THHN Cu in 2" EMT (R_jam = 2.907 - CRITICAL HAZARD)',
      builder: () {
        final groups = [ConductorGroup(id: 'j1', spec: spec250ThhnCu, count: 3, role: 'phaseA')];
        final fill = ConduitFillCalculator.calculate(raceway: emt2, conductorGroups: groups);
        return ComplianceReportData(
          projectTitle: 'Jam Hazard Pull Analysis - 250 kcmil',
          clientName: 'Foundry Machine Works',
          siteAddress: 'Smelter Bay 1',
          technicianName: 'Inspector Dan',
          companyName: 'VoltSafe LLC',
          date: DateTime(2026, 10, 13),
          raceway: emt2,
          conductors: groups,
          fillResult: fill,
        );
      },
    ));

    // 14. 3x 350 kcmil THHN Cu in 2-1/2" EMT (R_jam = 2.469 / 0.816 = 3.026 -> HAZARD)
    list.add(PdfStressConfig(
      id: 14,
      category: 'Critical Jam Ratio Condition',
      description: '3x 350 kcmil THHN Cu in 2-1/2" EMT (R_jam = 3.026 - CRITICAL HAZARD)',
      builder: () {
        final groups = [ConductorGroup(id: 'j2', spec: spec350ThhnCu, count: 3, role: 'phaseA')];
        final fill = ConduitFillCalculator.calculate(raceway: emt212, conductorGroups: groups);
        return ComplianceReportData(
          projectTitle: 'Jam Hazard Pull Analysis - 350 kcmil',
          clientName: 'Automotive Stamping Plant',
          siteAddress: 'Press Line 4',
          technicianName: 'Carlos Mendoza',
          companyName: 'VoltPro Electrical',
          date: DateTime(2026, 10, 13),
          raceway: emt212,
          conductors: groups,
          fillResult: fill,
        );
      },
    ));

    // 15. 3x 500 kcmil THHN Cu in 3" EMT (R_jam = 3.068 / 0.984 = 3.118 -> HAZARD)
    list.add(PdfStressConfig(
      id: 15,
      category: 'Critical Jam Ratio Condition',
      description: '3x 500 kcmil THHN Cu in 3" EMT (R_jam = 3.118 - CRITICAL HAZARD)',
      builder: () {
        final groups = [ConductorGroup(id: 'j3', spec: spec500ThhnCu, count: 3, role: 'phaseA')];
        final fill = ConduitFillCalculator.calculate(raceway: emt3, conductorGroups: groups);
        return ComplianceReportData(
          projectTitle: 'Jam Hazard Pull Analysis - 500 kcmil',
          clientName: 'Steel Mill Rolling Dept',
          siteAddress: 'Rolling Mill Substation',
          technicianName: 'Elena Rostova',
          companyName: 'Apex High Voltage Corp',
          date: DateTime(2026, 10, 13),
          raceway: emt3,
          conductors: groups,
          fillResult: fill,
        );
      },
    ));

    // 16. 3x 1/0 AWG THHN Cu in 1-1/2" EMT (R_jam = 1.610 / 0.532 = 3.026 -> HAZARD)
    list.add(PdfStressConfig(
      id: 16,
      category: 'Critical Jam Ratio Condition',
      description: '3x 1/0 AWG THHN Cu in 1-1/2" EMT (R_jam = 3.026 - CRITICAL HAZARD)',
      builder: () {
        final groups = [ConductorGroup(id: 'j4', spec: spec10ThhnCu, count: 3, role: 'phaseA')];
        final fill = ConduitFillCalculator.calculate(raceway: emt112, conductorGroups: groups);
        return ComplianceReportData(
          projectTitle: 'Jam Hazard Pull Analysis - 1/0 AWG',
          clientName: 'Commercial Plaza Feeder',
          siteAddress: 'Meter Bank B',
          technicianName: 'Marcus Wright',
          companyName: 'VoltPro Electrical',
          date: DateTime(2026, 10, 13),
          raceway: emt112,
          conductors: groups,
          fillResult: fill,
        );
      },
    ));

    // 17. 3x 400 kcmil THHN Cu in 3" PVC Sch 40 (R_jam = 3.042 / 0.884 = 3.441 -> SAFE Pull Clearance)
    list.add(PdfStressConfig(
      id: 17,
      category: 'Critical Jam Ratio Condition',
      description: '3x 400 kcmil THHN Cu in 3" PVC Sch 40 (R_jam = 3.441 - SAFE)',
      builder: () {
        final groups = [ConductorGroup(id: 'j5', spec: spec400ThhnCu, count: 3, role: 'phaseA')];
        final fill = ConduitFillCalculator.calculate(raceway: pvc40_3, conductorGroups: groups);
        return ComplianceReportData(
          projectTitle: 'Safe Pull Clearance Verification',
          clientName: 'Chemical Plant Storage',
          siteAddress: 'Tank Farm Feeder Run',
          technicianName: 'Inspector Dan',
          companyName: 'VoltSafe LLC',
          date: DateTime(2026, 10, 13),
          raceway: pvc40_3,
          conductors: groups,
          fillResult: fill,
        );
      },
    ));

    // =========================================================================
    // Category 4: High Ambient Temperature Derating (> 50°C, 12 CCC) (18 - 22)
    // =========================================================================

    // 18. 52°C ambient, 12 CCC, 12 AWG THHN Cu in 2" EMT (Severe derating: Temp: 0.76, Bundling: 0.50)
    list.add(PdfStressConfig(
      id: 18,
      category: 'High Ambient Temperature Derating',
      description: '52°C ambient, 12 CCC, 12 AWG THHN Cu (Temp=0.76, Bundling=0.50)',
      builder: () {
        final groups = [
          ConductorGroup(id: 'd1', spec: spec12ThhnCuW, count: 12, role: 'phaseA'),
        ];
        final fill = ConduitFillCalculator.calculate(raceway: emt2, conductorGroups: groups);
        final derate = DeratingCalculator.calculate(
          conductorSpec: spec12ThhnCuW,
          ambientTempC: 52.0,
          currentCarryingConductorsCount: 12,
          terminalRatingC: 75.0,
        );
        return ComplianceReportData(
          projectTitle: 'Boiler Room Control Circuits',
          clientName: 'Metropolitan District Heating',
          siteAddress: 'Steam Plant #1 Upper Deck',
          technicianName: 'Carlos Mendoza',
          companyName: 'VoltPro Electrical Solutions LLC',
          date: DateTime(2026, 10, 13),
          raceway: emt2,
          conductors: groups,
          fillResult: fill,
          deratingResult: derate,
          ambientTempC: 52.0,
          cccCount: 12,
        );
      },
    ));

    // 19. 55°C ambient, 16 CCC, 10 AWG THHN Cu in 2-1/2" EMT (Temp: 0.67, Bundling: 0.50)
    list.add(PdfStressConfig(
      id: 19,
      category: 'High Ambient Temperature Derating',
      description: '55°C ambient, 16 CCC, 10 AWG THHN Cu (Temp=0.67, Bundling=0.50)',
      builder: () {
        final groups = [
          ConductorGroup(id: 'd2', spec: spec10ThhnCuW, count: 16, role: 'phaseB'),
        ];
        final fill = ConduitFillCalculator.calculate(raceway: emt212, conductorGroups: groups);
        final derate = DeratingCalculator.calculate(
          conductorSpec: spec10ThhnCuW,
          ambientTempC: 55.0,
          currentCarryingConductorsCount: 16,
          terminalRatingC: 75.0,
        );
        return ComplianceReportData(
          projectTitle: 'Furnace Feeders Derating Evaluation',
          clientName: 'Glass Manufacturing Works',
          siteAddress: 'Furnace Hall Level 3',
          technicianName: 'Victor Vance',
          companyName: 'High Volt Engineering LLC',
          date: DateTime(2026, 10, 13),
          raceway: emt212,
          conductors: groups,
          fillResult: fill,
          deratingResult: derate,
          ambientTempC: 55.0,
          cccCount: 16,
        );
      },
    ));

    // 20. 60°C ambient (140°F rooftop), 20 CCC, 8 AWG XHHW Cu in 3" EMT (Temp: 0.58, Bundling: 0.50)
    list.add(PdfStressConfig(
      id: 20,
      category: 'High Ambient Temperature Derating',
      description: '60°C rooftop ambient, 20 CCC, 8 AWG XHHW Cu (Temp=0.58, Bundling=0.50)',
      builder: () {
        final groups = [
          ConductorGroup(id: 'd3', spec: spec8XhhwCu, count: 20, role: 'phaseC'),
        ];
        final fill = ConduitFillCalculator.calculate(raceway: emt3, conductorGroups: groups);
        final derate = DeratingCalculator.calculate(
          conductorSpec: spec8XhhwCu,
          ambientTempC: 60.0,
          currentCarryingConductorsCount: 20,
          terminalRatingC: 75.0,
        );
        return ComplianceReportData(
          projectTitle: 'Desert Solar Array Rooftop Raceways',
          clientName: 'Mojave Solar Project',
          siteAddress: 'Inverter Enclosure Rooftop',
          technicianName: 'Sarah Conner',
          companyName: 'Desert Solar EPC',
          date: DateTime(2026, 10, 13),
          raceway: emt3,
          conductors: groups,
          fillResult: fill,
          deratingResult: derate,
          ambientTempC: 60.0,
          cccCount: 20,
        );
      },
    ));

    // 21. 51°C ambient, 14 CCC, 6 AWG THHN Al in 2-1/2" PVC Sch 80 (Aluminum conductor derating)
    list.add(PdfStressConfig(
      id: 21,
      category: 'High Ambient Temperature Derating',
      description: '51°C ambient, 14 CCC, 6 AWG THHN Al in PVC Sch 80',
      builder: () {
        final groups = [
          ConductorGroup(id: 'd4', spec: spec6ThhnAl, count: 14, role: 'phaseA'),
        ];
        final fill = ConduitFillCalculator.calculate(raceway: pvc80_212, conductorGroups: groups);
        final derate = DeratingCalculator.calculate(
          conductorSpec: spec6ThhnAl,
          ambientTempC: 51.0,
          currentCarryingConductorsCount: 14,
          terminalRatingC: 75.0,
        );
        return ComplianceReportData(
          projectTitle: 'Thermal Derating Aluminum Run',
          clientName: 'AgriCorp Processing Facility',
          siteAddress: 'Grain Dryer Exhaust Tower',
          technicianName: 'Dan Kelly',
          companyName: 'Rural Electric Contractors',
          date: DateTime(2026, 10, 13),
          raceway: pvc80_212,
          conductors: groups,
          fillResult: fill,
          deratingResult: derate,
          ambientTempC: 51.0,
          cccCount: 14,
        );
      },
    ));

    // 22. 54°C ambient, 12 CCC, 4 AWG USE-2 Cu in 2" RMC
    list.add(PdfStressConfig(
      id: 22,
      category: 'High Ambient Temperature Derating',
      description: '54°C ambient, 12 CCC, 4 AWG USE-2 Cu in 2" RMC',
      builder: () {
        final groups = [
          ConductorGroup(id: 'd5', spec: spec4Use2Cu, count: 12, role: 'phaseB'),
        ];
        final fill = ConduitFillCalculator.calculate(raceway: rmc2, conductorGroups: groups);
        final derate = DeratingCalculator.calculate(
          conductorSpec: spec4Use2Cu,
          ambientTempC: 54.0,
          currentCarryingConductorsCount: 12,
          terminalRatingC: 75.0,
        );
        return ComplianceReportData(
          projectTitle: 'Industrial Kiln Feeders',
          clientName: 'Ceramic Works Inc',
          siteAddress: 'Tunnel Kiln #4 Wall Raceway',
          technicianName: 'Marcus Wright',
          companyName: 'VoltPro Electrical',
          date: DateTime(2026, 10, 13),
          raceway: rmc2,
          conductors: groups,
          fillResult: fill,
          deratingResult: derate,
          ambientTempC: 54.0,
          cccCount: 12,
        );
      },
    ));

    // =========================================================================
    // Category 5: Single-Phase 120V vs Three-Phase 480V Voltage Drops (23 - 29)
    // =========================================================================

    // 23. Single-Phase 120V: 16A load, 250 ft on 12 AWG Cu (Voltage drop > 7.5%, severe violation)
    list.add(PdfStressConfig(
      id: 23,
      category: 'Voltage Drop: 120V vs 480V',
      description: 'Single-phase 120V, 16A, 250 ft on 12 AWG Cu (7.7% drop - VIOLATION)',
      builder: () {
        final groups = [
          ConductorGroup(id: 'vd1', spec: spec12ThhnCuW, count: 2, role: 'phaseA'),
          ConductorGroup(id: 'vd2', spec: spec12ThhnCuW, count: 1, role: 'ground'),
        ];
        final fill = ConduitFillCalculator.calculate(raceway: emt34, conductorGroups: groups);
        final vdrop = VoltageDropCalculator.calculateEffectiveImpedance(
          nominalVoltage: 120.0,
          phase: CircuitPhase.singlePhase,
          currentAmps: 16.0,
          lengthFeet: 250.0,
          conductorSpec: spec12ThhnCuW,
          isSteelConduit: true,
          powerFactor: 0.90,
        );
        return ComplianceReportData(
          projectTitle: 'Parking Lot Lighting Branch 120V',
          clientName: 'Retail Strip Mall',
          siteAddress: 'Pole 12 Perimeter',
          technicianName: 'Carlos Mendoza',
          companyName: 'VoltPro Electrical',
          date: DateTime(2026, 10, 13),
          raceway: emt34,
          conductors: groups,
          fillResult: fill,
          voltageDropResult: vdrop,
          nominalVoltage: 120.0,
          circuitPhase: CircuitPhase.singlePhase,
          circuitLengthFeet: 250.0,
          loadCurrentAmps: 16.0,
        );
      },
    ));

    // 24. Single-Phase 120V: 20A load, 400 ft on 10 AWG Cu (Drop > 8%, severe violation)
    list.add(PdfStressConfig(
      id: 24,
      category: 'Voltage Drop: 120V vs 480V',
      description: 'Single-phase 120V, 20A, 400 ft on 10 AWG Cu (8.6% drop - VIOLATION)',
      builder: () {
        final groups = [
          ConductorGroup(id: 'vd3', spec: spec10ThhnCuW, count: 2, role: 'phaseA'),
          ConductorGroup(id: 'vd4', spec: spec10ThhnCuW, count: 1, role: 'ground'),
        ];
        final fill = ConduitFillCalculator.calculate(raceway: emt34, conductorGroups: groups);
        final vdrop = VoltageDropCalculator.calculateEffectiveImpedance(
          nominalVoltage: 120.0,
          phase: CircuitPhase.singlePhase,
          currentAmps: 20.0,
          lengthFeet: 400.0,
          conductorSpec: spec10ThhnCuW,
          isSteelConduit: true,
          powerFactor: 0.90,
        );
        return ComplianceReportData(
          projectTitle: 'Remote Security Gate 120V Run',
          clientName: 'Industrial Logistics Park',
          siteAddress: 'North Perimeter Gatehouse',
          technicianName: 'Marcus Wright',
          companyName: 'VoltPro Electrical',
          date: DateTime(2026, 10, 13),
          raceway: emt34,
          conductors: groups,
          fillResult: fill,
          voltageDropResult: vdrop,
          nominalVoltage: 120.0,
          circuitPhase: CircuitPhase.singlePhase,
          circuitLengthFeet: 400.0,
          loadCurrentAmps: 20.0,
        );
      },
    ));

    // 25. Single-Phase 240V: 30A load, 300 ft on 8 AWG Cu (Moderate drop evaluation)
    list.add(PdfStressConfig(
      id: 25,
      category: 'Voltage Drop: 120V vs 480V',
      description: 'Single-phase 240V, 30A, 300 ft on 8 AWG Cu (3.4% drop)',
      builder: () {
        final groups = [
          ConductorGroup(id: 'vd5', spec: spec8ThhnCu, count: 2, role: 'phaseA'),
          ConductorGroup(id: 'vd6', spec: spec10ThhnCuW, count: 1, role: 'ground'),
        ];
        final fill = ConduitFillCalculator.calculate(raceway: emt1, conductorGroups: groups);
        final vdrop = VoltageDropCalculator.calculateEffectiveImpedance(
          nominalVoltage: 240.0,
          phase: CircuitPhase.singlePhase,
          currentAmps: 30.0,
          lengthFeet: 300.0,
          conductorSpec: spec8ThhnCu,
          isSteelConduit: true,
          powerFactor: 0.92,
        );
        return ComplianceReportData(
          projectTitle: 'EV Charger Feeder 240V',
          clientName: 'Corporate Campus Garage',
          siteAddress: 'Level 2 EV Charging Bank',
          technicianName: 'Elena Rostova',
          companyName: 'Apex High Voltage Corp',
          date: DateTime(2026, 10, 13),
          raceway: emt1,
          conductors: groups,
          fillResult: fill,
          voltageDropResult: vdrop,
          nominalVoltage: 240.0,
          circuitPhase: CircuitPhase.singlePhase,
          circuitLengthFeet: 300.0,
          loadCurrentAmps: 30.0,
        );
      },
    ));

    // 26. Three-Phase 480V: 150A load, 600 ft on 3/0 AWG Cu (Compliant long feeder: ~2.4% drop <= 3.0% PASS)
    list.add(PdfStressConfig(
      id: 26,
      category: 'Voltage Drop: 120V vs 480V',
      description: 'Three-phase 480V, 150A, 600 ft on 3/0 AWG Cu (2.4% drop - PASS)',
      builder: () {
        final groups = [
          ConductorGroup(id: 'vd7', spec: spec30ThhnCu, count: 3, role: 'phaseA'),
          ConductorGroup(id: 'vd8', spec: spec4ThhnCu, count: 1, role: 'ground'),
        ];
        final fill = ConduitFillCalculator.calculate(raceway: emt2, conductorGroups: groups);
        final vdrop = VoltageDropCalculator.calculateEffectiveImpedance(
          nominalVoltage: 480.0,
          phase: CircuitPhase.threePhase,
          currentAmps: 150.0,
          lengthFeet: 600.0,
          conductorSpec: spec30ThhnCu,
          isSteelConduit: true,
          powerFactor: 0.88,
        );
        return ComplianceReportData(
          projectTitle: 'Industrial Motor Control Center 480V Feeder',
          clientName: 'Automated Bottling Facility',
          siteAddress: 'Main Substation to MCC-4',
          technicianName: 'Marcus Vance',
          companyName: 'High Volt Engineering LLC',
          date: DateTime(2026, 10, 13),
          raceway: emt2,
          conductors: groups,
          fillResult: fill,
          voltageDropResult: vdrop,
          nominalVoltage: 480.0,
          circuitPhase: CircuitPhase.threePhase,
          circuitLengthFeet: 600.0,
          loadCurrentAmps: 150.0,
        );
      },
    ));

    // 27. Three-Phase 480V: 320A load, 800 ft long industrial run on 500 kcmil Cu (Drop ~ 2.9% <= 3.0% PASS)
    list.add(PdfStressConfig(
      id: 27,
      category: 'Voltage Drop: 120V vs 480V',
      description: 'Three-phase 480V, 320A, 800 ft on 500 kcmil Cu (2.9% drop - PASS)',
      builder: () {
        final groups = [
          ConductorGroup(id: 'vd9', spec: spec500ThhnCu, count: 3, role: 'phaseA'),
          ConductorGroup(id: 'vd10', spec: spec2ThhnCu, count: 1, role: 'ground'),
        ];
        final fill = ConduitFillCalculator.calculate(raceway: emt312, conductorGroups: groups);
        final vdrop = VoltageDropCalculator.calculateEffectiveImpedance(
          nominalVoltage: 480.0,
          phase: CircuitPhase.threePhase,
          currentAmps: 320.0,
          lengthFeet: 800.0,
          conductorSpec: spec500ThhnCu,
          isSteelConduit: true,
          powerFactor: 0.90,
        );
        return ComplianceReportData(
          projectTitle: 'Chiller Plant Heavy Feeder 480V',
          clientName: 'International Airport Central Utility',
          siteAddress: 'Central Energy Plant Vault 1',
          technicianName: 'Robert Vance, AHJ',
          companyName: 'State Bureau of Safety',
          date: DateTime(2026, 10, 13),
          raceway: emt312,
          conductors: groups,
          fillResult: fill,
          voltageDropResult: vdrop,
          nominalVoltage: 480.0,
          circuitPhase: CircuitPhase.threePhase,
          circuitLengthFeet: 800.0,
          loadCurrentAmps: 320.0,
        );
      },
    ));

    // 28. Three-Phase 208V: 60A load, 250 ft on 4 AWG Cu (Drop ~ 2.2% <= 3.0% PASS)
    list.add(PdfStressConfig(
      id: 28,
      category: 'Voltage Drop: 120V vs 480V',
      description: 'Three-phase 208V, 60A, 250 ft on 4 AWG Cu (2.2% drop - PASS)',
      builder: () {
        final groups = [
          ConductorGroup(id: 'vd11', spec: spec4ThhnCu, count: 3, role: 'phaseA'),
          ConductorGroup(id: 'vd12', spec: spec8ThhnCu, count: 1, role: 'ground'),
        ];
        final fill = ConduitFillCalculator.calculate(raceway: emt114, conductorGroups: groups);
        final vdrop = VoltageDropCalculator.calculateEffectiveImpedance(
          nominalVoltage: 208.0,
          phase: CircuitPhase.threePhase,
          currentAmps: 60.0,
          lengthFeet: 250.0,
          conductorSpec: spec4ThhnCu,
          isSteelConduit: true,
          powerFactor: 0.92,
        );
        return ComplianceReportData(
          projectTitle: 'Commercial Kitchen Panel Feeder 208V',
          clientName: 'Grand Hotel & Resort',
          siteAddress: 'Main Kitchen Service Corridor',
          technicianName: 'Sara Lin',
          companyName: 'VoltCorp Solutions',
          date: DateTime(2026, 10, 13),
          raceway: emt114,
          conductors: groups,
          fillResult: fill,
          voltageDropResult: vdrop,
          nominalVoltage: 208.0,
          circuitPhase: CircuitPhase.threePhase,
          circuitLengthFeet: 250.0,
          loadCurrentAmps: 60.0,
        );
      },
    ));

    // 29. Three-Phase 480V Aluminum Feeder: 200A load, 500 ft on 350 kcmil Al (Drop ~ 2.6% PASS)
    list.add(PdfStressConfig(
      id: 29,
      category: 'Voltage Drop: 120V vs 480V',
      description: 'Three-phase 480V, 200A, 500 ft on 350 kcmil Al (2.6% drop - PASS)',
      builder: () {
        final groups = [
          ConductorGroup(id: 'vd13', spec: spec350ThhnAl, count: 3, role: 'phaseA'),
          ConductorGroup(id: 'vd14', spec: spec2ThhnCu, count: 1, role: 'ground'),
        ];
        final fill = ConduitFillCalculator.calculate(raceway: emt212, conductorGroups: groups);
        final vdrop = VoltageDropCalculator.calculateEffectiveImpedance(
          nominalVoltage: 480.0,
          phase: CircuitPhase.threePhase,
          currentAmps: 200.0,
          lengthFeet: 500.0,
          conductorSpec: spec350ThhnAl,
          isSteelConduit: true,
          powerFactor: 0.91,
        );
        return ComplianceReportData(
          projectTitle: 'Aluminum Overhead Feeder 480V',
          clientName: 'Fertilizer Warehouse',
          siteAddress: 'Building B East Distribution',
          technicianName: 'Lucas Grey',
          companyName: 'SunTech Power Solutions',
          date: DateTime(2026, 10, 13),
          raceway: emt212,
          conductors: groups,
          fillResult: fill,
          voltageDropResult: vdrop,
          nominalVoltage: 480.0,
          circuitPhase: CircuitPhase.threePhase,
          circuitLengthFeet: 500.0,
          loadCurrentAmps: 200.0,
        );
      },
    ));

    // =========================================================================
    // Category 6: Boundary Violations, Nipples & Full Integration (30 - 32)
    // =========================================================================

    // 30. Extreme Overfilled Raceway: 12x 500 kcmil in 2" EMT (> 400% fill limit violation)
    list.add(PdfStressConfig(
      id: 30,
      category: 'Boundary Violations & Nipples',
      description: 'Severe overfill violation: 12x 500 kcmil in 2" EMT (400% fill)',
      builder: () {
        final groups = [
          ConductorGroup(id: 'ov1', spec: spec500ThhnCu, count: 12, role: 'phaseA'),
        ];
        final fill = ConduitFillCalculator.calculate(raceway: emt2, conductorGroups: groups);
        return ComplianceReportData(
          projectTitle: 'Severe Raceway Overfill Violation Audit',
          clientName: 'Building Code Enforcement Agency',
          siteAddress: 'Site Inspection Report',
          technicianName: 'Chief Inspector Ramirez',
          companyName: 'City Compliance Office',
          date: DateTime(2026, 10, 13),
          raceway: emt2,
          conductors: groups,
          fillResult: fill,
        );
      },
    ));

    // 31. Nipple Conduit <= 24" at 60% fill limit: 4x 2/0 AWG THHN Cu in 2" EMT (58.2% fill <= 60% PASS)
    list.add(PdfStressConfig(
      id: 31,
      category: 'Boundary Violations & Nipples',
      description: 'Nipple conduit run <= 24" at 58.2% fill (60% allowed - PASS)',
      builder: () {
        final groups = [
          ConductorGroup(id: 'np1', spec: spec20ThhnCu, count: 4, role: 'phaseA'),
        ];
        final fill = ConduitFillCalculator.calculate(
          raceway: emt2,
          conductorGroups: groups,
          isNipple: true,
        );
        return ComplianceReportData(
          projectTitle: 'Panelboard Interconnect Nipple 18"',
          clientName: 'Commercial Office Main Switchboard',
          siteAddress: 'Electric Room MDP to Panel A',
          technicianName: 'Carlos Mendoza',
          companyName: 'VoltPro Electrical',
          date: DateTime(2026, 10, 13),
          raceway: emt2,
          conductors: groups,
          fillResult: fill,
        );
      },
    ));

    // 32. Full Technical Compliance Suite: 3-phase 480V feeder, derated for 45°C & 6 CCC, with digital signature
    list.add(PdfStressConfig(
      id: 32,
      category: 'Full Integration Suite',
      description: 'Comprehensive 480V feeder + Derating + Voltage Drop + Embedded Digital Signature',
      builder: () {
        final groups = [
          ConductorGroup(id: 'fl1', spec: spec40ThhnCu, count: 3, role: 'phaseA'),
          ConductorGroup(id: 'fl2', spec: spec40ThhnCu, count: 3, role: 'phaseB'),
          ConductorGroup(id: 'fl3', spec: spec2ThhnCu, count: 1, role: 'ground'),
        ];
        final fill = ConduitFillCalculator.calculate(raceway: emt3, conductorGroups: groups);
        final vdrop = VoltageDropCalculator.calculateEffectiveImpedance(
          nominalVoltage: 480.0,
          phase: CircuitPhase.threePhase,
          currentAmps: 220.0,
          lengthFeet: 350.0,
          conductorSpec: spec40ThhnCu,
          isSteelConduit: true,
          powerFactor: 0.90,
        );
        final derate = DeratingCalculator.calculate(
          conductorSpec: spec40ThhnCu,
          ambientTempC: 45.0,
          currentCarryingConductorsCount: 6,
          terminalRatingC: 75.0,
        );
        return ComplianceReportData(
          projectTitle: 'Critical Facility Substation Switchgear Feeder',
          clientName: 'Regional Telecommunications Hub',
          siteAddress: 'Primary Switchgear Room Bay 3',
          technicianName: 'Carlos Mendoza',
          companyName: 'VoltPro Electrical Solutions LLC',
          date: DateTime(2026, 10, 13),
          raceway: emt3,
          conductors: groups,
          fillResult: fill,
          voltageDropResult: vdrop,
          deratingResult: derate,
          signaturePngBytes: kChallengerTestSignatureBytes,
          inspectorName: 'Chief Inspector Arthur Pendelton',
          licenseNumber: 'AHJ-EXP-88401',
          agencyName: 'State Bureau of Industrial Safety',
          nominalVoltage: 480.0,
          circuitPhase: CircuitPhase.threePhase,
          circuitLengthFeet: 350.0,
          loadCurrentAmps: 220.0,
          powerFactor: 0.90,
          ambientTempC: 45.0,
          cccCount: 6,
        );
      },
    ));

    return list;
  }

  group('Milestone 3 Challenger: 32 Adversarial Calculation Configurations Stress Test', () {
    final configs = buildAdversarialConfigs();

    test('Verification Matrix: Exactly 32 configurations covering all 5 challenge archetypes', () {
      expect(configs.length, equals(32));
      expect(configs.length, greaterThanOrEqualTo(25));

      final categories = configs.map((c) => c.category).toSet();
      expect(categories, contains('Heavy Schedule Pagination'));
      expect(categories, contains('Single Feeder at 53% Limit'));
      expect(categories, contains('Critical Jam Ratio Condition'));
      expect(categories, contains('High Ambient Temperature Derating'));
      expect(categories, contains('Voltage Drop: 120V vs 480V'));
    });

    for (final cfg in configs) {
      test('Config #${cfg.id} [${cfg.category}]: ${cfg.description}', () async {
        final data = cfg.builder();
        final sw = Stopwatch()..start();
        final pdfBytes = await PdfReportService.generateReport(data);
        sw.stop();

        final elapsedMs = sw.elapsedMilliseconds;
        final byteLength = pdfBytes.length;

        print('Config #${cfg.id.toString().padLeft(2, '0')} | ${elapsedMs.toString().padLeft(3, ' ')} ms | ${(byteLength / 1024).toStringAsFixed(1).padLeft(5, ' ')} KB | ${cfg.description}');

        // 1. Structure integrity: Starts with %PDF- header
        expect(pdfBytes.length, greaterThan(100), reason: 'PDF byte length must be non-trivial');
        expect(pdfBytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]),
            reason: 'Generated PDF bytes must begin with %PDF-');

        // 2. Structure integrity: Ends with %%EOF
        final tailAscii = String.fromCharCodes(pdfBytes.sublist(pdfBytes.length - 30));
        expect(tailAscii.trim().endsWith('%%EOF'), isTrue,
            reason: 'Generated PDF bytes must terminate with %%EOF marker');

        // 3. Performance requirement: Generation must complete in < 500ms
        expect(elapsedMs, lessThan(500),
            reason: 'PDF generation latency must be strictly under 500ms. Actual: ${elapsedMs}ms');

        // 4. Compactness requirement: File size must be compact (< 150 KB)
        expect(byteLength, lessThan(150 * 1024),
            reason: 'PDF file size must be strictly under 150 KB. Actual: $byteLength bytes');
      });
    }
  });

  group('Milestone 3 Challenger: Endurance & Memory Stability Stress Test', () {
    test('Continuous generation burst of 32 configurations without performance degradation', () async {
      final configs = buildAdversarialConfigs();
      final durations = <int>[];
      final sizes = <int>[];

      for (final cfg in configs) {
        final sw = Stopwatch()..start();
        final bytes = await PdfReportService.generateReport(cfg.builder());
        sw.stop();

        durations.add(sw.elapsedMilliseconds);
        sizes.add(bytes.length);
      }

      final avgDuration = durations.reduce((a, b) => a + b) / durations.length;
      final maxDuration = durations.reduce((a, b) => a > b ? a : b);
      final avgSizeKb = (sizes.reduce((a, b) => a + b) / sizes.length) / 1024.0;
      final maxSizeKb = (sizes.reduce((a, b) => a > b ? a : b)) / 1024.0;

      print('=== ENDURANCE BURST SUMMARY ===');
      print('Total runs: ${configs.length}');
      print('Average latency: ${avgDuration.toStringAsFixed(1)} ms');
      print('Peak latency: $maxDuration ms (Limit: < 500 ms)');
      print('Average size: ${avgSizeKb.toStringAsFixed(1)} KB');
      print('Peak size: ${maxSizeKb.toStringAsFixed(1)} KB (Limit: < 150 KB)');

      expect(maxDuration, lessThan(500));
      expect(avgDuration, lessThan(200));
      expect(maxSizeKb, lessThan(150.0));
    });
  });
}
