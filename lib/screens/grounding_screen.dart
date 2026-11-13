import 'package:flutter/material.dart';
import '../calculators/grounding_calculator.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class GroundingScreen extends StatefulWidget {
  const GroundingScreen({super.key});

  @override
  State<GroundingScreen> createState() => _GroundingScreenState();
}

class _GroundingScreenState extends State<GroundingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- EGC State (Table 250.122) ---
  int _selectedOcpd = 100;
  bool _enableVoltageDropUpsize = false;
  String _stdPhaseConductor = '3 AWG';
  String _upsizedPhaseConductor = '1/0 AWG';

  // --- GEC State (Table 250.66) ---
  String _serviceConductorSize = '2/0 AWG';
  GroundingConductorMaterial _serviceMaterial =
      GroundingConductorMaterial.copper;
  ElectrodeType _selectedElectrode = ElectrodeType.rodPipePlate;

  static const List<int> _standardOcpdRatings = [
    15, 20, 30, 40, 50, 60, 70, 80, 90, 100, 125, 150, 175, 200, 225, 250,
    300, 350, 400, 500, 600, 800, 1000, 1200, 1600, 2000, 2500, 3000, 4000,
  ];

  static const List<String> _commonWireGauges = [
    '14 AWG', '12 AWG', '10 AWG', '8 AWG', '6 AWG', '4 AWG', '3 AWG',
    '2 AWG', '1 AWG', '1/0 AWG', '2/0 AWG', '3/0 AWG', '4/0 AWG',
    '250 kcmil', '300 kcmil', '350 kcmil', '400 kcmil', '500 kcmil',
    '600 kcmil', '750 kcmil', '1000 kcmil', '1500 kcmil', '2000 kcmil',
  ];

  String _tr(String es, String en, String pt) {
    final lang = StorageService.instance.localeCode;
    if (lang.startsWith('en')) return en;
    if (lang.startsWith('pt')) return pt;
    return es;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(
          _tr('Puesta a Tierra NEC 250', 'Grounding & Bonding NEC 250',
              'Aterramento NEC 250'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.surfaceElevated,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.compliant,
          indicatorWeight: 3,
          labelColor: AppColors.compliant,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.shield_outlined, size: 20),
              text: _tr('EGC (Equipos 250.122)', 'EGC (Equipment 250.122)',
                  'EGC (Equipamentos)'),
            ),
            Tab(
              icon: const Icon(Icons.flash_on_rounded, size: 20),
              text: _tr('GEC (Electrodo 250.66)', 'GEC (Electrode 250.66)',
                  'GEC (Eletrodo)'),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEgcTab(),
          _buildGecTab(),
        ],
      ),
    );
  }

  // ================= EGC TAB (NEC 250.122) =================
  Widget _buildEgcTab() {
    final egcResult = GroundingCalculator.calculateEGC(
      ocpdRating: _selectedOcpd,
      standardPhase: _enableVoltageDropUpsize ? _stdPhaseConductor : null,
      upsizedPhase: _enableVoltageDropUpsize ? _upsizedPhaseConductor : null,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            title: _tr('Protección contra Sobrecorriente (OCPD)',
                'Overcurrent Protective Device (OCPD)', 'Dispositivo de Proteção'),
            icon: Icons.electric_meter_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _selectedOcpd,
                  decoration: InputDecoration(
                    labelText: _tr('Capacidad del Interruptor / Fusible (Amperes)',
                        'Breaker / Fuse Rating (Amperes)', 'Capacidade do Disjuntor (A)'),
                    filled: true,
                    fillColor: AppColors.surfaceCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _standardOcpdRatings.map((rating) {
                    return DropdownMenuItem(
                      value: rating,
                      child: Text(
                        '$rating A',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedOcpd = val);
                  },
                ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.transparent,
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.compliant,
                    title: Text(
                      _tr(
                        '¿Conductores de fase sobredimensionados? (NEC 250.122(B))',
                        'Phase conductors upsized for voltage drop? (NEC 250.122(B))',
                        'Condutores de fase superdimensionados? (NEC 250.122(B))',
                      ),
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _tr(
                        'Si aumentaste el cable por caída de tensión, el EGC debe aumentarse proporcionalmente.',
                        'If phase wire was upsized for voltage drop, EGC must be scaled proportionally in circular mils.',
                        'O condutor de aterramento deve aumentar proporcionalmente.',
                      ),
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    value: _enableVoltageDropUpsize,
                    onChanged: (val) {
                      setState(() => _enableVoltageDropUpsize = val ?? false);
                    },
                  ),
                ),
                if (_enableVoltageDropUpsize) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _stdPhaseConductor,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: _tr('Calibre Estándar', 'Original Gauge', 'Bitola Padrão'),
                            filled: true,
                            fillColor: AppColors.surfaceCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: _commonWireGauges.map((g) {
                            return DropdownMenuItem(
                              value: g,
                              child: Text(g, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _stdPhaseConductor = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _upsizedPhaseConductor,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: _tr('Calibre Aumentado', 'Upsized Gauge', 'Bitola Aumentada'),
                            filled: true,
                            fillColor: AppColors.surfaceCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: _commonWireGauges.map((g) {
                            return DropdownMenuItem(
                              value: g,
                              child: Text(g, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _upsizedPhaseConductor = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildResultBanner(
            title: _tr(
              'CALIBRE MÍNIMO DEL CONDUCTOR DE TIERRA DE EQUIPOS (EGC)',
              'MINIMUM EQUIPMENT GROUNDING CONDUCTOR (EGC)',
              'CONDUTOR DE PROTEÇÃO DE EQUIPAMENTOS (EGC)',
            ),
            color: AppColors.compliant,
            children: [
              _buildResultRow(
                _tr('Conductor de Cobre (Cu):', 'Copper Conductor (Cu):', 'Condutor de Cobre:'),
                egcResult.cuSize,
                isHighlight: true,
              ),
              const Divider(color: Colors.white24, height: 16),
              _buildResultRow(
                _tr('Conductor de Aluminio (Al):', 'Aluminum Conductor (Al):', 'Condutor de Alumínio:'),
                egcResult.alSize,
                isHighlight: false,
              ),
              const Divider(color: Colors.white24, height: 16),
              _buildResultRow(
                _tr('Referencia Normativa:', 'Code Reference:', 'Referência NEC:'),
                egcResult.necReference,
                isHighlight: false,
              ),
            ],
          ),
          if (egcResult.adjustmentNote != null) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.caution.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.caution.withValues(alpha: 0.5)),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.caution, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      egcResult.adjustmentNote!,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildInstructionBox(
            _tr(
              'Regla NEC 250.122:\n'
              '• El conductor de puesta a tierra de equipos (EGC) protege contra fallas a tierra despegando el interruptor.\n'
              '• Si se instalan conductores en paralelo en múltiples canalizaciones (NEC 250.122(F)), cada tubería debe llevar un EGC de tamaño completo según la protección del circuito.',
              'NEC 250.122 Rules:\n'
              '• The equipment grounding conductor (EGC) bonds conductive metal parts back to source to trip breakers upon fault.\n'
              '• For parallel conductor runs in multiple raceways (NEC 250.122(F)), a full-sized EGC based on circuit OCPD must be pulled in each raceway.',
              'Regra NEC 250.122:\nO condutor EGC garante que a corrente de falha atinja o valor suficiente para desarmar a proteção.',
            ),
          ),
        ],
      ),
    );
  }

  // ================= GEC TAB (NEC 250.66) =================
  Widget _buildGecTab() {
    final gecResult = GroundingCalculator.calculateGEC(
      serviceSize: _serviceConductorSize,
      serviceMaterial: _serviceMaterial,
      electrodeType: _selectedElectrode,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            title: _tr('Acometida / Alimentador Principal',
                'Service Entrance / Main Feeder', 'Entrada de Serviço'),
            icon: Icons.power_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        initialValue: _serviceConductorSize,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: _tr('Calibre del Conductor de Fase',
                              'Largest Phase Conductor', 'Bitola do Condutor'),
                          filled: true,
                          fillColor: AppColors.surfaceCard,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: _commonWireGauges.map((g) {
                          return DropdownMenuItem(
                            value: g,
                            child: Text(g, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _serviceConductorSize = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<GroundingConductorMaterial>(
                        initialValue: _serviceMaterial,
                        decoration: InputDecoration(
                          labelText: _tr('Material', 'Material', 'Material'),
                          filled: true,
                          fillColor: AppColors.surfaceCard,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: GroundingConductorMaterial.values.map((m) {
                          return DropdownMenuItem(
                            value: m,
                            child: Text(
                              m == GroundingConductorMaterial.copper ? 'Cu' : 'Al',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _serviceMaterial = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ElectrodeType>(
                  initialValue: _selectedElectrode,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: _tr('Tipo de Electrodo de Puesta a Tierra',
                        'Grounding Electrode Type', 'Tipo de Eletrodo de Aterramento'),
                    filled: true,
                    fillColor: AppColors.surfaceCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: ElectrodeType.values.map((e) {
                    final isEs = StorageService.instance.localeCode.startsWith('es');
                    return DropdownMenuItem(
                      value: e,
                      child: Text(
                        isEs ? e.nameEs : e.nameEn,
                        style: const TextStyle(fontSize: 12.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedElectrode = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildResultBanner(
            title: _tr(
              'CONDUCTOR DEL ELECTRODO DE PUESTA A TIERRA (GEC)',
              'GROUNDING ELECTRODE CONDUCTOR (GEC)',
              'CONDUTOR DO ELETRODO DE ATERRAMENTO (GEC)',
            ),
            color: AppTheme.accent,
            children: [
              _buildResultRow(
                _tr('Conductor de Cobre (Cu):', 'Copper GEC (Cu):', 'Condutor Cobre GEC:'),
                gecResult.cuSize,
                isHighlight: true,
              ),
              const Divider(color: Colors.white24, height: 16),
              _buildResultRow(
                _tr('Conductor de Aluminio (Al):', 'Aluminum GEC (Al):', 'Condutor Alumínio GEC:'),
                gecResult.alSize,
                isHighlight: false,
              ),
              const Divider(color: Colors.white24, height: 16),
              _buildResultRow(
                _tr('Norma y Artículos:', 'Code & Section:', 'Artigo NEC:'),
                gecResult.necReference,
                isHighlight: false,
              ),
            ],
          ),
          if (gecResult.appliedException != null) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppTheme.accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      gecResult.appliedException!,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildInstructionBox(
            _tr(
              'Límites Especiales del NEC 250.66:\n'
              '• 250.66(A): Si se conecta exclusivamente a varilla, tubo o placa, NUNCA se requiere que sea mayor a 6 AWG Cu o 4 AWG Al.\n'
              '• 250.66(B): Si se conecta a un electrodo embebido en concreto (Ufer ground), el GEC no necesita ser mayor a 4 AWG Cu.\n'
              '• 250.66(C): Para anillo de tierra, no necesita ser mayor al calibre del propio anillo (mínimo 2 AWG Cu).',
              'Special NEC 250.66 Maximum Caps:\n'
              '• 250.66(A): When sole connection is to a rod, pipe, or plate, NEVER required to exceed 6 AWG Cu or 4 AWG Al.\n'
              '• 250.66(B): For concrete-encased (Ufer) ground, not required to exceed 4 AWG Cu.\n'
              '• 250.66(C): For ground ring, not required to be larger than ring conductor (min 2 AWG Cu).',
              'Limitações especiais do NEC 250.66 para hastes, sapatas e anéis de terra.',
            ),
          ),
        ],
      ),
    );
  }

  // ================= REUSABLE WIDGETS =================
  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildResultBanner({
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildResultRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isHighlight ? 14 : 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: isHighlight ? 20 : 15,
              fontWeight: FontWeight.w900,
              color: isHighlight ? AppColors.compliant : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionBox(String text) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
