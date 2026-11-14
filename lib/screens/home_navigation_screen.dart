import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/conductor.dart';
import '../models/raceway.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/onboarding_dialog.dart';
import '../widgets/pro_upsell_dialog.dart';
import 'calculator_screen.dart';
import 'nec_catalog_screen.dart';
import 'saved_projects_screen.dart';
import 'settings_screen.dart';

class HomeNavigationScreen extends StatefulWidget {
  final int initialIndex;
  final bool startEmpty;

  const HomeNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.startEmpty = true,
  });

  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  late int _currentIndex;
  bool _upsellShownThisSession = false;
  Timer? _usageUpsellTimer;

  final GlobalKey<CalculatorScreenState> _calculatorKey =
      GlobalKey<CalculatorScreenState>();

  String _tr(String es, String en, String pt) {
    final lang = StorageService.instance.localeCode;
    if (lang.startsWith('en')) return en;
    if (lang.startsWith('pt')) return pt;
    return es;
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (StorageService.isTestEnvironment) return;

      final seenOnboarding = await StorageService.instance.hasSeenOnboarding();
      if (!seenOnboarding) {
        if (mounted) {
          await OnboardingDialog.show(context);
        }
      } else {
        final shouldShow =
            await StorageService.instance.recordAppOpenAndCheckUpsell();
        final isPro = await StorageService.instance.isProSubscriber();
        if (shouldShow && mounted && !isPro) {
          _upsellShownThisSession = true;
          await ProUpsellDialog.show(context);
        }
      }
      _startUsageUpsellTimer();
    });
  }

  void _startUsageUpsellTimer() {
    _usageUpsellTimer?.cancel();
    if (StorageService.isTestEnvironment) return;

    _usageUpsellTimer = Timer(const Duration(minutes: 3), () async {
      if (!mounted || _upsellShownThisSession) return;
      final isPro = await StorageService.instance.isProSubscriber();
      if (isPro || !mounted || _upsellShownThisSession) return;

      final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
      if (isCurrentRoute) {
        _upsellShownThisSession = true;
        await ProUpsellDialog.show(context);
      }
    });
  }

  @override
  void dispose() {
    _usageUpsellTimer?.cancel();
    super.dispose();
  }

  void _handleSelectProject(SavedCalculation item) {
    setState(() => _currentIndex = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculatorKey.currentState?.loadSavedCalculation(item);
    });
  }

  void _handleSelectConductor(ConductorSpec spec) {
    setState(() => _currentIndex = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculatorKey.currentState?.addConductorFromCatalog(spec);
    });
  }

  void _handleSelectRaceway(RacewayProfile raceway) {
    setState(() => _currentIndex = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculatorKey.currentState?.selectRacewayFromCatalog(raceway);
    });
  }

  Future<bool> _showExitConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.darkBorder),
        ),
        title: Row(
          children: [
            const Icon(Icons.exit_to_app_rounded, color: AppTheme.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _tr('¿Salir de ElectroNorm?', 'Exit ElectroNorm?', 'Sair do ElectroNorm?'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          _tr(
            '¿Estás seguro de que deseas cerrar la aplicación?',
            'Are you sure you want to close the application?',
            'Tem certeza de que deseja fechar o aplicativo?',
          ),
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              _tr('Cancelar', 'Cancel', 'Cancelar'),
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              _tr('Salir', 'Exit', 'Sair'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StorageService.instance,
      builder: (context, _) {
        final s = StorageService.instance.strings;

        final screens = [
          CalculatorScreen(
            key: _calculatorKey,
            startEmpty: widget.startEmpty,
            onOpenProjectsTab: () => setState(() => _currentIndex = 1),
            onOpenSettingsTab: () => setState(() => _currentIndex = 3),
          ),
          SavedProjectsScreen(
            onSelectProject: _handleSelectProject,
            onBackToCalculator: () => setState(() => _currentIndex = 0),
          ),
          NecCatalogScreen(
            onSelectConductor: _handleSelectConductor,
            onSelectRaceway: _handleSelectRaceway,
          ),
          const SettingsScreen(),
        ];

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (_currentIndex != 0) {
              setState(() => _currentIndex = 0);
              return;
            }
            final shouldExit = await _showExitConfirmationDialog();
            if (shouldExit && context.mounted) {
              SystemNavigator.pop();
            }
          },
          child: Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
            bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: AppTheme.darkSurface,
              border: Border(
                top: BorderSide(color: AppTheme.darkBorder, width: 1),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                height: 62,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: Icons.calculate_outlined,
                      activeIcon: Icons.calculate_rounded,
                      label: _tr('Calculadora', 'Calculator', 'Calculadora'),
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: Icons.folder_copy_outlined,
                      activeIcon: Icons.folder_copy_rounded,
                      label: _tr('Proyectos', 'Projects', 'Projetos'),
                    ),
                    _buildNavItem(
                      index: 2,
                      icon: Icons.inventory_2_outlined,
                      activeIcon: Icons.inventory_2_rounded,
                      label: StorageService.instance.isMexicoProfile
                          ? _tr('Catálogo NOM', 'NOM-001 Catalog', 'Catálogo NOM')
                          : _tr('Catálogo NEC', 'NEC Catalog', 'Catálogo NEC'),
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: Icons.tune_rounded,
                      activeIcon: Icons.tune_rounded,
                      label: s.settings,
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

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        key: Key('navTab_$index'),
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
