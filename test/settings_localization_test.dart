import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:electronorm/l10n/app_strings.dart';
import 'package:electronorm/screens/settings_screen.dart';
import 'package:electronorm/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Localization & AppStrings Unit Tests', () {
    test('AppStrings.get returns correct language instances', () {
      expect(AppStrings.get('es').settings, equals('Ajustes'));
      expect(AppStrings.get('en').settings, equals('Settings'));
      expect(AppStrings.get('pt').settings, equals('Ajustes'));

      // Case insensitivity & prefix handling
      expect(AppStrings.get('ES-CO').languageSpanish, equals('Español'));
      expect(AppStrings.get('EN-US').languageEnglish, equals('English'));
      expect(AppStrings.get('PT-BR').languagePortuguese, equals('Português'));

      // Fallback
      expect(AppStrings.get('fr').settings, equals('Ajustes'));
      expect(AppStrings.get('').settings, equals('Ajustes'));
    });

    test('All languages have non-empty essential keys', () {
      final locales = [AppStrings.es, AppStrings.en, AppStrings.pt];
      for (final s in locales) {
        expect(s.appTitle.isNotEmpty, isTrue);
        expect(s.appSubtitle.isNotEmpty, isTrue);
        expect(s.settingsTitle.isNotEmpty, isTrue);
        expect(s.enterApp.isNotEmpty, isTrue);
        expect(s.newCalculation.isNotEmpty, isTrue);
        expect(s.savedProjects.isNotEmpty, isTrue);
        expect(s.technicianProfileHeader.isNotEmpty, isTrue);
        expect(s.saveSettingsBtn.isNotEmpty, isTrue);
        expect(s.privacyPolicyBtn.isNotEmpty, isTrue);
      }
    });
  });

  group('StorageService Locale Switching', () {
    late SharedPreferencesStorageService storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = SharedPreferencesStorageService();
      StorageService.instance = storage;
    });

    test('Defaults to Spanish (es) and switches reactively', () async {
      expect(storage.localeCode, equals('es'));
      expect(storage.strings.languageSpanish, equals('Español'));

      bool notified = false;
      storage.addListener(() {
        notified = true;
      });

      await storage.setLocale('en');
      expect(storage.localeCode, equals('en'));
      expect(storage.strings.settings, equals('Settings'));
      expect(notified, isTrue);

      await storage.setLocale('pt');
      expect(storage.localeCode, equals('pt'));
      expect(storage.strings.save, equals('Salvar'));

      // Calling setLocale with the same code does not trigger duplicate notification
      notified = false;
      await storage.setLocale('pt');
      expect(notified, isFalse);
    });
  });

  group('SettingsScreen Widget Tests', () {
    late SharedPreferencesStorageService storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = SharedPreferencesStorageService();
      StorageService.instance = storage;
    });

    testWidgets('Renders all fields, language selectors, and saves profile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(storageService: storage),
        ),
      );
      await tester.pumpAndSettle();

      // Check default presence of titles
      expect(find.text('Ajustes & Perfil Técnico'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Português'), findsOneWidget);

      // Verify default profile inputs start empty
      final initialProfile = await storage.getProfile();
      expect(initialProfile.technicianName, isEmpty);
      expect(initialProfile.companyName, isEmpty);

      // Tap on English language option
      final enPill = find.byKey(const Key('lang_option_en'));
      expect(enPill, findsOneWidget);
      await tester.tap(enPill);
      await tester.pumpAndSettle();

      // Check reactive language update in header
      expect(storage.localeCode, equals('en'));
      expect(find.text('Settings & Technician Profile'), findsOneWidget);

      // Edit technician name
      final nameField = find.widgetWithText(TextField, '').first;
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Jane Doe, PE');
      await tester.pumpAndSettle();

      // Save settings
      final saveBtn = find.byKey(const Key('btnSaveProfile'));
      expect(saveBtn, findsOneWidget);
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify persisted in storage
      final savedProfile = await storage.getProfile();
      expect(savedProfile.technicianName, equals('Jane Doe, PE'));
    });
  });
}
