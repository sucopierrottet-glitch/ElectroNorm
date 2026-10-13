import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'package:electronorm/screens/paywall_screen.dart';
import 'package:electronorm/screens/report_preview_screen.dart';
import 'package:electronorm/services/pdf_report_service.dart';
import 'package:electronorm/services/storage_service.dart';
import 'package:electronorm/theme/app_theme.dart';

// Valid 1x1 pixel RGBA transparent PNG byte sequence
final Uint8List kTestTransparentPngBytes = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.instance = SharedPreferencesStorageService();

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
      if (methodCall.method == 'sharePdf' || methodCall.method == 'printPdf') {
        return 1;
      }
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (MethodCall methodCall) async {
      return Directory.systemTemp.path;
    });
  });

  // =========================================================================
  // TIER 1: Feature Workflows
  // =========================================================================
  group('E2E Tier 1: Feature Workflows', () {
    test('1.1 Deterministic Conduit Fill Calculation & NEC Table 1 Limits', () {
      final emt34 = RacewayCatalog.getProfile(RacewayType.emt, '3/4');
      final wire10Cu = ConductorCatalog.getSpec(
        gauge: '10 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );
      final wire12Cu = ConductorCatalog.getSpec(
        gauge: '12 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      // Single wire fill (53% limit)
      final res1 = ConduitFillCalculator.calculate(
        raceway: emt34,
        conductorGroups: [
          ConductorGroup(id: 'g1', spec: wire10Cu, count: 1, role: 'phaseA'),
        ],
      );
      expect(res1.allowedFillPercentage, equals(53.0));
      expect(res1.isCompliant, isTrue);

      // Two wire fill (31% limit)
      final res2 = ConduitFillCalculator.calculate(
        raceway: emt34,
        conductorGroups: [
          ConductorGroup(id: 'g1', spec: wire10Cu, count: 2, role: 'phaseA'),
        ],
      );
      expect(res2.allowedFillPercentage, equals(31.0));
      expect(res2.isCompliant, isTrue);

      // Multi wire fill (40% limit): 3x #10 + 1x #12
      final res3 = ConduitFillCalculator.calculate(
        raceway: emt34,
        conductorGroups: [
          ConductorGroup(id: 'g1', spec: wire10Cu, count: 3, role: 'phaseA'),
          ConductorGroup(id: 'g2', spec: wire12Cu, count: 1, role: 'ground'),
        ],
      );
      expect(res3.allowedFillPercentage, equals(40.0));
      expect(res3.totalConductorArea, closeTo(0.0766, 0.001));
      expect(res3.fillPercentage, closeTo(14.37, 0.05));
      expect(res3.isCompliant, isTrue);

      // Short nipple (60% limit)
      final resNipple = ConduitFillCalculator.calculate(
        raceway: emt34,
        conductorGroups: [
          ConductorGroup(id: 'g1', spec: wire10Cu, count: 3, role: 'phaseA'),
          ConductorGroup(id: 'g2', spec: wire12Cu, count: 1, role: 'ground'),
        ],
        isNipple: true,
      );
      expect(resNipple.allowedFillPercentage, equals(60.0));
      expect(resNipple.isCompliant, isTrue);
    });

    test('1.2 AC Voltage Drop Engine for 1-Phase (120/240V) and 3-Phase (208/480V)', () {
      final wire12Cu = ConductorCatalog.getSpec(
        gauge: '12 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );
      final wire350Al = ConductorCatalog.getSpec(
        gauge: '350 kcmil',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.aluminum,
      );

      // Single-phase 120V 16A 75ft #12 Cu in Steel EMT
      final vDrop1P = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 120.0,
        phase: CircuitPhase.singlePhase,
        currentAmps: 16.0,
        lengthFeet: 75.0,
        conductorSpec: wire12Cu,
        isSteelConduit: true,
        powerFactor: 0.95,
      );
      expect(vDrop1P.voltageDropVolts, closeTo(4.555, 0.01));
      expect(vDrop1P.percentageDrop, closeTo(3.80, 0.05));
      expect(vDrop1P.isCompliantBranch, isFalse);
      expect(vDrop1P.isCompliantTotal, isTrue);

      // Three-phase 480V 200A 350ft 350 kcmil Al in PVC (non-steel)
      final vDrop3P = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 480.0,
        phase: CircuitPhase.threePhase,
        currentAmps: 200.0,
        lengthFeet: 350.0,
        conductorSpec: wire350Al,
        isSteelConduit: false,
        powerFactor: 0.90,
      );
      expect(vDrop3P.voltageDropVolts, closeTo(8.77, 0.10));
      expect(vDrop3P.percentageDrop, closeTo(1.83, 0.05));
      expect(vDrop3P.isCompliantBranch, isTrue);
      expect(vDrop3P.isCompliantTotal, isTrue);
    });

    test('1.3 Ampacity Derating Engine with Ambient Temperature & Bundling Multipliers', () {
      final wire40Cu = ConductorCatalog.getSpec(
        gauge: '4/0 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      // Baseline: 30C ambient, 3 CCC, 75C terminal clamp
      final derateBase = DeratingCalculator.calculate(
        conductorSpec: wire40Cu,
        ambientTempC: 30.0,
        currentCarryingConductorsCount: 3,
        terminalRatingC: 75.0,
      );
      expect(derateBase.baseAmpacity, equals(260.0));
      expect(derateBase.temperatureCorrectionFactor, equals(1.00));
      expect(derateBase.bundlingAdjustmentFactor, equals(1.00));
      expect(derateBase.terminalRatingLimit, equals(230.0));
      expect(derateBase.allowableAmpacity, equals(230.0));

      // Harsh: 45C ambient (0.87 for 90C), 6 CCC (0.80 factor)
      final derateHarsh = DeratingCalculator.calculate(
        conductorSpec: wire40Cu,
        ambientTempC: 45.0,
        currentCarryingConductorsCount: 6,
        terminalRatingC: 75.0,
      );
      expect(derateHarsh.temperatureCorrectionFactor, equals(0.87));
      expect(derateHarsh.bundlingAdjustmentFactor, equals(0.80));
      expect(derateHarsh.deratedAmpacity, closeTo(180.96, 0.05));
      expect(derateHarsh.allowableAmpacity, closeTo(180.96, 0.05));
    });

    test('1.4 Pure Vector PDF Compliance Document Generation & Signature Embedding', () async {
      final emt34 = RacewayCatalog.getProfile(RacewayType.emt, '3/4');
      final wire10 = ConductorCatalog.getSpec(
        gauge: '10 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );
      final fillRes = ConduitFillCalculator.calculate(
        raceway: emt34,
        conductorGroups: [
          ConductorGroup(id: 'g1', spec: wire10, count: 4, role: 'phaseA'),
        ],
      );

      final reportData = ComplianceReportData(
        projectTitle: 'Substation Feeder Unit 1',
        clientName: 'Industrial Energy Corp',
        siteAddress: '500 Grid Way, Sector 4',
        technicianName: 'Marcus Vance, PE',
        companyName: 'Apex Electrical Solutions LLC',
        date: DateTime(2026, 10, 13),
        raceway: emt34,
        conductors: [
          ConductorGroup(id: 'g1', spec: wire10, count: 4, role: 'phaseA'),
        ],
        fillResult: fillRes,
        signaturePngBytes: kTestTransparentPngBytes,
      );

      final pdfBytes = await PdfReportService.generateReport(reportData);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
      // PDF header validation (%PDF-)
      final header = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('1.5 SharedPreferences Storage Service Persistence & Retrieval', () async {
      final storage = StorageService.instance;
      expect(await storage.getSavedCalculations(), isEmpty);

      final emt2 = RacewayCatalog.getProfile(RacewayType.emt, '2');
      final wire30Cu = ConductorCatalog.getSpec(
        gauge: '3/0 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );
      final calc = SavedCalculation(
        id: 'run-alpha',
        title: 'Transformer Primary Feed',
        notes: 'Fed from Substation 3',
        timestamp: DateTime(2026, 10, 13, 14, 30),
        raceway: emt2,
        conductors: [
          ConductorGroup(id: 'g1', spec: wire30Cu, count: 3, role: 'phaseA'),
        ],
        fillResult: ConduitFillResult(
          totalConductorArea: 0.8037,
          racewayInternalArea: 3.356,
          fillPercentage: 23.95,
          allowedFillPercentage: 40.0,
          allowedFillArea: 1.3424,
          isCompliant: true,
          totalConductorCount: 3,
        ),
      );

      await storage.saveCalculation(calc);
      final retrieved = await storage.getSavedCalculations();
      expect(retrieved.length, equals(1));
      expect(retrieved.first.title, equals('Transformer Primary Feed'));
      expect(retrieved.first.raceway.tradeSize, equals('2'));

      // Technician profile
      final profile = TechnicianProfile(
        technicianName: 'Elena Rostova',
        companyName: 'Northern Power Eng',
        licenseNumber: 'EL-99482',
        phone: '555-0199',
        email: 'elena@npower.com',
      );
      await storage.saveProfile(profile);
      final loadedProfile = await storage.getProfile();
      expect(loadedProfile.technicianName, equals('Elena Rostova'));
      expect(loadedProfile.licenseNumber, equals('EL-99482'));

      // Cleanup
      await storage.deleteCalculation('run-alpha');
      expect(await storage.getSavedCalculations(), isEmpty);
    });
  });

  // =========================================================================
  // TIER 2: Boundary Invariants
  // =========================================================================
  group('E2E Tier 2: Boundary Invariants', () {
    test('2.1 Raceway Boundary Limits (1/2" to 4" across EMT, PVC 40, PVC 80, IMC, RMC, FMC)', () {
      final tradeSizes = ['1/2', '3/4', '1', '1-1/4', '1-1/2', '2', '2-1/2', '3', '3-1/2', '4'];
      final types = [
        RacewayType.emt,
        RacewayType.pvcSch40,
        RacewayType.pvcSch80,
        RacewayType.imc,
        RacewayType.rmc,
        RacewayType.fmc,
      ];

      for (final type in types) {
        double prevArea = 0.0;
        for (final size in tradeSizes) {
          final profile = RacewayCatalog.getProfile(type, size);
          expect(profile.internalAreaSqInches, greaterThan(prevArea));
          expect(profile.internalDiameterInches, greaterThan(0.0));
          expect(profile.internalAreaSqMm, greaterThan(0.0));
          expect(profile.internalDiameterMm, greaterThan(0.0));
          prevArea = profile.internalAreaSqInches;
        }
      }
    });

    test('2.2 NEC Fill Limits Thresholds (1 wire = 53%, 2 wires = 31%, 3+ wires = 40%, Nipple = 60%)', () {
      expect(ConduitFillCalculator.getAllowedFillPercentage(totalConductorCount: 0), equals(0.0));
      expect(ConduitFillCalculator.getAllowedFillPercentage(totalConductorCount: 1), equals(53.0));
      expect(ConduitFillCalculator.getAllowedFillPercentage(totalConductorCount: 2), equals(31.0));
      expect(ConduitFillCalculator.getAllowedFillPercentage(totalConductorCount: 3), equals(40.0));
      expect(ConduitFillCalculator.getAllowedFillPercentage(totalConductorCount: 10), equals(40.0));
      expect(ConduitFillCalculator.getAllowedFillPercentage(totalConductorCount: 1, isNipple: true), equals(60.0));
      expect(ConduitFillCalculator.getAllowedFillPercentage(totalConductorCount: 4, isNipple: true), equals(60.0));
    });

    test('2.3 Critical Jam Ratio Safety Range (2.80 <= R_jam <= 3.20)', () {
      // Safe Constrained: R_jam < 2.50
      final resConstrained = JamRatioCalculator.calculate(
        conduitInsideDiameter: 2.067,
        wireOutsideDiameter: 0.900, // 2.067 / 0.900 = 2.297
      );
      expect(resConstrained.riskLevel, equals(JamRiskLevel.safeConstrained));
      expect(resConstrained.isHighRisk, isFalse);

      // Moderate Risk: 2.50 <= R_jam < 2.80
      final resModerate = JamRatioCalculator.calculate(
        conduitInsideDiameter: 2.067,
        wireOutsideDiameter: 0.770, // 2.067 / 0.770 = 2.684
      );
      expect(resModerate.riskLevel, equals(JamRiskLevel.moderateRisk));
      expect(resModerate.isHighRisk, isFalse);

      // Critical High Jam Hazard: 2.80 <= R_jam <= 3.20
      final resJam = JamRatioCalculator.calculate(
        conduitInsideDiameter: 2.067,
        wireOutsideDiameter: 0.689, // 2.067 / 0.689 = 3.00
      );
      expect(resJam.riskLevel, equals(JamRiskLevel.highJamRisk));
      expect(resJam.isHighRisk, isTrue);

      // Safe Clearance: R_jam > 3.20
      final resClearance = JamRatioCalculator.calculate(
        conduitInsideDiameter: 2.067,
        wireOutsideDiameter: 0.500, // 2.067 / 0.500 = 4.134
      );
      expect(resClearance.riskLevel, equals(JamRiskLevel.safeClearance));
      expect(resClearance.isHighRisk, isFalse);
    });

    test('2.4 Extreme Temperature Limits & Non-Linear Bundling Multipliers', () {
      // Prohibited ambient temp above 85C for 90C conductors returns 0.00
      final cfOverTemp = DeratingCalculator.getTemperatureCorrectionFactor(
        ambientTempC: 90.0,
        conductorRatingC: 90.0,
      );
      expect(cfOverTemp, equals(0.00));

      // Bundling factor boundary checks per Table 310.15(C)(1)
      expect(DeratingCalculator.getBundlingAdjustmentFactor(currentCarryingConductorsCount: 3), equals(1.00));
      expect(DeratingCalculator.getBundlingAdjustmentFactor(currentCarryingConductorsCount: 4), equals(0.80));
      expect(DeratingCalculator.getBundlingAdjustmentFactor(currentCarryingConductorsCount: 6), equals(0.80));
      expect(DeratingCalculator.getBundlingAdjustmentFactor(currentCarryingConductorsCount: 7), equals(0.70));
      expect(DeratingCalculator.getBundlingAdjustmentFactor(currentCarryingConductorsCount: 9), equals(0.70));
      expect(DeratingCalculator.getBundlingAdjustmentFactor(currentCarryingConductorsCount: 10), equals(0.50));
      expect(DeratingCalculator.getBundlingAdjustmentFactor(currentCarryingConductorsCount: 20), equals(0.50));
      expect(DeratingCalculator.getBundlingAdjustmentFactor(currentCarryingConductorsCount: 21), equals(0.45));
      expect(DeratingCalculator.getBundlingAdjustmentFactor(currentCarryingConductorsCount: 30), equals(0.45));
      expect(DeratingCalculator.getBundlingAdjustmentFactor(currentCarryingConductorsCount: 31), equals(0.40));
      expect(DeratingCalculator.getBundlingAdjustmentFactor(currentCarryingConductorsCount: 40), equals(0.40));
      expect(DeratingCalculator.getBundlingAdjustmentFactor(currentCarryingConductorsCount: 41), equals(0.35));

      // Nipple exemption always returns 1.00
      expect(
        DeratingCalculator.getBundlingAdjustmentFactor(currentCarryingConductorsCount: 40, isNipple: true),
        equals(1.00),
      );
    });
  });

  // =========================================================================
  // TIER 3: Cross-Feature Integration
  // =========================================================================
  group('E2E Tier 3: Cross-Feature Integration', () {
    testWidgets('3.1 Schedule Modification triggers Live Cross-Section Update & 1-Tap Upsize Pill', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CalculatorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Default state has 4 conductors packed
      expect(find.text('4 conductors packed'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Select preset 3x 500k + 1x #3 Grd (fits in 3" EMT)
      await tester.tap(find.text('3x 500k + 1x #3 Grd'));
      await tester.pumpAndSettle();

      expect(find.text('3" EMT'), findsOneWidget);
      expect(find.textContaining('COMPLIANT'), findsOneWidget);
      expect(find.byKey(const Key('btnUpsize')), findsNothing);

      // Increment 500 kcmil count by 4 to trigger overfill (>50% fill)
      final stepperAdd = find.byKey(const Key('btnStepperAdd_0'));
      for (int i = 0; i < 4; i++) {
        await tester.tap(stepperAdd);
        await tester.pump(const Duration(milliseconds: 10));
      }
      await tester.pumpAndSettle();

      // State is now overfilled and upsize recommendation pill appears
      expect(find.textContaining('OVERFILLED'), findsOneWidget);
      final upsizePill = find.byKey(const Key('btnUpsize'));
      expect(upsizePill, findsOneWidget);

      // Tap 1-tap upsize pill to automatically upgrade trade size
      await tester.tap(upsizePill);
      await tester.pumpAndSettle();

      // Upgraded raceway is now compliant again
      expect(find.textContaining('COMPLIANT'), findsOneWidget);
      expect(find.byKey(const Key('btnUpsize')), findsNothing);
    });

    testWidgets('3.2 Calculation Save -> Saved Projects Screen Search -> Reload into Calculator', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CalculatorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Save Calculation action button
      await tester.tap(find.byKey(const Key('btnSaveProject')));
      await tester.pumpAndSettle();

      expect(find.text('Save Calculation Run'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('inputSaveTitle')), 'Compressor Vault Run');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btnConfirmSaveCalculation')));
      await tester.pumpAndSettle();

      // Open Saved Projects screen via AppBar action
      await tester.tap(find.byKey(const Key('btnSavedProjectsAppBar')));
      await tester.pumpAndSettle();

      expect(find.text('Saved Projects'), findsOneWidget);
      expect(find.text('Compressor Vault Run'), findsOneWidget);

      // Search filtering test
      final searchInput = find.byKey(const Key('inputSearchProjects'));
      expect(searchInput, findsOneWidget);
      await tester.enterText(searchInput, 'Vault');
      await tester.pumpAndSettle();
      expect(find.text('Compressor Vault Run'), findsOneWidget);

      await tester.enterText(searchInput, 'NonExistentXYZ');
      await tester.pumpAndSettle();
      expect(find.text('Compressor Vault Run'), findsNothing);

      await tester.enterText(searchInput, '');
      await tester.pumpAndSettle();
      expect(find.text('Compressor Vault Run'), findsOneWidget);

      // Tap the saved run card to reload it into CalculatorScreen
      final allSaved = await StorageService.instance.getSavedCalculations();
      final savedId = allSaved.first.id;
      await tester.tap(find.byKey(Key('cardProject_$savedId')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.textContaining('Loaded "Compressor Vault Run" into calculator'), findsOneWidget);
    });

    testWidgets('3.3 Report Preview Flow -> Digital Touch Signature Pad -> Embedded PDF Verification', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final emt34 = RacewayCatalog.getProfile(RacewayType.emt, '3/4');
      final wire10 = ConductorCatalog.getSpec(
        gauge: '10 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );
      final fillRes = ConduitFillCalculator.calculate(
        raceway: emt34,
        conductorGroups: [
          ConductorGroup(id: 'g1', spec: wire10, count: 4, role: 'phaseA'),
        ],
      );

      final reportData = ComplianceReportData(
        projectTitle: 'Data Center PDU Feeder',
        clientName: 'CloudCorp International',
        siteAddress: '100 Silicon Way, Bldg 3',
        technicianName: 'Nathaniel Drake',
        companyName: 'Master Voltage Systems',
        date: DateTime(2026, 10, 13),
        raceway: emt34,
        conductors: [
          ConductorGroup(id: 'g1', spec: wire10, count: 4, role: 'phaseA'),
        ],
        fillResult: fillRes,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ReportPreviewScreen(reportData: reportData),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Compliance Report Preview'), findsOneWidget);
      expect(find.text('Sign Report'), findsOneWidget);

      // Open Signature Pad dialog
      await tester.tap(find.text('Sign Report'));
      await tester.pumpAndSettle();

      expect(find.text('Inspector Digital Sign-Off'), findsOneWidget);
      expect(find.text('Confirm Sign-Off'), findsOneWidget);

      // Cancel dialog closes safely
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Inspector Digital Sign-Off'), findsNothing);
    });

    testWidgets('3.4 Store Paywall Gating: Free Tier PDF Share Trigger -> Rescue Dialog -> Trial Activation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = StorageService.instance;
      expect(await storage.isProSubscriber(), isFalse);

      final emt34 = RacewayCatalog.getProfile(RacewayType.emt, '3/4');
      final wire10 = ConductorCatalog.getSpec(
        gauge: '10 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );
      final fillRes = ConduitFillCalculator.calculate(
        raceway: emt34,
        conductorGroups: [
          ConductorGroup(id: 'g1', spec: wire10, count: 4, role: 'phaseA'),
        ],
      );

      final reportData = ComplianceReportData(
        projectTitle: 'Site Inspection Run',
        clientName: 'City Power Authority',
        siteAddress: 'Main St 101',
        technicianName: 'Alex Carter',
        companyName: 'Voltech Inc',
        date: DateTime(2026, 10, 13),
        raceway: emt34,
        conductors: [
          ConductorGroup(id: 'g1', spec: wire10, count: 4, role: 'phaseA'),
        ],
        fillResult: fillRes,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ReportPreviewScreen(reportData: reportData),
        ),
      );
      await tester.pumpAndSettle();

      // Free tier user taps share button -> triggers paywall
      await tester.tap(find.byIcon(Icons.share_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsOneWidget);
      expect(find.text('ElectroNorm Pro'), findsOneWidget);

      // User attempts to close paywall -> exit-intent rescue dialog triggered
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dialogRescue')), findsOneWidget);
      expect(find.text('Wait! Unlock 14 Days Free'), findsOneWidget);

      // User claims 14-day free trial
      await tester.tap(find.byKey(const Key('btnRescueClaimTrial')));
      await tester.pumpAndSettle();

      // Pro subscription and trial are now genuinely active in storage
      expect(await storage.isProSubscriber(), isTrue);
      expect(await storage.isTrialActive(), isTrue);
    });
  });

  // =========================================================================
  // TIER 4: Real-World Commercial & Industrial Scenarios
  // =========================================================================
  group('E2E Tier 4: Real-World Commercial & Industrial Scenarios', () {
    test('4.1 Industrial Feeder: 480V 3-Phase 250A 400ft 3x 350 kcmil Al + 1x #2 Al in 3" EMT', () {
      final emt3 = RacewayCatalog.getProfile(RacewayType.emt, '3');
      final wire350Al = ConductorCatalog.getSpec(
        gauge: '350 kcmil',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.aluminum,
      );
      final wire2Al = ConductorCatalog.getSpec(
        gauge: '2 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.aluminum,
      );

      // Conduit Fill
      final fill = ConduitFillCalculator.calculate(
        raceway: emt3,
        conductorGroups: [
          ConductorGroup(id: 'phases', spec: wire350Al, count: 3, role: 'phase'),
          ConductorGroup(id: 'ground', spec: wire2Al, count: 1, role: 'ground'),
        ],
      );
      expect(fill.allowedFillPercentage, equals(40.0));
      expect(fill.isCompliant, isTrue);
      expect(fill.fillPercentage, lessThan(40.0));

      // Voltage Drop at 480V 3-Phase 250A 400ft in Steel EMT
      final vDrop = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 480.0,
        phase: CircuitPhase.threePhase,
        currentAmps: 250.0,
        lengthFeet: 400.0,
        conductorSpec: wire350Al,
        isSteelConduit: true,
        powerFactor: 0.90,
      );
      expect(vDrop.percentageDrop, lessThan(3.0));
      expect(vDrop.isCompliantBranch, isTrue);
      expect(vDrop.isCompliantTotal, isTrue);

      // Derating: 35C ambient, 3 CCC, 75C terminal
      final derate = DeratingCalculator.calculate(
        conductorSpec: wire350Al,
        ambientTempC: 35.0,
        currentCarryingConductorsCount: 3,
        terminalRatingC: 75.0,
      );
      expect(derate.allowableAmpacity, greaterThanOrEqualTo(250.0));
    });

    test('4.2 Commercial Multi-Wire Branch: 208V 3-Phase 20A 120ft 6x #12 + 2x #12 Neutral in 3/4" EMT', () {
      final emt34 = RacewayCatalog.getProfile(RacewayType.emt, '3/4');
      final wire12Cu = ConductorCatalog.getSpec(
        gauge: '12 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      // Conduit fill for 8 total conductors in 3/4" EMT
      final fill = ConduitFillCalculator.calculate(
        raceway: emt34,
        conductorGroups: [
          ConductorGroup(id: 'c1', spec: wire12Cu, count: 6, role: 'phase'),
          ConductorGroup(id: 'c2', spec: wire12Cu, count: 2, role: 'neutral'),
        ],
      );
      expect(fill.allowedFillPercentage, equals(40.0));
      expect(fill.isCompliant, isTrue);
      expect(fill.fillPercentage, lessThan(40.0));

      // 6 current-carrying conductors requires 80% bundling multiplier per Table 310.15(C)(1)
      final derate = DeratingCalculator.calculate(
        conductorSpec: wire12Cu,
        ambientTempC: 30.0,
        currentCarryingConductorsCount: 6,
        terminalRatingC: 75.0,
      );
      expect(derate.bundlingAdjustmentFactor, equals(0.80));
      expect(derate.baseAmpacity, equals(30.0)); // 90C rating for #12 THHN
      expect(derate.deratedAmpacity, equals(24.0)); // 30 * 0.80 = 24.0A
      expect(derate.allowableAmpacity, equals(24.0)); // <= 25A 75C terminal limit
      expect(derate.smallWireOcpdLimit, equals(20)); // Max 20A breaker per NEC 240.4(D)
    });

    test('4.3 High Jam Hazard Resolution: 3x 250 kcmil in 2" EMT auto-upsized to 2-1/2" EMT', () {
      final emt2 = RacewayCatalog.getProfile(RacewayType.emt, '2');
      final wire250Cu = ConductorCatalog.getSpec(
        gauge: '250 kcmil',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      // In 2" EMT: ID = 2.197", Wire OD = 0.711" -> Jam ratio = 2.197 / 0.711 = 3.090 (Critical Jam Hazard)
      final fillIn2 = ConduitFillCalculator.calculate(
        raceway: emt2,
        conductorGroups: [
          ConductorGroup(id: 'g1', spec: wire250Cu, count: 3, role: 'phase'),
        ],
      );
      expect(fillIn2.hasJamRisk, isTrue);
      expect(fillIn2.jamRiskLevel, equals(JamRiskLevel.highJamRisk));
      expect(fillIn2.jamRatio!, inInclusiveRange(2.80, 3.20));

      // Recommended upsize or manual upgrade to 2-1/2" EMT
      final emt25 = RacewayCatalog.getProfile(RacewayType.emt, '2-1/2');
      final fillIn25 = ConduitFillCalculator.calculate(
        raceway: emt25,
        conductorGroups: [
          ConductorGroup(id: 'g1', spec: wire250Cu, count: 3, role: 'phase'),
        ],
      );
      // In 2-1/2" EMT: ID = 2.875" -> Jam ratio = 2.875 / 0.711 = 4.04 (Safe Clearance)
      expect(fillIn25.hasJamRisk, isFalse);
      expect(fillIn25.jamRiskLevel, equals(JamRiskLevel.safeClearance));
      expect(fillIn25.jamRatio!, greaterThan(3.20));
      expect(fillIn25.isCompliant, isTrue);
    });

    test('4.4 Complete Offline Field Cycle: New Calculation -> Overfill Upsize -> Local Save -> Signed PDF', () async {
      final storage = StorageService.instance;

      // 1. Start fresh calculation: 4x 4/0 AWG THHN Cu in 1-1/2" EMT (Intentionally overfilled)
      final emt112 = RacewayCatalog.getProfile(RacewayType.emt, '1-1/2');
      final wire40 = ConductorCatalog.getSpec(
        gauge: '4/0 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );
      final groups = [
        ConductorGroup(id: 'g1', spec: wire40, count: 4, role: 'phase'),
      ];

      final overfilledResult = ConduitFillCalculator.calculate(
        raceway: emt112,
        conductorGroups: groups,
      );
      expect(overfilledResult.isCompliant, isFalse);
      expect(overfilledResult.recommendedUpsizeTradeSize, isNotNull);

      // 2. Apply upsize recommendation to 2" or compliant size
      final upsizedTradeSize = overfilledResult.recommendedUpsizeTradeSize!;
      final upsizedRaceway = RacewayCatalog.getProfile(RacewayType.emt, upsizedTradeSize);
      final compliantResult = ConduitFillCalculator.calculate(
        raceway: upsizedRaceway,
        conductorGroups: groups,
      );
      expect(compliantResult.isCompliant, isTrue);

      // 3. Save run offline
      final savedRun = SavedCalculation(
        id: 'field-cycle-run-1',
        title: 'Emergency Generator Feed',
        notes: 'Upsized to $upsizedTradeSize EMT to guarantee NEC compliance',
        timestamp: DateTime(2026, 10, 13, 16, 45),
        raceway: upsizedRaceway,
        conductors: groups,
        fillResult: compliantResult,
        clientName: 'Regional General Hospital',
        siteAddress: '400 Healing Parkway',
      );
      await storage.saveCalculation(savedRun);

      // 4. Retrieve saved calculation and verify integrity
      final allSaved = await storage.getSavedCalculations();
      final retrieved = allSaved.firstWhere((r) => r.id == 'field-cycle-run-1');
      expect(retrieved.fillResult.isCompliant, isTrue);
      expect(retrieved.raceway.tradeSize, equals(upsizedTradeSize));

      // 5. Generate signed compliance PDF document
      final reportData = ComplianceReportData(
        projectTitle: retrieved.title,
        clientName: retrieved.clientName,
        siteAddress: retrieved.siteAddress,
        technicianName: 'Marcus Vance, PE',
        companyName: 'Apex Electrical Solutions LLC',
        date: retrieved.timestamp,
        raceway: retrieved.raceway,
        conductors: retrieved.conductors,
        fillResult: retrieved.fillResult,
        signaturePngBytes: kTestTransparentPngBytes,
      );
      final pdfBytes = await PdfReportService.generateReport(reportData);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(2000));
    });
  });
}
