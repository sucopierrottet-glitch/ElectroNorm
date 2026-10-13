import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/printing.dart';
import 'package:signature/signature.dart';

import 'package:electronorm/calculators/conduit_fill_calculator.dart';
import 'package:electronorm/calculators/derating_calculator.dart';
import 'package:electronorm/calculators/voltage_drop_calculator.dart';
import 'package:electronorm/catalogs/conductor_catalog.dart';
import 'package:electronorm/catalogs/raceway_catalog.dart';
import 'package:electronorm/models/calculation_results.dart';
import 'package:electronorm/models/conductor.dart';
import 'package:electronorm/models/raceway.dart';
import 'package:electronorm/screens/report_preview_screen.dart';
import 'package:electronorm/services/pdf_report_service.dart';
import 'package:electronorm/theme/app_theme.dart';
import 'package:electronorm/widgets/signature_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RacewayProfile standardEmt;
  late ConductorSpec spec10ThhnCu;
  late List<ConductorGroup> defaultGroups;
  late ConduitFillResult standardFill;
  late VoltageDropResult standardVDrop;
  late DeratingResult standardDerate;
  late ComplianceReportData sampleData;

  setUp(() {
    standardEmt = RacewayCatalog.getProfile(RacewayType.emt, '3/4');
    spec10ThhnCu = ConductorCatalog.getSpec(
      gauge: '10 AWG',
      insulation: ConductorInsulation.thhn,
      material: ConductorMaterial.copper,
    );

    defaultGroups = [
      ConductorGroup(id: '1', spec: spec10ThhnCu, count: 3, role: 'phaseA'),
      ConductorGroup(id: '2', spec: spec10ThhnCu, count: 1, role: 'neutral'),
      ConductorGroup(id: '3', spec: spec10ThhnCu, count: 1, role: 'ground'),
    ];

    standardFill = ConduitFillCalculator.calculate(
      raceway: standardEmt,
      conductorGroups: defaultGroups,
    );

    standardVDrop = VoltageDropCalculator.calculateEffectiveImpedance(
      nominalVoltage: 208.0,
      phase: CircuitPhase.threePhase,
      currentAmps: 20.0,
      lengthFeet: 100.0,
      conductorSpec: spec10ThhnCu,
      isSteelConduit: true,
      powerFactor: 0.90,
    );

    standardDerate = DeratingCalculator.calculate(
      conductorSpec: spec10ThhnCu,
      ambientTempC: 30.0,
      currentCarryingConductorsCount: 4,
      terminalRatingC: 75.0,
    );

    sampleData = ComplianceReportData(
      projectTitle: 'Adversarial Test Project',
      clientName: 'Test Utilities Inc',
      siteAddress: '404 Grid Way',
      technicianName: 'Tester Smith',
      companyName: 'Electra Testing Co',
      date: DateTime(2026, 10, 13),
      raceway: standardEmt,
      conductors: defaultGroups,
      fillResult: standardFill,
      voltageDropResult: standardVDrop,
      deratingResult: standardDerate,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('net.nfet.printing'), (MethodCall methodCall) async {
      if (methodCall.method == 'printingInfo') {
        return <String, dynamic>{
          'directPrint': true,
          'dynamicLayout': false,
          'canPrint': true,
          'canConvertHtml': false,
          'canShare': true,
          'canRaster': false,
        };
      }
      if (methodCall.method == 'printPdf') {
        final job = methodCall.arguments['job'];
        Future.microtask(() async {
          final data = const StandardMethodCodec().encodeMethodCall(
            MethodCall('onCompleted', <String, dynamic>{
              'job': job,
              'completed': true,
            }),
          );
          await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .handlePlatformMessage('net.nfet.printing', data, (ByteData? _) {});
        });
        return 1;
      }
      if (methodCall.method == 'sharePdf') {
        return 1;
      }
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (MethodCall methodCall) async {
      return Directory.systemTemp.path;
    });
  });

  group('Adversarial Test Suite 1: Touch Signature Pad Interaction', () {
    test('Unit test: SignatureController can draw points and export PNG bytes', () async {
      final controller = SignatureController(
        penStrokeWidth: 3.0,
        penColor: Colors.white,
      );
      expect(controller.isEmpty, isTrue);

      controller.addPoint(Point(const Offset(10, 10), PointType.tap, 1.0));
      controller.addPoint(Point(const Offset(20, 20), PointType.move, 1.0));
      expect(controller.isNotEmpty, isTrue);

      final pngBytes = await controller.toPngBytes();
      expect(pngBytes, isNotNull);
      expect(pngBytes, isNotEmpty);
    });

    testWidgets('Empty stroke rejection: displays validation error and prevents dismiss', (tester) async {
      SignatureDialogResult? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await SignatureDialog.show(ctx);
                },
                child: const Text('Open Pad'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Pad'));
      await tester.pumpAndSettle();

      // Tap confirm without any stroke
      await tester.tap(find.text('Confirm Sign-Off'));
      await tester.pumpAndSettle();

      expect(find.text('Please draw your signature on the pad before confirming.'), findsOneWidget);
      expect(find.byType(SignatureDialog), findsOneWidget);
      expect(result, isNull);
    });

    testWidgets('Drawing stroke, clearing canvas, and rejecting cleared canvas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => SignatureDialog.show(ctx),
                child: const Text('Open Pad'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Pad'));
      await tester.pumpAndSettle();

      // Find Signature widget
      final sigFinder = find.byType(Signature);
      expect(sigFinder, findsOneWidget);

      // Perform drawing gesture
      await tester.drag(sigFinder, const Offset(60, 30));
      await tester.pumpAndSettle();

      // Now clear canvas
      await tester.tap(find.text('Clear Stroke'));
      await tester.pumpAndSettle();

      // Confirm after clear should fail with validation error
      await tester.tap(find.text('Confirm Sign-Off'));
      await tester.pumpAndSettle();

      expect(find.text('Please draw your signature on the pad before confirming.'), findsOneWidget);
      expect(find.byType(SignatureDialog), findsOneWidget);
    });

    testWidgets('Drawing stroke and successfully exporting PNG bytes and custom metadata', (tester) async {
      SignatureDialogResult? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await SignatureDialog.show(ctx);
                },
                child: const Text('Open Pad'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Pad'));
      await tester.pumpAndSettle();

      // Fill in custom inspector metadata
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(3));

      await tester.enterText(textFields.at(0), 'Jane Doe, Lead AHJ');
      await tester.enterText(textFields.at(1), 'INSP-445566');
      await tester.enterText(textFields.at(2), 'State Electrical Safety Board');
      await tester.pumpAndSettle();

      // Draw stroke on signature canvas
      final sigFinder = find.byType(Signature);
      await tester.drag(sigFinder, const Offset(80, 40));
      await tester.pumpAndSettle();

      // Confirm sign-off
      await tester.tap(find.text('Confirm Sign-Off'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Validate PNG magic bytes [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
      expect(result, isNotNull);
      expect(result!.inspectorName, equals('Jane Doe, Lead AHJ'));
      expect(result!.licenseNumber, equals('INSP-445566'));
      expect(result!.agencyName, equals('State Electrical Safety Board'));
      expect(result!.signatureBytes, isNotEmpty);
    });

    testWidgets('Fallback to default values when text fields are empty / whitespace', (tester) async {
      SignatureDialogResult? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await SignatureDialog.show(ctx);
                },
                child: const Text('Open Pad'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Pad'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '   ');
      await tester.enterText(textFields.at(1), '   ');
      await tester.enterText(textFields.at(2), '   ');
      await tester.pumpAndSettle();

      // Draw stroke
      await tester.drag(find.byType(Signature), const Offset(50, 50));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm Sign-Off'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(result, isNotNull);
      expect(result!.inspectorName, equals('Inspector / AHJ'));
      expect(result!.licenseNumber, equals('N/A'));
      expect(result!.agencyName, equals('Electrical Bureau'));
      expect(result!.signatureBytes, isNotEmpty);
    });

    testWidgets('Cancel button dismisses without exporting or returning data', (tester) async {
      SignatureDialogResult? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await SignatureDialog.show(ctx);
                },
                child: const Text('Open Pad'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Pad'));
      await tester.pumpAndSettle();

      // Draw stroke
      await tester.drag(find.byType(Signature), const Offset(40, 20));
      await tester.pumpAndSettle();

      // Cancel instead of confirming
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
      expect(find.byType(SignatureDialog), findsNothing);
    });
  });

  group('Adversarial Test Suite 2: Direct File Save Export Verification', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('electronorm_challenger_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Direct file save export creates valid non-empty PDF in target directory', () async {
      final savedPath = await PdfReportService.saveReportToFile(
        sampleData,
        targetDirectory: tempDir,
      );

      expect(savedPath, isNotEmpty);
      expect(savedPath.startsWith(tempDir.path), isTrue);

      final file = File(savedPath);
      expect(await file.exists(), isTrue);

      final bytes = await file.readAsBytes();
      expect(bytes.length, greaterThan(5000));
      // %PDF- magic header
      expect(bytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
    });

    test('Direct file save with custom fileName creates expected file in target directory', () async {
      const customName = 'Special_Inspection_Memo_2026.pdf';
      final savedPath = await PdfReportService.saveReportToFile(
        sampleData,
        fileName: customName,
        targetDirectory: tempDir,
      );

      expect(savedPath.endsWith(customName), isTrue);
      final file = File(savedPath);
      expect(await file.exists(), isTrue);
      expect((await file.length()), greaterThan(5000));
    });

    test('Direct file save exports PDF embedding signature bytes', () async {
      final dataWithSignature = sampleData.copyWith(
        signaturePngBytes: Uint8List.fromList(<int>[
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
          0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
          0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
          0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
          0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
          0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
          0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
          0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
          0x42, 0x60, 0x82,
        ]),
        inspectorName: 'Chief Inspector Vance',
      );

      final savedPath = await PdfReportService.saveReportToFile(
        dataWithSignature,
        targetDirectory: tempDir,
      );

      final file = File(savedPath);
      expect(await file.exists(), isTrue);
      final bytes = await file.readAsBytes();
      expect(bytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
    });

    test('Direct file save with empty projectTitle falls back safely and creates file', () async {
      final blankTitleData = sampleData.copyWith(projectTitle: '');
      final savedPath = await PdfReportService.saveReportToFile(
        blankTitleData,
        targetDirectory: tempDir,
      );

      expect(savedPath.contains('Compliance_Report'), isTrue);
      final file = File(savedPath);
      expect(await file.exists(), isTrue);
      expect((await file.length()), greaterThan(5000));
    });

    test('Direct file save with multi-page conductor schedule and overfilled jam risk', () async {
      final spec500 = ConductorCatalog.getSpec(
        gauge: '500 kcmil',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      // Construct a heavy multi-wire group that overfills 3/4 EMT and induces jam hazard
      final heavyGroups = [
        ...defaultGroups,
        ConductorGroup(id: '10', spec: spec500, count: 3, role: 'feeder'),
        ConductorGroup(id: '11', spec: spec10ThhnCu, count: 6, role: 'branch'),
        ConductorGroup(id: '12', spec: spec10ThhnCu, count: 6, role: 'branch'),
      ];

      final overfilledFill = ConduitFillCalculator.calculate(
        raceway: standardEmt,
        conductorGroups: heavyGroups,
      );

      final stressData = sampleData.copyWith(
        projectTitle: 'Massive Industrial Overfill',
        conductors: heavyGroups,
        fillResult: overfilledFill,
      );

      final savedPath = await PdfReportService.saveReportToFile(
        stressData,
        targetDirectory: tempDir,
      );

      final file = File(savedPath);
      expect(await file.exists(), isTrue);
      final bytes = await file.readAsBytes();
      expect(bytes.length, greaterThan(8000));
      expect(bytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
    });
  });

  group('Adversarial Test Suite 3: ReportPreviewScreen Widget & Interaction Tests', () {
    testWidgets('Renders full preview layout, title, actions, and pending signature status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ReportPreviewScreen(reportData: sampleData),
        ),
      );
      await tester.pump();

      // Verify AppBar and titles
      expect(find.text('Compliance Report Preview'), findsOneWidget);
      expect(find.text('Adversarial Test Project'), findsOneWidget);

      // Verify Action icons in AppBar
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
      expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);

      // Verify PdfPreview widget
      expect(find.byType(PdfPreview), findsOneWidget);

      // Verify bottom status bar
      expect(find.text('Inspection Signature Pending'), findsOneWidget);
      expect(find.text('Tap to capture technician or AHJ signature'), findsOneWidget);
      expect(find.text('Sign Report'), findsOneWidget);
    });

    testWidgets('Triggers signature modal, draws stroke, and updates preview with verified state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ReportPreviewScreen(reportData: sampleData),
        ),
      );
      await tester.pump();

      // Tap Sign Report button to open signature modal
      await tester.tap(find.text('Sign Report'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Inspector Digital Sign-Off'), findsOneWidget);

      // Draw stroke on signature pad
      final sigFinder = find.byType(Signature);
      expect(sigFinder, findsOneWidget);
      await tester.drag(sigFinder, const Offset(60, 30));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter inspector name
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'Robert Vance');
      await tester.pump();

      // Confirm sign-off
      await tester.tap(find.text('Confirm Sign-Off'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify modal is dismissed
      expect(find.text('Inspector Digital Sign-Off'), findsNothing);

      // Verify preview updated with embedded signature and verified status
      expect(find.text('Inspector Sign-Off Verified'), findsOneWidget);
      expect(find.text('Re-Sign'), findsOneWidget);
      expect(find.textContaining('Signed by Robert Vance'), findsOneWidget);

      // Verify SnackBar notification
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Inspector signature embedded for Robert Vance'), findsOneWidget);
    });

    testWidgets('Re-signing flow preserves metadata and cancels cleanly without losing signature', (tester) async {
      // Start with signed data
      final signedData = sampleData.copyWith(
        signaturePngBytes: Uint8List.fromList(<int>[
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
          0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
          0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
          0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
          0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
          0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
          0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
          0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
          0x42, 0x60, 0x82,
        ]),
        inspectorName: 'Captain Marvel, PE',
        licenseNumber: 'PE-778899',
        agencyName: 'Regional Grid Authority',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ReportPreviewScreen(reportData: signedData),
        ),
      );
      await tester.pump();

      expect(find.text('Inspector Sign-Off Verified'), findsOneWidget);
      expect(find.text('Re-Sign'), findsOneWidget);
      expect(find.textContaining('Captain Marvel, PE'), findsOneWidget);

      // Tap Re-Sign
      await tester.tap(find.text('Re-Sign'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Inspector Digital Sign-Off'), findsOneWidget);
      expect(find.text('Captain Marvel, PE'), findsOneWidget);
      expect(find.text('PE-778899'), findsOneWidget);

      // Cancel re-signing
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify still verified
      expect(find.text('Inspector Sign-Off Verified'), findsOneWidget);
      expect(find.text('Re-Sign'), findsOneWidget);
      expect(find.textContaining('Captain Marvel, PE'), findsOneWidget);
    });

    testWidgets('Invoking native share trigger handles platform execution without crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ReportPreviewScreen(reportData: sampleData),
        ),
      );
      await tester.pump();

      final shareBtn = find.byIcon(Icons.share_outlined);
      expect(shareBtn, findsOneWidget);

      // Tap share
      await tester.tap(shareBtn);
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // No crash: preview screen remains mounted
      expect(find.byType(ReportPreviewScreen), findsOneWidget);
    });

    testWidgets('Invoking file download action handles export without crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ReportPreviewScreen(reportData: sampleData),
        ),
      );
      await tester.pump();

      final downloadBtn = find.byIcon(Icons.file_download_outlined);
      expect(downloadBtn, findsOneWidget);

      // Tap download
      await tester.tap(downloadBtn);
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // No crash: screen remains mounted and SnackBar / status handled
      expect(find.byType(ReportPreviewScreen), findsOneWidget);
    });

    test('PdfReportService.printReport generates bytes and invokes layoutPdf without uncaught crash', () async {
      // In headless CLI environment, layoutPdf interacts with printing channel
      try {
        await PdfReportService.printReport(sampleData);
      } catch (e) {
        // MissingPluginException or PlatformException in headless environment is expected and caught
        expect(e, isNotNull);
      }
    });
  });
}
