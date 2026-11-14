import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../calculators/conduit_fill_calculator.dart';
import '../calculators/derating_calculator.dart';
import '../calculators/jam_ratio_calculator.dart';
import '../calculators/voltage_drop_calculator.dart';
import '../catalogs/conductor_catalog.dart';
import '../catalogs/raceway_catalog.dart';
import '../models/calculation_results.dart';
import '../models/conductor.dart';
import '../models/raceway.dart';
import '../services/pdf_report_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/onboarding_dialog.dart';
import '../widgets/pro_upsell_dialog.dart';
import '../widgets/raceway_painter.dart';
import 'paywall_screen.dart';
import 'report_preview_screen.dart';
import 'saved_projects_screen.dart';
import 'settings_screen.dart';
import 'conduit_bending_screen.dart';
import 'grounding_screen.dart';

class CalculatorScreen extends StatefulWidget {
  final bool startEmpty;
  final VoidCallback? onOpenProjectsTab;
  final VoidCallback? onOpenSettingsTab;

  const CalculatorScreen({
    super.key,
    this.startEmpty = false,
    this.onOpenProjectsTab,
    this.onOpenSettingsTab,
  });

  @override
  State<CalculatorScreen> createState() => CalculatorScreenState();
}

class CalculatorScreenState extends State<CalculatorScreen> {
  // Raceway Selection
  RacewayType _selectedRacewayType = RacewayType.emt;
  String _selectedTradeSize = '3/4';
  bool _isNipple = false;

  // Conductor Schedule
  final List<ConductorGroup> _conductorGroups = [];

  // Progressive disclosure flags:
  // When startEmpty is true (real user session), advanced modules start hidden
  // so the user progressively adds them as they use the calculator.
  late bool _showPresets;
  late bool _showVoltageDrop;
  late bool _showThermalDerating;

  // Voltage Drop Parameters
  CircuitPhase _circuitPhase = CircuitPhase.singlePhase;
  double _nominalVoltage = 120.0;
  double _circuitLengthFeet = 100.0;
  double _loadCurrentAmps = 16.0;
  double _powerFactor = 0.90;
  late NormativeCountry _lastCountry;

  // Derating Parameters
  double _ambientTempC = 30.0;
  double _terminalRatingC = 75.0;

  // Subscription & Profile state
  bool _isProSubscriber = false;
  TechnicianProfile _technicianProfile = TechnicianProfile.defaultProfile;

  String _tr(String es, String en, String pt) {
    final lang = StorageService.instance.localeCode;
    if (lang.startsWith('en')) return en;
    if (lang.startsWith('pt')) return pt;
    return es;
  }

  @override
  void initState() {
    super.initState();
    _showPresets = !widget.startEmpty;
    _showVoltageDrop = !widget.startEmpty;
    _showThermalDerating = !widget.startEmpty;

    _lastCountry = StorageService.instance.normativeCountry;
    _nominalVoltage = _lastCountry.defaultSinglePhaseVoltage;

    if (!widget.startEmpty) {
      _loadDefaultPreset();
    }
    _refreshSubscriptionState();
    StorageService.instance.addListener(_onStorageChanged);
  }

  void _onStorageChanged() {
    final newCountry = StorageService.instance.normativeCountry;
    if (newCountry != _lastCountry) {
      _lastCountry = newCountry;
      if (mounted) {
        setState(() {
          if (newCountry == NormativeCountry.mexico) {
            if (_nominalVoltage == 120.0) _nominalVoltage = 127.0;
            if (_nominalVoltage == 208.0) _nominalVoltage = 220.0;
            if (_nominalVoltage == 480.0) _nominalVoltage = 440.0;
          } else {
            if (_nominalVoltage == 127.0) _nominalVoltage = 120.0;
            if (_nominalVoltage == 220.0) _nominalVoltage = 208.0;
            if (_nominalVoltage == 440.0) _nominalVoltage = 480.0;
          }
        });
      }
    } else if (mounted) {
      setState(() {});
    }
    _refreshSubscriptionState();
  }

  @override
  void dispose() {
    StorageService.instance.removeListener(_onStorageChanged);
    super.dispose();
  }

  Future<void> _refreshSubscriptionState() async {
    try {
      final isPro = await StorageService.instance.isProSubscriber();
      final p = await StorageService.instance.getProfile();
      if (mounted) {
        setState(() {
          _isProSubscriber = isPro;
          _technicianProfile = p;
        });
      }
    } catch (_) {}
  }

