import 'dart:convert';
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
import 'package:electronorm/screens/saved_projects_screen.dart';
import 'package:electronorm/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SavedCalculation buildAdversarialCalculation({
    required String id,
    String title = 'Test Calculation',
    String notes = 'Standard notes',
    RacewayType racewayType = RacewayType.emt,
    String tradeSize = '3/4',
    List<ConductorGroup>? conductors,
    double fillPercentage = 35.0,
    bool hasJamRisk = false,
    double nominalVoltage = 120.0,
    CircuitPhase circuitPhase = CircuitPhase.singlePhase,
    double circuitLengthFeet = 100.0,
    double loadCurrentAmps = 16.0,
    double powerFactor = 0.90,
    double ambientTempC = 30.0,
    double terminalRatingC = 75.0,
    bool isNipple = false,
    String clientName = 'Test Client Corp',
    String siteAddress = '123 Electric Ave',
    DateTime? timestamp,
  }) {
    final raceway = RacewayCatalog.getProfile(racewayType, tradeSize);
    final defaultConductor = ConductorCatalog.getSpec(
      gauge: '12 AWG',
      insulation: ConductorInsulation.thhn,
      material: ConductorMaterial.copper,
    );

    final conductorList = conductors ??
        [
          ConductorGroup(
            id: 'cond-$id-1',
            spec: defaultConductor,
            count: 3,
            role: 'phaseA',
            colorHex: 0xFF000000,
          ),
        ];

    final totalCount = conductorList.fold<int>(0, (sum, g) => sum + g.count);

    return SavedCalculation(
      id: id,
      title: title,
      notes: notes,
      timestamp: timestamp ?? DateTime.now(),
      raceway: raceway,
      conductors: conductorList,
      fillResult: ConduitFillResult(
        totalConductorArea: 0.05,
        racewayInternalArea: raceway.internalAreaSqInches,
        fillPercentage: fillPercentage,
        allowedFillPercentage: isNipple ? 60.0 : (totalCount == 1 ? 53.0 : (totalCount == 2 ? 31.0 : 40.0)),
        allowedFillArea: raceway.internalAreaSqInches * 0.40,
        isCompliant: fillPercentage <= (isNipple ? 60.0 : 40.0),
        totalConductorCount: totalCount,
        hasJamRisk: hasJamRisk,
        jamRatio: hasJamRisk ? 3.05 : 1.8,
        jamRiskLevel: hasJamRisk ? JamRiskLevel.highJamRisk : JamRiskLevel.safeClearance,
      ),
      voltageDropResult: VoltageDropResult(
        voltageDropVolts: 2.4,
        percentageDrop: 2.0,
        endVoltage: nominalVoltage - 2.4,
        isCompliantBranch: true,
        isCompliantTotal: true,
        effectiveImpedance: 0.15,
        complianceStatus: VoltageDropComplianceStatus.pass,
      ),
      deratingResult: const DeratingResult(
        baseAmpacity: 30.0,
        temperatureCorrectionFactor: 1.0,
        bundlingAdjustmentFactor: 1.0,
        deratedAmpacity: 30.0,
        terminalRatingLimit: 25.0,
        allowableAmpacity: 25.0,
      ),
      nominalVoltage: nominalVoltage,
      circuitPhase: circuitPhase,
      circuitLengthFeet: circuitLengthFeet,
      loadCurrentAmps: loadCurrentAmps,
      powerFactor: powerFactor,
      ambientTempC: ambientTempC,
      terminalRatingC: terminalRatingC,
      isNipple: isNipple,
      clientName: clientName,
      siteAddress: siteAddress,
    );
  }

  // =========================================================================
  // GROUP 1: Extreme Calculation Runs & Data Model Boundary Stress
  // =========================================================================
  group('Challenger M4: Extreme Calculation Runs & Data Model Boundary', () {
    late SharedPreferencesStorageService storageService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = SharedPreferencesStorageService();
      StorageService.instance = storageService;
    });

    test('1.1 Large Scale: Persists, retrieves, and sorts 120 unique calculations', () async {
      final baseDate = DateTime(2026, 1, 1);
      final List<SavedCalculation> items = [];

      for (int i = 0; i < 120; i++) {
        items.add(buildAdversarialCalculation(
          id: 'scale-$i',
          title: 'Feeder Run #$i',
          notes: 'Stress test run index $i with diverse parameters',
          fillPercentage: (i % 100).toDouble() + 0.5,
          timestamp: baseDate.add(Duration(hours: i)),
        ));
      }

      // Rapid sequential save of 120 items
      for (final item in items) {
        await storageService.saveCalculation(item);
      }

      final fetched = await storageService.getSavedCalculations();
      expect(fetched.length, equals(120));

      // Verify sorted by timestamp descending
      for (int i = 0; i < fetched.length - 1; i++) {
        expect(
          fetched[i].timestamp.isAfter(fetched[i + 1].timestamp) ||
              fetched[i].timestamp.isAtSameMomentAs(fetched[i + 1].timestamp),
          isTrue,
          reason: 'Item at index $i must be >= next item timestamp',
        );
      }

      // Verify individual lookup for boundary indices
      final firstSaved = await storageService.getCalculationById('scale-0');
      final midSaved = await storageService.getCalculationById('scale-60');
      final lastSaved = await storageService.getCalculationById('scale-119');
      final missingSaved = await storageService.getCalculationById('scale-999');

      expect(firstSaved, isNotNull);
      expect(firstSaved!.title, equals('Feeder Run #0'));
      expect(midSaved, isNotNull);
      expect(midSaved!.title, equals('Feeder Run #60'));
      expect(lastSaved, isNotNull);
      expect(lastSaved!.title, equals('Feeder Run #119'));
      expect(missingSaved, isNull);
    });

    test('1.2 Massive Conductor Groups: 50 groups with 1,500 total conductors', () async {
      final availableGauges = ConductorCatalog.standardAwgGauges;
      final List<ConductorGroup> largeGroups = [];

      int expectedConductorCount = 0;
      for (int i = 0; i < 50; i++) {
        final gauge = availableGauges[i % availableGauges.length];
        final spec = ConductorCatalog.getSpec(
          gauge: gauge,
          insulation: i % 2 == 0 ? ConductorInsulation.thhn : ConductorInsulation.xhhw,
          material: i % 3 == 0 ? ConductorMaterial.aluminum : ConductorMaterial.copper,
        );
        const count = 30; // 30 per group -> 1500 total
        expectedConductorCount += count;
        largeGroups.add(ConductorGroup(
          id: 'grp-$i',
          spec: spec,
          count: count,
          role: i % 3 == 0 ? 'phaseA' : (i % 3 == 1 ? 'phaseB' : 'neutral'),
          colorHex: 0xFF123456 + i,
        ));
      }

      final hugeCalc = buildAdversarialCalculation(
        id: 'massive-calc-1',
        title: 'Industrial Heavy Busduct Run',
        conductors: largeGroups,
        racewayType: RacewayType.rmc,
        tradeSize: '4',
      );

      // Verify serialization round-trip
      final json = hugeCalc.toJson();
      final decodedCalc = SavedCalculation.fromJson(json);

      expect(decodedCalc.conductors.length, equals(50));
      final totalDecodedCount = decodedCalc.conductors.fold<int>(0, (sum, g) => sum + g.count);
      expect(totalDecodedCount, equals(expectedConductorCount));
      expect(totalDecodedCount, equals(1500));

      // Save and retrieve from storage service
      await storageService.saveCalculation(hugeCalc);
      final retrieved = await storageService.getCalculationById('massive-calc-1');

      expect(retrieved, isNotNull);
      expect(retrieved!.conductors.length, equals(50));
      expect(retrieved.conductors.first.spec.gauge, equals(largeGroups.first.spec.gauge));
      expect(retrieved.conductors.last.spec.gauge, equals(largeGroups.last.spec.gauge));
      expect(retrieved.conductors.last.colorHex, equals(largeGroups.last.colorHex));
    });

    test('1.3 Boundary Raceways: All 8 raceway types and extreme trade sizes', () async {
      for (final rType in RacewayType.values) {
        final typeProfiles = RacewayCatalog.getProfilesForType(rType);
        expect(typeProfiles, isNotEmpty);

        final minSize = typeProfiles.first.tradeSize;
        final maxSize = typeProfiles.last.tradeSize;

        for (final size in [minSize, maxSize]) {
          final item = buildAdversarialCalculation(
            id: 'raceway-${rType.name}-$size',
            title: '${rType.displayName} $size boundary run',
            racewayType: rType,
            tradeSize: size,
            isNipple: size == minSize,
            fillPercentage: size == minSize ? 59.9 : 120.0,
          );

          await storageService.saveCalculation(item);
          final fetched = await storageService.getCalculationById('raceway-${rType.name}-$size');
          expect(fetched, isNotNull);
          expect(fetched!.raceway.type, equals(rType));
          expect(fetched.tradeSize, equals(size));
          expect(fetched.isNipple, equals(size == minSize));
        }
      }

      final allSaved = await storageService.getSavedCalculations();
      expect(allSaved.length, equals(RacewayType.values.length * 2));
    });

    test('1.4 Extreme Strings: 10,000 char notes, Unicode, Emojis, and JSON-like injection', () async {
      final hugeNotes = 'A' * 10000;
      const unicodeTitle = '⚡ Substation 3-Phase [Alpha & Omega] — 13.8kV » 480V 📐🔧';
      const maliciousChars = '{"hack": true, "key": [1, 2, 3]}, <script>alert("xss")</script>, \'\'; DROP TABLE;';
      const addressWithQuotes = '100 "Industrial" Parkway, Suite #4B \n Line 2 \t Tabbed';

      final extremeCalc = buildAdversarialCalculation(
        id: 'extreme-strings-1',
        title: unicodeTitle,
        notes: '$hugeNotes\n$maliciousChars',
        clientName: 'Client ⚡ "Quoted" Corp',
        siteAddress: addressWithQuotes,
      );

      await storageService.saveCalculation(extremeCalc);
      final retrieved = await storageService.getCalculationById('extreme-strings-1');

      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals(unicodeTitle));
      expect(retrieved.notes.length, equals(10000 + 1 + maliciousChars.length));
      expect(retrieved.notes.contains(maliciousChars), isTrue);
      expect(retrieved.clientName, equals('Client ⚡ "Quoted" Corp'));
      expect(retrieved.siteAddress, equals(addressWithQuotes));
    });

    test('1.5 High-Precision Float and State Round-Trip Fidelity', () async {
      final preciseCalc = buildAdversarialCalculation(
        id: 'precise-1',
        title: 'Precision Feeder',
        nominalVoltage: 208.123456,
        circuitLengthFeet: 345.6789,
        loadCurrentAmps: 42.98765,
        powerFactor: 0.87654,
        ambientTempC: -25.5,
        terminalRatingC: 90.0,
        fillPercentage: 38.123456,
      );

      final json = preciseCalc.toJson();
      final restored = SavedCalculation.fromJson(json);

      expect(restored.nominalVoltage, closeTo(208.123456, 1e-5));
      expect(restored.circuitLengthFeet, closeTo(345.6789, 1e-4));
      expect(restored.loadCurrentAmps, closeTo(42.98765, 1e-4));
      expect(restored.powerFactor, closeTo(0.87654, 1e-4));
      expect(restored.ambientTempC, equals(-25.5));
      expect(restored.terminalRatingC, equals(90.0));
      expect(restored.fillResult.fillPercentage, closeTo(38.123456, 1e-5));
    });
  });

  // =========================================================================
  // GROUP 2: Corrupted JSON Payloads & Adversarial Recovery
  // =========================================================================
  group('Challenger M4: Corrupted JSON Payloads & Adversarial Recovery', () {
    test('2.1 Truncated JSON Strings: Returns empty list gracefully without throwing', () async {
      final truncatedPayloads = [
        '[',
        '[{',
        '[{"id": "c1", "title": "Run',
        '[{"id": "c1", "raceway": {"type": "em',
        '[{"id": "c1", "conductors": [{"spec": {',
        '{"id": "c1"',
        '["unclosed string',
        '[,]',
      ];

      for (final truncated in truncatedPayloads) {
        SharedPreferences.setMockInitialValues({
          'electronorm_saved_calculations': truncated,
        });
        final service = SharedPreferencesStorageService();
        final results = await service.getSavedCalculations();
        expect(results, isEmpty, reason: 'Failed gracefully on truncated string: "$truncated"');
      }
    });

    test('2.2 Root Type Violations in SharedPreferences', () async {
      final invalidRootPayloads = [
        '42', // JSON number
        '-99.9', // JSON negative float
        'true', // JSON boolean
        'false',
        '"A standalone string"', // JSON string
        '{"single": "map_not_a_list"}', // JSON map
        '', // Empty string
        '    \n\t   ', // Whitespace string
        'null', // JSON null literal
      ];

      for (final payload in invalidRootPayloads) {
        SharedPreferences.setMockInitialValues({
          'electronorm_saved_calculations': payload,
        });
        final service = SharedPreferencesStorageService();
        final results = await service.getSavedCalculations();
        expect(results, isEmpty, reason: 'Must return empty list for root violation: "$payload"');
      }
    });

    test('2.3 Partial Corrupted Array: Rescues valid calculations and drops malformed ones', () async {
      final valid1 = buildAdversarialCalculation(id: 'v1', title: 'Valid Alpha');
      final valid2 = buildAdversarialCalculation(id: 'v2', title: 'Valid Beta');
      final valid3 = buildAdversarialCalculation(id: 'v3', title: 'Valid Gamma');

      final mixedCorruptList = [
        valid1.toJson(),
        12345, // int primitive -> dropped by (item is Map)
        'corrupt raw string', // string primitive -> dropped by (item is Map)
        false, // bool primitive -> dropped by (item is Map)
        null, // null element -> dropped by (item is Map)
        {'id': 999, 'title': 'Bad Types', 'conductors': 'not a list'}, // bad int id -> TypeError dropped
        {'id': 'c-bad-enum', 'raceway': {'type': 'unknownNonExistentRacewayType'}}, // bad enum -> StateError dropped
        {'id': 'c-bad-date', 'timestamp': 'not-a-timestamp-99999'}, // bad date -> FormatException dropped
        valid2.toJson(),
        {'id': 'c-bad-cond', 'conductors': [{'spec': {'gauge': 'invalidGauge'}}]}, // bad conductor spec -> StateError dropped
        {'id': 'c-bad-conductors-type', 'conductors': 'not a list'}, // TypeError dropped
        [1, 2, 3], // nested list -> dropped by (item is Map)
        valid3.toJson(),
      ];

      SharedPreferences.setMockInitialValues({
        'electronorm_saved_calculations': jsonEncode(mixedCorruptList),
      });

      final service = SharedPreferencesStorageService();
      final results = await service.getSavedCalculations();

      // Exactly the 3 valid items must be recovered
      expect(results.length, equals(3));
      final recoveredIds = results.map((e) => e.id).toSet();
      expect(recoveredIds, containsAll({'v1', 'v2', 'v3'}));
    });

    test('2.3b Blank Map and Fallbacks: Empty map deserializes safely to default calculation', () async {
      // Test that an empty map {} gracefully falls back to default values without crashing
      SharedPreferences.setMockInitialValues({
        'electronorm_saved_calculations': jsonEncode([
          {},
          {'id': 'phase-fallback', 'circuitPhase': 'nonExistentPhaseEnum'},
        ]),
      });

      final service = SharedPreferencesStorageService();
      final results = await service.getSavedCalculations();
      expect(results.length, equals(2));
      expect(results[0].circuitPhase, equals(CircuitPhase.singlePhase));
      expect(results[1].circuitPhase, equals(CircuitPhase.singlePhase));
    });

    test('2.4 Corrupted Technician Profile: Recovers with default profile fallback', () async {
      final corruptedProfilePayloads = [
        '{ malformed json :::: profile',
        '[1, 2, 3]', // List instead of map
        '"a string not a map"',
        '42',
        'true',
        '',
        '   ',
      ];

      for (final badProfile in corruptedProfilePayloads) {
        SharedPreferences.setMockInitialValues({
          'electronorm_technician_profile': badProfile,
        });
        final service = SharedPreferencesStorageService();
        final profile = await service.getProfile();

        expect(profile.technicianName, equals(TechnicianProfile.defaultProfile.technicianName));
        expect(profile.companyName, equals(TechnicianProfile.defaultProfile.companyName));
        expect(profile.licenseNumber, equals(TechnicianProfile.defaultProfile.licenseNumber));
      }
    });

    test('2.5 Corrupted Pro / Trial Dates & Flags Resilience', () async {
      // Test invalid ISO trial date string
      SharedPreferences.setMockInitialValues({
        'electronorm_trial_start_date': 'INVALID_TIMESTAMP_2026',
        'electronorm_is_pro_subscriber': true,
      });
      final service1 = SharedPreferencesStorageService();
      expect(await service1.getTrialStartDate(), isNull);
      expect(await service1.isTrialActive(), isFalse);
      expect(await service1.getRemainingTrialDays(), equals(0));

      // Test trial date 100 days in the past (expired trial)
      final pastDate = DateTime.now().subtract(const Duration(days: 100)).toIso8601String();
      SharedPreferences.setMockInitialValues({
        'electronorm_trial_start_date': pastDate,
        'electronorm_is_pro_subscriber': false,
        'electronorm_demo_mode': false,
      });
      final service2 = SharedPreferencesStorageService();
      expect(await service2.isTrialActive(), isFalse);
      expect(await service2.getRemainingTrialDays(), equals(0));
      expect(await service2.isProSubscriber(), isFalse);

      // Test trial date with zero days elapsed (just started)
      final todayDate = DateTime.now().toIso8601String();
      SharedPreferences.setMockInitialValues({
        'electronorm_trial_start_date': todayDate,
        'electronorm_is_pro_subscriber': false,
      });
      final service3 = SharedPreferencesStorageService();
      expect(await service3.isTrialActive(), isTrue);
      expect(await service3.getRemainingTrialDays(), equals(14));
      // Even if is_pro was false in prefs, active trial yields true for isProSubscriber
      expect(await service3.isProSubscriber(), isTrue);
    });

    test('2.6 Random / Binary and Control Bytes in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'electronorm_saved_calculations': '\u0000\u0001\u0002\uFFFF\uFFFE\u{1F4A9}',
        'electronorm_technician_profile': '\x00\xFF\xFE\xFD',
      });
      final service = SharedPreferencesStorageService();
      expect(await service.getSavedCalculations(), isEmpty);
      expect((await service.getProfile()).technicianName, equals('Carlos Mendoza'));
    });
  });

  // =========================================================================
  // GROUP 3: Concurrent & Rapid Sequential CRUD Stress
  // =========================================================================
  group('Challenger M4: Concurrent & Rapid Sequential CRUD Stress', () {
    late SharedPreferencesStorageService storageService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = SharedPreferencesStorageService();
      StorageService.instance = storageService;
    });

    test('3.1 Rapid Sequential Lifecycle: 80 Saves, 40 In-Place Updates, 20 Deletes', () async {
      // 1. Rapid sequential save of 80 items
      for (int i = 0; i < 80; i++) {
        await storageService.saveCalculation(buildAdversarialCalculation(
          id: 'seq-$i',
          title: 'Original Title $i',
          loadCurrentAmps: 10.0 + i,
        ));
      }
      var all = await storageService.getSavedCalculations();
      expect(all.length, equals(80));

      // 2. Rapid sequential in-place updates of first 40 items
      for (int i = 0; i < 40; i++) {
        final existing = await storageService.getCalculationById('seq-$i');
        expect(existing, isNotNull);
        final updated = existing!.copyWith(
          title: 'UPDATED Title $i',
          notes: 'Revision notes $i',
          loadCurrentAmps: 99.0 + i,
        );
        await storageService.saveCalculation(updated);
      }
      all = await storageService.getSavedCalculations();
      expect(all.length, equals(80), reason: 'In-place updates must not inflate item count');

      // Verify updated values
      final updated0 = await storageService.getCalculationById('seq-0');
      expect(updated0!.title, equals('UPDATED Title 0'));
      expect(updated0.loadCurrentAmps, equals(99.0));

      // 3. Rapid sequential deletion of 20 items (indices 0..19)
      for (int i = 0; i < 20; i++) {
        await storageService.deleteCalculation('seq-$i');
      }
      all = await storageService.getSavedCalculations();
      expect(all.length, equals(60));

      // Verify deleted items are gone
      for (int i = 0; i < 20; i++) {
        expect(await storageService.getCalculationById('seq-$i'), isNull);
      }
      // Remaining items are still intact
      for (int i = 20; i < 80; i++) {
        expect(await storageService.getCalculationById('seq-$i'), isNotNull);
      }
    });

    test('3.2 Idempotency: Saving the identical ID repeatedly updates cleanly without duplicates', () async {
      const targetId = 'idempotent-calc';

      for (int version = 1; version <= 25; version++) {
        await storageService.saveCalculation(buildAdversarialCalculation(
          id: targetId,
          title: 'Calculation Version $version',
          fillPercentage: version * 2.0,
        ));
      }

      final all = await storageService.getSavedCalculations();
      expect(all.length, equals(1));
      expect(all.first.id, equals(targetId));
      expect(all.first.title, equals('Calculation Version 25'));
      expect(all.first.fillResult.fillPercentage, equals(50.0));
    });

    test('3.3 Non-Existent and Malformed Deletion Safety', () async {
      await storageService.saveCalculation(buildAdversarialCalculation(id: 'existing-1'));

      // Attempt deleting empty string, non-existent, and special character IDs
      await storageService.deleteCalculation('');
      await storageService.deleteCalculation('   ');
      await storageService.deleteCalculation('does-not-exist');
      await storageService.deleteCalculation('!@#\$%^&*()');
      await storageService.deleteCalculation('null');

      final all = await storageService.getSavedCalculations();
      expect(all.length, equals(1));
      expect(all.first.id, equals('existing-1'));

      // Delete existing item twice
      await storageService.deleteCalculation('existing-1');
      await storageService.deleteCalculation('existing-1');
      expect(await storageService.getSavedCalculations(), isEmpty);
    });

    test('3.4 Concurrent Save Robustness (Future.wait without crash)', () async {
      // Dispatch 20 concurrent save operations simultaneously
      final futures = <Future<void>>[];
      for (int i = 0; i < 20; i++) {
        futures.add(storageService.saveCalculation(buildAdversarialCalculation(
          id: 'concurrent-$i',
          title: 'Concurrent Run $i',
        )));
      }

      // Must complete without unhandled platform exceptions or corrupted JSON state
      await Future.wait(futures);

      final result = await storageService.getSavedCalculations();
      expect(result, isNotEmpty);
      // Ensure storage JSON remains completely parseable and uncorrupted
      for (final item in result) {
        expect(item.id, startsWith('concurrent-'));
      }
    });

    test('3.5 ClearAll Atomic Purge', () async {
      await storageService.saveCalculation(buildAdversarialCalculation(id: 'to-clear-1'));
      await storageService.saveCalculation(buildAdversarialCalculation(id: 'to-clear-2'));
      await storageService.saveProfile(const TechnicianProfile(technicianName: 'To Be Cleared'));
      await storageService.setProSubscriber(true);
      await storageService.startTrial();
      await storageService.setDemoMode(true);

      await storageService.clearAll();

      expect(await storageService.getSavedCalculations(), isEmpty);
      expect((await storageService.getProfile()).technicianName, equals('Carlos Mendoza'));
      expect(await storageService.isProSubscriber(), isFalse);
      expect(await storageService.isDemoMode(), isFalse);
      expect(await storageService.isTrialActive(), isFalse);
      expect(await storageService.getSubscriptionTier(), isNull);
    });
  });

  // =========================================================================
  // GROUP 4: SavedProjectsScreen UI Stress Testing with 100+ Items
  // =========================================================================
  group('Challenger M4: SavedProjectsScreen UI Stress Testing', () {
    late SharedPreferencesStorageService storageService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = SharedPreferencesStorageService();
      StorageService.instance = storageService;
    });

    testWidgets('4.1 Multi-Criteria Sorting on 100 Saved Calculations in UI', (tester) async {
      final baseDate = DateTime(2026, 1, 1);
      final List<SavedCalculation> items = [];

      // Create 100 items with staggered titles, fill percentages, and dates
      for (int i = 0; i < 100; i++) {
        final paddedIndex = i.toString().padLeft(3, '0');
        items.add(buildAdversarialCalculation(
          id: 'ui-calc-$i',
          title: 'Project $paddedIndex',
          fillPercentage: (i % 60).toDouble() + 5.0, // Range 5.0 to 64.0
          timestamp: baseDate.add(Duration(days: i)),
        ));
      }

      for (final item in items) {
        await storageService.saveCalculation(item);
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: SavedProjectsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify screen rendered and shows total count chip
      expect(find.text('All (100)'), findsOneWidget);

      // 1. Sort Alphabetical (A - Z)
      await tester.tap(find.byKey(const Key('btnSortProjects')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alphabetical (A - Z)'));
      await tester.pumpAndSettle();

      expect(find.text('Project 000'), findsOneWidget);

      // 2. Sort Fill Percentage (High to Low)
      await tester.tap(find.byKey(const Key('btnSortProjects')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fill Percentage (High to Low)'));
      await tester.pumpAndSettle();

      // Highest fill was 64.0%
      expect(find.textContaining('64.0%'), findsWidgets);

      // 3. Sort Oldest First
      await tester.tap(find.byKey(const Key('btnSortProjects')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oldest First'));
      await tester.pumpAndSettle();

      expect(find.text('Project 000'), findsOneWidget);
    });

    testWidgets('4.2 Real-Time Search Filtering on 100 Calculations', (tester) async {
      for (int i = 0; i < 100; i++) {
        await storageService.saveCalculation(buildAdversarialCalculation(
          id: 'search-$i',
          title: i == 42 ? 'Special Hospital Emergency Feeder' : 'Generic Run #$i',
          clientName: i == 77 ? 'St. Jude Healthcare' : 'General Client',
          notes: i == 15 ? 'Secret subterranean raceway note' : 'Standard note',
        ));
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: SavedProjectsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Search by title keyword
      await tester.enterText(find.byKey(const Key('inputSearchProjects')), 'Hospital');
      await tester.pumpAndSettle();
      expect(find.text('Special Hospital Emergency Feeder'), findsOneWidget);
      expect(find.textContaining('Generic Run'), findsNothing);

      // Search by client name
      await tester.enterText(find.byKey(const Key('inputSearchProjects')), 'St. Jude');
      await tester.pumpAndSettle();
      expect(find.text('Generic Run #77'), findsOneWidget);

      // Search by notes
      await tester.enterText(find.byKey(const Key('inputSearchProjects')), 'subterranean');
      await tester.pumpAndSettle();
      expect(find.text('Generic Run #15'), findsOneWidget);

      // Search with non-matching term: shows empty state
      await tester.enterText(find.byKey(const Key('inputSearchProjects')), 'NON_EXISTENT_QUERY_XYZ');
      await tester.pumpAndSettle();
      expect(find.textContaining('No Calculations Match'), findsOneWidget);

      // Clear search via clear icon
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      expect(find.text('All (100)'), findsOneWidget);
    });

    testWidgets('4.3 Filter Chips Stress Test: Compliant, Caution, Overfilled, Jam Hazard', (tester) async {
      // 4 distinct items matching each threshold
      final items = [
        buildAdversarialCalculation(id: 'f1', title: 'Comp 1', fillPercentage: 35.0),
        buildAdversarialCalculation(id: 'f2', title: 'Caut 1', fillPercentage: 45.0),
        buildAdversarialCalculation(id: 'f3', title: 'Over 1', fillPercentage: 65.0),
        buildAdversarialCalculation(id: 'f4', title: 'Jam 1', fillPercentage: 38.0, hasJamRisk: true),
      ];

      for (final item in items) {
        await storageService.saveCalculation(item);
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: SavedProjectsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Compliant Filter (fill <= 40%)
      await tester.tap(find.text('Compliant'));
      await tester.pumpAndSettle();
      expect(find.text('Comp 1'), findsOneWidget);
      expect(find.text('Jam 1'), findsOneWidget);
      expect(find.text('Caut 1'), findsNothing);
      expect(find.text('Over 1'), findsNothing);

      // Caution Filter (40% < fill <= 50%)
      await tester.tap(find.text('Caution'));
      await tester.pumpAndSettle();
      expect(find.text('Caut 1'), findsOneWidget);
      expect(find.text('Comp 1'), findsNothing);
      expect(find.text('Over 1'), findsNothing);

      // Overfilled Filter (fill > 50%)
      await tester.tap(find.text('Overfilled'));
      await tester.pumpAndSettle();
      expect(find.text('Over 1'), findsOneWidget);
      expect(find.text('Comp 1'), findsNothing);
      expect(find.text('Caut 1'), findsNothing);

      // Jam Hazard Filter (hasJamRisk == true)
      await tester.tap(find.text('Jam Hazard'));
      await tester.pumpAndSettle();
      expect(find.text('Jam 1'), findsOneWidget);
      expect(find.text('Comp 1'), findsNothing);
      expect(find.text('Over 1'), findsNothing);
    });

    testWidgets('4.4 Two-step Deletion Dialog and Empty State Transition', (tester) async {
      await storageService.saveCalculation(buildAdversarialCalculation(
        id: 'del-item-1',
        title: 'Disposable Calculation',
      ));

      await tester.pumpWidget(
        const MaterialApp(
          home: SavedProjectsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Disposable Calculation'), findsOneWidget);

      // 1. Open delete dialog, then cancel
      await tester.tap(find.byKey(const Key('btnDeleteProject_del-item-1')));
      await tester.pumpAndSettle();
      expect(find.text('Delete Calculation?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Disposable Calculation'), findsOneWidget);

      // 2. Open delete dialog, then confirm delete
      await tester.tap(find.byKey(const Key('btnDeleteProject_del-item-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btnConfirmDelete')));
      await tester.pumpAndSettle();

      // Verify item deleted and empty state rendered
      expect(find.text('Disposable Calculation'), findsNothing);
      expect(find.text('No Saved Calculations Yet'), findsOneWidget);
      expect(await storageService.getSavedCalculations(), isEmpty);
    });
  });

  // =========================================================================
  // GROUP 5: Screen-Level Robustness Under Corrupted Storage & Concurrency
  // =========================================================================
  group('Challenger M4: Screen-Level Robustness Under Corrupted Storage & Concurrency', () {
    testWidgets('5.1 SavedProjectsScreen Launches Gracefully with Completely Corrupted JSON in Preferences', (tester) async {
      SharedPreferences.setMockInitialValues({
        'electronorm_saved_calculations': '{ completely corrupted JSON payload ::: !!!',
        'electronorm_technician_profile': '1234567890',
      });
      StorageService.instance = SharedPreferencesStorageService();

      await tester.pumpWidget(
        const MaterialApp(
          home: SavedProjectsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Must display clean empty state rather than crash
      expect(find.text('No Saved Calculations Yet'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('5.2 PaywallScreen Launches Gracefully with Corrupted Subscription & Trial Keys', (tester) async {
      SharedPreferences.setMockInitialValues({
        'electronorm_is_pro_subscriber': 'invalid_string_not_bool',
        'electronorm_subscription_tier': 'unrecognized_tier_xyz',
        'electronorm_trial_start_date': 'corrupted_timestamp',
        'electronorm_demo_mode': 99999,
      });
      StorageService.instance = SharedPreferencesStorageService();

      await tester.pumpWidget(
        const MaterialApp(
          home: PaywallScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verifies UI rendered safely
      expect(find.text('ElectroNorm Pro'), findsWidgets);
      expect(find.byKey(const Key('btnSubscribePaywall')), findsOneWidget);

      // Trigger 5-tap secret demo toggle to verify recovery
      final secretToggleFinder = find.byKey(const Key('btnSecretDemoToggle'));
      for (int i = 0; i < 5; i++) {
        await tester.tap(secretToggleFinder);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      // Pro state is restored
      expect(await StorageService.instance.isProSubscriber(), isTrue);
    });

    testWidgets('5.3 CalculatorScreen Loads Saved Calculation with Null Optional Fields Safely', (tester) async {
      final storageService = SharedPreferencesStorageService();
      StorageService.instance = storageService;

      // Create calculation with null optional fields and boundary parameters
      final boundaryCalc = buildAdversarialCalculation(
        id: 'boundary-calc-null-opts',
        title: 'Zero Drop Null Derating Feeder',
        racewayType: RacewayType.fmc,
        tradeSize: '1/2',
        isNipple: true,
      ).copyWith(
        voltageDropResult: null,
        deratingResult: null,
        clientName: '',
        siteAddress: '',
      );

      await storageService.saveCalculation(boundaryCalc);

      await tester.pumpWidget(
        const MaterialApp(
          home: CalculatorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Open SavedProjectsScreen from AppBar
      await tester.tap(find.byKey(const Key('btnSavedProjectsAppBar')));
      await tester.pumpAndSettle();

      // Tap on the saved project card to load it
      await tester.tap(find.byKey(const Key('cardProject_boundary-calc-null-opts')));
      await tester.pumpAndSettle();

      // Should return to CalculatorScreen and show SnackBar confirmation
      expect(find.text('Loaded "Zero Drop Null Derating Feeder" into calculator'), findsOneWidget);
    });

    test('5.4 Stress Test: Concurrent Mixed Saves, Deletes, and Updates', () async {
      SharedPreferences.setMockInitialValues({});
      final service = SharedPreferencesStorageService();

      // Pre-seed 10 items
      for (int i = 0; i < 10; i++) {
        await service.saveCalculation(buildAdversarialCalculation(
          id: 'pre-$i',
          title: 'Pre-seeded Item $i',
        ));
      }

      // Concurrently run 10 new saves, 5 updates, and 5 deletes
      final concurrentOperations = <Future<void>>[];

      for (int i = 0; i < 10; i++) {
        concurrentOperations.add(service.saveCalculation(buildAdversarialCalculation(
          id: 'new-$i',
          title: 'New Concurrency Run $i',
        )));
      }
      for (int i = 0; i < 5; i++) {
        concurrentOperations.add(service.saveCalculation(buildAdversarialCalculation(
          id: 'pre-$i',
          title: 'CONCURRENTLY UPDATED $i',
        )));
      }
      for (int i = 5; i < 10; i++) {
        concurrentOperations.add(service.deleteCalculation('pre-$i'));
      }

      // Execute all concurrently
      await Future.wait(concurrentOperations);

      // Verify storage integrity: should not throw, JSON remains completely valid
      final remaining = await service.getSavedCalculations();
      expect(remaining, isNotEmpty);
      for (final item in remaining) {
        expect(item.id, isNotEmpty);
        expect(item.title, isNotEmpty);
      }
    });
  });
}

