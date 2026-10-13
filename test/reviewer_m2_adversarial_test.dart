import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:electronorm/catalogs/conductor_catalog.dart';
import 'package:electronorm/catalogs/raceway_catalog.dart';
import 'package:electronorm/models/conductor.dart';
import 'package:electronorm/models/raceway.dart';
import 'package:electronorm/screens/calculator_screen.dart';
import 'package:electronorm/theme/app_theme.dart';
import 'package:electronorm/widgets/packing_algorithm.dart';

void main() {
  group('Reviewer M2 Adversarial Suite: Boundary Checks & Stress Invariants', () {
    testWidgets('Boundary 1: Empty conductor schedule renders gracefully without crashes',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CalculatorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Clear all initial conductors by tapping delete on each group
      while (find.byIcon(Icons.delete_outline).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.delete_outline).first);
        await tester.pumpAndSettle();
      }

      // Verify empty state display
      expect(find.text('0 conductors packed'), findsOneWidget);
      expect(find.textContaining('COMPLIANT — 0.0% / 0% max'), findsOneWidget);
      expect(
        find.text('No conductors added. Tap "Add Conductor" or select a preset.'),
        findsOneWidget,
      );

      // Verify derating and voltage drop cards survive empty schedule
      expect(find.textContaining('Final Allowable Ampacity:'), findsOneWidget);
      expect(find.textContaining('Branch Limit: 3%'), findsOneWidget);
    });

    testWidgets('Boundary 2: Single large conductor (500 kcmil in 1/2" EMT) triggers overfill & upsizes to 1-1/4" EMT',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CalculatorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Clear default conductors
      while (find.byIcon(Icons.delete_outline).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.delete_outline).first);
        await tester.pumpAndSettle();
      }

      // Add 1x 500 kcmil conductor via Add dialog
      await tester.tap(find.byKey(const Key('btnAddConductor')));
      await tester.pumpAndSettle();

      // Select 500 kcmil in dropdown
      await tester.tap(find.text('12 AWG').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('500 kcmil').last);
      await tester.pumpAndSettle();

      // Tap Add to Schedule
      await tester.tap(find.text('Add to Schedule'));
      await tester.pumpAndSettle();

      // Switch conduit to 1/2" EMT
      // Open trade size dropdown
      final tradeSizeDropdown = find.widgetWithText(DropdownButtonFormField<String>, '3/4"');
      if (tradeSizeDropdown.evaluate().isNotEmpty) {
        await tester.tap(tradeSizeDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('1/2"').last);
        await tester.pumpAndSettle();
      }

      // 500 kcmil (area 0.7073 sq in) in 1/2" EMT (area 0.304 sq in) -> Overfilled!
      expect(find.textContaining('OVERFILLED'), findsOneWidget);

      // Upsize recommendation pill must appear and recommend 1-1/4" EMT
      final upsizePill = find.byKey(const Key('btnUpsize'));
      expect(upsizePill, findsOneWidget);
      expect(find.textContaining('1-1/4" EMT'), findsOneWidget);

      // Tap upsize pill
      await tester.tap(upsizePill);
      await tester.pumpAndSettle();

      // Now raceway should be 1-1/4" EMT and status COMPLIANT (53% limit for 1 wire)
      expect(find.textContaining('1-1/4" EMT'), findsOneWidget);
      expect(find.textContaining('COMPLIANT'), findsOneWidget);
      expect(find.byKey(const Key('btnUpsize')), findsNothing);
    });

    test('Boundary 3: 35 small conductors packing algorithm integrity and performance', () {
      const algorithm = GoldenSpiralPackingAlgorithm();
      final emt2 = RacewayCatalog.getProfile(RacewayType.emt, '2');
      final radius = emt2.internalDiameterInches / 2.0;
      final spec14 = ConductorCatalog.getSpec(gauge: '14 AWG');

      final groups = [
        ConductorGroup(id: '1', spec: spec14, count: 35, role: 'phaseA'),
      ];

      // Warm-up JIT
      for (int i = 0; i < 5; i++) {
        algorithm.pack(conduitRadius: radius, groups: groups);
      }

      final stopwatch = Stopwatch()..start();
      const runs = 20;
      for (int i = 0; i < runs; i++) {
        algorithm.pack(conduitRadius: radius, groups: groups);
      }
      stopwatch.stop();

      final avgMicroseconds = stopwatch.elapsedMicroseconds / runs;
      expect(avgMicroseconds, lessThan(800)); // Under 0.8ms average in debug test runner

      final packed = algorithm.pack(conduitRadius: radius, groups: groups);
      expect(packed.length, equals(35));

      // Invariant: all 35 conductors are strictly inside the conduit bore
      for (final p in packed) {
        final dist = math.sqrt(p.normalizedX * p.normalizedX + p.normalizedY * p.normalizedY);
        expect(dist + p.normalizedRadius, lessThanOrEqualTo(1.001));
      }

      // Invariant: no severe overlap among packed conductors
      for (int i = 0; i < packed.length; i++) {
        for (int j = i + 1; j < packed.length; j++) {
          final pi = packed[i];
          final pj = packed[j];
          final dist = math.sqrt(
            math.pow(pi.normalizedX - pj.normalizedX, 2) +
            math.pow(pi.normalizedY - pj.normalizedY, 2),
          );
          final minDist = pi.normalizedRadius + pj.normalizedRadius;
          expect(dist, greaterThanOrEqualTo(minDist - 0.015)); // Tolerable contact packing
        }
      }
    });

    testWidgets('Boundary 4: Extreme overfill state (> 2000% fill) beyond 4" raceway capacity',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CalculatorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Clear conductors
      while (find.byIcon(Icons.delete_outline).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.delete_outline).first);
        await tester.pumpAndSettle();
      }

      // Add 500 kcmil conductor
      await tester.tap(find.byKey(const Key('btnAddConductor')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('12 AWG').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('500 kcmil').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to Schedule'));
      await tester.pumpAndSettle();

      // Increase quantity to 15 using stepper
      final stepperAdd = find.byKey(const Key('btnStepperAdd_0'));
      for (int i = 0; i < 14; i++) {
        await tester.tap(stepperAdd);
        await tester.pumpAndSettle();
      }

      // 15x 500 kcmil = 15 * 0.7073 = 10.6095 sq in.
      // In 4" EMT, 40% area is 5.089 sq in. So 15x 500 kcmil CANNOT fit in any trade size <= 4"!
      expect(find.textContaining('OVERFILLED'), findsOneWidget);

      // Verify that when no raceway up to 4" can fit the run,
      // the upsize button gracefully hides instead of crashing or showing invalid sizes.
      expect(find.byKey(const Key('btnUpsize')), findsNothing);
    });

    testWidgets('Boundary 5: Aggregated Jam Ratio warning triggers for 3 separate phase wires of 250 kcmil in 2" EMT',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CalculatorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Clear default conductors
      while (find.byIcon(Icons.delete_outline).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.delete_outline).first);
        await tester.pumpAndSettle();
      }

      // Add 1x 250 kcmil Phase A
      await tester.tap(find.byKey(const Key('btnAddConductor')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('12 AWG').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('250 kcmil').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to Schedule'));
      await tester.pumpAndSettle();

      // Add 1x 250 kcmil Phase B
      await tester.tap(find.byKey(const Key('btnAddConductor')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('12 AWG').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('250 kcmil').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phase B'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to Schedule'));
      await tester.pumpAndSettle();

      // Add 1x 250 kcmil Phase C
      await tester.tap(find.byKey(const Key('btnAddConductor')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('12 AWG').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('250 kcmil').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phase C'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to Schedule'));
      await tester.pumpAndSettle();

      // Select 2" EMT
      final tradeSizeDropdown = find.widgetWithText(DropdownButtonFormField<String>, '3/4"');
      if (tradeSizeDropdown.evaluate().isNotEmpty) {
        await tester.tap(tradeSizeDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('2"').last);
        await tester.pumpAndSettle();
      }

      // 2" EMT ID = 2.067", 250 kcmil OD = 0.711".
      // Jam Ratio = 2.067 / 0.711 = 2.91 (between 2.80 and 3.20)
      // Must trigger CRITICAL JAM RISK alert banner!
      expect(find.textContaining('CRITICAL JAM RISK (Ratio 2.91)'), findsOneWidget);

      // Now add a 4th wire: #4 AWG Ground wire
      await tester.tap(find.byKey(const Key('btnAddConductor')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('12 AWG').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('4 AWG').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ground'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to Schedule'));
      await tester.pumpAndSettle();

      // The 3 phase wires are still identical 250 kcmil, so jam risk MUST persist!
      expect(find.textContaining('CRITICAL JAM RISK (Ratio 2.91)'), findsOneWidget);
    });

    testWidgets('Ergonomics: Quick Presets switch raceway and schedule instantaneously',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CalculatorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Cycle rapidly through presets
      await tester.tap(find.text('3x 500k + 1x #3 Grd'));
      await tester.pumpAndSettle();
      expect(find.textContaining('3" EMT'), findsOneWidget);

      await tester.tap(find.text('4x #12 Branch'));
      await tester.pumpAndSettle();
      expect(find.textContaining('1/2" EMT'), findsOneWidget);

      await tester.tap(find.text('3x 4/0 Service'));
      await tester.pumpAndSettle();
      expect(find.textContaining('2" EMT'), findsOneWidget);

      await tester.tap(find.text('3x #10 + 1x #12 Grd'));
      await tester.pumpAndSettle();
      expect(find.textContaining('3/4" EMT'), findsOneWidget);
    });

    testWidgets('Dropdown Sync: Trade size and raceway dropdown widgets match state after preset and upsize',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CalculatorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap preset: 3x 500k + 1x #3 Grd (sets 3" EMT)
      await tester.tap(find.text('3x 500k + 1x #3 Grd'));
      await tester.pumpAndSettle();

      // Check what is displayed inside the Trade Size DropdownButtonFormField
      expect(find.widgetWithText(DropdownButtonFormField<String>, '3"'), findsOneWidget);

      // Now add 500 kcmil conductors to make it overfilled
      final stepperAdd = find.byKey(const Key('btnStepperAdd_0'));
      await tester.tap(stepperAdd); // 4x
      await tester.pumpAndSettle();
      await tester.tap(stepperAdd); // 5x (overfilled!)
      await tester.pumpAndSettle();

      final upsizePill = find.byKey(const Key('btnUpsize'));
      expect(upsizePill, findsOneWidget);

      // Tap upsize pill -> upsizes to 3-1/2"
      await tester.tap(upsizePill);
      await tester.pumpAndSettle();

      // Does the dropdown show 3-1/2"?
      expect(find.widgetWithText(DropdownButtonFormField<String>, '3-1/2"'), findsOneWidget);
    });
  });
}
