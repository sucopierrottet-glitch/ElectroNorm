import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:electronorm/calculators/conduit_fill_calculator.dart';
import 'package:electronorm/calculators/derating_calculator.dart';
import 'package:electronorm/calculators/grounding_calculator.dart';
import 'package:electronorm/calculators/voltage_drop_calculator.dart';
import 'package:electronorm/catalogs/conductor_catalog.dart';
import 'package:electronorm/catalogs/raceway_catalog.dart';
import 'package:electronorm/models/conductor.dart';
import 'package:electronorm/models/raceway.dart';
import 'package:electronorm/screens/calculator_screen.dart';
import 'package:electronorm/screens/conduit_bending_screen.dart';
import 'package:electronorm/screens/grounding_screen.dart';
import 'package:electronorm/screens/settings_screen.dart';
import 'package:electronorm/screens/welcome_landing_screen.dart';
import 'package:electronorm/services/pdf_report_service.dart';
import 'package:electronorm/services/storage_service.dart';
import 'package:electronorm/theme/app_theme.dart';
import 'package:electronorm/widgets/onboarding_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StorageService.instance = SharedPreferencesStorageService();
  });

  group('Normative Profile Detection & Persistence Tests', () {
    test('Detects Mexico/metric for MX locales and USA/imperial for US/en locales', () async {
      final storage = StorageService.instance as SharedPreferencesStorageService;

      await storage.init(deviceLocaleOverride: const Locale('es', 'MX'));
      expect(storage.localeCode, equals('es'));
      expect(storage.normativeCountry, equals(NormativeCountry.mexico));
      expect(storage.unitSystem, equals(MeasurementUnitSystem.metric));
      expect(storage.isMexicoProfile, isTrue);
      expect(storage.isMetric, isTrue);

      SharedPreferences.setMockInitialValues({});
      final storageUs = SharedPreferencesStorageService();
      await storageUs.init(deviceLocaleOverride: const Locale('en', 'US'));
      expect(storageUs.localeCode, equals('en'));
      expect(storageUs.normativeCountry, equals(NormativeCountry.usa));
      expect(storageUs.unitSystem, equals(MeasurementUnitSystem.imperial));
      expect(storageUs.isMexicoProfile, isFalse);
      expect(storageUs.isMetric, isFalse);

      SharedPreferences.setMockInitialValues({});
      final storageEsUs = SharedPreferencesStorageService();
      await storageEsUs.init(deviceLocaleOverride: const Locale('es', 'US'));
      expect(storageEsUs.localeCode, equals('es'));
      expect(storageEsUs.normativeCountry, equals(NormativeCountry.usa));
      expect(storageEsUs.unitSystem, equals(MeasurementUnitSystem.imperial));
    });

    test('Switching country updates default unit system unless overridden cleanly', () async {
      final storage = StorageService.instance;
      await storage.setNormativeCountry(NormativeCountry.usa);
      expect(storage.normativeCountry, equals(NormativeCountry.usa));
      expect(storage.unitSystem, equals(MeasurementUnitSystem.imperial));

      await storage.setNormativeCountry(NormativeCountry.mexico);
      expect(storage.normativeCountry, equals(NormativeCountry.mexico));
      expect(storage.unitSystem, equals(MeasurementUnitSystem.metric));

      // Independent unit override keeps Mexico normative refs with imperial units
      await storage.setUnitSystem(MeasurementUnitSystem.imperial);
      expect(storage.normativeCountry, equals(NormativeCountry.mexico));
      expect(storage.unitSystem, equals(MeasurementUnitSystem.imperial));
    });

    test('Formatters format DN raceway sizes and AWG mm² gauges accurately', () {
      expect(
        NormativeFormatters.formatRacewaySize('3/4', metricDesignator: '21', isMetric: true),
        equals('DN 21 (3/4")'),
      );
      expect(
        NormativeFormatters.formatRacewaySize('3/4', metricDesignator: '21', isMetric: false),
        equals('3/4"'),
      );
      expect(
        NormativeFormatters.formatAwgWithMetric('12 AWG', isMetric: true),
        contains('mm²'),
      );
      expect(
        NormativeFormatters.formatAwgWithMetric('12 AWG', isMetric: false),
        equals('12 AWG'),
      );
    });
  });

  group('Calculator, Presets, Grounding, Bending & Settings Country Profile Tests', () {
    testWidgets('WelcomeLandingScreen profile pill toggles between Mexico NOM-001 and USA NEC',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const WelcomeLandingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final pill = find.byKey(const Key('btnWelcomeProfileToggle'));
      expect(pill, findsOneWidget);
      expect(find.textContaining('NOM-001-SEDE'), findsOneWidget);

      await tester.tap(pill);
      await tester.pumpAndSettle();

      expect(StorageService.instance.normativeCountry, equals(NormativeCountry.usa));
      expect(find.textContaining('NEC (NFPA 70)'), findsOneWidget);
    });

    testWidgets('SettingsScreen allows switching country profile & unit system', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: SettingsScreen(storageService: StorageService.instance),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_option_mexico')), findsOneWidget);
      expect(find.byKey(const Key('profile_option_usa')), findsOneWidget);
      expect(find.byKey(const Key('unit_option_metric')), findsOneWidget);
      expect(find.byKey(const Key('unit_option_imperial')), findsOneWidget);

      await tester.tap(find.byKey(const Key('profile_option_usa')));
      await tester.pumpAndSettle();
      expect(StorageService.instance.normativeCountry, equals(NormativeCountry.usa));
      expect(StorageService.instance.isMetric, isFalse);

      await tester.tap(find.byKey(const Key('unit_option_metric')));
      await tester.pumpAndSettle();
      expect(StorageService.instance.isMetric, isTrue);

      await tester.tap(find.byKey(const Key('profile_option_mexico')));
      await tester.pumpAndSettle();
      expect(StorageService.instance.normativeCountry, equals(NormativeCountry.mexico));
      expect(StorageService.instance.isMetric, isTrue);
    });

    testWidgets('OnboardingDialog displays selectable Mexico NOM-001 and USA NEC profile cards',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showDialog(
                  context: ctx,
                  builder: (_) => OnboardingDialog(
                    storageService: StorageService.instance,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding_profile_mexico')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_profile_usa')), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding_profile_usa')));
      await tester.pumpAndSettle();
      expect(StorageService.instance.normativeCountry, equals(NormativeCountry.usa));
    });

    testWidgets('CalculatorScreen loads Mexico NOM-001 presets (127V/220V/440V) & toggles to USA NEC',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await StorageService.instance.setLocale('es');
      await StorageService.instance.setNormativeCountry(NormativeCountry.mexico);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CalculatorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Mexico banner and DN metric sizing
      expect(find.byKey(const Key('btnCalculatorProfileBanner')), findsOneWidget);
      expect(find.textContaining('NOM-001-SEDE'), findsWidgets);
      expect(find.textContaining('DN 21 (3/4")'), findsWidgets);

      // Mexico quick presets visible
      expect(find.text('3x #12 Monofásico 127V'), findsOneWidget);
      expect(find.text('3x #10 Bifásico 220V'), findsOneWidget);
      expect(find.text('3x 250k + #4 Alim. 440V'), findsOneWidget);

      // Tap 220V bifásico preset
      await tester.tap(find.text('3x #10 Bifásico 220V'));
      await tester.pumpAndSettle();
      expect(find.textContaining('220V'), findsWidgets);

      // Tap profile banner to switch cleanly to USA NEC without crash
      await tester.tap(find.byKey(const Key('btnCalculatorProfileBanner')));
      await tester.pumpAndSettle();
      expect(StorageService.instance.normativeCountry, equals(NormativeCountry.usa));
      expect(find.textContaining('NEC (NFPA 70)'), findsWidgets);
    });

    test('GroundingCalculator cites NOM-001-SEDE Tabla 250-122 / 250-66 when isMexico is true', () {
      final egcMx = GroundingCalculator.calculateEGC(ocpdRating: 100, isMexico: true);
      expect(egcMx.necReference, contains('NOM-001-SEDE'));
      expect(egcMx.necReference, contains('250-122'));

      final gecMx = GroundingCalculator.calculateGEC(
        serviceSize: '3/0 AWG',
        serviceMaterial: GroundingConductorMaterial.copper,
        electrodeType: ElectrodeType.waterPipeOrBuildingSteel,
        isMexico: true,
      );
      expect(gecMx.necReference, contains('NOM-001-SEDE'));
      expect(gecMx.necReference, contains('250-66'));

      final egcUs = GroundingCalculator.calculateEGC(ocpdRating: 100, isMexico: false);
      expect(egcUs.necReference, contains('NEC Table 250.122'));
    });

    testWidgets('GroundingScreen and ConduitBendingScreen render Mexico NOM-001 & metric cm/DN UI',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await StorageService.instance.setLocale('es');
      await StorageService.instance.setNormativeCountry(NormativeCountry.mexico);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const GroundingScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('NOM-001'), findsWidgets);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ConduitBendingScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('btnToggleBendingUnit')), findsOneWidget);
      expect(find.textContaining('cm / DN'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btnToggleBendingUnit')));
      await tester.pumpAndSettle();
      expect(StorageService.instance.isMetric, isFalse);
      expect(find.textContaining('in / "'), findsOneWidget);
    });

    test('PdfReportService generates valid %PDF- for both Mexico NOM-001-SEDE (metric/es) and USA NEC (imperial/en)',
        () async {
      final emt = RacewayCatalog.getProfile(RacewayType.emt, '3/4');
      final spec10 = ConductorCatalog.getSpec(gauge: '10 AWG');
      final groups = [
        ConductorGroup(id: '1', spec: spec10, count: 3, role: 'phaseA'),
      ];
      final fill = ConduitFillCalculator.calculate(raceway: emt, conductorGroups: groups);
      final vDrop = VoltageDropCalculator.calculateEffectiveImpedance(
        nominalVoltage: 127.0,
        phase: CircuitPhase.singlePhase,
        currentAmps: 20.0,
        lengthFeet: 82.0,
        conductorSpec: spec10,
        isSteelConduit: true,
      );
      final derate = DeratingCalculator.calculate(
        conductorSpec: spec10,
        ambientTempC: 35.0,
        currentCarryingConductorsCount: 3,
      );

      final mxData = ComplianceReportData(
        projectTitle: 'Nave Industrial Querétaro',
        clientName: 'Manufactura Bajío SA de CV',
        siteAddress: 'Parque Industrial Bernardo Quintana',
        technicianName: 'Ing. Alejandro Garza',
        companyName: 'Instalaciones Eléctricas MX',
        date: DateTime(2026, 11, 13),
        raceway: emt,
        conductors: groups,
        fillResult: fill,
        voltageDropResult: vDrop,
        deratingResult: derate,
        inspectorName: 'UVIE Ing. Laura Méndez',
        licenseNumber: 'CED-492817',
        agencyName: 'UVIE Certificada del Centro',
        nominalVoltage: 127.0,
        localeCode: 'es',
        normativeCountry: NormativeCountry.mexico,
        useMetricUnits: true,
      );

      final mxPdf = await PdfReportService.generateReport(mxData);
      expect(mxPdf.length, greaterThan(4000));
      expect(mxPdf.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));

      final usData = mxData.copyWith(
        nominalVoltage: 120.0,
        localeCode: 'en',
        normativeCountry: NormativeCountry.usa,
        useMetricUnits: false,
      );
      final usPdf = await PdfReportService.generateReport(usData);
      expect(usPdf.length, greaterThan(4000));
      expect(usPdf.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
    });
  });
}