  /// Public method to load a saved calculation from HomeNavigationScreen or SavedProjectsScreen
  void loadSavedCalculation(SavedCalculation calc) {
    setState(() {
      _selectedRacewayType = calc.raceway.type;
      _selectedTradeSize = calc.raceway.tradeSize;
      _isNipple = calc.isNipple;
      _conductorGroups.clear();
      _conductorGroups.addAll(calc.conductors);
      _nominalVoltage = calc.nominalVoltage;
      _circuitPhase = calc.circuitPhase;
      _circuitLengthFeet = calc.circuitLengthFeet;
      _loadCurrentAmps = calc.loadCurrentAmps;
      _powerFactor = calc.powerFactor;
      _ambientTempC = calc.ambientTempC;
      _terminalRatingC = calc.terminalRatingC;
      if (calc.voltageDropResult != null) _showVoltageDrop = true;
      if (calc.deratingResult != null) _showThermalDerating = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Text(
            _tr(
              'Cálculo "${calc.title}" cargado',
              'Loaded "${calc.title}" into calculator',
              'Cálculo "${calc.title}" carregado',
            ),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Public method to add a conductor directly from NecCatalogScreen
  void addConductorFromCatalog(ConductorSpec spec) {
    setState(() {
      _conductorGroups.add(
        ConductorGroup(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          spec: spec,
          count: 1,
          role: 'phaseA',
        ),
      );
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.success,
          content: Text(
            _tr(
              'Conductor ${spec.gauge} agregado al cálculo',
              'Added ${spec.gauge} conductor to calculation',
              'Condutor ${spec.gauge} adicionado ao cálculo',
            ),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Public method to select a raceway directly from NecCatalogScreen
  void selectRacewayFromCatalog(RacewayProfile profile) {
    setState(() {
      _selectedRacewayType = profile.type;
      _selectedTradeSize = profile.tradeSize;
    });
    if (mounted) {
      final sizeStr = NormativeFormatters.formatRacewaySize(
        profile.tradeSize,
        type: profile.type,
        metricDesignator: profile.metricDesignator,
        isMetric: StorageService.instance.isMetric,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.primary,
          content: Text(
            _tr(
              'Tubería seleccionada: $sizeStr ${profile.type.displayName}',
              'Selected raceway: $sizeStr ${profile.type.displayName}',
              'Eletroduto selecionado: $sizeStr ${profile.type.displayName}',
            ),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Public method to reset to a clean progressive state
  void resetToNewCalculation() {
    setState(() {
      _conductorGroups.clear();
      _selectedRacewayType = RacewayType.emt;
      _selectedTradeSize = '3/4';
      _isNipple = false;
      _nominalVoltage =
          StorageService.instance.normativeCountry.defaultSinglePhaseVoltage;
      if (widget.startEmpty) {
        _showPresets = false;
        _showVoltageDrop = false;
        _showThermalDerating = false;
      }
    });
  }

  void _loadDefaultPreset() {
    _conductorGroups.clear();
    final spec10 = ConductorCatalog.getSpec(
      gauge: '10 AWG',
      insulation: ConductorInsulation.thhn,
      material: ConductorMaterial.copper,
    );
    final spec12 = ConductorCatalog.getSpec(
      gauge: '12 AWG',
      insulation: ConductorInsulation.thhn,
      material: ConductorMaterial.copper,
    );

    _conductorGroups.addAll([
      ConductorGroup(
        id: '1',
        spec: spec10,
        count: 1,
        role: 'phaseA',
      ),
      ConductorGroup(
        id: '2',
        spec: spec10,
        count: 1,
        role: 'phaseB',
      ),
      ConductorGroup(
        id: '3',
        spec: spec10,
        count: 1,
        role: 'phaseC',
      ),
      ConductorGroup(
        id: '4',
        spec: spec12,
        count: 1,
        role: 'ground',
      ),
    ]);
  }

  RacewayProfile get _currentRacewayProfile {
    return RacewayCatalog.getProfile(_selectedRacewayType, _selectedTradeSize);
  }

  ConduitFillResult get _fillResult {
    return ConduitFillCalculator.calculate(
      raceway: _currentRacewayProfile,
      conductorGroups: _conductorGroups,
      isNipple: _isNipple,
    );
  }

  /// Aggregates phase/all conductors of identical diameter before checking jam ratio
  /// so that entering 3 separate phase wires correctly evaluates jam risk!
  JamRatioResult? get _aggregatedJamCheck {
    final profile = _currentRacewayProfile;
    final diameterCounts = <double, int>{};
    for (final group in _conductorGroups) {
      if (group.count <= 0) continue;
      final od = double.parse(group.spec.outerDiameterInches.toStringAsFixed(4));
      diameterCounts[od] = (diameterCounts[od] ?? 0) + group.count;
    }

    for (final entry in diameterCounts.entries) {
      if (entry.value == 3) {
        return JamRatioCalculator.calculate(
          conduitInsideDiameter: profile.internalDiameterInches,
          wireOutsideDiameter: entry.key,
        );
      }
    }
    return null;
  }

  double? get _activeJamRatio {
    final aggregated = _aggregatedJamCheck;
    if (aggregated != null) return aggregated.ratio;
    return _fillResult.jamRatio;
  }

  bool get _hasActiveJamRisk {
    final aggregated = _aggregatedJamCheck;
    if (aggregated != null) return aggregated.isHighRisk;
    return _fillResult.hasJamRisk;
  }

  ConductorSpec get _primaryConductorSpec {
    if (_conductorGroups.isNotEmpty) {
      final phaseGroup = _conductorGroups.firstWhere(
        (g) => !g.isGround,
        orElse: () => _conductorGroups.first,
      );
      return phaseGroup.spec;
    }
    return ConductorCatalog.getSpec(gauge: '10 AWG');
  }

  VoltageDropResult get _voltageDropResult {
    return VoltageDropCalculator.calculateEffectiveImpedance(
      nominalVoltage: _nominalVoltage,
      phase: _circuitPhase,
      currentAmps: _loadCurrentAmps,
      lengthFeet: _circuitLengthFeet,
      conductorSpec: _primaryConductorSpec,
      isSteelConduit: _selectedRacewayType.isMetallic,
      powerFactor: _powerFactor,
    );
  }

  int get _calculatedCccCount {
    int count = 0;
    for (final g in _conductorGroups) {
      if (!g.isGround) {
        count += g.count;
      }
    }
    return count > 0 ? count : 1;
  }

  DeratingResult get _deratingResult {
    return DeratingCalculator.calculate(
      conductorSpec: _primaryConductorSpec,
      ambientTempC: _ambientTempC,
      currentCarryingConductorsCount: _calculatedCccCount,
      terminalRatingC: _terminalRatingC,
      isNipple: _isNipple,
    );
  }

  // --- Actions ---

  void _applyPreset(String name) {
    setState(() {
      _conductorGroups.clear();
      switch (name) {
        case 'preset_mx_mono_127':
          _selectedRacewayType = RacewayType.emt;
          _selectedTradeSize = '1/2';
          final spec12 = ConductorCatalog.getSpec(gauge: '12 AWG');
          _conductorGroups.addAll([
            ConductorGroup(id: 'p1', spec: spec12, count: 1, role: 'phaseA'),
            ConductorGroup(id: 'p2', spec: spec12, count: 1, role: 'neutral'),
            ConductorGroup(id: 'p3', spec: spec12, count: 1, role: 'ground'),
          ]);
          _loadCurrentAmps = 16.0;
          _nominalVoltage = 127.0;
          _circuitPhase = CircuitPhase.singlePhase;
          break;

        case 'preset_mx_bif_220':
          _selectedRacewayType = RacewayType.emt;
          _selectedTradeSize = '3/4';
          final spec10 = ConductorCatalog.getSpec(gauge: '10 AWG');
          _conductorGroups.addAll([
            ConductorGroup(id: 'p1', spec: spec10, count: 1, role: 'phaseA'),
            ConductorGroup(id: 'p2', spec: spec10, count: 1, role: 'phaseB'),
            ConductorGroup(id: 'p3', spec: spec10, count: 1, role: 'ground'),
          ]);
          _loadCurrentAmps = 24.0;
          _nominalVoltage = 220.0;
          _circuitPhase = CircuitPhase.singlePhase;
          break;

        case 'preset_mx_tri_220':
          _selectedRacewayType = RacewayType.emt;
          _selectedTradeSize = '1';
          final spec8 = ConductorCatalog.getSpec(gauge: '8 AWG');
          final spec10 = ConductorCatalog.getSpec(gauge: '10 AWG');
          _conductorGroups.addAll([
            ConductorGroup(id: 'p1', spec: spec8, count: 1, role: 'phaseA'),
            ConductorGroup(id: 'p2', spec: spec8, count: 1, role: 'phaseB'),
            ConductorGroup(id: 'p3', spec: spec8, count: 1, role: 'phaseC'),
            ConductorGroup(id: 'p4', spec: spec10, count: 1, role: 'ground'),
          ]);
          _loadCurrentAmps = 40.0;
          _nominalVoltage = 220.0;
          _circuitPhase = CircuitPhase.threePhase;
          break;

        case 'preset_mx_alim_440':
          _selectedRacewayType = RacewayType.emt;
          _selectedTradeSize = '2-1/2';
          final spec250 = ConductorCatalog.getSpec(gauge: '250 kcmil');
          final spec4 = ConductorCatalog.getSpec(gauge: '4 AWG');
          _conductorGroups.addAll([
            ConductorGroup(id: 'p1', spec: spec250, count: 3, role: 'phaseA'),
            ConductorGroup(id: 'p2', spec: spec4, count: 1, role: 'ground'),
          ]);
          _loadCurrentAmps = 230.0;
          _nominalVoltage = 440.0;
          _circuitPhase = CircuitPhase.threePhase;
          break;

        case 'preset_3x10_1x12':
          _selectedRacewayType = RacewayType.emt;
          _selectedTradeSize = '3/4';
          final spec10 = ConductorCatalog.getSpec(gauge: '10 AWG');
          final spec12 = ConductorCatalog.getSpec(gauge: '12 AWG');
          _conductorGroups.addAll([
            ConductorGroup(id: 'p1', spec: spec10, count: 1, role: 'phaseA'),
            ConductorGroup(id: 'p2', spec: spec10, count: 1, role: 'phaseB'),
            ConductorGroup(id: 'p3', spec: spec10, count: 1, role: 'phaseC'),
            ConductorGroup(id: 'p4', spec: spec12, count: 1, role: 'ground'),
          ]);
          _loadCurrentAmps = 24.0;
          _nominalVoltage = 208.0;
          _circuitPhase = CircuitPhase.threePhase;
          break;

        case 'preset_3x500_1x3':
          _selectedRacewayType = RacewayType.emt;
          _selectedTradeSize = '3';
          final spec500 = ConductorCatalog.getSpec(gauge: '500 kcmil');
          final spec3 = ConductorCatalog.getSpec(gauge: '3 AWG');
          _conductorGroups.addAll([
            ConductorGroup(id: 'p1', spec: spec500, count: 3, role: 'phaseA'),
            ConductorGroup(id: 'p2', spec: spec3, count: 1, role: 'ground'),
          ]);
          _loadCurrentAmps = 350.0;
          _nominalVoltage = 480.0;
          _circuitPhase = CircuitPhase.threePhase;
          break;

        case 'preset_4x12_branch':
          _selectedRacewayType = RacewayType.emt;
          _selectedTradeSize = '1/2';
          final spec12 = ConductorCatalog.getSpec(gauge: '12 AWG');
          _conductorGroups.addAll([
            ConductorGroup(id: 'p1', spec: spec12, count: 2, role: 'phaseA'),
            ConductorGroup(id: 'p2', spec: spec12, count: 1, role: 'neutral'),
            ConductorGroup(id: 'p3', spec: spec12, count: 1, role: 'ground'),
          ]);
          _loadCurrentAmps = 16.0;
          _nominalVoltage = 120.0;
          _circuitPhase = CircuitPhase.singlePhase;
          break;

        case 'preset_3x40_service':
          _selectedRacewayType = RacewayType.emt;
          _selectedTradeSize = '2';
          final spec40 = ConductorCatalog.getSpec(gauge: '4/0 AWG');
          final spec4 = ConductorCatalog.getSpec(gauge: '4 AWG');
          _conductorGroups.addAll([
            ConductorGroup(id: 'p1', spec: spec40, count: 3, role: 'phaseA'),
            ConductorGroup(id: 'p2', spec: spec4, count: 1, role: 'ground'),
          ]);
          _loadCurrentAmps = 180.0;
          _nominalVoltage = 240.0;
          _circuitPhase = CircuitPhase.singlePhase;
          break;
      }
    });
  }

  void _upsizeRaceway() {
    final upsize = _fillResult.recommendedUpsizeTradeSize;
    if (upsize != null) {
      setState(() {
        _selectedTradeSize = upsize;
      });
    }
  }

  void _openReportPreview() {
    final storage = StorageService.instance;
    final reportData = ComplianceReportData(
      projectTitle: _tr('Tramo de Tubería #1', 'Field Conduit Run #1', 'Trecho de Eletroduto #1'),
      clientName: _tr('Cliente Comercial', 'Commercial Client', 'Cliente Comercial'),
      siteAddress: _tr('Cuarto Eléctrico / Tablero', 'Facility Electrical Room B', 'Quadro Elétrico'),
      technicianName: _technicianProfile.technicianName,
      companyName: _technicianProfile.companyName,
      licenseNumber: _technicianProfile.licenseNumber,
      agencyName: _technicianProfile.agencyName,
      date: DateTime.now(),
      raceway: _currentRacewayProfile,
      conductors: List.unmodifiable(_conductorGroups),
      fillResult: _fillResult,
      voltageDropResult: _voltageDropResult,
      deratingResult: _deratingResult,
      nominalVoltage: _nominalVoltage,
      circuitPhase: _circuitPhase,
      circuitLengthFeet: _circuitLengthFeet,
      loadCurrentAmps: _loadCurrentAmps,
      powerFactor: _powerFactor,
      ambientTempC: _ambientTempC,
      terminalRatingC: _terminalRatingC,
      cccCount: _calculatedCccCount,
      signaturePngBytes: _technicianProfile.defaultSignatureBytes,
      localeCode: storage.localeCode,
      normativeCountry: storage.normativeCountry,
      useMetricUnits: storage.isMetric,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ReportPreviewScreen(reportData: reportData),
      ),
    );
  }

  Future<void> _openSavedProjects() async {
    final selected = await Navigator.of(context).push<SavedCalculation>(
      MaterialPageRoute(builder: (ctx) => const SavedProjectsScreen()),
    );
    if (selected != null && mounted) {
      loadSavedCalculation(selected);
    }
  }

  Future<void> _openPaywall() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => const PaywallScreen()),
    );
    await _refreshSubscriptionState();
  }

  Future<void> _toggleCountryQuickly() async {
    final storage = StorageService.instance;
    final next = storage.normativeCountry == NormativeCountry.mexico
        ? NormativeCountry.usa
        : NormativeCountry.mexico;
    await storage.setNormativeCountry(next, syncUnits: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Text(
          '${next.flagEmoji} ${_tr("Norma activa", "Active standard", "Norma ativa")}: ${next.codeBadge}',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showSaveCalculationDialog() async {
    final canSave = await StorageService.instance.canCreateProject();
    if (!canSave) {
      if (mounted) {
        await ProUpsellDialog.show(context);
      }
      return;
    }
    if (!mounted) return;

    final storage = StorageService.instance;
    final isMetric = storage.isMetric;
    final totalConds = _conductorGroups.fold(0, (sum, g) => sum + g.count);
    final sizeLabel = NormativeFormatters.formatRacewaySize(
      _currentRacewayProfile.tradeSize,
      type: _currentRacewayProfile.type,
      metricDesignator: _currentRacewayProfile.metricDesignator,
      isMetric: isMetric,
    );
    final defaultTitle = _tr(
      'Circuito #${totalConds}C - $sizeLabel ${_currentRacewayProfile.type.displayName}',
      'Run #${totalConds}W - $sizeLabel ${_currentRacewayProfile.type.displayName}',
      'Circuito #${totalConds}C - $sizeLabel ${_currentRacewayProfile.type.displayName}',
    );
    final titleController = TextEditingController(text: defaultTitle);
    final clientController = TextEditingController();
    final notesController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.bookmark_add, color: AppColors.compliant, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _tr('Guardar Cálculo', 'Save Calculation Run', 'Salvar Cálculo'),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('inputSaveTitle'),
                controller: titleController,
                decoration: InputDecoration(
                  labelText: _tr('Título del Proyecto / Cálculo *',
                      'Project / Calculation Title *', 'Título do Projeto *'),
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('inputSaveClient'),
                controller: clientController,
                decoration: InputDecoration(
                  labelText: _tr('Cliente / Obra (Opcional)',
                      'Client / Site Name (Optional)', 'Cliente / Local (Opcional)'),
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('inputSaveNotes'),
                controller: notesController,
                decoration: InputDecoration(
                  labelText: _tr('Notas / Tablero (Opcional)',
                      'Notes / Panel Location (Optional)', 'Notas / Quadro (Opcional)'),
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_tr('Cancelar', 'Cancel', 'Cancelar'),
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            key: const Key('btnConfirmSaveCalculation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.compliant,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final title = titleController.text.trim().isEmpty
                  ? _tr('Tramo de Tubería', 'Conduit Run', 'Trecho')
                  : titleController.text.trim();
              final now = DateTime.now();
              final savedItem = SavedCalculation(
                id: const Uuid().v4(),
                title: title,
                clientName: clientController.text.trim(),
                siteAddress: '',
                notes: notesController.text.trim(),
                timestamp: now,
                raceway: _currentRacewayProfile,
                conductors: List.unmodifiable(_conductorGroups),
                fillResult: _fillResult,
                voltageDropResult: _voltageDropResult,
                deratingResult: _deratingResult,
                nominalVoltage: _nominalVoltage,
                circuitPhase: _circuitPhase,
                circuitLengthFeet: _circuitLengthFeet,
                loadCurrentAmps: _loadCurrentAmps,
                powerFactor: _powerFactor,
                ambientTempC: _ambientTempC,
                terminalRatingC: _terminalRatingC,
                isNipple: _isNipple,
              );
              await StorageService.instance.saveCalculation(savedItem);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surfaceElevated,
                    content: Text(
                      _tr(
                        'Guardado "$title" en proyectos',
                        'Saved "$title" to projects',
                        'Salvo "$title" em projetos',
                      ),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(
              _tr('Guardar', 'Save Run', 'Salvar'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _updateGroupCount(int index, int delta) {
    setState(() {
      final current = _conductorGroups[index];
      final newCount = current.count + delta;
      if (newCount <= 0) {
        _conductorGroups.removeAt(index);
      } else {
        _conductorGroups[index] = current.copyWith(count: newCount);
      }
    });
  }

  void _removeGroup(int index) {
    setState(() {
      _conductorGroups.removeAt(index);
    });
  }

  void _openAddConductorDialog() {
    String selectedGauge = '12 AWG';
    String selectedRole = 'phaseA';
    ConductorInsulation selectedInsulation = ConductorInsulation.thhn;
    ConductorMaterial selectedMaterial = ConductorMaterial.copper;
    int quantity = 1;
    final isMetric = StorageService.instance.isMetric;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _tr('Agregar Grupo de Conductores', 'Add Conductor Group',
                              'Adicionar Grupo de Condutores'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.borderSubtle),

                    // Gauge Selector
                    Text(
                      _tr('Calibre del Conductor', 'Conductor Gauge', 'Bitola do Condutor'),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: selectedGauge,
                      dropdownColor: AppColors.surfaceCardHover,
                      items: ConductorCatalog.standardAwgGauges.map((g) {
                        return DropdownMenuItem(
                          value: g,
                          child: Text(
                            NormativeFormatters.formatAwgWithMetric(g, isMetric: isMetric),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedGauge = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Role Selector
                    Text(
                      _tr('Rol en el Circuito', 'Circuit Role', 'Função no Circuito'),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildRoleChip('phaseA', _tr('Fase A', 'Phase A', 'Fase A'),
                            selectedRole, (r) => setDialogState(() => selectedRole = r)),
                        _buildRoleChip('phaseB', _tr('Fase B', 'Phase B', 'Fase B'),
                            selectedRole, (r) => setDialogState(() => selectedRole = r)),
                        _buildRoleChip('phaseC', _tr('Fase C', 'Phase C', 'Fase C'),
                            selectedRole, (r) => setDialogState(() => selectedRole = r)),
                        _buildRoleChip('neutral', _tr('Neutro', 'Neutral', 'Neutro'),
                            selectedRole, (r) => setDialogState(() => selectedRole = r)),
                        _buildRoleChip('ground', _tr('Tierra', 'Ground', 'Terra'),
                            selectedRole, (r) => setDialogState(() => selectedRole = r)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Insulation & Material Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _tr('Aislamiento', 'Insulation', 'Isolação'),
                                style: const TextStyle(
                                    color: AppColors.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<ConductorInsulation>(
                                initialValue: selectedInsulation,
                                dropdownColor: AppColors.surfaceCardHover,
                                items: ConductorInsulation.values.map((ins) {
                                  return DropdownMenuItem(
                                    value: ins,
                                    child: Text(ins.displayName.split(' ').first),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setDialogState(() => selectedInsulation = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _tr('Material', 'Material', 'Material'),
                                style: const TextStyle(
                                    color: AppColors.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<ConductorMaterial>(
                                initialValue: selectedMaterial,
                                dropdownColor: AppColors.surfaceCardHover,
                                items: ConductorMaterial.values.map((mat) {
                                  return DropdownMenuItem(
                                    value: mat,
                                    child: Text(mat.displayName.split(' ').first),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setDialogState(() => selectedMaterial = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quantity Stepper
                    Row(
                      children: [
                        Text(
                          _tr('Cantidad:', 'Quantity:', 'Quantidade:'),
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: AppColors.textSecondary),
                          onPressed:
                              quantity > 1 ? () => setDialogState(() => quantity--) : null,
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.compliant),
                          onPressed: () => setDialogState(() => quantity++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Add Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: Text(
                            _tr('Agregar al Cálculo', 'Add to Schedule', 'Adicionar ao Cálculo')),
                        onPressed: () {
                          final spec = ConductorCatalog.getSpec(
                            gauge: selectedGauge,
                            insulation: selectedInsulation,
                            material: selectedMaterial,
                          );
                          setState(() {
                            _conductorGroups.add(ConductorGroup(
                              id: DateTime.now().microsecondsSinceEpoch.toString(),
                              spec: spec,
                              count: quantity,
                              role: selectedRole,
                            ));
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoleChip(
      String role, String label, String currentRole, Function(String) onSelect) {
    final isSelected = role == currentRole;
    final color = AppColors.getConductorColor(role);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelect(role),
      avatar: CircleAvatar(
        radius: 6,
        backgroundColor: color,
      ),
      selectedColor: color.withValues(alpha: 0.25),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = StorageService.instance;
    final country = storage.normativeCountry;
    final isMexico = storage.isMexicoProfile;
    final isMetric = storage.isMetric;

    final fill = _fillResult;
    final raceway = _currentRacewayProfile;
    final vDrop = _voltageDropResult;
    final derate = _deratingResult;
    final hasSubtitle = _technicianProfile.companyName.isNotEmpty ||
        _technicianProfile.technicianName.isNotEmpty;

    final upsizeSizeLabel = fill.recommendedUpsizeTradeSize != null
        ? NormativeFormatters.formatRacewaySize(
            fill.recommendedUpsizeTradeSize!,
            type: raceway.type,
            isMetric: isMetric,
          )
        : '';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: GestureDetector(
          onTap: () async {
            if (_technicianProfile.companyName.isEmpty &&
                _technicianProfile.technicianName.isEmpty) {
              await showDialog(
                context: context,
                builder: (_) => OnboardingDialog(storageService: StorageService.instance),
              );
              await _refreshSubscriptionState();
            } else if (widget.onOpenSettingsTab != null) {
              widget.onOpenSettingsTab!();
            } else {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              await _refreshSubscriptionState();
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ElectroNorm Pro',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              Text(
                hasSubtitle
                    ? (_technicianProfile.companyName.isNotEmpty
                        ? _technicianProfile.companyName
                        : _technicianProfile.technicianName)
                    : _tr(
                        'Configurar Perfil Técnico ▾',
                        'Set Up Technician Profile ▾',
                        'Configurar Perfil Técnico ▾',
                      ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // FieldQuote-style PRO Pill Badge
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: InkWell(
              key: const Key('btnPaywallAppBar'),
              onTap: _openPaywall,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: _isProSubscriber
                      ? const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF047857)],
                        )
                      : LinearGradient(
                          colors: [
                            const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            const Color(0xFFD97706).withValues(alpha: 0.2),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isProSubscriber
                        ? AppTheme.success
                        : const Color(0xFFF59E0B).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isProSubscriber
                          ? Icons.verified_rounded
                          : Icons.workspace_premium_rounded,
                      size: 14,
                      color: _isProSubscriber ? Colors.white : const Color(0xFFFBBF24),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _isProSubscriber ? Colors.white : const Color(0xFFFBBF24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            key: const Key('btnClearCalculation'),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: _tr('Limpiar / Nuevo', 'Clear / New', 'Limpar / Novo'),
            onPressed: () {
              resetToNewCalculation();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_tr('Cálculo limpiado', 'Calculation cleared', 'Cálculo limpo')),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            key: const Key('btnSavedProjectsAppBar'),
            icon: const Icon(Icons.folder_special_outlined, size: 20),
            tooltip: _tr('Proyectos Guardados', 'Saved Projects', 'Projetos Salvos'),
            onPressed: _openSavedProjects,
          ),
          IconButton(
            key: const Key('btnExportPdfAppBar'),
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
            tooltip: _tr('Exportar PDF / Firmar', 'Export PDF / Sign Report', 'Exportar PDF'),
            onPressed: _openReportPreview,
          ),
          IconButton(
            key: const Key('btnSaveProject'),
            icon: const Icon(Icons.bookmark_add_outlined, size: 20),
            tooltip: _tr('Guardar Cálculo', 'Save Calculation', 'Salvar Cálculo'),
            onPressed: _showSaveCalculationDialog,
          ),
          IconButton(
            key: const Key('btnSettingsAppBar'),
            icon: const Icon(Icons.tune_rounded, size: 20),
            tooltip: _tr('Ajustes / Perfil Normativo', 'Settings / Normative Profile',
                'Ajustes / Perfil'),
            onPressed: () async {
              if (widget.onOpenSettingsTab != null) {
                widget.onOpenSettingsTab!();
              } else {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
                await _refreshSubscriptionState();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact Normative Country & Unit Banner
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  key: const Key('btnCalculatorProfileBanner'),
                  onTap: _toggleCountryQuickly,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.accent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(country.flagEmoji, style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${country.codeBadge}  •  ${isMetric ? _tr("Métrico (DN / mm² / m)", "Metric (DN / mm² / m)", "Métrico") : _tr("Imperial (in / ft)", "Imperial (in / ft)", "Imperial")}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _tr('Cambiar ⇄', 'Switch ⇄', 'Trocar ⇄'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Sticky Top Cross-Section Vector Visualizer
              RacewayVisualizer(
                conduitRadiusInches: raceway.internalDiameterInches / 2.0,
                groups: _conductorGroups,
                fillPercentage: fill.fillPercentage,
                maxAllowedFill: fill.allowedFillPercentage,
                tradeSize: raceway.tradeSize,
                racewayType: raceway.type.displayName,
                jamRatio: _activeJamRatio,
                hasJamRisk: _hasActiveJamRisk,
                isNipple: _isNipple,
              ),

              const SizedBox(height: 10),

              // Automated Upsize Recommendation Pill
              if (!fill.isCompliant && fill.recommendedUpsizeTradeSize != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ElevatedButton.icon(
                    key: const Key('btnUpsize'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.overfilled,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: const Icon(Icons.bolt, size: 20),
                    label: Text(
                      _tr(
                        '⚡ ¡Excedido! Tocar para subir a $upsizeSizeLabel ${raceway.type.displayName}',
                        '⚡ Overfilled! Tap to Upsize to $upsizeSizeLabel ${raceway.type.displayName}',
                        '⚡ Excedido! Subir para $upsizeSizeLabel ${raceway.type.displayName}',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: _upsizeRaceway,
                  ),
                ),

              // Quick Presets Row (Progressive Disclosure)
              if (_showPresets) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isMexico
                          ? _tr('Plantillas Rápidas NOM-001', 'NOM-001 Quick Presets',
                              'Modelos Rápidos NOM')
                          : _tr('Plantillas Rápidas NEC', 'Quick Presets', 'Modelos Rápidos'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    if (widget.startEmpty)
                      InkWell(
                        onTap: () => setState(() => _showPresets = false),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.close_rounded,
                              size: 16, color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: isMexico
                        ? [
                            ActionChip(
                              label: const Text('3x #12 Monofásico 127V'),
                              onPressed: () => _applyPreset('preset_mx_mono_127'),
                            ),
                            const SizedBox(width: 6),
                            ActionChip(
                              label: const Text('3x #10 Bifásico 220V'),
                              onPressed: () => _applyPreset('preset_mx_bif_220'),
                            ),
                            const SizedBox(width: 6),
                            ActionChip(
                              label: const Text('3x #8 + #10 Trifásico'),
                              onPressed: () => _applyPreset('preset_mx_tri_220'),
                            ),
                            const SizedBox(width: 6),
                            ActionChip(
                              label: const Text('3x 250k + #4 Alim. 440V'),
                              onPressed: () => _applyPreset('preset_mx_alim_440'),
                            ),
                          ]
                        : [
                            ActionChip(
                              label: const Text('3x #10 + 1x #12 Grd'),
                              onPressed: () => _applyPreset('preset_3x10_1x12'),
                            ),
                            const SizedBox(width: 6),
                            ActionChip(
                              label: const Text('3x 500k + 1x #3 Grd'),
                              onPressed: () => _applyPreset('preset_3x500_1x3'),
                            ),
                            const SizedBox(width: 6),
                            ActionChip(
                              label: const Text('4x #12 Branch'),
                              onPressed: () => _applyPreset('preset_4x12_branch'),
                            ),
                            const SizedBox(width: 6),
                            ActionChip(
                              label: const Text('3x 4/0 Service'),
                              onPressed: () => _applyPreset('preset_3x40_service'),
                            ),
                          ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Raceway Selector Card
              _buildRacewaySelectorCard(raceway),

              const SizedBox(height: 14),

              // Conductor Schedule Card
              _buildConductorScheduleCard(),

              const SizedBox(height: 14),

              // Progressive Disclosure Add-On Modules Bar
              // Allows users to add Voltage Drop, Thermal Derating, or Quick Presets on demand
              if (!_showVoltageDrop || !_showThermalDerating || !_showPresets) ...[
                _buildProgressiveModulesSelector(),
                const SizedBox(height: 14),
              ],

              // Voltage Drop Expansion Card
              if (_showVoltageDrop) ...[
                _buildVoltageDropCard(vDrop),
                const SizedBox(height: 14),
              ],

              // Ampacity Derating Expansion Card
              if (_showThermalDerating) ...[
                _buildDeratingCard(derate),
                const SizedBox(height: 14),
              ],

              // Export PDF / Sign Report Card
              _buildExportPdfCard(),

              const SizedBox(height: 10),

              // Save Calculation to Projects Card
              _buildSaveProjectCard(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Progressive Disclosure Selector: lets users add calculation modules as they need them
  Widget _buildProgressiveModulesSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.add_chart_rounded, color: AppTheme.accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _tr(
                    'AGREGAR ANÁLISIS O HERRAMIENTAS AL CÁLCULO',
                    'ADD ANALYSIS OR TOOLS TO CALCULATION',
                    'ADICIONAR ANÁLISE OU FERRAMENTAS AO CÁLCULO',
                  ),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accent,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _tr(
              'Activa únicamente los módulos que necesites para este tramo:',
              'Enable only the modules you need for this conduit run:',
              'Ative apenas os módulos necessários para este trecho:',
            ),
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!_showVoltageDrop)
                ActionChip(
                  key: const Key('btnToggleVoltageDrop'),
                  avatar: const Icon(Icons.bolt_rounded, size: 16, color: AppColors.caution),
                  label: Text(
                    _tr('+ Caída de Tensión', '+ Voltage Drop', '+ Queda de Tensão'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: AppColors.surfaceElevated,
                  side: BorderSide(color: AppColors.caution.withValues(alpha: 0.5)),
                  onPressed: () => setState(() => _showVoltageDrop = true),
                ),
              if (!_showThermalDerating)
                ActionChip(
                  key: const Key('btnToggleThermalDerating'),
                  avatar:
                      const Icon(Icons.thermostat_rounded, size: 16, color: AppColors.compliant),
                  label: Text(
                    _tr('+ Desclasificación Térmica', '+ Thermal Derating', '+ Fator Térmico'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: AppColors.surfaceElevated,
                  side: BorderSide(color: AppColors.compliant.withValues(alpha: 0.5)),
                  onPressed: () => setState(() => _showThermalDerating = true),
                ),
              if (!_showPresets)
                ActionChip(
                  key: const Key('btnToggleQuickPresets'),
                  avatar: const Icon(Icons.auto_awesome_rounded, size: 16, color: AppTheme.accent),
                  label: Text(
                    StorageService.instance.isMexicoProfile
                        ? _tr('+ Plantillas NOM-001', '+ Quick Presets', '+ Modelos NOM')
                        : _tr('+ Plantillas Rápidas NEC', '+ Quick Presets', '+ Modelos Rápidos'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: AppColors.surfaceElevated,
                  side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.5)),
                  onPressed: () => setState(() => _showPresets = true),
                ),
              ActionChip(
                key: const Key('btnOpenConduitBending'),
                avatar: const Icon(Icons.architecture_rounded, size: 16, color: AppTheme.accent),
                label: Text(
                  _tr('Doblado EMT', 'Conduit Bending', 'Dobragem EMT'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppColors.surfaceElevated,
                side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.5)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ConduitBendingScreen()),
                  );
                },
              ),
              ActionChip(
                key: const Key('btnOpenGroundingCalc'),
                avatar: const Icon(Icons.shield_outlined, size: 16, color: AppColors.compliant),
                label: Text(
                  StorageService.instance.isMexicoProfile
                      ? _tr('Tierra NOM 250', 'Grounding NOM 250', 'Aterramento 250')
                      : _tr('Tierra NEC 250', 'Grounding NEC 250', 'Aterramento 250'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppColors.surfaceElevated,
                side: BorderSide(color: AppColors.compliant.withValues(alpha: 0.5)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GroundingScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportPdfCard() {
    return Card(
      key: const Key('cardExportPdf'),
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderHighContrast, width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _openReportPreview,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.compliant.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: AppColors.compliant,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr('Exportar PDF / Firmar Dictamen', 'Export PDF / Sign Report',
                          'Exportar PDF / Assinar'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      StorageService.instance.isMexicoProfile
                          ? _tr(
                              'Generar memoria técnica NOM-001 A4 lista para verificación con firma táctil',
                              'Generate inspection-ready A4 compliance memorandum with touch signature',
                              'Gerar relatório técnico A4 com assinatura digital',
                            )
                          : _tr(
                              'Generar memoria de cumplimiento NEC A4 con firma táctil',
                              'Generate inspection-ready A4 compliance memorandum with touch signature',
                              'Gerar relatório técnico A4 com assinatura digital',
                            ),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveProjectCard() {
    return Card(
      key: const Key('cardSaveProject'),
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderHighContrast, width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _showSaveCalculationDialog,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.phaseC.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bookmark_add,
                  color: AppColors.phaseC,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr('Guardar Cálculo en Proyectos', 'Save Calculation to Projects',
                          'Salvar Cálculo em Projetos'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _tr(
                        'Almacena tubería, conductores y parámetros localmente',
                        'Store raceway schedule, conductors & parameters locally',
                        'Armazena eletroduto, condutores e parâmetros localmente',
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRacewaySelectorCard(RacewayProfile raceway) {
    final isMetric = StorageService.instance.isMetric;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _tr('Especificación de Canalización', 'Raceway Specification',
                        'Especificação do Eletroduto'),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Nipple <= 24" (60 cm) toggle
                Row(
                  children: [
                    Text(
                      isMetric ? 'Niple ≤ 60 cm' : 'Nipple ≤ 24"',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Switch(
                      value: _isNipple,
                      activeThumbColor: AppColors.compliant,
                      onChanged: (val) => setState(() => _isNipple = val),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: AppColors.borderSubtle),
            Row(
              children: [
                // Raceway Family
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<RacewayType>(
                    isExpanded: true,
                    initialValue: _selectedRacewayType,
                    decoration: InputDecoration(
                      labelText: _tr('Tipo de Tubería', 'Raceway Family', 'Tipo de Tubo'),
                    ),
                    dropdownColor: AppColors.surfaceCardHover,
                    items: RacewayType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRacewayType = val);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Trade Size
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedTradeSize,
                    decoration: InputDecoration(
                      labelText: isMetric
                          ? _tr('Diámetro Nominal', 'Trade Size (DN)', 'Diâmetro')
                          : _tr('Diámetro (")', 'Trade Size', 'Bitola'),
                    ),
                    dropdownColor: AppColors.surfaceCardHover,
                    items: RacewayCatalog.standardTradeSizes.map((size) {
                      return DropdownMenuItem(
                        value: size,
                        child: Text(
                          NormativeFormatters.formatRacewaySize(
                            size,
                            type: _selectedRacewayType,
                            isMetric: isMetric,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTradeSize = val);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConductorScheduleCard() {
    final storage = StorageService.instance;
    final isMetric = storage.isMetric;
    final isMexico = storage.isMexicoProfile;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _tr('Lista de Conductores', 'Conductor Schedule', 'Lista de Condutores'),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  key: const Key('btnAddConductor'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: Text(
                    _tr('Agregar', 'Add Conductor', 'Adicionar'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: _openAddConductorDialog,
                ),
              ],
            ),
            const Divider(color: AppColors.borderSubtle),
            if (_conductorGroups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Center(
                      child: Text(
                        _tr(
                          'Sin conductores agregados. Toca "Agregar" o elige una plantilla.',
                          'No conductors added. Tap "Add Conductor" or select a preset.',
                          'Nenhum condutor adicionado. Toque em "Adicionar".',
                        ),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (!_showPresets) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () => setState(() => _showPresets = true),
                        icon: const Icon(Icons.auto_awesome_rounded,
                            size: 16, color: AppTheme.accent),
                        label: Text(
                          isMexico
                              ? _tr(
                                  'Ver Plantillas NOM-001',
                                  'Show Quick NOM-001 Presets',
                                  'Ver Modelos NOM',
                                )
                              : _tr(
                                  'Ver Plantillas Rápidas NEC',
                                  'Show Quick NEC Presets',
                                  'Ver Modelos Rápidos NEC',
                                ),
                          style: const TextStyle(color: AppTheme.accent, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _conductorGroups.length,
                separatorBuilder: (context, i) =>
                    const Divider(color: AppColors.borderSubtle, height: 1),
                itemBuilder: (context, index) {
                  final group = _conductorGroups[index];
                  final color = AppColors.getConductorColor(group.role);
                  final metricsLine = isMetric
                      ? '${_tr("Área", "Area", "Área")}: ${(group.totalAreaSqInches * NormativeFormatters.sqInchesToSqMm).toStringAsFixed(1)} mm² | Ø: ${(group.spec.outerDiameterInches * NormativeFormatters.inchesToMm).toStringAsFixed(2)} mm'
                      : 'Area: ${group.totalAreaSqInches.toStringAsFixed(4)} sq in | OD: ${group.spec.outerDiameterInches.toStringAsFixed(3)}"';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 7,
                          backgroundColor: color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${group.count}x ${group.spec.gauge} ${group.spec.insulation.name.toUpperCase()} (${group.role})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                metricsLine,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Stepper buttons
                        IconButton(
                          key: Key('btnStepperRemove_$index'),
                          icon:
                              const Icon(Icons.remove, size: 16, color: AppColors.textSecondary),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () => _updateGroupCount(index, -1),
                        ),
                        Text(
                          '${group.count}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          key: Key('btnStepperAdd_$index'),
                          icon: const Icon(Icons.add, size: 16, color: AppColors.compliant),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () => _updateGroupCount(index, 1),
                        ),
                        IconButton(
                          key: Key('btnDeleteGroup_$index'),
                          icon: const Icon(Icons.delete_outline,
                              size: 16, color: AppColors.overfilled),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () => _removeGroup(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoltageDropCard(VoltageDropResult vDrop) {
    final storage = StorageService.instance;
    final isMetric = storage.isMetric;
    final country = storage.normativeCountry;

    final statusColor = vDrop.complianceStatus == VoltageDropComplianceStatus.pass
        ? AppColors.compliant
        : (vDrop.complianceStatus == VoltageDropComplianceStatus.caution
            ? AppColors.caution
            : AppColors.overfilled);

    final double lengthMeters =
        (_circuitLengthFeet * NormativeFormatters.feetToMeters).clamp(3.0, 300.0);
    final String lengthText = isMetric
        ? '${_tr("Longitud del Circuito", "Circuit Length", "Comprimento")}: ${lengthMeters.toStringAsFixed(0)} m (${_circuitLengthFeet.toStringAsFixed(0)} ft)'
        : '${_tr("Longitud del Circuito", "Circuit Length", "Comprimento")}: ${_circuitLengthFeet.toStringAsFixed(0)} ft';

    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Row(
          children: [
            Expanded(
              child: Text(
                _tr('Caída de Tensión en Vivo', 'Live Voltage Drop', 'Queda de Tensão'),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  '${vDrop.percentageDrop.toStringAsFixed(2)}% (${vDrop.complianceStatus.displayName})',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (widget.startEmpty) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: () => setState(() => _showVoltageDrop = false),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                ),
              ),
            ],
          ],
        ),
        childrenPadding: const EdgeInsets.all(12),
        children: [
          // Phase and Voltage Toggles
          Row(
            children: [
              Expanded(
                child: SegmentedButton<CircuitPhase>(
                  segments: [
                    ButtonSegment(
                      value: CircuitPhase.singlePhase,
                      label: Text(_tr('1-Fase', '1-Phase', '1-Fase')),
                    ),
                    ButtonSegment(
                      value: CircuitPhase.threePhase,
                      label: Text(_tr('3-Fases', '3-Phase', '3-Fases')),
                    ),
                  ],
                  selected: {_circuitPhase},
                  onSelectionChanged: (set) {
                    setState(() => _circuitPhase = set.first);
                  },
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<double>(
                value: _nominalVoltage,
                dropdownColor: AppColors.surfaceCardHover,
                items: NormativeCountryExtension.allSupportedVoltages.map((v) {
                  return DropdownMenuItem(
                    value: v,
                    child: Text('${v.toStringAsFixed(0)} V'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _nominalVoltage = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Length Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  lengthText,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    '${_tr("Caída", "Drop", "Queda")}: ${vDrop.voltageDropVolts.toStringAsFixed(2)} V',
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: isMetric ? lengthMeters : _circuitLengthFeet.clamp(10.0, 1000.0),
            min: isMetric ? 3.0 : 10.0,
            max: isMetric ? 300.0 : 1000.0,
            divisions: 99,
            activeColor: AppColors.compliant,
            onChanged: (val) => setState(() {
              _circuitLengthFeet =
                  isMetric ? val / NormativeFormatters.feetToMeters : val;
            }),
          ),

          // Load Current Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${_tr("Corriente de Carga", "Load Current", "Corrente")}: ${_loadCurrentAmps.toStringAsFixed(0)} A',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    '${_tr("Tensión Final", "End Voltage", "Tensão Final")}: ${vDrop.endVoltage.toStringAsFixed(1)} V',
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _loadCurrentAmps.clamp(1.0, 500.0),
            min: 1.0,
            max: 500.0,
            divisions: 499,
            activeColor: AppColors.compliant,
            onChanged: (val) => setState(() => _loadCurrentAmps = val),
          ),

          // Power Factor Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${_tr("Factor de Potencia", "Power Factor", "Fator de Potência")}: ${_powerFactor.toStringAsFixed(2)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    '${country.shortCode}: ${_tr("Derivado 3% | Total 5%", "Branch 3% | Total 5%", "3% | 5%")}',
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _powerFactor.clamp(0.70, 1.00),
            min: 0.70,
            max: 1.00,
            divisions: 30,
            activeColor: AppColors.compliant,
            onChanged: (val) => setState(() => _powerFactor = val),
          ),
        ],
      ),
    );
  }

  Widget _buildDeratingCard(DeratingResult derate) {
    final storage = StorageService.instance;
    final country = storage.normativeCountry;
    final isMetric = storage.isMetric;

    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Row(
          children: [
            Expanded(
              child: Text(
                _tr('Ajuste Térmico y Ampacidad', 'Live Thermal Derating', 'Fator Térmico'),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.compliant.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.compliant),
                ),
                child: Text(
                  '${derate.allowableAmpacity.toStringAsFixed(1)} A ${_tr("Perm.", "Allowable", "Adm.")}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.compliant, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (widget.startEmpty) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: () => setState(() => _showThermalDerating = false),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                ),
              ),
            ],
          ],
        ),
        childrenPadding: const EdgeInsets.all(12),
        children: [
          // Ambient Temperature Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isMetric
                      ? '${_tr("Temp. Ambiente", "Ambient Temp", "Temp. Ambiente")}: ${_ambientTempC.toStringAsFixed(0)}°C'
                      : '${_tr("Temp. Ambiente", "Ambient Temp", "Temp. Ambiente")}: ${_ambientTempC.toStringAsFixed(0)}°C (${(_ambientTempC * 1.8 + 32).toStringAsFixed(0)}°F)',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    '${_tr("Factor Temp.", "Temp Factor", "Fator Temp.")}: ${derate.temperatureCorrectionFactor.toStringAsFixed(2)}',
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _ambientTempC.clamp(10.0, 70.0),
            min: 10.0,
            max: 70.0,
            divisions: 60,
            activeColor: AppColors.caution,
            onChanged: (val) => setState(() => _ambientTempC = val),
          ),

          // CCC & Factors Summary Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${_tr("Cond. Activos (CCC)", "CCC Count", "Cond. Ativos")}: $_calculatedCccCount',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    '${_tr("Factor Agrupamiento", "Bundling Factor", "Fator Agrupamento")}: ${derate.bundlingAdjustmentFactor.toStringAsFixed(2)}',
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Terminal Rating Toggle (60°C / 75°C)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${_tr("Límite Terminales", "Terminal Rating", "Limite Terminais")} (${country.terminalRatingRef}):',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              SegmentedButton<double>(
                segments: const [
                  ButtonSegment(value: 60.0, label: Text('60°C')),
                  ButtonSegment(value: 75.0, label: Text('75°C')),
                ],
                selected: {_terminalRatingC},
                onSelectionChanged: (set) => setState(() => _terminalRatingC = set.first),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Ampacity breakdown details table
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                _buildAmpacityRow(
                    '${_tr("Ampacidad Base", "Base Ampacity", "Ampacidade Base")} (${_primaryConductorSpec.insulation.name.toUpperCase()} 90°C):',
                    '${derate.baseAmpacity.toStringAsFixed(1)} A'),
                _buildAmpacityRow(
                    _tr('Ampacidad Ajustada (Base × FT × FA):',
                        'Derated Ampacity (Base × CF × AF):', 'Ampacidade Ajustada:'),
                    '${derate.deratedAmpacity.toStringAsFixed(1)} A'),
                _buildAmpacityRow(
                    '${_tr("Límite Terminal", "Terminal Limit", "Limite Terminal")} (${_terminalRatingC.toStringAsFixed(0)}°C ${country.terminalRatingRef}):',
                    '${derate.terminalRatingLimit.toStringAsFixed(1)} A'),
                const Divider(color: AppColors.borderSubtle, height: 8),
                _buildAmpacityRow(
                    _tr('Ampacidad Final Permisible (${country.shortCode}):',
                        'Final Allowable Ampacity:', 'Ampacidade Final:'),
                    '${derate.allowableAmpacity.toStringAsFixed(1)} A',
                    isBold: true),
                if (derate.smallWireOcpdLimit != null)
                  _buildAmpacityRow(
                      '${_tr("Límite OCPD Calibres Menores", "Small Conductor OCPD Limit", "Limite OCPD")} (${country.smallOcpdRef}):',
                      '${derate.smallWireOcpdLimit} A ${_tr("Máx", "Max", "Máx")}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmpacityRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isBold ? AppColors.compliant : AppColors.textPrimary,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
