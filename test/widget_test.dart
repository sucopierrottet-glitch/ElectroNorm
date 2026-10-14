import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:electronorm/main.dart';
import 'package:electronorm/screens/calculator_screen.dart';
import 'package:electronorm/screens/welcome_landing_screen.dart';

void main() {
  testWidgets('ElectroNormApp boots cleanly into WelcomeLandingScreen and enters CalculatorScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ElectroNormApp());
    await tester.pumpAndSettle();

    // Verify that WelcomeLandingScreen is mounted with minimalist brand elements
    expect(find.byType(WelcomeLandingScreen), findsOneWidget);
    expect(find.text('ELECTRONORM'), findsOneWidget);
    expect(find.byKey(const Key('btnWelcomeEnter')), findsOneWidget);
    expect(find.byKey(const Key('btnWelcomeNewCalculation')), findsOneWidget);

    // Tap "Entrar" to enter CalculatorScreen
    await tester.tap(find.byKey(const Key('btnWelcomeEnter')));
    await tester.pumpAndSettle();

    // Verify CalculatorScreen is mounted and starts empty
    expect(find.byType(CalculatorScreen), findsOneWidget);
    expect(find.text('0 conductors packed'), findsOneWidget);
  });
}

