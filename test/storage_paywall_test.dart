import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:electronorm/catalogs/conductor_catalog.dart';
import 'package:electronorm/catalogs/raceway_catalog.dart';
import 'package:electronorm/models/calculation_results.dart';
import 'package:electronorm/models/conductor.dart';
import 'package:electronorm/models/raceway.dart';
import 'package:electronorm/screens/calculator_screen.dart';
import 'package:electronorm/screens/paywall_screen.dart';
import 'package:electronorm/screens/report_preview_screen.dart';
import 'package:electronorm/screens/saved_projects_screen.dart';
import 'package:electronorm/services/pdf_report_service.dart';
import 'package:electronorm/services/storage_service.dart';
import 'package:electronorm/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SavedCalculation createSampleCalculation({
    String id = 'calc-test-1',
    String title = 'Substation Feeder #1',
    String notes = 'Main switchboard MDP-1 conduit run',
    double fillPercentage = 34.2,
    bool hasJamRisk = false,
    double dropPercentage = 1.8,
  }) {
    final raceway = RacewayCatalog.getProfile(RacewayType.emt, '3/4');
    final conductor = ConductorCatalog.getSpec(
      gauge: '10 AWG',
      insulation: ConductorInsulation.thhn,
      material: ConductorMaterial.copper,
    );

    return SavedCalculation(
      id: id,
      title: title,
      notes: notes,
      timestamp: DateTime.now(),
      raceway: raceway,
      conductors: [
        ConductorGroup(
          id: 'group-1',
          spec: conductor,
          count: 3,
          role: 'phaseA',
        ),
      ],
      fillResult: ConduitFillResult(
        totalConductorArea: 0.0633,
        racewayInternalArea: 0.533,
        fillPercentage: fillPercentage,
        allowedFillPercentage: 40.0,
        allowedFillArea: 0.2132,
        isCompliant: fillPercentage <= 40.0,
        totalConductorCount: 3,
        hasJamRisk: hasJamRisk,
        jamRatio: hasJamRisk ? 3.01 : 1.5,
        jamRiskLevel: hasJamRisk ? JamRiskLevel.highJamRisk : JamRiskLevel.safeClearance,
      ),
      voltageDropResult: VoltageDropResult(
        voltageDropVolts: 2.16,
        percentageDrop: dropPercentage,
        endVoltage: 117.84,
        isCompliantBranch: dropPercentage <= 3.0,
        isCompliantTotal: dropPercentage <= 5.0,
        effectiveImpedance: 1.20,
        complianceStatus: dropPercentage <= 3.0
            ? VoltageDropComplianceStatus.pass
            : VoltageDropComplianceStatus.caution,
      ),
      deratingResult: const DeratingResult(
        baseAmpacity: 40.0,
        temperatureCorrectionFactor: 1.0,
        bundlingAdjustmentFactor: 1.0,
        deratedAmpacity: 40.0,
        terminalRatingLimit: 35.0,
        allowableAmpacity: 35.0,
      ),
      nominalVoltage: 120.0,
      circuitPhase: CircuitPhase.singlePhase,
      circuitLengthFeet: 100.0,
      loadCurrentAmps: 16.0,
      powerFactor: 0.90,
      ambientTempC: 30.0,
      terminalRatingC: 75.0,
      isNipple: false,
      clientName: 'Apex Data Center',
      siteAddress: '100 Technology Dr, Vault 2',
    );
  }

  group('Milestone 4: Storage Service Unit Tests', () {
    late SharedPreferencesStorageService storageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storageService = SharedPreferencesStorageService();
      StorageService.instance = storageService;
    });

    test('1. Initial empty storage returns empty list of calculations', () async {
      final list = await storageService.getSavedCalculations();
      expect(list, isEmpty);
    });

    test('2. CRUD: saves, retrieves by ID, updates in-place, and deletes calculation', () async {
      final item1 = createSampleCalculation(id: 'c1', title: 'Run A');
      final item2 = createSampleCalculation(id: 'c2', title: 'Run B');

      // Save two calculations
      await storageService.saveCalculation(item1);
      await storageService.saveCalculation(item2);

      var all = await storageService.getSavedCalculations();
      expect(all.length, equals(2));

      // Get by ID
      final fetched = await storageService.getCalculationById('c1');
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Run A'));
      expect(fetched.clientName, equals('Apex Data Center'));

      // Update in place
      final updatedItem1 = item1.copyWith(title: 'Run A - Revised', notes: 'Updated notes');
      await storageService.saveCalculation(updatedItem1);

      all = await storageService.getSavedCalculations();
      expect(all.length, equals(2));
      final reFetched = await storageService.getCalculationById('c1');
      expect(reFetched!.title, equals('Run A - Revised'));
      expect(reFetched.notes, equals('Updated notes'));

      // Delete item
      await storageService.deleteCalculation('c1');
      all = await storageService.getSavedCalculations();
      expect(all.length, equals(1));
      expect(all.first.id, equals('c2'));

      // Delete non-existent ID completes safely
      await storageService.deleteCalculation('non-existent');
      all = await storageService.getSavedCalculations();
      expect(all.length, equals(1));
    });

    test('3. ClearAll purges calculations, profiles, subscription flags and trials', () async {
      await storageService.saveCalculation(createSampleCalculation(id: 'c3'));
      await storageService.setProSubscriber(true);
      await storageService.startTrial();
      await storageService.setDemoMode(true);

      expect(await storageService.isProSubscriber(), isTrue);

      await storageService.clearAll();

      final all = await storageService.getSavedCalculations();
      expect(all, isEmpty);
      expect(await storageService.isProSubscriber(), isFalse);
      expect(await storageService.isDemoMode(), isFalse);
      expect(await storageService.isTrialActive(), isFalse);
    });

    test('4. TechnicianProfile save and retrieve with defaults fallback', () async {
      // Uninitialized profile returns default
      final defaultProfile = await storageService.getProfile();
      expect(defaultProfile.technicianName, equals('Carlos Mendoza'));
      expect(defaultProfile.companyName, equals('VoltPro Electrical LLC'));
      expect(defaultProfile.licenseNumber, equals('ME-948210'));

      // Save custom profile
      const customProfile = TechnicianProfile(
        technicianName: 'Eleanor Vance',
        companyName: 'Apex Industrial Electric',
        licenseNumber: 'ME-772910',
        email: 'eleanor@apex.com',
        phone: '(555) 019-2831',
        agencyName: 'State Electrical Board',
        address: '400 Main St, Suite 5',
      );
      await storageService.saveProfile(customProfile);

      final fetchedProfile = await storageService.getProfile();
      expect(fetchedProfile.technicianName, equals('Eleanor Vance'));
      expect(fetchedProfile.companyName, equals('Apex Industrial Electric'));
      expect(fetchedProfile.licenseNumber, equals('ME-772910'));
      expect(fetchedProfile.email, equals('eleanor@apex.com'));
    });

    test('5. Graceful corrupted JSON recovery: malformed strings or corrupted array items', () async {
      // Injected corrupted string
      SharedPreferences.setMockInitialValues({
        'electronorm_saved_calculations': '{ invalid json corrupted !!! :::',
        'electronorm_technician_profile': 'not a json object',
      });

      final freshStorage = SharedPreferencesStorageService();
      final calculations = await freshStorage.getSavedCalculations();
      expect(calculations, isEmpty);

      final profile = await freshStorage.getProfile();
      expect(profile.technicianName, equals('Carlos Mendoza')); // Fallback to defaultProfile
    });

    test('6. Partial corrupted list: recovers valid items and drops corrupted items safely', () async {
      final validItem = createSampleCalculation(id: 'valid-1', title: 'Valid Run');
      final validJson = validItem.toJson();

      final partialCorruptList = [
        validJson,
        {'id': 12345, 'conductors': 'not a valid list'},
        'not even a map',
      ];

      SharedPreferences.setMockInitialValues({
        'electronorm_saved_calculations': jsonEncode(partialCorruptList),
      });

      final freshStorage = SharedPreferencesStorageService();
      final calculations = await freshStorage.getSavedCalculations();
      expect(calculations.length, equals(1));
      expect(calculations.first.id, equals('valid-1'));
    });

    test('7. Subscription tier, 14-day free trial lifecycle, and remaining trial days calculation', () async {
      expect(await storageService.isProSubscriber(), isFalse);
      expect(await storageService.isTrialActive(), isFalse);
      expect(await storageService.getRemainingTrialDays(), equals(0));

      // Start 14-day trial
      await storageService.startTrial();
      expect(await storageService.isTrialActive(), isTrue);
      expect(await storageService.isProSubscriber(), isTrue);
      expect(await storageService.getRemainingTrialDays(), inInclusiveRange(13, 14));
      expect(await storageService.getSubscriptionTier(), equals('trial_14d'));

      // Direct Pro subscriber toggle
      await storageService.setProSubscriber(false);
      await storageService.setSubscriptionTier('monthly');
      expect(await storageService.getSubscriptionTier(), equals('monthly'));
    });

    test('8. Secret Demo Mode: enables Pro status without store credentials', () async {
      expect(await storageService.isDemoMode(), isFalse);
      expect(await storageService.isProSubscriber(), isFalse);

      await storageService.setDemoMode(true);
      expect(await storageService.isDemoMode(), isTrue);
      expect(await storageService.isProSubscriber(), isTrue);

      await storageService.setDemoMode(false);
      await storageService.setProSubscriber(false);
      expect(await storageService.isDemoMode(), isFalse);
      expect(await storageService.isProSubscriber(), isFalse);
    });
  });

  group('Milestone 4: SavedProjectsScreen Widget Tests', () {
    late SharedPreferencesStorageService storageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storageService = SharedPreferencesStorageService();
      StorageService.instance = storageService;

      // Seed 3 calculations with different fill and jam characteristics
      await storageService.saveCalculation(createSampleCalculation(
        id: 'run-1',
        title: 'Alpha Feeder 1',
        notes: '3/4 EMT compliant run',
        fillPercentage: 32.5,
        hasJamRisk: false,
      ));

      await storageService.saveCalculation(createSampleCalculation(
        id: 'run-2',
        title: 'Beta Substation Run',
        notes: 'Overfilled run in transformer yard',
        fillPercentage: 54.0,
        hasJamRisk: true,
      ));

      await storageService.saveCalculation(createSampleCalculation(
        id: 'run-3',
        title: 'Gamma Panel MDP',
        notes: 'Caution run with 45% fill',
        fillPercentage: 45.0,
        hasJamRisk: false,
      ));
    });

    testWidgets('1. Renders saved project cards with titles, badges, and conductor summaries', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          themeMode: ThemeMode.dark,
          home: SavedProjectsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saved Projects'), findsOneWidget);
      expect(find.text('Alpha Feeder 1'), findsOneWidget);
      expect(find.text('Beta Substation Run'), findsOneWidget);
      expect(find.text('Gamma Panel MDP'), findsOneWidget);

      // Status badges
      expect(find.text('32.5% Fill'), findsOneWidget);
      expect(find.text('54.0% Fill'), findsOneWidget);
      expect(find.text('45.0% Fill'), findsOneWidget);
      expect(find.text('JAM HAZARD'), findsOneWidget);
    });

    testWidgets('2. Search query filters calculations in real time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          themeMode: ThemeMode.dark,
          home: SavedProjectsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('inputSearchProjects'));
      expect(searchField, findsOneWidget);

      // Search for "Alpha"
      await tester.enterText(searchField, 'Alpha');
      await tester.pumpAndSettle();

      expect(find.text('Alpha Feeder 1'), findsOneWidget);
      expect(find.text('Beta Substation Run'), findsNothing);
      expect(find.text('Gamma Panel MDP'), findsNothing);

      // Search for non-matching string displays empty state
      await tester.enterText(searchField, 'NonExistentCalculationXYZ');
      await tester.pumpAndSettle();

      expect(find.textContaining('No Calculations Match'), findsOneWidget);
    });

    testWidgets('3. Tapping project card pops and returns selected calculation', (tester) async {
      SavedCalculation? returnedCalculation;

      await tester.pumpWidget(
        MaterialApp(
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                returnedCalculation = await Navigator.of(context).push<SavedCalculation>(
                  MaterialPageRoute(builder: (_) => const SavedProjectsScreen()),
                );
              },
              child: const Text('Open Saved Projects'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open screen
      await tester.tap(find.text('Open Saved Projects'));
      await tester.pumpAndSettle();

      // Tap card
      await tester.tap(find.byKey(const Key('cardProject_run-1')));
      await tester.pumpAndSettle();

      expect(returnedCalculation, isNotNull);
      expect(returnedCalculation!.id, equals('run-1'));
      expect(returnedCalculation!.title, equals('Alpha Feeder 1'));
    });

    testWidgets('4. Delete button triggers confirmation dialog and deletes item', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          themeMode: ThemeMode.dark,
          home: SavedProjectsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alpha Feeder 1'), findsOneWidget);

      // Tap delete on run-1
      await tester.tap(find.byKey(const Key('btnDeleteProject_run-1')));
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Delete Calculation?'), findsOneWidget);
      expect(find.byKey(const Key('btnConfirmDelete')), findsOneWidget);

      // Confirm delete
      await tester.tap(find.byKey(const Key('btnConfirmDelete')));
      await tester.pumpAndSettle();

      // Run-1 is now gone from UI and storage
      expect(find.text('Alpha Feeder 1'), findsNothing);
      final remaining = await storageService.getSavedCalculations();
      expect(remaining.length, equals(2));
    });

    testWidgets('5. Empty state renders when all items deleted', (tester) async {
      await storageService.clearAll();

      await tester.pumpWidget(
        const MaterialApp(
          themeMode: ThemeMode.dark,
          home: SavedProjectsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Saved Calculations Yet'), findsOneWidget);
      expect(find.text('Back to Calculator'), findsOneWidget);
    });
  });

  group('Milestone 4: PaywallScreen Widget Tests', () {
    late SharedPreferencesStorageService storageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storageService = SharedPreferencesStorageService();
      StorageService.instance = storageService;
    });

    testWidgets('1. Displays both pricing tiers (\$8.99/mo and \$69.00/yr) with 14-day trial badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          themeMode: ThemeMode.dark,
          home: PaywallScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ElectroNorm Pro'), findsOneWidget);
      expect(find.byKey(const Key('cardTierAnnual')), findsOneWidget);
      expect(find.byKey(const Key('cardTierMonthly')), findsOneWidget);

      expect(find.text('\$69.00/yr'), findsOneWidget);
      expect(find.text('\$8.99/mo'), findsOneWidget);
      expect(find.text('14-DAY FREE TRIAL'), findsOneWidget);
      expect(find.text('BEST VALUE • SAVE 36%'), findsOneWidget);
      expect(find.byKey(const Key('btnSubscribePaywall')), findsOneWidget);
      expect(find.text('Start 14-Day Free Trial'), findsOneWidget);
    });

    testWidgets('2. Tapping Monthly tier updates selected plan and CTA button text', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          themeMode: ThemeMode.dark,
          home: PaywallScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cardTierMonthly')));
      await tester.pumpAndSettle();

      expect(find.text('Subscribe Now — \$8.99/mo'), findsOneWidget);
    });

    testWidgets('3. 5-tap secret demo toggle enables Pro status without store credentials', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          themeMode: ThemeMode.dark,
          home: PaywallScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(await storageService.isProSubscriber(), isFalse);

      final demoTarget = find.byKey(const Key('btnSecretDemoToggle'));
      expect(demoTarget, findsOneWidget);

      // Tap 5 times
      for (int i = 0; i < 5; i++) {
        await tester.tap(demoTarget);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Pro state is now enabled
      expect(await storageService.isProSubscriber(), isTrue);
      expect(find.textContaining('Secret Demo Mode: Pro Status ENABLED'), findsOneWidget);

      // Tap 5 times again to toggle off
      for (int i = 0; i < 5; i++) {
        await tester.tap(demoTarget);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(await storageService.isProSubscriber(), isFalse);
      expect(find.textContaining('Secret Demo Mode: Pro Status RESET'), findsOneWidget);
    });

    testWidgets('4. Exit-intent rescue dialog displays on back press and offers 14-day trial', (tester) async {
      bool? paywallResult;

      await tester.pumpWidget(
        MaterialApp(
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                paywallResult = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                );
              },
              child: const Text('Open Paywall'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open paywall
      await tester.tap(find.text('Open Paywall'));
      await tester.pumpAndSettle();

      // Attempt to pop via close icon
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Rescue dialog appears
      expect(find.byKey(const Key('dialogRescue')), findsOneWidget);
      expect(find.text('Wait! Unlock 14 Days Free'), findsOneWidget);
      expect(find.byKey(const Key('btnRescueClaimTrial')), findsOneWidget);

      // Claim trial
      await tester.tap(find.byKey(const Key('btnRescueClaimTrial')));
      await tester.pumpAndSettle();

      // Paywall closes and returns true
      expect(paywallResult, isTrue);
      expect(await storageService.isProSubscriber(), isTrue);
      expect(await storageService.isTrialActive(), isTrue);
    });
  });

  group('Milestone 4: CalculatorScreen Integration Tests', () {
    late SharedPreferencesStorageService storageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storageService = SharedPreferencesStorageService();
      StorageService.instance = storageService;
    });

    testWidgets('1. Contains btnSavedProjectsAppBar and btnSaveProject actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CalculatorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btnSavedProjectsAppBar')), findsOneWidget);
      expect(find.byKey(const Key('btnSaveProject')), findsOneWidget);
      expect(find.byKey(const Key('cardSaveProject')), findsOneWidget);
      expect(find.byKey(const Key('btnExportPdfAppBar')), findsOneWidget);
      expect(find.byKey(const Key('cardExportPdf')), findsOneWidget);
    });

    testWidgets('2. Saving a project run persists to StorageService', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CalculatorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Save Calculation action
      await tester.tap(find.byKey(const Key('btnSaveProject')));
      await tester.pumpAndSettle();

      expect(find.text('Save Calculation Run'), findsOneWidget);
      expect(find.byKey(const Key('inputSaveTitle')), findsOneWidget);

      // Enter custom title
      await tester.enterText(find.byKey(const Key('inputSaveTitle')), 'Feeder Line 440V');
      await tester.pumpAndSettle();

      // Confirm Save
      await tester.tap(find.byKey(const Key('btnConfirmSaveCalculation')));
      await tester.pumpAndSettle();

      // Verify item saved into storage
      final all = await storageService.getSavedCalculations();
      expect(all.length, equals(1));
      expect(all.first.title, equals('Feeder Line 440V'));
      expect(find.textContaining('Saved "Feeder Line 440V" to projects'), findsOneWidget);
    });

    testWidgets('3. Loading a saved project updates CalculatorScreen reactive state', (tester) async {
      // Seed a 2" PVC 80 run with 4 conductors
      final pProfile = RacewayCatalog.getProfile(RacewayType.pvcSch80, '2');
      final condSpec = ConductorCatalog.getSpec(
        gauge: '3/0 AWG',
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );

      final customRun = SavedCalculation(
        id: 'seed-pvc-run',
        title: 'Industrial Feeder PVC',
        notes: '2 inch PVC schedule 80 underground run',
        timestamp: DateTime.now(),
        raceway: pProfile,
        conductors: [
          ConductorGroup(id: 'cg-1', spec: condSpec, count: 4, role: 'phaseA'),
        ],
        fillResult: const ConduitFillResult(
          totalConductorArea: 1.116,
          racewayInternalArea: 2.874,
          fillPercentage: 38.8,
          allowedFillPercentage: 40.0,
          allowedFillArea: 1.1496,
          isCompliant: true,
          totalConductorCount: 4,
        ),
        nominalVoltage: 480.0,
        circuitPhase: CircuitPhase.threePhase,
        circuitLengthFeet: 250.0,
        loadCurrentAmps: 150.0,
        powerFactor: 0.95,
        ambientTempC: 40.0,
        terminalRatingC: 75.0,
      );
      await storageService.saveCalculation(customRun);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CalculatorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Saved Projects
      await tester.tap(find.byKey(const Key('btnSavedProjectsAppBar')));
      await tester.pumpAndSettle();

      expect(find.text('Industrial Feeder PVC'), findsOneWidget);

      // Tap card to load it
      await tester.tap(find.byKey(const Key('cardProject_seed-pvc-run')));
      await tester.pumpAndSettle();

      // Verification: CalculatorScreen has loaded 2" and PVC Schedule 80
      expect(find.textContaining('Loaded "Industrial Feeder PVC" into calculator'), findsOneWidget);
      expect(find.text('2"'), findsOneWidget);
    });
  });

  group('Milestone 4: ReportPreviewScreen Pro Gating Tests', () {
    late SharedPreferencesStorageService storageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storageService = SharedPreferencesStorageService();
      StorageService.instance = storageService;
    });

    testWidgets('1. Free tier navigation to ReportPreview allows signature dialog without crash', (tester) async {
      final sample = createSampleCalculation();
      final reportData = ComplianceReportData(
        projectTitle: sample.title,
        clientName: sample.clientName,
        siteAddress: sample.siteAddress,
        technicianName: 'Carlos Mendoza',
        companyName: 'VoltPro Electrical LLC',
        date: sample.timestamp,
        raceway: sample.raceway,
        conductors: sample.conductors,
        fillResult: sample.fillResult,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ReportPreviewScreen(reportData: reportData),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Preview screen renders
      expect(find.text('Compliance Report Preview'), findsOneWidget);

      // Signature action is available
      final signButton = find.text('Sign Report');
      expect(signButton, findsOneWidget);

      await tester.tap(signButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Signature dialog opens freely for non-Pro users
      expect(find.text('Inspector Digital Sign-Off'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('2. Export and Share actions prompt PaywallScreen when user is not Pro', (tester) async {
      final sample = createSampleCalculation();
      final reportData = ComplianceReportData(
        projectTitle: sample.title,
        clientName: sample.clientName,
        siteAddress: sample.siteAddress,
        technicianName: 'Carlos Mendoza',
        companyName: 'VoltPro Electrical LLC',
        date: sample.timestamp,
        raceway: sample.raceway,
        conductors: sample.conductors,
        fillResult: sample.fillResult,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ReportPreviewScreen(reportData: reportData),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap share button
      await tester.tap(find.byIcon(Icons.share_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Paywall screen is prompted
      expect(find.byType(PaywallScreen), findsOneWidget);
      expect(find.text('ElectroNorm Pro'), findsOneWidget);
    });
  });

  group('Milestone 4: Store Packaging & Compliance File Audits', () {
    test('1. android/app/build.gradle.kts configuration matches Store standards', () {
      final gradleFile = File('android/app/build.gradle.kts');
      expect(gradleFile.existsSync(), isTrue);

      final content = gradleFile.readAsStringSync();
      expect(content, contains('namespace = "com.simpleappspg.electronorm"'));
      expect(content, contains('compileSdk = 34'));
      expect(content, contains('applicationId = "com.simpleappspg.electronorm"'));
      expect(content, contains('minSdk = 21'));
      expect(content, contains('targetSdk = 34'));
      expect(content, contains('versionCode = 1'));
      expect(content, contains('versionName = "1.0.0"'));
      expect(content, contains('signingConfigs.getByName("debug")'));
    });

    test('2. android/app/src/main/AndroidManifest.xml permissions and label audit', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue);

      final content = manifestFile.readAsStringSync();
      expect(content, contains('android:label="ElectroNorm Pro"'));
      expect(content, contains('android.permission.INTERNET'));

      // STRICTLY ZERO prohibited or dangerous permissions
      expect(content.contains('CAMERA'), isFalse);
      expect(content.contains('ACCESS_FINE_LOCATION'), isFalse);
      expect(content.contains('ACCESS_COARSE_LOCATION'), isFalse);
      expect(content.contains('RECORD_AUDIO'), isFalse);
      expect(content.contains('READ_CONTACTS'), isFalse);
      expect(content.contains('READ_EXTERNAL_STORAGE'), isFalse);
      expect(content.contains('WRITE_EXTERNAL_STORAGE'), isFalse);
      expect(content.contains('MANAGE_EXTERNAL_STORAGE'), isFalse);
    });

    test('3. privacy_policy.html exists and discloses all required terms for simpleappspg', () {
      final policyFile = File('privacy_policy.html');
      expect(policyFile.existsSync(), isTrue);

      final content = policyFile.readAsStringSync();
      expect(content, contains('simpleappspg'));
      expect(content, contains('ElectroNorm Pro'));
      expect(content, contains('com.simpleappspg.electronorm'));
      expect(content, contains('support@simpleappspg.com'));
      expect(content, contains('Offline-First Architecture'));
      expect(content, contains('\$8.99'));
      expect(content, contains('\$69.00'));
      expect(content, contains('14-Day Free Trial'));
    });
  });
}
