import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'calculator_screen.dart';
import 'saved_projects_screen.dart';
import 'settings_screen.dart';

/// Minimalist welcome and landing screen for ElectroNorm Pro,
/// designed with the same clean, focused identity as FieldQuote.
class WelcomeLandingScreen extends StatelessWidget {
  final StorageService? storageService;

  const WelcomeLandingScreen({super.key, this.storageService});

  void _enterApp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CalculatorScreen(startEmpty: true),
      ),
    );
  }

  void _createNewCalculation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CalculatorScreen(startEmpty: true),
      ),
    );
  }

  void _openSavedProjects(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SavedProjectsScreen()),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(storageService: storageService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = storageService ?? StorageService.instance;

    return AnimatedBuilder(
      animation: storage,
      builder: (context, _) {
        final s = storage.strings;

        return Scaffold(
          backgroundColor: AppColors.bgDark,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Utility Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            key: const Key('btnWelcomeSettings'),
                            onPressed: () => _openSettings(context),
                            icon: const Icon(
                              Icons.settings_outlined,
                              color: AppColors.textTertiary,
                              size: 22,
                            ),
                            tooltip: s.settings,
                          ),
                        ],
                      ),

                      // Centered Brand Icon & Typography
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 132,
                            height: 132,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2979FF).withValues(alpha: 0.25),
                                  blurRadius: 40,
                                  spreadRadius: 4,
                                ),
                                BoxShadow(
                                  color: AppColors.compliant.withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              'assets/icon/app_icon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            s.appTitle,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 5.0,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.appSubtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),

                      // Action Buttons Section
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Primary Button: Entrar
                          ElevatedButton(
                            key: const Key('btnWelcomeEnter'),
                            onPressed: () => _enterApp(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.compliant,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              s.enterApp,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Secondary Button: + Nuevo Cálculo
                          OutlinedButton(
                            key: const Key('btnWelcomeNewCalculation'),
                            onPressed: () => _createNewCalculation(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: const BorderSide(color: AppColors.borderSubtle, width: 1.5),
                            ),
                            child: Text(
                              s.newCalculation,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Tertiary Option: Proyectos Guardados
                          TextButton.icon(
                            key: const Key('btnWelcomeSavedProjects'),
                            onPressed: () => _openSavedProjects(context),
                            icon: const Icon(
                              Icons.folder_open_outlined,
                              size: 18,
                              color: AppColors.textTertiary,
                            ),
                            label: Text(
                              s.savedProjects,
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
