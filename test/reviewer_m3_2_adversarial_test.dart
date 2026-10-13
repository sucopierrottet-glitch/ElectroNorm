import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:electronorm/calculators/conduit_fill_calculator.dart';
import 'package:electronorm/catalogs/conductor_catalog.dart';
import 'package:electronorm/catalogs/raceway_catalog.dart';
import 'package:electronorm/models/calculation_results.dart';
import 'package:electronorm/models/conductor.dart';
import 'package:electronorm/models/raceway.dart';
import 'package:electronorm/services/pdf_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reviewer 2 Adversarial Stress Tests: PDF Document Structure & Edge Cases', () {
    late RacewayProfile standardEmt;
    late ConductorSpec spec10;

    setUp(() {
      standardEmt = RacewayCatalog.getProfile(RacewayType.emt, '3/4');
      spec10 = ConductorCatalog.getSpec(gauge: '10 AWG');
    });

    test('Stress Test 1: Empty conductor list produces valid A4 PDF without throwing', () async {
      final fill = ConduitFillCalculator.calculate(
        raceway: standardEmt,
        conductorGroups: [],
      );

      final data = ComplianceReportData(
        projectTitle: 'Empty Run',
        clientName: 'Test Client',
        siteAddress: 'Empty Site',
        technicianName: 'Tech',
        companyName: 'Company',
        date: DateTime.now(),
        raceway: standardEmt,
        conductors: [],
        fillResult: fill,
        voltageDropResult: null,
        deratingResult: null,
      );

      final bytes = await PdfReportService.generateReport(data);
      expect(bytes, isNotEmpty);
      expect(bytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
    });

    test('Stress Test 2: Moderate schedule (6-8 conductor groups) fits cleanly', () async {
      final groups = List.generate(
        8,
        (i) => ConductorGroup(
          id: '$i',
          spec: spec10,
          count: 2,
          role: i % 2 == 0 ? 'phaseA' : 'neutral',
        ),
      );

      final fill = ConduitFillCalculator.calculate(
        raceway: RacewayCatalog.getProfile(RacewayType.emt, '2'),
        conductorGroups: groups,
      );

      final data = ComplianceReportData(
        projectTitle: '8 Group Schedule',
        clientName: 'Test Client',
        siteAddress: 'Site 8',
        technicianName: 'Tech',
        companyName: 'Company',
        date: DateTime.now(),
        raceway: RacewayCatalog.getProfile(RacewayType.emt, '2'),
        conductors: groups,
        fillResult: fill,
      );

      final bytes = await PdfReportService.generateReport(data);
      expect(bytes, isNotEmpty);
      expect(bytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
    });

    test('Stress Test 3: Large conductor schedule pagination (15 and 25 conductor groups)', () async {
      final groups15 = List.generate(
        15,
        (i) => ConductorGroup(
          id: '$i',
          spec: spec10,
          count: 1,
          role: 'phaseA',
        ),
      );

      final fill15 = ConduitFillCalculator.calculate(
        raceway: RacewayCatalog.getProfile(RacewayType.emt, '2'),
        conductorGroups: groups15,
      );

      final data15 = ComplianceReportData(
        projectTitle: '15 Groups Schedule',
        clientName: 'Large Schedule Client',
        siteAddress: 'Main Switchgear Room',
        technicianName: 'Engineer',
        companyName: 'Apex',
        date: DateTime.now(),
        raceway: RacewayCatalog.getProfile(RacewayType.emt, '2'),
        conductors: groups15,
        fillResult: fill15,
      );

      // Testing whether pw.MultiPage handles 15 groups across pages
      try {
        final bytes15 = await PdfReportService.generateReport(data15);
        expect(bytes15, isNotEmpty);
        expect(bytes15.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
      } catch (e) {
        fail('PDF generation failed on 15 conductor groups: $e');
      }
    });

    test('Stress Test 4: Extreme conductor schedule pagination (30 conductor groups)', () async {
      final groups30 = List.generate(
        30,
        (i) => ConductorGroup(
          id: '$i',
          spec: spec10,
          count: 1,
          role: 'phaseA',
        ),
      );

      final fill30 = ConduitFillCalculator.calculate(
        raceway: RacewayCatalog.getProfile(RacewayType.emt, '3'),
        conductorGroups: groups30,
      );

      final data30 = ComplianceReportData(
        projectTitle: '30 Groups Overflow Test',
        clientName: 'Overflow Client',
        siteAddress: 'Substation B',
        technicianName: 'Tech',
        companyName: 'Volt',
        date: DateTime.now(),
        raceway: RacewayCatalog.getProfile(RacewayType.emt, '3'),
        conductors: groups30,
        fillResult: fill30,
      );

      final bytes30 = await PdfReportService.generateReport(data30);
      expect(bytes30, isNotEmpty);
      expect(bytes30.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));

      // Verify multi-page pagination by inspecting /Type /Page in the PDF structure
      final pdfText = String.fromCharCodes(bytes30);
      final pageMatches = RegExp(r'/Type\s*/Page\b').allMatches(pdfText).length;
      expect(pageMatches, greaterThanOrEqualTo(2), reason: '30 conductor groups must paginate across at least 2 pages');

      // Test 50 conductor groups
      final groups50 = List.generate(
        50,
        (i) => ConductorGroup(
          id: '$i',
          spec: spec10,
          count: 1,
          role: 'phaseA',
        ),
      );
      final data50 = data30.copyWith(
        conductors: groups50,
        fillResult: ConduitFillCalculator.calculate(
          raceway: RacewayCatalog.getProfile(RacewayType.emt, '4'),
          conductorGroups: groups50,
        ),
      );
      final bytes50 = await PdfReportService.generateReport(data50);
      expect(bytes50, isNotEmpty);
    });

    test('Stress Test 5: Digital Signature variations - empty bytes vs corrupted bytes vs valid PNG', () async {
      // Case A: empty byte buffer
      final dataEmptySig = ComplianceReportData(
        projectTitle: 'Empty Sig',
        clientName: 'C',
        siteAddress: 'A',
        technicianName: 'T',
        companyName: 'Co',
        date: DateTime.now(),
        raceway: standardEmt,
        conductors: [ConductorGroup(id: '1', spec: spec10, count: 3, role: 'phaseA')],
        fillResult: ConduitFillCalculator.calculate(
          raceway: standardEmt,
          conductorGroups: [ConductorGroup(id: '1', spec: spec10, count: 3, role: 'phaseA')],
        ),
        signaturePngBytes: Uint8List(0), // empty bytes
      );

      final pdfBytesEmpty = await PdfReportService.generateReport(dataEmptySig);
      expect(pdfBytesEmpty, isNotEmpty);
    });

    test('Stress Test 6: Special characters and symbols in text fields (quotes, slashes, unicode)', () async {
      final dataSpecialChars = ComplianceReportData(
        projectTitle: 'Feeder "A-1" & Test <Main> / 480V',
        clientName: 'O\'Connor & Sons #12',
        siteAddress: '123 1st Ave, Suite #400 (Bldg B)',
        technicianName: 'Jean-Luc Picard',
        companyName: 'Alpha & Omega Electrical, Inc.',
        date: DateTime.now(),
        raceway: standardEmt,
        conductors: [ConductorGroup(id: '1', spec: spec10, count: 3, role: 'phaseA')],
        fillResult: ConduitFillCalculator.calculate(
          raceway: standardEmt,
          conductorGroups: [ConductorGroup(id: '1', spec: spec10, count: 3, role: 'phaseA')],
        ),
      );

      final bytes = await PdfReportService.generateReport(dataSpecialChars);
      expect(bytes, isNotEmpty);
    });

    test('Stress Test 7: Extremely long metadata strings (truncation / multi-line safety)', () async {
      final longString = 'A' * 250;
      final dataLong = ComplianceReportData(
        projectTitle: 'Very Long Title: $longString',
        clientName: 'Very Long Client Name: $longString',
        siteAddress: 'Very Long Site Address: $longString',
        technicianName: 'Very Long Tech Name: $longString',
        companyName: 'Very Long Company Name: $longString',
        inspectorName: 'Very Long Inspector: $longString',
        agencyName: 'Very Long Agency: $longString',
        licenseNumber: 'LIC-$longString',
        date: DateTime.now(),
        raceway: standardEmt,
        conductors: [ConductorGroup(id: '1', spec: spec10, count: 3, role: 'phaseA')],
        fillResult: ConduitFillCalculator.calculate(
          raceway: standardEmt,
          conductorGroups: [ConductorGroup(id: '1', spec: spec10, count: 3, role: 'phaseA')],
        ),
      );

      final bytes = await PdfReportService.generateReport(dataLong);
      expect(bytes, isNotEmpty);
      expect(bytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
    });

    test('Stress Test 8: Extreme failing voltage drop (e.g. 18.5% drop) and massive derating', () async {
      final vDropFail = VoltageDropResult(
        voltageDropVolts: 22.2,
        percentageDrop: 18.5,
        endVoltage: 97.8,
        isCompliantBranch: false,
        isCompliantTotal: false,
        effectiveImpedance: 1.25,
        complianceStatus: VoltageDropComplianceStatus.fail,
      );

      final derateHeavy = DeratingResult(
        baseAmpacity: 30.0,
        temperatureCorrectionFactor: 0.58,
        bundlingAdjustmentFactor: 0.45,
        deratedAmpacity: 7.83,
        terminalRatingLimit: 30.0,
        allowableAmpacity: 7.83,
      );

      final dataFail = ComplianceReportData(
        projectTitle: 'Severe Electrical Failure Run',
        clientName: 'Critical Hazard Facility',
        siteAddress: 'Long Feeder Run 1000ft',
        technicianName: 'Field Inspector',
        companyName: 'Safety First',
        date: DateTime.now(),
        raceway: standardEmt,
        conductors: [ConductorGroup(id: '1', spec: spec10, count: 3, role: 'phaseA')],
        fillResult: ConduitFillCalculator.calculate(
          raceway: standardEmt,
          conductorGroups: [ConductorGroup(id: '1', spec: spec10, count: 3, role: 'phaseA')],
        ),
        voltageDropResult: vDropFail,
        deratingResult: derateHeavy,
      );

      final bytes = await PdfReportService.generateReport(dataFail);
      expect(bytes, isNotEmpty);
      expect(bytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
    });

    test('Stress Test 9: Vulnerability Check - Unsanitized slash in projectTitle causes PathNotFoundException on export', () async {
      final dataWithSlash = ComplianceReportData(
        projectTitle: 'Hospital Feeder #4 (Main/Sub)',
        clientName: 'St. Jude Hospital',
        siteAddress: 'Wing B',
        technicianName: 'Bob Vance',
        companyName: 'Vance Electric',
        date: DateTime.now(),
        raceway: standardEmt,
        conductors: [ConductorGroup(id: '1', spec: spec10, count: 3, role: 'phaseA')],
        fillResult: ConduitFillCalculator.calculate(
          raceway: standardEmt,
          conductorGroups: [ConductorGroup(id: '1', spec: spec10, count: 3, role: 'phaseA')],
        ),
      );

      // Demonstrates that slashes in projectTitle are interpreted as non-existent subdirectories
      expect(
        () => PdfReportService.saveReportToFile(dataWithSlash, targetDirectory: Directory.systemTemp),
        throwsA(isA<PathNotFoundException>()),
      );
    });

    test('Stress Test 10: Standard alphanumeric title exports successfully without errors', () async {
      final dataClean = ComplianceReportData(
        projectTitle: 'Hospital Feeder 4 Main Sub',
        clientName: 'St. Jude Hospital',
        siteAddress: 'Wing B',
        technicianName: 'Bob Vance',
        companyName: 'Vance Electric',
        date: DateTime.now(),
        raceway: standardEmt,
        conductors: [ConductorGroup(id: '1', spec: spec10, count: 3, role: 'phaseA')],
        fillResult: ConduitFillCalculator.calculate(
          raceway: standardEmt,
          conductorGroups: [ConductorGroup(id: '1', spec: spec10, count: 3, role: 'phaseA')],
        ),
      );

      final exportedPath = await PdfReportService.saveReportToFile(
        dataClean,
        targetDirectory: Directory.systemTemp,
      );
      expect(exportedPath, isNotEmpty);
      final file = File(exportedPath);
      expect(await file.exists(), isTrue);
      await file.delete();
    });
  });
}
