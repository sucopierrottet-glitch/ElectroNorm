import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:electronorm/screens/calculator_screen.dart';
import 'package:electronorm/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adversarial Suite 1: Conductor Schedule Rapid Mutation (Add, Increment, Decrement, Clear)', () {
    testWidgets('Rapid clearing of all default conductors results in stable empty state',
        (tester) async {
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

      // Initial state: default preset has 4 conductor groups
      expect(find.text('4 conductors packed'), findsOneWidget);

      // Rapidly delete groups until empty
      while (find.byKey(const Key('btnDeleteGroup_0')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('btnDeleteGroup_0')));
        await tester.pumpAndSettle();
      }

      // Empty schedule state invariants
      expect(find.text('0 conductors packed'), findsOneWidget);
      expect(find.textContaining('0.0% / 0% max'), findsOneWidget);
      expect(
        find.text('No conductors added. Tap "Add Conductor" or select a preset.'),
        findsOneWidget,
      );

      // Verify CustomPaint renders without throwing
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Add conductor via modal dialog with custom parameters and rapid quantity changes',
        (tester) async {
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

      // Clear existing conductors to start clean
      while (find.byKey(const Key('btnDeleteGroup_0')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('btnDeleteGroup_0')));
        await tester.pumpAndSettle();
      }

      // Open Add Conductor dialog
      final addBtn = find.byKey(const Key('btnAddConductor'));
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.text('Add Conductor Group'), findsOneWidget);

      // Increase quantity in dialog
      final addQty = find.byIcon(Icons.add_circle_outline).last;
      await tester.tap(addQty); // qty = 2
      await tester.pump();
      await tester.tap(addQty); // qty = 3
      await tester.pump();

      // Tap 'Add to Schedule'
      final submitBtn = find.text('Add to Schedule');
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Schedule now contains 1 group with 3 conductors
      expect(find.text('3 conductors packed'), findsOneWidget);
      expect(find.byKey(const Key('btnStepperAdd_0')), findsOneWidget);

      // Rapid increment via stepper button
      for (int i = 0; i < 7; i++) {
        await tester.tap(find.byKey(const Key('btnStepperAdd_0')));
        await tester.pump(const Duration(milliseconds: 10));
      }
      await tester.pumpAndSettle();
      expect(find.text('10 conductors packed'), findsOneWidget);

      // Rapid decrement via stepper button down to removal (10 -> 0)
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.byKey(const Key('btnStepperRemove_0')));
        await tester.pump(const Duration(milliseconds: 10));
      }
      await tester.pumpAndSettle();

      // Should be empty again
      expect(find.text('0 conductors packed'), findsOneWidget);
    });
  });

  group('Adversarial Suite 2: Preset Chips Cycling & Instant Visualizer Updates', () {
    testWidgets('Tapping all preset chips rapidly updates raceway size, conductor counts, and calculations',
        (tester) async {
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

      // 1. Preset 3x 500k + 1x #3 Grd
      final preset500 = find.text('3x 500k + 1x #3 Grd');
      expect(preset500, findsOneWidget);
      await tester.tap(preset500);
      await tester.pumpAndSettle();

      expect(find.text('3" EMT'), findsOneWidget);
      expect(find.textContaining('500 kcmil'), findsOneWidget);
      expect(find.textContaining('3 AWG'), findsOneWidget);
      expect(find.text('4 conductors packed'), findsOneWidget);
      expect(find.textContaining('COMPLIANT'), findsOneWidget);
      expect(find.descendant(of: find.byType(DropdownButtonFormField<String>), matching: find.text('3"')), findsOneWidget);

      // 2. Preset 4x #12 Branch
      final preset12 = find.text('4x #12 Branch');
      expect(preset12, findsOneWidget);
      await tester.tap(preset12);
      await tester.pumpAndSettle();

      expect(find.text('1/2" EMT'), findsOneWidget);
      expect(find.textContaining('12 AWG'), findsWidgets);
      expect(find.text('4 conductors packed'), findsOneWidget);

      // 3. Preset 3x 4/0 Service
      final preset40 = find.text('3x 4/0 Service');
      expect(preset40, findsOneWidget);
      await tester.tap(preset40);
      await tester.pumpAndSettle();

      expect(find.text('2" EMT'), findsOneWidget);
      expect(find.textContaining('4/0 AWG'), findsOneWidget);
      expect(find.text('4 conductors packed'), findsOneWidget);

      // 4. Return to 3x #10 + 1x #12 Grd
      final preset10 = find.text('3x #10 + 1x #12 Grd');
      expect(preset10, findsOneWidget);
      await tester.tap(preset10);
      await tester.pumpAndSettle();

      expect(find.text('3/4" EMT'), findsOneWidget);
      expect(find.textContaining('10 AWG'), findsWidgets);
      expect(find.text('4 conductors packed'), findsOneWidget);

      // 5. Stress: Rapid cycling through all presets back-to-back without settling
      await tester.tap(preset500);
      await tester.pump(const Duration(milliseconds: 5));
      await tester.tap(preset12);
      await tester.pump(const Duration(milliseconds: 5));
      await tester.tap(preset40);
      await tester.pump(const Duration(milliseconds: 5));
      await tester.tap(preset10);
      await tester.pumpAndSettle();

      expect(find.text('3/4" EMT'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('Adversarial Suite 3: Critical Jam Risk Warning Pill Detection & State Transition', () {
    testWidgets('Aggregated jam ratio warning pill appears and disappears reactively on count changes',
        (tester) async {
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

      // Clear default schedule
      while (find.byKey(const Key('btnDeleteGroup_0')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('btnDeleteGroup_0')));
        await tester.pumpAndSettle();
      }

      // Select 2" EMT via 3x 4/0 Service preset
      await tester.tap(find.text('3x 4/0 Service'));
      await tester.pumpAndSettle();

      // Clear the schedule again to keep 2" EMT selected
      while (find.byKey(const Key('btnDeleteGroup_0')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('btnDeleteGroup_0')));
        await tester.pumpAndSettle();
      }

      // Now add 3x 250 kcmil conductors via Add Conductor dialog:
      // 2" EMT ID = 2.067", 250 kcmil OD = 0.711" -> D/d = 2.907 -> 2.91 (hazard: 2.80 - 3.20)
      await tester.tap(find.byKey(const Key('btnAddConductor')));
      await tester.pumpAndSettle();

      // Select 250 kcmil inside the modal dialog
      final modalDropdown = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(DropdownButtonFormField<String>),
      );
      expect(modalDropdown, findsOneWidget);
      await tester.tap(modalDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('250 kcmil').last);
      await tester.pumpAndSettle();

      // Set quantity to 3
      final addQty = find.byIcon(Icons.add_circle_outline).last;
      await tester.tap(addQty); // qty = 2
      await tester.pump();
      await tester.tap(addQty); // qty = 3
      await tester.pump();

      await tester.tap(find.text('Add to Schedule'));
      await tester.pumpAndSettle();

      // Verify Critical Jam Risk warning pill is displayed with ratio 2.91
      expect(find.textContaining('CRITICAL JAM RISK'), findsOneWidget);
      expect(find.textContaining('2.91'), findsOneWidget);

      // Increment count to 4 (Jam occurs strictly on 3 conductors)
      await tester.tap(find.byKey(const Key('btnStepperAdd_0')));
      await tester.pumpAndSettle();

      // Jam risk warning MUST disappear
      expect(find.textContaining('CRITICAL JAM RISK'), findsNothing);

      // Decrement count back to 3
      await tester.tap(find.byKey(const Key('btnStepperRemove_0')));
      await tester.pumpAndSettle();

      // Jam risk warning MUST reappear
      expect(find.textContaining('CRITICAL JAM RISK'), findsOneWidget);
      expect(find.textContaining('2.91'), findsOneWidget);
    });
  });

  group('Adversarial Suite 4: Overfilled Raceway & 1-Tap Upsize Pill Lifecycle', () {
    testWidgets('Overfilled raceway triggers upsize pill, which updates trade size and disappears',
        (tester) async {
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

      // Start with 3x 500k in 3" EMT preset
      await tester.tap(find.text('3x 500k + 1x #3 Grd'));
      await tester.pumpAndSettle();

      // Verify compliant state initially
      expect(find.textContaining('COMPLIANT'), findsOneWidget);
      expect(find.byKey(const Key('btnUpsize')), findsNothing);

      // 3" EMT: 3x 500k + 1x #3 = 2.2192 sq in. 40% area = 3.538 sq in.
      // Add 4 more 500 kcmil conductors -> total area = 5.048 sq in (> 50% fill, overfilled!)
      final stepperAdd = find.byKey(const Key('btnStepperAdd_0'));
      for (int i = 0; i < 4; i++) {
        await tester.tap(stepperAdd);
        await tester.pump(const Duration(milliseconds: 10));
      }
      await tester.pumpAndSettle();

      // Must now be OVERFILLED
      expect(find.textContaining('OVERFILLED'), findsOneWidget);

      // Upsize pill must now exist
      final upsizePill = find.byKey(const Key('btnUpsize'));
      expect(upsizePill, findsOneWidget);

      // Tap the upsize recommendation pill
      await tester.tap(upsizePill);
      await tester.pumpAndSettle();

      // Trade size was upgraded from 3" to a compliant EMT size
      expect(find.textContaining('EMT'), findsWidgets);
      // Status should be compliant again and upsize pill gone
      expect(find.textContaining('COMPLIANT'), findsOneWidget);
      expect(find.byKey(const Key('btnUpsize')), findsNothing);
    });

    testWidgets('Massive overfill beyond 4" conduit handles null recommendation safely',
        (tester) async {
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

      // Switch to 3x 500k in 3" EMT
      await tester.tap(find.text('3x 500k + 1x #3 Grd'));
      await tester.pumpAndSettle();

      // Add 20 more 500 kcmil conductors to massively blow past 4" EMT capacity
      final stepperAdd = find.byKey(const Key('btnStepperAdd_0'));
      for (int i = 0; i < 20; i++) {
        await tester.tap(stepperAdd);
        await tester.pump(const Duration(milliseconds: 5));
      }
      await tester.pumpAndSettle();

      // Fill percentage is > 200%
      expect(find.textContaining('OVERFILLED'), findsOneWidget);

      // Since even 4" EMT cannot fit 23x 500 kcmil, recommendedUpsizeTradeSize is null.
      // Verify app does not crash and btnUpsize is safely hidden
      expect(find.byKey(const Key('btnUpsize')), findsNothing);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('Adversarial Suite 5: Live Voltage Drop & Derating Expansion Cards Stress', () {
    testWidgets('Voltage drop card expands, toggles phases, drops voltages, and survives slider extremities',
        (tester) async {
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

      // Live Voltage Drop title exists
      expect(find.text('Live Voltage Drop'), findsOneWidget);

      // Toggle 3-Phase
      await tester.tap(find.text('3-Phase'));
      await tester.pumpAndSettle();

      // Toggle back to 1-Phase
      await tester.tap(find.text('1-Phase'));
      await tester.pumpAndSettle();

      // Test Sliders (Length, Load, Power Factor)
      final sliders = find.byType(Slider);
      expect(sliders, findsWidgets);

      // Drag Length slider to maximum
      final lengthSlider = sliders.at(0);
      await tester.drag(lengthSlider, const Offset(300, 0));
      await tester.pumpAndSettle();

      // Drag Load Current slider to maximum
      final currentSlider = sliders.at(1);
      await tester.drag(currentSlider, const Offset(300, 0));
      await tester.pumpAndSettle();

      // Verify no NaN or crash
      expect(find.textContaining('Drop:'), findsOneWidget);
      expect(find.textContaining('NaN'), findsNothing);
    });

    testWidgets('Thermal Derating card survives temperature slider extremes and Nipple 24" toggle',
        (tester) async {
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

      // Live Thermal Derating card exists
      expect(find.text('Live Thermal Derating'), findsOneWidget);

      // Terminal rating toggles (60°C / 75°C)
      expect(find.text('60°C'), findsWidgets);
      expect(find.text('75°C'), findsWidgets);
      await tester.tap(find.text('60°C'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Terminal Limit (60°C NEC 110.14(C)):'), findsOneWidget);

      await tester.tap(find.text('75°C'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Terminal Limit (75°C NEC 110.14(C)):'), findsOneWidget);

      // Toggle Nipple Switch (Nipple <= 24")
      final nippleSwitch = find.byType(Switch);
      expect(nippleSwitch, findsOneWidget);
      await tester.tap(nippleSwitch);
      await tester.pumpAndSettle();

      // Fill limit should now be 60% max!
      expect(find.textContaining('/ 60% max'), findsOneWidget);

      // Toggle Nipple switch back off
      await tester.tap(nippleSwitch);
      await tester.pumpAndSettle();

      expect(find.textContaining('/ 40% max'), findsOneWidget);
    });
  });

  group('Adversarial Suite 6: Viewport Boundaries, Narrow Screens & Zero Render Overflows', () {
    testWidgets('Small mobile viewport (360x640) renders without any overflow errors',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CalculatorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll up and down across the entire view
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, 500));
      await tester.pumpAndSettle();
    });

    testWidgets('Large bundle of 50 packed conductors renders on CustomPainter with zero crashes',
        (tester) async {
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

      // Clear conductors
      while (find.byKey(const Key('btnDeleteGroup_0')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('btnDeleteGroup_0')));
        await tester.pumpAndSettle();
      }

      // Add 10 conductors
      await tester.tap(find.byKey(const Key('btnAddConductor')));
      await tester.pumpAndSettle();
      for (int i = 0; i < 9; i++) {
        await tester.tap(find.byIcon(Icons.add_circle_outline).last);
        await tester.pump(const Duration(milliseconds: 5));
      }
      await tester.tap(find.text('Add to Schedule'));
      await tester.pumpAndSettle();

      // Rapidly increment count to 50
      for (int i = 0; i < 40; i++) {
        await tester.tap(find.byKey(const Key('btnStepperAdd_0')));
        await tester.pump(const Duration(milliseconds: 5));
      }
      await tester.pumpAndSettle();

      expect(find.text('50 conductors packed'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
