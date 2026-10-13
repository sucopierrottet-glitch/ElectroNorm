import 'package:flutter/material.dart';

import '../calculators/conduit_fill_calculator.dart';
import '../calculators/derating_calculator.dart';
import '../calculators/jam_ratio_calculator.dart';
import '../calculators/voltage_drop_calculator.dart';
import '../catalogs/conductor_catalog.dart';
import '../catalogs/raceway_catalog.dart';
import '../models/calculation_results.dart';
import '../models/conductor.dart';
import '../models/raceway.dart';
import '../theme/app_theme.dart';
import '../widgets/raceway_painter.dart';
import 'package:uuid/uuid.dart';

import '../services/pdf_report_service.dart';
import '../services/storage_service.dart';
import 'paywall_screen.dart';
import 'report_preview_screen.dart';
import 'saved_projects_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  // Raceway Selection
  RacewayType _selectedRacewayType = RacewayType.emt;
  String _selectedTradeSize = '3/4';
  bool _isNipple = false;

  // Conductor Schedule
  final List<ConductorGroup> _conductorGroups = [];

  // Voltage Drop Parameters
  CircuitPhase _circuitPhase = CircuitPhase.singlePhase;
  double _nominalVoltage = 120.0;
  double _circuitLengthFeet = 100.0;
  double _loadCurrentAmps = 16.0;
  double _powerFactor = 0.90;

  // Derating Parameters
  double _ambientTempC = 30.0;
  double _terminalRatingC = 75.0;

  @override
  void initState() {
    super.initState();
    _loadDefaultPreset();
  }

  void _loadDefaultPreset() {
    _conductorGroups.clear();
    // Default: 3x #10 AWG THHN Cu + 1x #12 AWG Ground
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
    // Map of outside diameter -> total count
    final diameterCounts = <double, int>{};
    for (final group in _conductorGroups) {
      if (group.count <= 0) continue;
      // Round to 4 decimal places for floating point grouping
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
    final reportData = ComplianceReportData(
      projectTitle: 'Field Conduit Run #1',
      clientName: 'Commercial Client',
      siteAddress: 'Facility Electrical Room B',
      technicianName: 'Carlos Mendoza',
      companyName: 'VoltPro Electrical LLC',
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
      _loadSavedCalculation(selected);
    }
  }

  Future<void> _openPaywall() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => const PaywallScreen()),
    );
  }

  void _loadSavedCalculation(SavedCalculation calc) {
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
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Text(
          'Loaded "${calc.title}" into calculator',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showSaveCalculationDialog() async {
    final totalConds = _conductorGroups.fold(0, (sum, g) => sum + g.count);
    final defaultTitle = 'Run #${totalConds}W - ${_currentRacewayProfile.tradeSize}" ${_currentRacewayProfile.type.displayName}';
    final titleController = TextEditingController(text: defaultTitle);
    final clientController = TextEditingController();
    final notesController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.bookmark_add, color: AppColors.compliant, size: 24),
            SizedBox(width: 8),
            Text('Save Calculation Run', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
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
                decoration: const InputDecoration(
                  labelText: 'Project / Calculation Title *',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('inputSaveClient'),
                controller: clientController,
                decoration: const InputDecoration(
                  labelText: 'Client / Site Name (Optional)',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('inputSaveNotes'),
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes / Panel Location (Optional)',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            key: const Key('btnConfirmSaveCalculation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.compliant,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final title = titleController.text.trim().isEmpty ? 'Conduit Run' : titleController.text.trim();
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
                      'Saved "$title" to projects',
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save Run', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        const Text(
                          'Add Conductor Group',
                          style: TextStyle(
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
                    const Text('Conductor Gauge',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: selectedGauge,
                      dropdownColor: AppColors.surfaceCardHover,
                      items: ConductorCatalog.standardAwgGauges.map((g) {
                        return DropdownMenuItem(value: g, child: Text(g));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedGauge = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Role Selector
                    const Text('Circuit Role',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildRoleChip('phaseA', 'Phase A', selectedRole, (r) => setDialogState(() => selectedRole = r)),
                        _buildRoleChip('phaseB', 'Phase B', selectedRole, (r) => setDialogState(() => selectedRole = r)),
                        _buildRoleChip('phaseC', 'Phase C', selectedRole, (r) => setDialogState(() => selectedRole = r)),
                        _buildRoleChip('neutral', 'Neutral', selectedRole, (r) => setDialogState(() => selectedRole = r)),
                        _buildRoleChip('ground', 'Ground', selectedRole, (r) => setDialogState(() => selectedRole = r)),
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
                              const Text('Insulation',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
                              const Text('Material',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
                        const Text('Quantity:',
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecondary),
                          onPressed: quantity > 1 ? () => setDialogState(() => quantity--) : null,
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
                        label: const Text('Add to Schedule'),
                        onPressed: () {
                          final spec = ConductorCatalog.getSpec(
                            gauge: selectedGauge,
                            insulation: selectedInsulation,
                            material: selectedMaterial,
                          );
                          setState(() {
                            _conductorGroups.add(ConductorGroup(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
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

  Widget _buildRoleChip(String role, String label, String currentRole, Function(String) onSelect) {
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
    final fill = _fillResult;
    final raceway = _currentRacewayProfile;
    final vDrop = _voltageDropResult;
    final derate = _deratingResult;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ElectroNorm Pro'),
        actions: [
          IconButton(
            key: const Key('btnSavedProjectsAppBar'),
            icon: const Icon(Icons.folder_special_outlined),
            tooltip: 'Saved Projects',
            onPressed: _openSavedProjects,
          ),
          IconButton(
            key: const Key('btnExportPdfAppBar'),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF / Sign Report',
            onPressed: _openReportPreview,
          ),
          IconButton(
            key: const Key('btnSaveProject'),
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Save Calculation',
            onPressed: _showSaveCalculationDialog,
          ),
          IconButton(
            key: const Key('btnPaywallAppBar'),
            icon: const Icon(Icons.workspace_premium_outlined, color: AppColors.caution),
            tooltip: 'ElectroNorm Pro',
            onPressed: _openPaywall,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to default preset',
            onPressed: _loadDefaultPreset,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      '⚡ Overfilled! Tap to Upsize to ${fill.recommendedUpsizeTradeSize}" ${raceway.type.displayName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: _upsizeRaceway,
                  ),
                ),

              // Quick Presets Row
              const Text(
                'Quick Presets',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
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

              // Raceway Selector Card
              _buildRacewaySelectorCard(raceway),

              const SizedBox(height: 14),

              // Conductor Schedule Card
              _buildConductorScheduleCard(),

              const SizedBox(height: 14),

              // Voltage Drop Expansion Card
              _buildVoltageDropCard(vDrop),

              const SizedBox(height: 14),

              // Ampacity Derating Expansion Card
              _buildDeratingCard(derate),

              const SizedBox(height: 14),

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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export PDF / Sign Report',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Generate inspection-ready A4 compliance memorandum with touch signature',
                      style: TextStyle(
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Save Calculation to Projects',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Store raceway schedule, conductors & parameters locally',
                      style: TextStyle(
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Raceway Specification',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Nipple <= 24" toggle
                Row(
                  children: [
                    const Text('Nipple ≤ 24"', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                    decoration: const InputDecoration(labelText: 'Raceway Family'),
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
                    decoration: const InputDecoration(labelText: 'Trade Size'),
                    dropdownColor: AppColors.surfaceCardHover,
                    items: RacewayCatalog.standardTradeSizes.map((size) {
                      return DropdownMenuItem(
                        value: size,
                        child: Text('$size"', overflow: TextOverflow.ellipsis),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Conductor Schedule',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
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
                  label: const Text('Add Conductor', style: TextStyle(fontSize: 12)),
                  onPressed: _openAddConductorDialog,
                ),
              ],
            ),
            const Divider(color: AppColors.borderSubtle),

            if (_conductorGroups.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No conductors added. Tap "Add Conductor" or select a preset.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _conductorGroups.length,
                separatorBuilder: (context, i) => const Divider(color: AppColors.borderSubtle, height: 1),
                itemBuilder: (context, index) {
                  final group = _conductorGroups[index];
                  final color = AppColors.getConductorColor(group.role);
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
                                'Area: ${group.totalAreaSqInches.toStringAsFixed(4)} sq in | OD: ${group.spec.outerDiameterInches.toStringAsFixed(3)}"',
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
                          icon: const Icon(Icons.remove, size: 16, color: AppColors.textSecondary),
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
                          icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.overfilled),
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
    final statusColor = vDrop.complianceStatus == VoltageDropComplianceStatus.pass
        ? AppColors.compliant
        : (vDrop.complianceStatus == VoltageDropComplianceStatus.caution
            ? AppColors.caution
            : AppColors.overfilled);

    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'Live Voltage Drop',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
          ],
        ),
        childrenPadding: const EdgeInsets.all(12),
        children: [
          // Phase and Voltage Toggles
          Row(
            children: [
              Expanded(
                child: SegmentedButton<CircuitPhase>(
                  segments: const [
                    ButtonSegment(value: CircuitPhase.singlePhase, label: Text('1-Phase')),
                    ButtonSegment(value: CircuitPhase.threePhase, label: Text('3-Phase')),
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
                items: const [
                  DropdownMenuItem(value: 120.0, child: Text('120 V')),
                  DropdownMenuItem(value: 208.0, child: Text('208 V')),
                  DropdownMenuItem(value: 240.0, child: Text('240 V')),
                  DropdownMenuItem(value: 480.0, child: Text('480 V')),
                ],
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
                  'Circuit Length: ${_circuitLengthFeet.toStringAsFixed(0)} ft',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    'Drop: ${vDrop.voltageDropVolts.toStringAsFixed(2)} V',
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _circuitLengthFeet.clamp(10.0, 1000.0),
            min: 10.0,
            max: 1000.0,
            divisions: 99,
            activeColor: AppColors.compliant,
            onChanged: (val) => setState(() => _circuitLengthFeet = val),
          ),

          // Load Current Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Load Current: ${_loadCurrentAmps.toStringAsFixed(0)} A',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    'End Voltage: ${vDrop.endVoltage.toStringAsFixed(1)} V',
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
                  'Power Factor: ${_powerFactor.toStringAsFixed(2)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              const Flexible(
                child: Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text(
                    'Branch Limit: 3% | Total: 5%',
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
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
    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'Live Thermal Derating',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                  '${derate.allowableAmpacity.toStringAsFixed(1)} A Allowable',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.compliant, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
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
                  'Ambient Temp: ${_ambientTempC.toStringAsFixed(0)}°C (${(_ambientTempC * 1.8 + 32).toStringAsFixed(0)}°F)',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    'Temp Factor: ${derate.temperatureCorrectionFactor.toStringAsFixed(2)}',
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                  'CCC Count: $_calculatedCccCount',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    'Bundling Factor: ${derate.bundlingAdjustmentFactor.toStringAsFixed(2)}',
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
              const Expanded(
                child: Text(
                  'Terminal Rating (NEC 110.14(C)):',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                _buildAmpacityRow('Base Ampacity (${_primaryConductorSpec.insulation.name.toUpperCase()} 90°C):',
                    '${derate.baseAmpacity.toStringAsFixed(1)} A'),
                _buildAmpacityRow('Derated Ampacity (Base × CF × AF):',
                    '${derate.deratedAmpacity.toStringAsFixed(1)} A'),
                _buildAmpacityRow('Terminal Limit (${_terminalRatingC.toStringAsFixed(0)}°C NEC 110.14(C)):',
                    '${derate.terminalRatingLimit.toStringAsFixed(1)} A'),
                const Divider(color: AppColors.borderSubtle, height: 8),
                _buildAmpacityRow('Final Allowable Ampacity:',
                    '${derate.allowableAmpacity.toStringAsFixed(1)} A', isBold: true),
                if (derate.smallWireOcpdLimit != null)
                  _buildAmpacityRow('Small Conductor OCPD Limit (NEC 240.4(D)):',
                      '${derate.smallWireOcpdLimit} A Max'),
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
