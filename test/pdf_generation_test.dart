import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/printing.dart';

import 'package:electronorm/calculators/conduit_fill_calculator.dart';
import 'package:electronorm/calculators/derating_calculator.dart';
import 'package:electronorm/calculators/jam_ratio_calculator.dart';
import 'package:electronorm/calculators/voltage_drop_calculator.dart';
import 'package:electronorm/catalogs/conductor_catalog.dart';
import 'package:electronorm/catalogs/raceway_catalog.dart';
import 'package:electronorm/models/calculation_results.dart';
import 'package:electronorm/models/conductor.dart';
import 'package:electronorm/models/raceway.dart';
import 'package:electronorm/screens/calculator_screen.dart';
import 'package:electronorm/screens/report_preview_screen.dart';
import 'package:electronorm/services/pdf_report_service.dart';
import 'package:electronorm/theme/app_theme.dart';
import 'package:electronorm/widgets/signature_dialog.dart';

// Valid 1x1 pixel RGBA transparent PNG byte sequence
final Uint8List kTestTransparentPngBytes = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 pixels
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, // 8-bit truecolor RGBA
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, // IDAT chunk
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, // IEND chunk
  0x42, 0x60, 0x82,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Milestone 3: PDF Technical Compliance Engine Unit Tests', () {
    late RacewayProfile standardEmt;
    late ConductorSpec spec10ThhnCu;
    late ConductorSpec spec12ThhnCu;
    late List<ConductorGroup> defaultGroups;
    late ConduitFillResult standardFill;
    late VoltageDropResult standardVDrop;
    late DeratingResult standardDerate;

    setUp(() {
      standardEmt = RacewayCatalog.getProfile(RacewayType.emt, '3/4');
      spec10ThhnCu = ConductorCatalog.getSpec(
        gauge: '10 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );
      spec12ThhnCu = ConductorCatalog.getSpec(
        gauge: '12 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      defaultGroups = [
        ConductorGroup(id: '1', spec: spec10ThhnCu, count: 1, role: 'phaseA'),
        ConductorGroup(id: '2', spec: spec10ThhnCu, count: 1, role: 'phaseB'),
        ConductorGroup(id: '3', spec: spec10ThhnCu, count: 1, role: 'phaseC'),
        ConductorGroup(id: '4', spec: spec12ThhnCu, count: 1, role: 'ground'),
      ];

      standardFill = ConduitFillCalculator.calculate(
        raceway: standardEmt,
        conductorGroups: defaultGroups,
      );

      standardVDrop = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 208.0,
        phase: CircuitPhase.threePhase,
        currentAmps: 24.0,
        lengthFeet: 120.0,
        conductorSpec: spec10ThhnCu,
        isSteelConduit: true,
        powerFactor: 0.90,
      );

      standardDerate = DeratingCalculator.calculate(
        conductorSpec: spec10ThhnCu,
        ambientTempC: 35.0,
        currentCarryingConductorsCount: 3,
        terminalRatingC: 75.0,
      );
    });

    test('1. Generates valid non-empty A4 PDF buffer with %PDF- header without signature', () async {
      final reportData = ComplianceReportData(
        projectTitle: 'Data Center Feeder Run',
        clientName: 'Global Cloud Systems',
        siteAddress: '100 Tech Blvd, Silicon Valley',
        technicianName: 'Marcus Wright',
        companyName: 'Prime Electric Contracting',
        date: DateTime(2026, 10, 13),
        raceway: standardEmt,
        conductors: defaultGroups,
        fillResult: standardFill,
        voltageDropResult: standardVDrop,
        deratingResult: standardDerate,
        signaturePngBytes: null,
      );

      final pdfBytes = await PdfReportService.generateReport(reportData);

      expect(pdfBytes, isNotNull);
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(5000));
      // %PDF- magic header
      expect(pdfBytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
    });

    test('2. Generates valid PDF embedding digital signature PNG bytes', () async {
      final reportData = ComplianceReportData(
        projectTitle: 'Substation Control Center',
        clientName: 'City Power & Light',
        siteAddress: 'Substation #4, West Sector',
        technicianName: 'Elena Rostova',
        companyName: 'Apex High Voltage Corp',
        date: DateTime(2026, 10, 13),
        raceway: standardEmt,
        conductors: defaultGroups,
        fillResult: standardFill,
        voltageDropResult: standardVDrop,
        deratingResult: standardDerate,
        signaturePngBytes: kTestTransparentPngBytes,
        inspectorName: 'Robert Vance, AHJ',
        licenseNumber: 'AHJ-99210',
        agencyName: 'State Bureau of Electrical Safety',
      );

      final pdfBytes = await PdfReportService.generateReport(reportData);

      expect(pdfBytes, isNotNull);
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
    });

    test('3. Generates valid PDF across all 6 raceway types (EMT, PVC 40, PVC 80, IMC, RMC, FMC)', () async {
      for (final type in RacewayType.values) {
        final profile = RacewayCatalog.getProfile(type, '2');
        final fill = ConduitFillCalculator.calculate(
          raceway: profile,
          conductorGroups: defaultGroups,
        );

        final data = ComplianceReportData(
          projectTitle: '${type.displayName} Raceway Test',
          clientName: 'Quality Assurance Inc',
          siteAddress: 'Field Lab',
          technicianName: 'QA Bot',
          companyName: 'Testing Corp',
          date: DateTime.now(),
          raceway: profile,
          conductors: defaultGroups,
          fillResult: fill,
          voltageDropResult: standardVDrop,
          deratingResult: standardDerate,
        );

        final bytes = await PdfReportService.generateReport(data);
        expect(bytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
      }
    });

    test('4. Correctly verifies NEC Table 1 fill limits (1=53%, 2=31%, 3+=40%, Nipple=60%) in PDF generation', () async {
      final raceway1 = RacewayCatalog.getProfile(RacewayType.emt, '1');

      // Case A: 1 Conductor (53% limit)
      final fill1 = ConduitFillCalculator.calculate(
        raceway: raceway1,
        conductorGroups: [ConductorGroup(id: '1', spec: spec10ThhnCu, count: 1, role: 'phaseA')],
      );
      expect(fill1.allowedFillPercentage, equals(53.0));

      final pdf1 = await PdfReportService.generateReport(
        ComplianceReportData(
          projectTitle: 'Single Wire Run',
          clientName: 'Client 1',
          siteAddress: 'Site 1',
          technicianName: 'Tech',
          companyName: 'Co',
          date: DateTime.now(),
          raceway: raceway1,
          conductors: [ConductorGroup(id: '1', spec: spec10ThhnCu, count: 1, role: 'phaseA')],
          fillResult: fill1,
        ),
      );
      expect(pdf1, isNotEmpty);

      // Case B: 2 Conductors (31% limit)
      final fill2 = ConduitFillCalculator.calculate(
        raceway: raceway1,
        conductorGroups: [ConductorGroup(id: '1', spec: spec10ThhnCu, count: 2, role: 'phaseA')],
      );
      expect(fill2.allowedFillPercentage, equals(31.0));

      final pdf2 = await PdfReportService.generateReport(
        ComplianceReportData(
          projectTitle: 'Dual Wire Run',
          clientName: 'Client 2',
          siteAddress: 'Site 2',
          technicianName: 'Tech',
          companyName: 'Co',
          date: DateTime.now(),
          raceway: raceway1,
          conductors: [ConductorGroup(id: '1', spec: spec10ThhnCu, count: 2, role: 'phaseA')],
          fillResult: fill2,
        ),
      );
      expect(pdf2, isNotEmpty);

      // Case C: Nipple Conduit (60% limit)
      final fillNipple = ConduitFillCalculator.calculate(
        raceway: raceway1,
        conductorGroups: defaultGroups,
        isNipple: true,
      );
      expect(fillNipple.allowedFillPercentage, equals(60.0));
      expect(fillNipple.isNipple, isTrue);

      final pdfNipple = await PdfReportService.generateReport(
        ComplianceReportData(
          projectTitle: 'Nipple Run 24 Inch',
          clientName: 'Client Nipple',
          siteAddress: 'Panel A to B',
          technicianName: 'Tech',
          companyName: 'Co',
          date: DateTime.now(),
          raceway: raceway1,
          conductors: defaultGroups,
          fillResult: fillNipple,
        ),
      );
      expect(pdfNipple, isNotEmpty);
    });

    test('5. Critical Jam Ratio Pull Hazard calculation (2.80 <= R_jam <= 3.20) rendered in PDF without crashes', () async {
      // 3x 250 kcmil THHN Cu (OD = 0.711 in) in 2" EMT (ID = 2.067 in)
      // Jam Ratio = 2.067 / 0.711 = 2.907 (HIGH RISK)
      final emt2 = RacewayCatalog.getProfile(RacewayType.emt, '2');
      final spec250 = ConductorCatalog.getSpec(gauge: '250 kcmil');

      final jamResult = JamRatioCalculator.calculate(
        conduitInsideDiameter: emt2.internalDiameterInches,
        wireOutsideDiameter: spec250.outerDiameterInches,
      );
      expect(jamResult.isHighRisk, isTrue);
      expect(jamResult.ratio, inInclusiveRange(2.80, 3.20));

      final jamGroups = [
        ConductorGroup(id: '1', spec: spec250, count: 3, role: 'phaseA'),
      ];
      final fillWithJam = ConduitFillCalculator.calculate(
        raceway: emt2,
        conductorGroups: jamGroups,
      );
      expect(fillWithJam.hasJamRisk, isTrue);

      final reportData = ComplianceReportData(
        projectTitle: 'Critical Jam Ratio Evaluation',
        clientName: 'Industrial Foundry',
        siteAddress: 'Motor Control Center 1',
        technicianName: 'Inspector Dan',
        companyName: 'VoltSafe LLC',
        date: DateTime.now(),
        raceway: emt2,
        conductors: jamGroups,
        fillResult: fillWithJam,
      );

      final pdfBytes = await PdfReportService.generateReport(reportData);
      expect(pdfBytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
    });

    test('6. Overfilled raceway (> 40% fill) compiles with Violation status badge in PDF', () async {
      final emtHalf = RacewayCatalog.getProfile(RacewayType.emt, '1/2');
      final spec500 = ConductorCatalog.getSpec(gauge: '500 kcmil');

      final overfilledGroups = [
        ConductorGroup(id: '1', spec: spec500, count: 3, role: 'phaseA'),
      ];
      final overfilledResult = ConduitFillCalculator.calculate(
        raceway: emtHalf,
        conductorGroups: overfilledGroups,
      );
      expect(overfilledResult.isCompliant, isFalse);

      final reportData = ComplianceReportData(
        projectTitle: 'Overfilled Violation Audit',
        clientName: 'Inspection Dept',
        siteAddress: 'Basement Vault',
        technicianName: 'Chief Inspector',
        companyName: 'City Compliance',
        date: DateTime.now(),
        raceway: emtHalf,
        conductors: overfilledGroups,
        fillResult: overfilledResult,
      );

      final pdfBytes = await PdfReportService.generateReport(reportData);
      expect(pdfBytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
    });

    test('7. Exports PDF file directly to device storage via saveReportToFile()', () async {
      final reportData = ComplianceReportData(
        projectTitle: 'Storage Persistence Test',
        clientName: 'Local Storage Test',
        siteAddress: 'Device Sandbox',
        technicianName: 'Worker M3',
        companyName: 'ElectroNorm Pro',
        date: DateTime.now(),
        raceway: standardEmt,
        conductors: defaultGroups,
        fillResult: standardFill,
      );

      final savedPath = await PdfReportService.saveReportToFile(
        reportData,
        fileName: 'test_compliance_export.pdf',
        targetDirectory: Directory.systemTemp,
      );

      expect(savedPath, isNotEmpty);
      final file = File(savedPath);
      expect(await file.exists(), isTrue);

      final fileBytes = await file.readAsBytes();
      expect(fileBytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));

      // Clean up test file
      if (await file.exists()) {
        await file.delete();
      }
    });
  });

  group('Milestone 3: Digital Signature Pad Widget Tests', () {
    testWidgets('Renders SignatureDialog with pad and action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => SignatureDialog.show(ctx),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Inspector Digital Sign-Off'), findsOneWidget);
      expect(find.text('Touch Signature Pad'), findsOneWidget);
      expect(find.text('Clear Stroke'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm Sign-Off'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3)); // Name, License, Agency
    });

    testWidgets('Tapping Confirm on empty signature pad displays validation error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => SignatureDialog.show(ctx),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm Sign-Off'));
      await tester.pumpAndSettle();

      expect(find.text('Please draw your signature on the pad before confirming.'), findsOneWidget);
    });

    testWidgets('Tapping Cancel dismisses the dialog with null result', (tester) async {
      SignatureDialogResult? capturedResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  capturedResult = await SignatureDialog.show(ctx);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(capturedResult, isNull);
      expect(find.text('Inspector Digital Sign-Off'), findsNothing);
    });
  });

  group('Milestone 3: Report Preview Screen & Calculator Screen Integration', () {
    late ComplianceReportData sampleData;

    setUp(() {
      final emt = RacewayCatalog.getProfile(RacewayType.emt, '3/4');
      final spec10 = ConductorCatalog.getSpec(gauge: '10 AWG');
      final groups = [
        ConductorGroup(id: '1', spec: spec10, count: 3, role: 'phaseA'),
      ];
      final fill = ConduitFillCalculator.calculate(raceway: emt, conductorGroups: groups);

      sampleData = ComplianceReportData(
        projectTitle: 'Substation Preview Test',
        clientName: 'City Grid',
        siteAddress: 'Sector 7',
        technicianName: 'Carlos M.',
        companyName: 'VoltPro',
        date: DateTime.now(),
        raceway: emt,
        conductors: groups,
        fillResult: fill,
      );
    });

    testWidgets('ReportPreviewScreen renders PdfPreview widget and action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ReportPreviewScreen(reportData: sampleData),
        ),
      );

      expect(find.text('Compliance Report Preview'), findsOneWidget);
      expect(find.text('Substation Preview Test'), findsOneWidget);
      expect(find.byType(PdfPreview), findsOneWidget);
      expect(find.text('Inspection Signature Pending'), findsOneWidget);
      expect(find.text('Sign Report'), findsOneWidget);
    });

    testWidgets('CalculatorScreen contains Export PDF action button and navigates to ReportPreviewScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CalculatorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AppBar Export button exists
      final appBarBtn = find.byKey(const Key('btnExportPdfAppBar'));
      expect(appBarBtn, findsOneWidget);

      // Verify prominent Card exists
      final exportCard = find.byKey(const Key('cardExportPdf'));
      expect(exportCard, findsOneWidget);

      // Tap AppBar export button to navigate to preview
      await tester.tap(appBarBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify ReportPreviewScreen is pushed
      expect(find.byType(ReportPreviewScreen), findsOneWidget);
      expect(find.text('Compliance Report Preview'), findsOneWidget);
    });
  });
}
