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
import 'package:electronorm/widgets/pro_upsell_dialog.dart';

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

  test('Auto-detects device language when no saved locale exists and respects saved preference',
      () async {
    SharedPreferences.setMockInitialValues({});
    final storage = SharedPreferencesStorageService();

    await storage.init(deviceLocaleOverride: const Locale('en', 'US'));
    expect(storage.localeCode, equals('en'));

    await storage.init(deviceLocaleOverride: const Locale('pt', 'BR'));
    expect(storage.localeCode, equals('pt'));

    await storage.init(deviceLocaleOverride: const Locale('es', 'MX'));
    expect(storage.localeCode, equals('es'));

    // Once user explicitly chooses a language, init preserves it
    await storage.setLocale('en');
    await storage.init(deviceLocaleOverride: const Locale('es', 'ES'));
    expect(storage.localeCode, equals('en'));
  });

  test('Pro upsell counter triggers every 3rd app open for non-Pro users', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = SharedPreferencesStorageService();

    // Before onboarding completed -> never triggers
    expect(await storage.recordAppOpenAndCheckUpsell(), isFalse);

    await storage.setHasSeenOnboarding(true);

    expect(await storage.recordAppOpenAndCheckUpsell(), isFalse); // Open 1
    expect(await storage.recordAppOpenAndCheckUpsell(), isFalse); // Open 2
    expect(await storage.recordAppOpenAndCheckUpsell(), isTrue); // Open 3 -> show popup!
    expect(await storage.recordAppOpenAndCheckUpsell(), isFalse); // Open 4
    expect(await storage.recordAppOpenAndCheckUpsell(), isFalse); // Open 5
    expect(await storage.recordAppOpenAndCheckUpsell(), isTrue); // Open 6 -> show popup!

    // Once upgraded to Pro, never shows again
    await storage.setProSubscriber(true);
    expect(await storage.recordAppOpenAndCheckUpsell(), isFalse);
  });

  testWidgets('ProUpsellDialog renders soft payment suggestion and dismisses cleanly',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = SharedPreferencesStorageService();
    StorageService.instance = storage;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('btnShowUpsell'),
              onPressed: () => ProUpsellDialog.show(context, storageService: storage),
              child: const Text('Show Upsell'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('btnShowUpsell')));
    await tester.pumpAndSettle();

    expect(find.byType(ProUpsellDialog), findsOneWidget);
    expect(find.text('ELECTRONORM PRO'), findsOneWidget);
    expect(find.byKey(const Key('btnUpsellContinuePro')), findsOneWidget);
    expect(find.byKey(const Key('btnUpsellCancelFree')), findsOneWidget);

    await tester.tap(find.byKey(const Key('btnUpsellCancelFree')));
    await tester.pumpAndSettle();
    expect(find.byType(ProUpsellDialog), findsNothing);
  });
}
