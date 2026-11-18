import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/conductor.dart';
import '../models/raceway.dart';
import '../services/billing_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/onboarding_dialog.dart';
import 'calculator_screen.dart';
import 'nec_catalog_screen.dart';
import 'paywall_screen.dart';
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

class _HomeNavigationScreenState extends State<HomeNavigationScreen>
    with WidgetsBindingObserver {
  late int _currentIndex;
  Timer? _usageTimer;
  bool _isGateOpen = false;
  bool _isForeground = true;
  late final BillingService _billingSyncService;

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
    WidgetsBinding.instance.addObserver(this);

    _billingSyncService = BillingService(storageService: StorageService.instance);
    if (!StorageService.isTestEnvironment) {
      _billingSyncService.init(syncPurchases: true);

      _usageTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        if (!_isForeground) return;
        await StorageService.instance.recordActiveUsageSeconds(5);
        if (mounted && !StorageService.instance.hasFullAccess && !_isGateOpen) {
          _openMandatoryPaywallGate();
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (StorageService.isTestEnvironment) return;

      final seenOnboarding = await StorageService.instance.hasSeenOnboarding();
      if (!seenOnboarding) {
        if (mounted) {
          await OnboardingDialog.show(context);
        }
      }
      if (mounted && !StorageService.instance.hasFullAccess && !_isGateOpen) {
        _openMandatoryPaywallGate();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (_isForeground &&
        !StorageService.isTestEnvironment &&
        mounted &&
        !StorageService.instance.hasFullAccess &&
        !_isGateOpen) {
      _openMandatoryPaywallGate();
    }
  }

  Future<void> _openMandatoryPaywallGate() async {
    if (_isGateOpen || !mounted) return;
    _isGateOpen = true;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PaywallScreen(isMandatoryGate: true),
      ),
    );
    _isGateOpen = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _usageTimer?.cancel();
    _billingSyncService.dispose();
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
            body: Column(
              children: [
                if (!StorageService.instance.isProSync &&
                    !StorageService.instance.isFreeWindowActive)
                  SafeArea(
                    bottom: false,
                    child: GestureDetector(
                      key: const Key('bannerMonetizationStage'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaywallScreen(
                              isMandatoryGate: !StorageService.instance.hasFullAccess,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: StorageService.instance.isAccessExpired
                              ? Colors.redAccent.withValues(alpha: 0.14)
                              : AppTheme.primary.withValues(alpha: 0.14),
                          border: Border(
                            bottom: BorderSide(
                              color: StorageService.instance.isAccessExpired
                                  ? Colors.redAccent.withValues(alpha: 0.4)
                                  : AppTheme.primary.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              StorageService.instance.isAccessExpired
                                  ? Icons.lock_clock_rounded
                                  : Icons.timer_outlined,
                              size: 15,
                              color: StorageService.instance.isAccessExpired
                                  ? Colors.redAccent
                                  : AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                StorageService.instance.needsTrialActivation
                                    ? _tr(
                                        'Activa tu Prueba Gratuita de 7 días para continuar',
                                        'Start your 7-day Free Trial to continue',
                                        'Ative seu Free Trial de 7 dias para continuar',
                                      )
                                    : StorageService.instance.isSevenDayTrialActive
                                        ? _tr(
                                            '⏳ Free Trial activo: ${StorageService.instance.trialDaysRemainingSync} días restantes',
                                            '⏳ Free Trial active: ${StorageService.instance.trialDaysRemainingSync} days left',
                                            '⏳ Free Trial ativo: ${StorageService.instance.trialDaysRemainingSync} dias restantes',
                                          )
                                        : _tr(
                                            '🔒 Trial finalizado • Suscríbete a ElectroNorm PRO',
                                            '🔒 Trial ended • Subscribe to ElectroNorm PRO',
                                            '🔒 Trial finalizado • Assine o ElectroNorm PRO',
                                          ),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: StorageService.instance.isAccessExpired
                                      ? Colors.redAccent
                                      : const Color(0xFF93C5FD),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: StorageService.instance.isAccessExpired
                                    ? Colors.redAccent
                                    : AppTheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                StorageService.instance.needsTrialActivation
                                    ? 'FREE TRIAL'
                                    : 'PRO',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: screens,
                  ),
                ),
              ],
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
