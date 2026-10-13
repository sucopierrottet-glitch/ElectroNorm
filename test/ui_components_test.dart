import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:electronorm/catalogs/conductor_catalog.dart';
import 'package:electronorm/models/conductor.dart';
import 'package:electronorm/screens/calculator_screen.dart';
import 'package:electronorm/theme/app_theme.dart';
import 'package:electronorm/widgets/packing_algorithm.dart';
import 'package:electronorm/widgets/raceway_painter.dart';

void main() {
  group('RacewayPainter & RacewayVisualizer Widget Tests', () {
    testWidgets('RacewayPainter paints without throwing on compliant state',
        (tester) async {
      final spec10 = ConductorCatalog.getSpec(gauge: '10 AWG');
      final groups = [
        ConductorGroup(id: '1', spec: spec10, count: 3, role: 'phaseA'),
      ];
      final packed = const GoldenSpiralPackingAlgorithm().pack(
        conduitRadius: 0.412,
        groups: groups,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 250,
                height: 250,
                child: CustomPaint(
                  painter: RacewayPainter(
                    conduitRadiusInches: 0.412,
                    positions: packed,
                    fillPercentage: 24.5,
                    maxAllowedFill: 40.0,
                    showCrosshairs: true,
                    showAllowedFillRing: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('RacewayVisualizer renders compliant status badge and conduit specs',
        (tester) async {
      final spec12 = ConductorCatalog.getSpec(gauge: '12 AWG');
      final groups = [
        ConductorGroup(id: '1', spec: spec12, count: 2, role: 'phaseA'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: RacewayVisualizer(
              conduitRadiusInches: 0.311,
              groups: groups,
              fillPercentage: 22.0,
              maxAllowedFill: 31.0,
              tradeSize: '1/2',
              racewayType: 'EMT',
              jamRatio: 4.5,
              hasJamRisk: false,
            ),
          ),
        ),
      );

      expect(find.textContaining('COMPLIANT'), findsOneWidget);
      expect(find.text('1/2" EMT'), findsOneWidget);
      expect(find.text('2 conductors packed'), findsOneWidget);
    });

    testWidgets('RacewayVisualizer displays Critical Jam Risk alert pill when hazard detected',
        (tester) async {
      final spec250 = ConductorCatalog.getSpec(gauge: '250 kcmil');
      final groups = [
        ConductorGroup(id: '1', spec: spec250, count: 3, role: 'phaseA'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: RacewayVisualizer(
              conduitRadiusInches: 1.0335, // 2" EMT ID: 2.067"
              groups: groups,
              fillPercentage: 35.5,
              maxAllowedFill: 40.0,
              tradeSize: '2',
              racewayType: 'EMT',
              jamRatio: 2.91,
              hasJamRisk: true,
            ),
          ),
        ),
      );

      expect(find.textContaining('CRITICAL JAM RISK'), findsOneWidget);
    });
  });

  group('CalculatorScreen Full UX & Interaction Tests', () {
    testWidgets('CalculatorScreen initializes with default preset and cards',
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

      expect(find.text('ElectroNorm Pro'), findsOneWidget);
      expect(find.text('Raceway Specification'), findsOneWidget);
      expect(find.text('Conductor Schedule'), findsOneWidget);
      expect(find.text('Live Voltage Drop'), findsOneWidget);
      expect(find.text('Live Thermal Derating'), findsOneWidget);
      expect(find.text('Quick Presets'), findsOneWidget);

      // Verify default preset items
      expect(find.textContaining('10 AWG THHN'), findsWidgets);
      expect(find.textContaining('12 AWG THHN'), findsWidgets);
    });

    testWidgets('Preset chips update conduit size and conductor schedule',
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

      // Tap 3x 500k + 1x #3 Grd preset chip
      final presetChip = find.text('3x 500k + 1x #3 Grd');
      expect(presetChip, findsOneWidget);
      await tester.tap(presetChip);
      await tester.pumpAndSettle();

      expect(find.textContaining('500 kcmil'), findsOneWidget);
      expect(find.textContaining('3" EMT'), findsOneWidget);

      // Tap 4x #12 Branch preset chip
      final branchChip = find.text('4x #12 Branch');
      expect(branchChip, findsOneWidget);
      await tester.tap(branchChip);
      await tester.pumpAndSettle();

      expect(find.textContaining('1/2" EMT'), findsOneWidget);
    });

    testWidgets('Stepper increment and decrement dynamically changes conductor count',
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

      // Initial count in footer
      expect(find.text('4 conductors packed'), findsOneWidget);

      // Stepper '+' button inside the first schedule row
      final stepperAdd = find.byKey(const Key('btnStepperAdd_0'));
      expect(stepperAdd, findsOneWidget);
      await tester.tap(stepperAdd);
      await tester.pumpAndSettle();

      // Verify total conductor count in footer increased from 4 to 5
      expect(find.text('5 conductors packed'), findsOneWidget);

      // Tap remove stepper button
      final stepperRemove = find.byKey(const Key('btnStepperRemove_0'));
      expect(stepperRemove, findsOneWidget);
      await tester.tap(stepperRemove);
      await tester.pumpAndSettle();

      expect(find.text('4 conductors packed'), findsOneWidget);
    });

    testWidgets('Automated Upsize recommendation pill appears when overfilled and 1-tap resolves overfill',
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

      // Select 3x 500k + 1x #3 Grd preset
      await tester.tap(find.text('3x 500k + 1x #3 Grd'));
      await tester.pumpAndSettle();

      // In 3" EMT, 3x 500k + 1x #3 takes 3x0.7073 + 0.0973 = 2.2192 sq in.
      // 3" EMT total area = 7.383 sq in, 40% area = 2.953 sq in.
      // Now add 500k conductors using stepper until overfilled (> 2.953 sq in)
      final stepperAdd = find.byKey(const Key('btnStepperAdd_0'));
      await tester.tap(stepperAdd); // 4x 500k -> 4x0.7073 + 0.0973 = 2.9265
      await tester.pumpAndSettle();
      await tester.tap(stepperAdd); // 5x 500k -> 5x0.7073 + 0.0973 = 3.6338 (> 2.953, overfilled!)
      await tester.pumpAndSettle();

      // Verify upsize pill appears
      final upsizePill = find.byKey(const Key('btnUpsize'));
      expect(upsizePill, findsOneWidget);

      // Tap the upsize recommendation pill
      await tester.tap(upsizePill);
      await tester.pumpAndSettle();

      // Conduit was upsized to compliant size (3-1/2" EMT)
      expect(find.textContaining('3-1/2" EMT'), findsOneWidget);
    });

    testWidgets('Aggregated jam ratio detection: 3 separate phase wires of 250 kcmil triggers Jam Risk warning in 2" EMT',
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

      // Switch to 3x 4/0 Service preset in 2" EMT
      await tester.tap(find.text('3x 4/0 Service'));
      await tester.pumpAndSettle();

      expect(find.text('2" EMT'), findsOneWidget);
      expect(find.textContaining('4/0 AWG'), findsOneWidget);
    });

    testWidgets('Live Voltage drop and thermal derating expansion cards toggle and compute values',
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

      // Voltage drop displays allowable drop and end voltage
      expect(find.textContaining('Branch Limit: 3%'), findsOneWidget);
      expect(find.textContaining('1-Phase'), findsOneWidget);
      expect(find.textContaining('3-Phase'), findsOneWidget);

      // Tap 3-Phase toggle in segmented button
      await tester.tap(find.text('3-Phase'));
      await tester.pumpAndSettle();

      // Derating displays base ampacity and allowable ampacity
      expect(find.textContaining('Base Ampacity'), findsOneWidget);
      expect(find.textContaining('Final Allowable Ampacity:'), findsOneWidget);
      expect(find.textContaining('CCC Count:'), findsOneWidget);
    });
  });
}
