import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/raceway.dart';
import '../services/pdf_report_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
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
  const SavedProjectsScreen({super.key});

  @override
  State<SavedProjectsScreen> createState() => _SavedProjectsScreenState();
}

class _SavedProjectsScreenState extends State<SavedProjectsScreen> {
  List<SavedCalculation> _allCalculations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  SortOption _selectedSort = SortOption.newest;
  FilterOption _selectedFilter = FilterOption.all;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCalculations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCalculations() async {
    final list = await StorageService.instance.getSavedCalculations();
    if (mounted) {
      setState(() {
        _allCalculations = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCalculation(SavedCalculation item) async {
    await StorageService.instance.deleteCalculation(item.id);
    await _loadCalculations();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Text(
            'Deleted "${item.title}"',
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
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.overfilled, size: 26),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete Calculation?',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${item.title}"? This action cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            key: const Key('btnConfirmDelete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.overfilled,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _exportSavedProject(SavedCalculation item) async {
    final profile = await StorageService.instance.getProfile();
    final ccc = item.conductors
        .where((g) => g.role != 'ground')
        .fold(0, (sum, g) => sum + g.count);

    final reportData = ComplianceReportData(
      projectTitle: item.title,
      clientName: item.clientName.isEmpty ? 'Client Facility' : item.clientName,
      siteAddress: item.siteAddress.isEmpty ? 'Site Conduit Installation' : item.siteAddress,
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
        final matchesSize = item.tradeSize.toLowerCase().contains(q);
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
    final items = _filteredAndSortedCalculations;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Saved Projects'),
        actions: [
          PopupMenuButton<SortOption>(
            key: const Key('btnSortProjects'),
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort Calculations',
            initialValue: _selectedSort,
            onSelected: (val) => setState(() => _selectedSort = val),
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: SortOption.newest,
                child: Text('Newest First'),
              ),
              PopupMenuItem(
                value: SortOption.oldest,
                child: Text('Oldest First'),
              ),
              PopupMenuItem(
                value: SortOption.alphabetical,
                child: Text('Alphabetical (A - Z)'),
              ),
              PopupMenuItem(
                value: SortOption.fillPercentage,
                child: Text('Fill Percentage (High to Low)'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.compliant))
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    key: const Key('inputSearchProjects'),
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search by title, notes, raceway size...',
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
                      _buildFilterChip('All (${_allCalculations.length})', FilterOption.all),
                      const SizedBox(width: 8),
                      _buildFilterChip('Compliant', FilterOption.compliant),
                      const SizedBox(width: 8),
                      _buildFilterChip('Caution', FilterOption.caution),
                      const SizedBox(width: 8),
                      _buildFilterChip('Overfilled', FilterOption.overfilled),
                      const SizedBox(width: 8),
                      _buildFilterChip('Jam Hazard', FilterOption.jamRisk),
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
                            return _buildProjectCard(item);
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                  ? 'No Calculations Match "$_searchQuery"'
                  : 'No Saved Calculations Yet',
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
                  ? 'Try adjusting your search terms or filter criteria.'
                  : 'Perform a conduit calculation and tap "Save Run" to keep project records offline.',
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
              label: const Text('Back to Calculator', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(SavedCalculation item) {
    final fill = item.fillResult.fillPercentage;
    final fillColor = _getFillColor(fill);
    final totalConductors = item.conductors.fold(0, (sum, g) => sum + g.count);
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(item.timestamp);

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
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_forever, color: Colors.white, size: 26),
            SizedBox(width: 8),
            Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            // Tap on card loads calculation back into CalculatorScreen
            Navigator.of(context).pop(item);
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
                          icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.textSecondary, size: 20),
                          tooltip: 'Export PDF',
                          onPressed: () => _exportSavedProject(item),
                        ),
                        IconButton(
                          key: Key('btnDeleteProject_${item.id}'),
                          icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary, size: 20),
                          tooltip: 'Delete',
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
                        '${item.tradeSize}" ${item.raceway.type.displayName}',
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
                        '$totalConductors Conductors',
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
                        '${fill.toStringAsFixed(1)}% Fill',
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
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning, color: AppColors.caution, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'JAM HAZARD',
                              style: TextStyle(
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
                          '${item.voltageDropResult!.percentageDrop.toStringAsFixed(1)}% VD',
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
