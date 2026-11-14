import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/raceway.dart';
import '../services/pdf_report_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pro_upsell_dialog.dart';
import '../widgets/stat_card.dart';
import 'report_preview_screen.dart';

enum SortOption {
  newest,
  oldest,
  alphabetical,
  fillPercentage,
}

enum FilterOption {
  all,
  compliant,
  caution,
  overfilled,
  jamRisk,
}

class SavedProjectsScreen extends StatefulWidget {
  final ValueChanged<SavedCalculation>? onSelectProject;
  final VoidCallback? onBackToCalculator;

  const SavedProjectsScreen({
    super.key,
    this.onSelectProject,
    this.onBackToCalculator,
  });

  @override
  State<SavedProjectsScreen> createState() => _SavedProjectsScreenState();
}

class _SavedProjectsScreenState extends State<SavedProjectsScreen> {
  List<SavedCalculation> _allCalculations = [];
  bool _isLoading = true;
  bool _isPro = false;
  int _remainingFree = 3;
  String _searchQuery = '';
  SortOption _selectedSort = SortOption.newest;
  FilterOption _selectedFilter = FilterOption.all;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCalculations();
    StorageService.instance.addListener(_onStorageChanged);
  }

  void _onStorageChanged() {
    _loadCalculations();
  }

  @override
  void dispose() {
    StorageService.instance.removeListener(_onStorageChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCalculations() async {
    final list = await StorageService.instance.getSavedCalculations();
    final isPro = await StorageService.instance.isProSubscriber();
    final remaining = await StorageService.instance.getRemainingFreeProjects();
    if (mounted) {
      setState(() {
        _allCalculations = list;
        _isPro = isPro;
        _remainingFree = remaining;
        _isLoading = false;
      });
    }
  }

  String _tr(String es, String en, String pt) {
    final lang = StorageService.instance.localeCode.toLowerCase();
    if (lang.startsWith('en')) return en;
    if (lang.startsWith('pt')) return pt;
    return es;
  }

  Future<void> _deleteCalculation(SavedCalculation item) async {
    await StorageService.instance.deleteCalculation(item.id);
    await _loadCalculations();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Text(
            _tr('Eliminado "${item.title}"', 'Deleted "${item.title}"',
                'Excluído "${item.title}"'),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(SavedCalculation item) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.overfilled, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _tr('¿Eliminar Cálculo?', 'Delete Calculation?', 'Excluir Cálculo?'),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          _tr(
            '¿Seguro que deseas eliminar permanentemente "${item.title}"? Esta acción no se puede deshacer.',
            'Are you sure you want to permanently delete "${item.title}"? This action cannot be undone.',
            'Tem certeza de que deseja excluir permanentemente "${item.title}"?',
          ),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              _tr('Cancelar', 'Cancel', 'Cancelar'),
              style: const TextStyle(color: AppColors.textTertiary),
            ),
          ),
          ElevatedButton(
            key: const Key('btnConfirmDelete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.overfilled,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              _tr('Eliminar', 'Delete', 'Excluir'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _exportSavedProject(SavedCalculation item) async {
    final storage = StorageService.instance;
    final profile = await storage.getProfile();
    final ccc = item.conductors
        .where((g) => g.role != 'ground')
        .fold(0, (sum, g) => sum + g.count);

    final reportData = ComplianceReportData(
      projectTitle: item.title,
      clientName: item.clientName.isEmpty
          ? _tr('Cliente / Instalación', 'Client Facility', 'Cliente / Instalação')
          : item.clientName,
      siteAddress: item.siteAddress.isEmpty
          ? _tr('Sitio de Instalación Eléctrica', 'Site Conduit Installation', 'Local da Obra')
          : item.siteAddress,
      technicianName: profile.technicianName,
      companyName: profile.companyName,
      date: item.timestamp,
      raceway: item.raceway,
      conductors: List.unmodifiable(item.conductors),
      fillResult: item.fillResult,
      voltageDropResult: item.voltageDropResult,
      deratingResult: item.deratingResult,
      licenseNumber: profile.licenseNumber,
      agencyName: profile.agencyName,
      nominalVoltage: item.nominalVoltage,
      circuitPhase: item.circuitPhase,
      circuitLengthFeet: item.circuitLengthFeet,
      loadCurrentAmps: item.loadCurrentAmps,
      powerFactor: item.powerFactor,
      ambientTempC: item.ambientTempC,
      terminalRatingC: item.terminalRatingC,
      cccCount: ccc,
      signaturePngBytes: profile.defaultSignatureBytes,
      localeCode: storage.localeCode,
      normativeCountry: storage.normativeCountry,
      useMetricUnits: storage.isMetric,
    );

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => ReportPreviewScreen(reportData: reportData),
        ),
      );
    }
  }

  List<SavedCalculation> get _filteredAndSortedCalculations {
    List<SavedCalculation> list = _allCalculations.where((item) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = item.title.toLowerCase().contains(q);
        final matchesNotes = item.notes.toLowerCase().contains(q);
        final matchesSize = item.tradeSize.toLowerCase().contains(q) ||
            item.raceway.metricDesignator.toLowerCase().contains(q);
        final matchesType = item.raceway.type.displayName.toLowerCase().contains(q);
        final matchesClient = item.clientName.toLowerCase().contains(q);
        if (!matchesTitle && !matchesNotes && !matchesSize && !matchesType && !matchesClient) {
          return false;
        }
      }

      switch (_selectedFilter) {
        case FilterOption.all:
          return true;
        case FilterOption.compliant:
          return item.fillResult.fillPercentage <= 40.0;
        case FilterOption.caution:
          return item.fillResult.fillPercentage > 40.0 && item.fillResult.fillPercentage <= 50.0;
        case FilterOption.overfilled:
          return item.fillResult.fillPercentage > 50.0;
        case FilterOption.jamRisk:
          return item.fillResult.hasJamRisk;
      }
    }).toList();

    switch (_selectedSort) {
      case SortOption.newest:
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case SortOption.oldest:
        list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case SortOption.alphabetical:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOption.fillPercentage:
        list.sort((a, b) => b.fillResult.fillPercentage.compareTo(a.fillResult.fillPercentage));
        break;
    }

    return list;
  }

  Color _getFillColor(double fill) {
    if (fill <= 40.0) return AppColors.compliant;
    if (fill <= 50.0) return AppColors.caution;
    return AppColors.overfilled;
  }

  @override
  Widget build(BuildContext context) {
    final storage = StorageService.instance;
    final country = storage.normativeCountry;
    final isMetric = storage.isMetric;
    final items = _filteredAndSortedCalculations;
    final compliantCount =
        _allCalculations.where((c) => c.fillResult.fillPercentage <= 40.0).length;
    final alertCount = _allCalculations
        .where((c) => c.fillResult.fillPercentage > 40.0 || c.fillResult.hasJamRisk)
        .length;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(_tr('Proyectos Guardados', 'Saved Projects', 'Projetos Salvos')),
        actions: [
          if (!_isPro)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: InkWell(
                key: const Key('btnFreeQuotaPill'),
                onTap: () => ProUpsellDialog.show(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: Text(
                      '$_remainingFree/3 ${_tr("Gratis", "Free", "Grátis")}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          PopupMenuButton<SortOption>(
            key: const Key('btnSortProjects'),
            icon: const Icon(Icons.sort_rounded),
            tooltip: _tr('Ordenar Cálculos', 'Sort Calculations', 'Ordenar Cálculos'),
            initialValue: _selectedSort,
            onSelected: (val) => setState(() => _selectedSort = val),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: SortOption.newest,
                child: Text(_tr('Más recientes', 'Newest First', 'Mais recentes')),
              ),
              PopupMenuItem(
                value: SortOption.oldest,
                child: Text(_tr('Más antiguos', 'Oldest First', 'Mais antigos')),
              ),
              PopupMenuItem(
                value: SortOption.alphabetical,
                child: Text(_tr('Alfabético (A - Z)', 'Alphabetical (A - Z)', 'Alfabético (A - Z)')),
              ),
              PopupMenuItem(
                value: SortOption.fillPercentage,
                child: Text(_tr('Porcentaje de Llenado', 'Fill Percentage (High to Low)',
                    'Percentual de Ocupação')),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.compliant))
          : Column(
              children: [
                // KPI StatCards row (FieldQuote style) when projects exist and screen height is sufficient
                if (_allCalculations.isNotEmpty &&
                    MediaQuery.of(context).size.height >= 700)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: _tr('Proyectos', 'Projects', 'Projetos'),
                            value: '${_allCalculations.length}',
                            subtitle:
                                '$compliantCount ${_tr("Cumplen", "Compliant", "Conformes")} ${country.shortCode}',
                            icon: Icons.check_circle_outline_rounded,
                            accentColor: AppTheme.success,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatCard(
                            title: _tr('En Alerta', 'Alerts', 'Em Alerta'),
                            value: '$alertCount',
                            subtitle: alertCount == 0
                                ? _tr('0 Violaciones', '0 Violations', '0 Violações')
                                : _tr('Revisar Llenado', 'Check Fill', 'Revisar Ocupação'),
                            icon: Icons.warning_amber_rounded,
                            accentColor:
                                alertCount == 0 ? AppTheme.accent : AppTheme.warning,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: TextField(
                    key: const Key('inputSearchProjects'),
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: _tr(
                        'Buscar por título, notas, diámetro DN...',
                        'Search by title, notes, raceway size...',
                        'Buscar por título, notas, bitola...',
                      ),
                      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surfaceCard,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.compliant, width: 1.5),
                      ),
                    ),
                  ),
                ),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      _buildFilterChip(
                          '${_tr("Todos", "All", "Todos")} (${_allCalculations.length})',
                          FilterOption.all),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          _tr('Cumplen', 'Compliant', 'Conformes'), FilterOption.compliant),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          _tr('Precaución', 'Caution', 'Atenção'), FilterOption.caution),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          _tr('Excedido', 'Overfilled', 'Excedido'), FilterOption.overfilled),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          _tr('Atascamiento', 'Jam Hazard', 'Travamento'), FilterOption.jamRisk),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Calculation List or Empty State
                Expanded(
                  child: items.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _buildProjectCard(item, isMetric: isMetric);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, FilterOption option) {
    final isSelected = _selectedFilter == option;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = option);
      },
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.black : AppColors.textSecondary,
      ),
      selectedColor: AppColors.compliant,
      backgroundColor: AppColors.surfaceCard,
      side: BorderSide(
        color: isSelected ? AppColors.compliant : AppColors.borderSubtle,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceCard,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Icon(
                Icons.folder_open_outlined,
                color: AppColors.textSecondary,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? _tr('Sin resultados para "$_searchQuery"',
                      'No Calculations Match "$_searchQuery"', 'Nenhum resultado para "$_searchQuery"')
                  : _tr('Aún no hay cálculos guardados', 'No Saved Calculations Yet',
                      'Nenhum cálculo salvo ainda'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? _tr(
                      'Intenta ajustar tu búsqueda o los criterios de filtro.',
                      'Try adjusting your search terms or filter criteria.',
                      'Tente ajustar os termos de busca ou filtros.',
                    )
                  : _tr(
                      'Realiza un cálculo de tubería y presiona "Guardar" para mantener tus registros sin conexión.',
                      'Perform a conduit calculation and tap "Save Run" to keep project records offline.',
                      'Realize um cálculo e toque em "Salvar" para manter registros offline.',
                    ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.compliant,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(
                _tr('Volver a Calculadora', 'Back to Calculator', 'Voltar à Calculadora'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                if (widget.onBackToCalculator != null) {
                  widget.onBackToCalculator!();
                } else if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(SavedCalculation item, {required bool isMetric}) {
    final fill = item.fillResult.fillPercentage;
    final fillColor = _getFillColor(fill);
    final totalConductors = item.conductors.fold(0, (sum, g) => sum + g.count);
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(item.timestamp);
    final racewaySizeLabel = NormativeFormatters.formatRacewaySize(
      item.tradeSize,
      type: item.raceway.type,
      metricDesignator: item.raceway.metricDesignator,
      isMetric: isMetric,
    );

    return Dismissible(
      key: Key('dismissible_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.overfilled,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(Icons.delete_forever, color: Colors.white, size: 26),
            const SizedBox(width: 8),
            Text(_tr('Eliminar', 'Delete', 'Excluir'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      confirmDismiss: (direction) => _showDeleteConfirmationDialog(item),
      onDismissed: (direction) => _deleteCalculation(item),
      child: Card(
        key: Key('cardSavedProject_${item.id}'),
        margin: const EdgeInsets.only(bottom: 12),
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        child: InkWell(
          key: Key('cardProject_${item.id}'),
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (widget.onSelectProject != null) {
              widget.onSelectProject!(item);
            } else {
              Navigator.of(context).pop(item);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title & Action Buttons
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: Key('btnExportPdf_${item.id}'),
                          icon: const Icon(Icons.picture_as_pdf_outlined,
                              color: AppColors.textSecondary, size: 20),
                          tooltip: _tr('Exportar PDF', 'Export PDF', 'Exportar PDF'),
                          onPressed: () => _exportSavedProject(item),
                        ),
                        IconButton(
                          key: Key('btnDeleteProject_${item.id}'),
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.textSecondary, size: 20),
                          tooltip: _tr('Eliminar', 'Delete', 'Excluir'),
                          onPressed: () async {
                            final confirm = await _showDeleteConfirmationDialog(item);
                            if (confirm == true) {
                              await _deleteCalculation(item);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                if (item.notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.notes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Details Badges & Indicators
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    // Raceway Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderHighContrast),
                      ),
                      child: Text(
                        '$racewaySizeLabel ${item.raceway.type.displayName}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    // Conductor Count
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Text(
                        '$totalConductors ${_tr("Conductores", "Conductors", "Condutores")}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                    // Fill Percentage Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: fillColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: fillColor, width: 1.2),
                      ),
                      child: Text(
                        '${fill.toStringAsFixed(1)}% ${_tr("Llenado", "Fill", "Ocupação")}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: fillColor,
                        ),
                      ),
                    ),

                    // Jam Hazard Badge
                    if (item.fillResult.hasJamRisk)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.caution.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.caution, width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning, color: AppColors.caution, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              _tr('ATASCAMIENTO', 'JAM HAZARD', 'TRAVAMENTO'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.caution,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Voltage Drop Badge
                    if (item.voltageDropResult != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (item.voltageDropResult!.isCompliantBranch
                                  ? AppColors.compliant
                                  : AppColors.overfilled)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: item.voltageDropResult!.isCompliantBranch
                                ? AppColors.compliant
                                : AppColors.overfilled,
                          ),
                        ),
                        child: Text(
                          '${item.voltageDropResult!.percentageDrop.toStringAsFixed(1)}% ${_tr("ΔV", "VD", "ΔV")}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: item.voltageDropResult!.isCompliantBranch
                                ? AppColors.compliant
                                : AppColors.overfilled,
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
    );
  }
}
