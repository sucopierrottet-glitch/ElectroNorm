import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:electronorm/main.dart';
import 'package:electronorm/screens/calculator_screen.dart';
import 'package:electronorm/screens/home_navigation_screen.dart';
import 'package:electronorm/screens/nec_catalog_screen.dart';
import 'package:electronorm/screens/saved_projects_screen.dart';
import 'package:electronorm/screens/settings_screen.dart';
import 'package:electronorm/screens/welcome_landing_screen.dart';
import 'package:electronorm/services/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.instance = SharedPreferencesStorageService();
  });

  testWidgets(
      'ElectroNormApp boots cleanly into WelcomeLandingScreen, enters HomeNavigationScreen with progressive disclosure, and navigates tabs',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ElectroNormApp());
    await tester.pumpAndSettle();

    // Verify that WelcomeLandingScreen is mounted with minimalist brand elements
    expect(find.byType(WelcomeLandingScreen), findsOneWidget);
    expect(find.text('ELECTRONORM'), findsOneWidget);
    expect(find.byKey(const Key('btnWelcomeEnter')), findsOneWidget);
    expect(find.byKey(const Key('btnWelcomeNewCalculation')), findsOneWidget);

    // Tap "Entrar" to enter HomeNavigationScreen
    await tester.tap(find.byKey(const Key('btnWelcomeEnter')));
    await tester.pumpAndSettle();

    // Verify HomeNavigationScreen & CalculatorScreen are mounted and start empty
    expect(find.byType(HomeNavigationScreen), findsOneWidget);
    expect(find.byType(CalculatorScreen), findsOneWidget);
    expect(find.text('0 conductors packed'), findsOneWidget);

    // Progressive disclosure: advanced modules are hidden initially in user flow
    expect(find.text('Live Voltage Drop'), findsNothing);
    expect(find.text('Live Thermal Derating'), findsNothing);
    expect(find.byKey(const Key('btnToggleVoltageDrop')), findsOneWidget);
    expect(find.byKey(const Key('btnToggleThermalDerating')), findsOneWidget);
    expect(find.byKey(const Key('btnToggleQuickPresets')), findsOneWidget);

    // Progressively add Voltage Drop module on demand
    await tester.tap(find.byKey(const Key('btnToggleVoltageDrop')));
    await tester.pumpAndSettle();
    expect(find.text('Live Voltage Drop'), findsOneWidget);

    // Progressively add Thermal Derating module on demand
    await tester.tap(find.byKey(const Key('btnToggleThermalDerating')));
    await tester.pumpAndSettle();
    expect(find.text('Live Thermal Derating'), findsOneWidget);

    // Navigate bottom tabs (FieldQuote layout: 0=Calculadora, 1=Proyectos, 2=Catálogo NEC, 3=Ajustes)
    await tester.tap(find.byKey(const Key('navTab_1')));
    await tester.pumpAndSettle();
    expect(find.byType(SavedProjectsScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('navTab_2')));
    await tester.pumpAndSettle();
    expect(find.byType(NecCatalogScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('navTab_3')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('IDIOMA / LANGUAGE'), findsOneWidget);
    expect(find.text('FIRMA DIGITAL PREDETERMINADA'), findsOneWidget);
    expect(find.text('COMUNIDAD Y OPINIONES'), findsOneWidget);
  });
}
