import 'package:flutter/material.dart';
import '../catalogs/conductor_catalog.dart';
import '../catalogs/raceway_catalog.dart';
import '../models/conductor.dart';
import '../models/raceway.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'conduit_bending_screen.dart';
import 'grounding_screen.dart';

class NecCatalogScreen extends StatefulWidget {
  final void Function(ConductorSpec spec)? onSelectConductor;
  final void Function(RacewayProfile raceway)? onSelectRaceway;

  const NecCatalogScreen({
    super.key,
    this.onSelectConductor,
    this.onSelectRaceway,
  });

  @override
  State<NecCatalogScreen> createState() => _NecCatalogScreenState();
}

class _NecCatalogScreenState extends State<NecCatalogScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'all';
  final TextEditingController _searchCtrl = TextEditingController();

  String _tr(String es, String en, String pt) {
    final lang = StorageService.instance.localeCode;
    if (lang.startsWith('en')) return en;
    if (lang.startsWith('pt')) return pt;
    return es;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_CatalogEntry> _buildEntries({
    required bool isMetric,
    required bool isMexico,
  }) {
    final List<_CatalogEntry> entries = [];

    // 1. Copper THHN Conductors
    for (final gauge in ConductorCatalog.standardAwgGauges) {
      final specCu = ConductorCatalog.getSpec(
        gauge: gauge,
        insulation: ConductorInsulation.thhn,
        material: ConductorMaterial.copper,
      );
      final areaMm2 = (specCu.areaSqInches * 645.16).toStringAsFixed(1);
      entries.add(_CatalogEntry(
        id: 'cu_thhn_$gauge',
        category: 'cu',
        title: '$gauge THHN/THWN-2 — ${_tr('Cobre (Cu)', 'Copper (Cu)', 'Cobre (Cu)')}',
        subtitle: isMetric
            ? 'Ø ${specCu.outerDiameterMm.toStringAsFixed(1)} mm (${specCu.outerDiameterInches.toStringAsFixed(3)}") • ${_tr('Área', 'Area', 'Área')}: $areaMm2 mm² (${specCu.areaSqInches.toStringAsFixed(4)} in²)'
            : 'Ø ${specCu.outerDiameterInches.toStringAsFixed(3)}" (${specCu.outerDiameterMm.toStringAsFixed(1)} mm) • ${_tr('Área', 'Area', 'Área')}: ${specCu.areaSqInches.toStringAsFixed(4)} in²',
        badgePrimary: '${specCu.ampacity75C.toInt()}A @75°C',
        badgeSecondary: '${specCu.ampacity90C.toInt()}A @90°C',
        isConductor: true,
        conductorSpec: specCu,
      ));
    }

    // 2. Aluminum XHHW Conductors
    for (final gauge in ConductorCatalog.standardAwgGauges.skip(2)) {
      final specAl = ConductorCatalog.getSpec(
        gauge: gauge,
        insulation: ConductorInsulation.xhhw,
        material: ConductorMaterial.aluminum,
      );
      final areaMm2 = (specAl.areaSqInches * 645.16).toStringAsFixed(1);
      entries.add(_CatalogEntry(
        id: 'al_xhhw_$gauge',
        category: 'al',
        title: '$gauge XHHW-2 — ${_tr('Aluminio (Al)', 'Aluminum (Al)', 'Alumínio (Al)')}',
        subtitle: isMetric
            ? 'Ø ${specAl.outerDiameterMm.toStringAsFixed(1)} mm (${specAl.outerDiameterInches.toStringAsFixed(3)}") • ${_tr('Área', 'Area', 'Área')}: $areaMm2 mm² (${specAl.areaSqInches.toStringAsFixed(4)} in²)'
            : 'Ø ${specAl.outerDiameterInches.toStringAsFixed(3)}" (${specAl.outerDiameterMm.toStringAsFixed(1)} mm) • ${_tr('Área', 'Area', 'Área')}: ${specAl.areaSqInches.toStringAsFixed(4)} in²',
        badgePrimary: '${specAl.ampacity75C.toInt()}A @75°C',
        badgeSecondary: '${specAl.ampacity90C.toInt()}A @90°C',
        isConductor: true,
        conductorSpec: specAl,
      ));
    }

    // 3. Raceways (EMT, IMC, RMC, PVC 40, PVC 80, FMC)
    for (final profile in RacewayCatalog.profiles) {
      final isPvc = profile.type == RacewayType.pvcSch40 || profile.type == RacewayType.pvcSch80;
      entries.add(_CatalogEntry(
        id: 'raceway_${profile.type.name}_${profile.tradeSize}',
        category: isPvc ? 'pvc' : 'metal',
        title: isMetric
            ? 'DN ${profile.metricDesignator} (${profile.tradeSize}") ${profile.type.displayName}'
            : '${profile.tradeSize}" ${profile.type.displayName} (DN ${profile.metricDesignator})',
        subtitle: isMetric
            ? 'ID: ${profile.internalDiameterMm.toStringAsFixed(1)} mm (${profile.internalDiameterInches.toStringAsFixed(3)}") • Total: ${profile.internalAreaSqMm.toStringAsFixed(0)} mm² (${profile.internalAreaSqInches.toStringAsFixed(3)} in²)'
            : 'ID: ${profile.internalDiameterInches.toStringAsFixed(3)}" • Total: ${profile.internalAreaSqInches.toStringAsFixed(3)} in² (${profile.internalAreaSqMm.toStringAsFixed(0)} mm²)',
        badgePrimary: isMetric
            ? '40%: ${(profile.fill40AreaSqInches * 645.16).toStringAsFixed(0)} mm²'
            : '40%: ${profile.fill40AreaSqInches.toStringAsFixed(3)} in²',
        badgeSecondary: isMetric
            ? '60%: ${(profile.fill60AreaSqInches * 645.16).toStringAsFixed(0)} mm²'
            : '60%: ${profile.fill60AreaSqInches.toStringAsFixed(3)} in²',
        isConductor: false,
        racewayProfile: profile,
      ));
    }

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StorageService.instance,
      builder: (context, _) {
        final storage = StorageService.instance;
        final isMetric = storage.isMetric;
        final isMexico = storage.isMexicoProfile;
        final allEntries = _buildEntries(isMetric: isMetric, isMexico: isMexico);
        final categories = <String, String>{
          'all': _tr('Todos', 'All', 'Todos'),
          'cu': _tr('Conductores Cobre', 'Copper Conductors', 'Condutores Cobre'),
          'al': _tr('Conductores Aluminio', 'Aluminum Conductors', 'Condutores Alumínio'),
          'metal': _tr('Tuberías Metálicas (EMT/IMC/RMC)', 'Metallic Conduit', 'Eletrodutos Metálicos'),
          'pvc': _tr('Tuberías PVC (Sch 40/80)', 'PVC Conduit', 'Eletrodutos PVC'),
        };

        final filtered = allEntries.where((item) {
          final matchesCategory = _selectedCategory == 'all' || item.category == _selectedCategory;
          final matchesSearch = _searchQuery.isEmpty ||
              item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.subtitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.badgePrimary.toLowerCase().contains(_searchQuery.toLowerCase());
          return matchesCategory && matchesSearch;
        }).toList();

        return Scaffold(
          backgroundColor: AppTheme.darkBg,
          appBar: AppBar(
            title: Text(
              isMexico
                  ? _tr('Catálogo y Tablas NOM-001', 'NOM-001 Catalog & Tables',
                      'Catálogo e Tabelas NOM-001')
                  : _tr('Catálogo y Tablas NEC', 'NEC Catalog & Tables', 'Catálogo e Tabelas NEC'),
            ),
            actions: [
              IconButton(
                tooltip: _tr('Doblado de Tubería', 'Conduit Bending', 'Dobragem EMT'),
                icon: const Icon(Icons.architecture_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ConduitBendingScreen()),
                ),
              ),
              IconButton(
                tooltip: isMexico
                    ? _tr('Puesta a Tierra NOM 250', 'Grounding NOM 250', 'Aterramento 250')
                    : _tr('Puesta a Tierra NEC 250', 'Grounding NEC 250', 'Aterramento 250'),
                icon: const Icon(Icons.shield_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GroundingScreen()),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search & Categories (Identical layout to FieldQuote CatalogScreen)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: isMetric
                            ? _tr(
                                'Buscar calibre (ej: 12 AWG) o tubo (ej: DN 21 / 3/4 EMT)...',
                                'Search gauge (e.g. 12 AWG) or conduit (e.g. DN 21 / 3/4 EMT)...',
                                'Buscar bitola (ex: 12 AWG) ou eletroduto (ex: DN 21)...',
                              )
                            : _tr(
                                'Buscar calibre (ej: 12 AWG, 250 kcmil) o tubería (ej: 3/4 EMT)...',
                                'Search gauge (e.g. 12 AWG, 250 kcmil) or conduit (e.g. 3/4 EMT)...',
                                'Buscar bitola (ex: 12 AWG) ou eletroduto (ex: 3/4 EMT)...',
                              ),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8)),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.entries.map((entry) {
                          final isSelected = _selectedCategory == entry.key;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(entry.value),
                              selected: isSelected,
                              selectedColor: AppTheme.primary,
                              backgroundColor: AppTheme.darkCard,
                              side: BorderSide(
                                color: isSelected ? AppTheme.primary : AppTheme.darkBorder,
                              ),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                              ),
                              onSelected: (_) => setState(() => _selectedCategory = entry.key),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Items List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 40,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _tr('No se encontraron especificaciones', 'No specifications found',
                                    'Nenhuma especificação encontrada'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _tr(
                                  'Intenta con otro calibre o tipo de canalización.',
                                  'Try another wire gauge or raceway type.',
                                  'Tente outra bitola ou tipo de eletroduto.',
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: AppTheme.darkCard,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: AppTheme.darkBorder),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: item.isConductor
                                      ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                                      : const Color(0xFF6366F1).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  item.isConductor ? Icons.cable_rounded : Icons.architecture_rounded,
                                  color: item.isConductor
                                      ? const Color(0xFFFBBF24)
                                      : const Color(0xFF818CF8),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  item.subtitle,
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.badgePrimary,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.success,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.badgeSecondary,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                if (item.isConductor &&
                                    item.conductorSpec != null &&
                                    widget.onSelectConductor != null) {
                                  widget.onSelectConductor!(item.conductorSpec!);
                                } else if (!item.isConductor &&
                                    item.racewayProfile != null &&
                                    widget.onSelectRaceway != null) {
                                  widget.onSelectRaceway!(item.racewayProfile!);
                                }
                              },
                            ),
                          ),
                        );
                      },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CatalogEntry {
  final String id;
  final String category;
  final String title;
  final String subtitle;
  final String badgePrimary;
  final String badgeSecondary;
  final bool isConductor;
  final ConductorSpec? conductorSpec;
  final RacewayProfile? racewayProfile;

  const _CatalogEntry({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.badgePrimary,
    required this.badgeSecondary,
    required this.isConductor,
    this.conductorSpec,
    this.racewayProfile,
  });
}
