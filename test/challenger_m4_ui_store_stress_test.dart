import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:electronorm/catalogs/conductor_catalog.dart';
import 'package:electronorm/catalogs/raceway_catalog.dart';
import 'package:electronorm/models/calculation_results.dart';
import 'package:electronorm/models/conductor.dart';
import 'package:electronorm/models/raceway.dart';
import 'package:electronorm/screens/paywall_screen.dart';
import 'package:electronorm/screens/saved_projects_screen.dart';
import 'package:electronorm/services/storage_service.dart';
import 'package:electronorm/theme/app_theme.dart';

SavedCalculation createStressCalculation({
  required String id,
  required String title,
  required String notes,
  String clientName = 'Apex Energy Dynamics Industrial Corp',
  String siteAddress = '9800 North Technology Parkway, Building D, Suite 400',
  double fillPercentage = 38.5,
  bool hasJamRisk = false,
  bool vdCompliant = true,
}) {
  final raceway = RacewayCatalog.getProfile(RacewayType.emt, '2');
  final conductor = ConductorCatalog.getSpec(
    gauge: '3/0 AWG',
    insulation: ConductorInsulation.thhn,
    material: ConductorMaterial.copper,
  );

  return SavedCalculation(
    id: id,
    title: title,
    notes: notes,
    timestamp: DateTime(2026, 10, 13, 14, 30),
    raceway: raceway,
    conductors: [
      ConductorGroup(
        id: 'group-stress-1',
        spec: conductor,
        count: 4,
        role: 'phaseA',
      ),
    ],
    fillResult: ConduitFillResult(
      totalConductorArea: 0.8892,
      racewayInternalArea: 3.356,
      fillPercentage: fillPercentage,
      allowedFillPercentage: 40.0,
      allowedFillArea: 1.3424,
      isCompliant: fillPercentage <= 40.0,
      totalConductorCount: 4,
      hasJamRisk: hasJamRisk,
      jamRatio: hasJamRisk ? 3.01 : 1.5,
      jamRiskLevel: hasJamRisk ? JamRiskLevel.highJamRisk : JamRiskLevel.safeClearance,
    ),
    voltageDropResult: VoltageDropResult(
      voltageDropVolts: vdCompliant ? 3.4 : 8.9,
      percentageDrop: vdCompliant ? 1.4 : 3.7,
      endVoltage: vdCompliant ? 236.6 : 231.1,
      isCompliantBranch: vdCompliant,
      isCompliantTotal: vdCompliant,
      effectiveImpedance: 0.08,
      complianceStatus: vdCompliant
          ? VoltageDropComplianceStatus.pass
          : VoltageDropComplianceStatus.caution,
    ),
    deratingResult: const DeratingResult(
      baseAmpacity: 225.0,
      temperatureCorrectionFactor: 1.0,
      bundlingAdjustmentFactor: 0.8,
      deratedAmpacity: 180.0,
      terminalRatingLimit: 200.0,
      allowableAmpacity: 180.0,
    ),
    nominalVoltage: 240.0,
    circuitPhase: CircuitPhase.singlePhase,
    circuitLengthFeet: 120.0,
    loadCurrentAmps: 150.0,
    powerFactor: 0.95,
    ambientTempC: 30.0,
    terminalRatingC: 75.0,
    isNipple: false,
    clientName: clientName,
    siteAddress: siteAddress,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferencesStorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = SharedPreferencesStorageService();
    StorageService.instance = storageService;
  });

  // =========================================================================
  // SUITE 1: VIEWPORT BOUNDARY STRESS TESTS (Zero RenderFlex Overflow Oracle)
  // =========================================================================
  group('CHALLENGER SUITE 1: Viewport Boundary & Overflow Stress Tests', () {
    final viewports = <String, Size>{
      'Ultra-Narrow (320x640)': const Size(320, 640),
      'Standard Narrow (360x800)': const Size(360, 800),
      'Standard Phone (412x915)': const Size(412, 915),
      'Large Tablet (800x1280)': const Size(800, 1280),
    };

    for (final entry in viewports.entries) {
      final name = entry.key;
      final size = entry.value;

      testWidgets('1.1 SavedProjectsScreen across $name with long strings & badge clutter', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        // Populate with extreme text payloads
        await storageService.saveCalculation(createStressCalculation(
          id: 'proj_stress_1',
          title: 'Industrial Wastewater Subpanel Feeder B-42 Distribution Facility Unit 9 West Wing Extension',
          notes: 'Conduit run passing through high-temperature boiler room environment with 65C ambient derating required and 4 bends exceeding 360 degrees total inspection note required before concrete pour.',
          clientName: 'Consolidated Global Industrial Infrastructure Holdings Corporation Ltd.',
          siteAddress: 'Building 14, Unit 4B, 10000 Innovation Boulevard, Tech Park Sector 7, Chicago IL 60601',
          fillPercentage: 48.5,
          hasJamRisk: true,
          vdCompliant: false,
        ));

        final errors = <FlutterErrorDetails>[];
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          errors.add(details);
        };

        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: const SavedProjectsScreen(),
            ),
          );
          await tester.pumpAndSettle();

          // Check that no RenderFlex overflow error was logged
          final overflowErrors = errors.where((e) => e.toString().contains('A RenderFlex overflowed by')).toList();
          expect(overflowErrors, isEmpty,
              reason: 'SavedProjectsScreen generated RenderFlex overflow on $name: ${overflowErrors.map((e) => e.exceptionAsString()).toList()}');

          // Verify project card is present (allow offstage for small screens)
          expect(find.byKey(const Key('cardSavedProject_proj_stress_1'), skipOffstage: false), findsOneWidget);
        } finally {
          FlutterError.onError = originalOnError;
        }
      });

      testWidgets('1.2 PaywallScreen across $name renders cleanly without RenderFlex overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final errors = <FlutterErrorDetails>[];
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          errors.add(details);
        };

        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: const PaywallScreen(),
            ),
          );
          await tester.pumpAndSettle();

          // Check for RenderFlex overflow error
          final overflowErrors = errors.where((e) => e.toString().contains('A RenderFlex overflowed by')).toList();
          expect(overflowErrors, isEmpty,
              reason: 'PaywallScreen generated RenderFlex overflow on $name: ${overflowErrors.map((e) => e.exceptionAsString()).toList()}');

          // Verify both tier cards are present
          expect(find.byKey(const Key('cardTierAnnual')), findsOneWidget);
          expect(find.byKey(const Key('cardTierMonthly')), findsOneWidget);
        } finally {
          FlutterError.onError = originalOnError;
        }
      });
    }

    testWidgets('1.3 SavedProjectsScreen delete confirmation dialog RenderFlex overflow check on 360dp width', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await storageService.saveCalculation(createStressCalculation(
        id: 'del_test',
        title: 'Run for Deletion',
        notes: 'Notes',
      ));

      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
      };

      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const SavedProjectsScreen(),
          ),
        );
        await tester.pumpAndSettle();

        // Tap delete icon to trigger dialog
        await tester.tap(find.byKey(const Key('btnDeleteProject_del_test')));
        await tester.pumpAndSettle();

        final overflowErrors = errors.where((e) => e.toString().contains('A RenderFlex overflowed by')).toList();
        expect(overflowErrors, isEmpty,
            reason: 'Delete confirmation dialog in SavedProjectsScreen generated RenderFlex overflow on 360dp screen: ${overflowErrors.map((e) => e.exceptionAsString()).toList()}');

        // Dismiss dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });

  // =========================================================================
  // SUITE 2: PAYWALL POP INTERCEPTION & RESCUE DIALOG TESTS
  // =========================================================================
  group('CHALLENGER SUITE 2: Paywall Pop Interception & Rescue Dialog Stress', () {
    // Note: We use a tablet width here (800x1200) to isolate pop interception logic
    // from the known layout overflow bugs identified in Suite 1.
    const tabletViewport = Size(800, 1200);

    testWidgets('2.1 Pop attempt on Free user triggers Rescue Dialog', (tester) async {
      tester.view.physicalSize = tabletViewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool? paywallPopResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                paywallPopResult = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                );
              },
              child: const Text('Launch Paywall'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Launch Paywall'));
      await tester.pumpAndSettle();

      // Tap close button in AppBar
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Rescue dialog must appear
      expect(find.byKey(const Key('dialogRescue')), findsOneWidget);
      expect(find.byKey(const Key('btnRescueDismiss')), findsOneWidget);
      expect(find.byKey(const Key('btnRescueClaimTrial')), findsOneWidget);

      // Dismiss rescue dialog ("Continue with Free Version")
      await tester.tap(find.byKey(const Key('btnRescueDismiss')));
      await tester.pumpAndSettle();

      // Paywall should pop with result == false
      expect(paywallPopResult, isFalse);
      expect(await storageService.isProSubscriber(), isFalse);
    });

    testWidgets('2.2 Claiming trial in Rescue Dialog grants Pro and closes paywall with true', (tester) async {
      tester.view.physicalSize = tabletViewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool? paywallPopResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                paywallPopResult = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                );
              },
              child: const Text('Launch Paywall'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Launch Paywall'));
      await tester.pumpAndSettle();

      // Trigger pop
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Claim trial
      await tester.tap(find.byKey(const Key('btnRescueClaimTrial')));
      await tester.pumpAndSettle();

      // Verifications
      expect(paywallPopResult, isTrue);
      expect(await storageService.isProSubscriber(), isTrue);
      expect(await storageService.isTrialActive(), isTrue);
    });

    testWidgets('2.3 Re-opening Paywall in a new session triggers Rescue Dialog again', (tester) async {
      tester.view.physicalSize = tabletViewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool? firstResult;
      bool? secondResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  key: const Key('btnLaunch1'),
                  onPressed: () async {
                    firstResult = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const PaywallScreen()),
                    );
                  },
                  child: const Text('Session 1'),
                ),
                ElevatedButton(
                  key: const Key('btnLaunch2'),
                  onPressed: () async {
                    secondResult = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const PaywallScreen()),
                    );
                  },
                  child: const Text('Session 2'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Session 1: open and dismiss rescue
      await tester.tap(find.byKey(const Key('btnLaunch1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dialogRescue')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btnRescueDismiss')));
      await tester.pumpAndSettle();
      expect(firstResult, isFalse);

      // Session 2: open again and verify rescue dialog triggers again
      await tester.tap(find.byKey(const Key('btnLaunch2')));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dialogRescue')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btnRescueDismiss')));
      await tester.pumpAndSettle();
      expect(secondResult, isFalse);
    });

    testWidgets('2.4 Pro subscribers exit immediately without Rescue Dialog interception', (tester) async {
      tester.view.physicalSize = tabletViewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await storageService.setProSubscriber(true);

      bool? paywallPopResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                paywallPopResult = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                );
              },
              child: const Text('Launch Paywall Pro'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Launch Paywall Pro'));
      await tester.pumpAndSettle();

      // Tap close
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Dialog should NEVER have opened
      expect(find.byKey(const Key('dialogRescue')), findsNothing);
      expect(paywallPopResult, isFalse);
    });
  });

  // =========================================================================
  // SUITE 3: 5-TAP SECRET DEMO TOGGLE RAPID STRESS
  // =========================================================================
  group('CHALLENGER SUITE 3: 5-Tap Secret Demo Toggle Stress', () {
    const tabletViewport = Size(800, 1200);

    testWidgets('3.1 Slow taps (> 2000ms timeout) fail to activate Pro status', (tester) async {
      tester.view.physicalSize = tabletViewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const PaywallScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(await storageService.isProSubscriber(), isFalse);

      final demoTarget = find.byKey(const Key('btnSecretDemoToggle'));
      expect(demoTarget, findsOneWidget);

      // 4 rapid taps
      for (int i = 0; i < 4; i++) {
        await tester.tap(demoTarget);
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Wait past timeout (2.1 seconds wall clock) via real async execution
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 2100));
      });
      await tester.pump();

      // 5th tap arrives too late
      await tester.tap(demoTarget);
      await tester.pumpAndSettle();

      // Pro status remains false
      expect(await storageService.isProSubscriber(), isFalse);
    });

    testWidgets('3.2 Rapid burst tapping toggles Pro state back and forth deterministically', (tester) async {
      tester.view.physicalSize = tabletViewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const PaywallScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final demoTarget = find.byKey(const Key('btnSecretDemoToggle'));

      // Cycle 1: 5 taps -> Turn Pro ON
      for (int i = 0; i < 5; i++) {
        await tester.tap(demoTarget);
        await tester.pump(const Duration(milliseconds: 40));
      }
      await tester.pumpAndSettle();
      expect(await storageService.isProSubscriber(), isTrue);
      expect(await storageService.isDemoMode(), isTrue);

      // Cycle 2: 5 taps -> Turn Pro OFF
      for (int i = 0; i < 5; i++) {
        await tester.tap(demoTarget);
        await tester.pump(const Duration(milliseconds: 40));
      }
      await tester.pumpAndSettle();
      expect(await storageService.isProSubscriber(), isFalse);
      expect(await storageService.isDemoMode(), isFalse);

      // Cycle 3: 5 taps -> Turn Pro ON again
      for (int i = 0; i < 5; i++) {
        await tester.tap(demoTarget);
        await tester.pump(const Duration(milliseconds: 40));
      }
      await tester.pumpAndSettle();
      expect(await storageService.isProSubscriber(), isTrue);
    });

    testWidgets('3.3 20 ultra-rapid consecutive taps execute 4 clean state toggles without uncaught exception', (tester) async {
      tester.view.physicalSize = tabletViewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const PaywallScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final demoTarget = find.byKey(const Key('btnSecretDemoToggle'));

      // Fire 20 taps in 400ms (20ms spacing)
      for (int i = 0; i < 20; i++) {
        await tester.tap(demoTarget);
        await tester.pump(const Duration(milliseconds: 20));
      }
      await tester.pumpAndSettle();

      // 20 taps = 4 cycles (even number of toggles -> ends up in original state: false)
      expect(await storageService.isProSubscriber(), isFalse);
    });
  });

  // =========================================================================
  // SUITE 4: SAVED PROJECTS SEARCH, SORT & GESTURE STRESS
  // =========================================================================
  group('CHALLENGER SUITE 4: SavedProjectsScreen Search, Sort & Gestures', () {
    const tabletViewport = Size(800, 1200);

    testWidgets('4.1 Adversarial search characters do not crash regex or list rendering', (tester) async {
      tester.view.physicalSize = tabletViewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await storageService.saveCalculation(createStressCalculation(
        id: 'calc_special',
        title: 'Panel [A-1] (Special & Regular) + 480V',
        notes: r'Contains regex specials: .*+?^${}()|[]\ and emojis',
      ));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SavedProjectsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cardSavedProject_calc_special')), findsOneWidget);

      // Search with brackets
      final searchInput = find.byKey(const Key('inputSearchProjects'));
      await tester.enterText(searchInput, '[A-1]');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cardSavedProject_calc_special')), findsOneWidget);

      // Search with characters that broke unescaped RegExp in older designs
      await tester.enterText(searchInput, '.*+?xyz');
      await tester.pumpAndSettle();
      expect(find.text('No Calculations Match ".*+?xyz"'), findsOneWidget);

      // Clear search
      await tester.enterText(searchInput, '');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cardSavedProject_calc_special')), findsOneWidget);
    });

    testWidgets('4.2 Filter chips cycle and correctly filter calculations by compliance', (tester) async {
      tester.view.physicalSize = tabletViewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await storageService.saveCalculation(createStressCalculation(
        id: 'calc_compliant',
        title: 'Run Compliant',
        notes: 'Compliant note',
        fillPercentage: 30.0,
      ));

      await storageService.saveCalculation(createStressCalculation(
        id: 'calc_caution',
        title: 'Run Caution',
        notes: 'Caution note',
        fillPercentage: 45.0,
      ));

      await storageService.saveCalculation(createStressCalculation(
        id: 'calc_overfilled',
        title: 'Run Overfilled',
        notes: 'Overfilled note',
        fillPercentage: 55.0,
      ));

      await storageService.saveCalculation(createStressCalculation(
        id: 'calc_jam',
        title: 'Run Jam Hazard',
        notes: 'Jam note',
        fillPercentage: 38.0,
        hasJamRisk: true,
      ));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SavedProjectsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // All 4 visible initially
      expect(find.text('Run Compliant'), findsOneWidget);
      expect(find.text('Run Caution'), findsOneWidget);
      expect(find.text('Run Overfilled'), findsOneWidget);
      expect(find.text('Run Jam Hazard'), findsOneWidget);

      // Tap 'Compliant' chip
      await tester.tap(find.text('Compliant'));
      await tester.pumpAndSettle();
      expect(find.text('Run Compliant'), findsOneWidget);
      expect(find.text('Run Jam Hazard'), findsOneWidget); // 38% fill <= 40%
      expect(find.text('Run Caution'), findsNothing);
      expect(find.text('Run Overfilled'), findsNothing);

      // Tap 'Caution' chip
      await tester.tap(find.text('Caution'));
      await tester.pumpAndSettle();
      expect(find.text('Run Caution'), findsOneWidget);
      expect(find.text('Run Compliant'), findsNothing);

      // Tap 'Overfilled' chip
      await tester.tap(find.text('Overfilled'));
      await tester.pumpAndSettle();
      expect(find.text('Run Overfilled'), findsOneWidget);
      expect(find.text('Run Caution'), findsNothing);

      // Tap 'Jam Hazard' chip
      await tester.tap(find.text('Jam Hazard'));
      await tester.pumpAndSettle();
      expect(find.text('Run Jam Hazard'), findsOneWidget);
      expect(find.text('Run Overfilled'), findsNothing);
    });

    testWidgets('4.3 Two-step deletion dialog cancellation preserves data integrity', (tester) async {
      tester.view.physicalSize = tabletViewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await storageService.saveCalculation(createStressCalculation(
        id: 'calc_keep',
        title: 'Critical Project Do Not Delete',
        notes: 'Very important',
      ));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SavedProjectsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap delete icon button
      await tester.tap(find.byKey(const Key('btnDeleteProject_calc_keep')));
      await tester.pumpAndSettle();

      // Dialog is open
      expect(find.text('Delete Calculation?'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify item still exists
      expect(find.text('Critical Project Do Not Delete'), findsOneWidget);
      final remaining = await storageService.getSavedCalculations();
      expect(remaining.length, equals(1));
    });
  });

  // =========================================================================
  // SUITE 5: STORE COMPLIANCE & ZERO-PERMISSION PACKAGING AUDIT
  // =========================================================================
  group('CHALLENGER SUITE 5: Store Compliance & Android Configuration Hardening', () {
    test('5.1 AndroidManifest.xml contains ONLY non-invasive INTERNET permission and correct App Label', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue, reason: 'AndroidManifest.xml must exist');

      final content = manifestFile.readAsStringSync();

      // Required positive assertions
      expect(content, contains('android:label="ElectroNorm Pro"'));
      expect(content, contains('<uses-permission android:name="android.permission.INTERNET"/>'));
      expect(content, contains('android:name=".MainActivity"'));
      expect(content, contains('android:exported="true"'));
      expect(content, contains('android.intent.action.MAIN'));
      expect(content, contains('android.intent.category.LAUNCHER'));

      // STRICT ZERO dangerous/invasive permissions
      final prohibitedPermissions = [
        'CAMERA',
        'ACCESS_FINE_LOCATION',
        'ACCESS_COARSE_LOCATION',
        'ACCESS_BACKGROUND_LOCATION',
        'RECORD_AUDIO',
        'READ_CONTACTS',
        'WRITE_CONTACTS',
        'READ_CALENDAR',
        'WRITE_CALENDAR',
        'READ_EXTERNAL_STORAGE',
        'WRITE_EXTERNAL_STORAGE',
        'MANAGE_EXTERNAL_STORAGE',
        'READ_PHONE_STATE',
        'READ_SMS',
        'RECEIVE_SMS',
        'SEND_SMS',
        'BODY_SENSORS',
        'POST_NOTIFICATIONS',
        'SYSTEM_ALERT_WINDOW',
      ];

      for (final perm in prohibitedPermissions) {
        expect(
          content.contains(perm),
          isFalse,
          reason: 'PROHIBITED PERMISSION DETECTED: Manifest requests $perm which violates zero-permission policy',
        );
      }
    });

    test('5.2 android/app/build.gradle.kts adheres to Google Play SDK 34 rules and signing fallback', () {
      final gradleFile = File('android/app/build.gradle.kts');
      expect(gradleFile.existsSync(), isTrue);

      final content = gradleFile.readAsStringSync();

      // Store identity assertions
      expect(content, contains('namespace = "com.simpleappspg.electronorm"'));
      expect(content, contains('applicationId = "com.simpleappspg.electronorm"'));

      // Target SDK compliance (Google Play 2026 mandates >= 34)
      expect(content, contains('compileSdk = 34'));
      expect(content, contains('targetSdk = 34'));
      expect(content, contains('minSdk = 21'));

      // Versioning
      expect(content, contains('versionCode = 1'));
      expect(content, contains('versionName = "1.0.0"'));

      // Release signing fallback (vital for CI pipelines and test builds without secrets)
      expect(content, contains('signingConfigs.getByName("debug")'));
      expect(content, contains('signingConfigs.getByName("release")'));
      expect(content, contains('keystorePropertiesFile'));
    });

    test('5.3 privacy_policy.html hosts accurate legal disclosures for SimpleApps PG and Play Console', () {
      final policyFile = File('privacy_policy.html');
      expect(policyFile.existsSync(), isTrue);

      final html = policyFile.readAsStringSync();

      // Entity and application branding
      expect(html, contains('SimpleApps PG'));
      expect(html, contains('ElectroNorm Pro'));
      expect(html, contains('com.simpleappspg.electronorm'));
      expect(html, contains('support@simpleappspg.com'));

      // Architecture disclosures
      expect(html, contains('Offline-First Architecture'));
      expect(html, contains('Zero Personal Data Collection'));
      expect(html, contains('INTERNET'));

      // Pricing disclosures
      expect(html, contains(r'$8.99'));
      expect(html, contains(r'$69.00'));
      expect(html, contains('14-Day Free Trial'));
    });
  });
}
