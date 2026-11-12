import 'package:flutter/material.dart';
import '../calculators/conduit_bending_calculator.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class ConduitBendingScreen extends StatefulWidget {
  const ConduitBendingScreen({super.key});

  @override
  State<ConduitBendingScreen> createState() => _ConduitBendingScreenState();
}

class _ConduitBendingScreenState extends State<ConduitBendingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 1. Offsets
  double _offsetHeight = 4.0;
  BendAngle _offsetAngle = BendAngle.deg30;
  final TextEditingController _offsetHeightCtrl =
      TextEditingController(text: '4.0');

  // 2. 90° Stub
  double _stubHeight = 12.0;
  BendingConduitType _stubConduitType = BendingConduitType.emt;
  String _stubTradeSize = '3/4';
  final TextEditingController _stubHeightCtrl =
      TextEditingController(text: '12.0');

  // 3. 3-Bend Saddle
  double _saddle3Height = 2.0;
  double _saddle3CenterAngle = 45.0;
  final TextEditingController _saddle3HeightCtrl =
      TextEditingController(text: '2.0');

  // 4. 4-Bend Saddle
  double _saddle4Height = 3.0;
  double _saddle4Width = 6.0;
  BendAngle _saddle4Angle = BendAngle.deg30;
  final TextEditingController _saddle4HeightCtrl =
      TextEditingController(text: '3.0');
  final TextEditingController _saddle4WidthCtrl =
      TextEditingController(text: '6.0');

  String _tr(String es, String en, String pt) {
    final lang = StorageService.instance.localeCode;
    if (lang.startsWith('en')) return en;
    if (lang.startsWith('pt')) return pt;
    return es;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _offsetHeightCtrl.dispose();
    _stubHeightCtrl.dispose();
    _saddle3HeightCtrl.dispose();
    _saddle4HeightCtrl.dispose();
    _saddle4WidthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(
          _tr('Doblado de Tubería', 'Conduit Bending', 'Dobragem de Tubos'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.surfaceElevated,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.accent,
          indicatorWeight: 3,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.linear_scale_rounded, size: 20),
              text: _tr('Offset (Salto)', 'Offset Bend', 'Desvio'),
            ),
            Tab(
              icon: const Icon(Icons.turn_right_rounded, size: 20),
              text: _tr('90° Stub-Up', '90° Stub-Up', 'Curva 90°'),
            ),
            Tab(
              icon: const Icon(Icons.rounded_corner_rounded, size: 20),
              text: _tr('Montura 3 Curvas', '3-Bend Saddle', 'Sela 3 Curvas'),
            ),
            Tab(
              icon: const Icon(Icons.filter_hdr_rounded, size: 20),
              text: _tr('Montura 4 Curvas', '4-Bend Saddle', 'Sela 4 Curvas'),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOffsetTab(),
          _buildStub90Tab(),
          _buildSaddle3Tab(),
          _buildSaddle4Tab(),
        ],
      ),
    );
  }

  // ================= OFFSET TAB =================
  Widget _buildOffsetTab() {
    final result = ConduitBendingCalculator.calculateOffset(
      offsetHeight: _offsetHeight,
      angle: _offsetAngle,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            title: _tr('Parámetros del Salto', 'Offset Parameters', 'Parâmetros do Desvio'),
            icon: Icons.tune_rounded,
            child: Column(
              children: [
                TextField(
                  controller: _offsetHeightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _tr('Altura del obstáculo / Salto (pulgadas)',
                        'Obstacle / Offset Height (inches)', 'Altura do obstáculo (polegadas)'),
                    suffixText: 'in (")',
                    filled: true,
                    fillColor: AppColors.surfaceCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) {
                    final d = double.tryParse(val.replaceAll(',', '.'));
                    if (d != null && d > 0) {
                      setState(() => _offsetHeight = d);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BendAngle>(
                  initialValue: _offsetAngle,
                  decoration: InputDecoration(
                    labelText: _tr('Ángulo de Doblado', 'Bend Angle', 'Ângulo de Dobra'),
                    filled: true,
                    fillColor: AppColors.surfaceCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: BendAngle.values.map((angle) {
                    return DropdownMenuItem(
                      value: angle,
                      child: Text(
                        '${angle.degrees.toStringAsFixed(angle.degrees % 1 == 0 ? 0 : 1)}° (Multiplicador: ${angle.multiplier}x)',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _offsetAngle = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildResultBanner(
            title: _tr('MEDICIONES PARA TUBO EMT / RIGID', 'EMT / RIGID TAPE MEASURE MARKS',
                'MEDIDAS PARA O TUBO'),
            color: AppTheme.accent,
            children: [
              _buildResultRow(
                _tr('Distancia entre marcas:', 'Distance between marks:', 'Distância entre marcas:'),
                result.distanceFraction,
                '(${result.distanceBetweenMarks.toStringAsFixed(2)}")',
                isHighlight: true,
              ),
              const Divider(color: Colors.white24, height: 16),
              _buildResultRow(
                _tr('Acortamiento total (Shrink):', 'Total conduit shrink:', 'Encurtamento total:'),
                result.shrinkFraction,
                '(${result.totalShrink.toStringAsFixed(2)}")',
              ),
              const Divider(color: Colors.white24, height: 16),
              _buildResultRow(
                _tr('Multiplicador aplicado:', 'Applied multiplier:', 'Multiplicador aplicado:'),
                '${result.angle.multiplier}x',
                _tr('${result.angle.shrinkFraction} por cada pulgada de salto',
                    '${result.angle.shrinkFraction} per inch of offset', ''),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionBox(
            _tr(
              'Instrucciones de Marcado:\n'
              '1. Haz la Marca 1 en el punto donde debe iniciar el desvío.\n'
              '2. Mide exactamente ${result.distanceFraction} y haz la Marca 2.\n'
              '3. Alinea la flecha de la dobladora con la Marca 1 y dobla a ${_offsetAngle.degrees.toStringAsFixed(0)}°.\n'
              '4. Gira el tubo 180°, alinea con la Marca 2 y realiza la segunda curva a ${_offsetAngle.degrees.toStringAsFixed(0)}°.\n'
              '5. Agrega ${result.shrinkFraction} a tu longitud total de tubo para compensar el acortamiento.',
              'Marking Instructions:\n'
              '1. Place Mark 1 at the point where the bend should start.\n'
              '2. Measure exactly ${result.distanceFraction} and place Mark 2.\n'
              '3. Align the bender arrow with Mark 1 and bend to ${_offsetAngle.degrees.toStringAsFixed(0)}°.\n'
              '4. Rotate the conduit 180°, align with Mark 2, and bend to ${_offsetAngle.degrees.toStringAsFixed(0)}°.\n'
              '5. Add ${result.shrinkFraction} to your overall conduit cut length to compensate for shrink.',
              'Instruções de Marcação:\n1. Faça a Marca 1 onde o desvio deve começar.\n2. Meça ${result.distanceFraction} e faça a Marca 2.\n3. Dobre cada uma a ${_offsetAngle.degrees.toStringAsFixed(0)}° girando 180° entre curvas.',
            ),
          ),
        ],
      ),
    );
  }

  // ================= 90° STUB TAB =================
  Widget _buildStub90Tab() {
    final result = ConduitBendingCalculator.calculateStub90(
      desiredStubHeight: _stubHeight,
      conduitType: _stubConduitType,
      tradeSize: _stubTradeSize,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            title: _tr('Parámetros de la Curva a 90°', '90° Stub Parameters',
                'Parâmetros da Curva a 90°'),
            icon: Icons.architecture_rounded,
            child: Column(
              children: [
                TextField(
                  controller: _stubHeightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _tr('Altura deseada del Stub (pulgadas)',
                        'Desired Stub Height (inches)', 'Altura desejada do Stub (polegadas)'),
                    suffixText: 'in (")',
                    filled: true,
                    fillColor: AppColors.surfaceCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) {
                    final d = double.tryParse(val.replaceAll(',', '.'));
                    if (d != null && d > 0) {
                      setState(() => _stubHeight = d);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<BendingConduitType>(
                        initialValue: _stubConduitType,
                        decoration: InputDecoration(
                          labelText: _tr('Tipo de Tubo', 'Conduit Type', 'Tipo de Tubo'),
                          filled: true,
                          fillColor: AppColors.surfaceCard,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: BendingConduitType.values.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t.displayName, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _stubConduitType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _stubTradeSize,
                        decoration: InputDecoration(
                          labelText: _tr('Calibre / Tamaño', 'Trade Size', 'Bitola'),
                          filled: true,
                          fillColor: AppColors.surfaceCard,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: ConduitBendingCalculator.supportedTradeSizes.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text('$s"', style: const TextStyle(fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _stubTradeSize = val);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildResultBanner(
            title: _tr('MEDICIÓN PARA LA FLECHA DE LA DOBLADORA', 'BENDER ARROW MARK DISTANCE',
                'MEDIDA PARA A FLECHA DO DOBRADOR'),
            color: AppColors.caution,
            children: [
              _buildResultRow(
                _tr('Medir desde el extremo hasta la Flecha:',
                    'Measure from end to Arrow Mark:', 'Medir da extremidade até a flecha:'),
                result.distanceToArrowFraction,
                '(${result.distanceToArrow.toStringAsFixed(2)}")',
                isHighlight: true,
              ),
              const Divider(color: Colors.white24, height: 16),
              _buildResultRow(
                _tr('Deducción del bender (Take-Up):', 'Bender Take-up deduction:',
                    'Dedução da dobradora (Take-Up):'),
                '${result.takeUpDeduction.toStringAsFixed(1)}"',
                _tr('Deducción estándar para $_stubTradeSize" ${_stubConduitType.displayName}',
                    'Standard deduction for $_stubTradeSize" ${_stubConduitType.displayName}', ''),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionBox(
            _tr(
              'Fórmula Aplicada:\n'
              'Distancia a la Flecha = Altura Deseada (${result.desiredStubHeight}") - Deducción (${result.takeUpDeduction}") = ${result.distanceToArrowFraction}.\n\n'
              'Instrucciones de Doblado:\n'
              '1. Mide ${result.distanceToArrowFraction} desde la punta del tubo hacia adentro y haz una marca.\n'
              '2. Inserta el tubo en la dobladora alineando la FLECHA (Arrow symbol) exactamente con la marca.\n'
              '3. Apoya el pie firmemente sobre el pedal y dobla con presión uniforme hasta que el nivel marque 90° exactos.',
              'Formula:\n'
              'Distance to Arrow = Desired Height (${result.desiredStubHeight}") - Take-up (${result.takeUpDeduction}") = ${result.distanceToArrowFraction}.\n\n'
              'Bending Steps:\n'
              '1. Measure ${result.distanceToArrowFraction} from the end of the conduit and mark.\n'
              '2. Insert the conduit into the bender, aligning the ARROW exactly with your mark.\n'
              '3. Keep firm foot pressure on the pedal and pull smoothly until the bubble level reads 90°.',
              'Instruções:\nMeça ${result.distanceToArrowFraction} da ponta do tubo até a marca da flecha do dobrador e faça a curva até 90° exatos.',
            ),
          ),
        ],
      ),
    );
  }

  // ================= 3-BEND SADDLE TAB =================
  Widget _buildSaddle3Tab() {
    final result = ConduitBendingCalculator.calculate3BendSaddle(
      obstructionHeight: _saddle3Height,
      centerAngle: _saddle3CenterAngle,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            title: _tr('Montura de 3 Curvas (Saddle)', '3-Bend Saddle Parameters',
                'Parâmetros da Sela 3 Curvas'),
            icon: Icons.rounded_corner_rounded,
            child: Column(
              children: [
                TextField(
                  controller: _saddle3HeightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _tr('Altura del obstáculo a sobrepasar',
                        'Obstacle Height to clear', 'Altura do obstáculo'),
                    suffixText: 'in (")',
                    filled: true,
                    fillColor: AppColors.surfaceCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) {
                    final d = double.tryParse(val.replaceAll(',', '.'));
                    if (d != null && d > 0) {
                      setState(() => _saddle3Height = d);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<double>(
                  initialValue: _saddle3CenterAngle,
                  decoration: InputDecoration(
                    labelText: _tr('Ángulo de la Curva Central', 'Center Bend Angle',
                        'Ângulo da Curva Central'),
                    filled: true,
                    fillColor: AppColors.surfaceCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 45.0,
                      child: Text('45° Centro (22.5° laterales) — Estándar Industrial'),
                    ),
                    DropdownMenuItem(
                      value: 30.0,
                      child: Text('30° Centro (15° laterales) — Perfil bajo'),
                    ),
                    DropdownMenuItem(
                      value: 60.0,
                      child: Text('60° Centro (30° laterales) — Obstáculos altos'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _saddle3CenterAngle = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildResultBanner(
            title: _tr('MEDICIONES PARA MARCAR EL TUBO', 'TAPE MEASURE LAYOUT',
                'MEDIDAS DE TRAÇADO DO TUBO'),
            color: AppTheme.accent,
            children: [
              _buildResultRow(
                _tr('Distancia del Centro a cada lado:', 'Distance from Center to each side bend:',
                    'Distância do Centro a cada lado:'),
                result.distanceFraction,
                '(${result.distanceCenterToSide.toStringAsFixed(2)}")',
                isHighlight: true,
              ),
              const Divider(color: Colors.white24, height: 16),
              _buildResultRow(
                _tr('Acortamiento total (Shrink):', 'Total conduit shrink:', 'Encurtamento total:'),
                result.shrinkFraction,
                '(${result.totalShrink.toStringAsFixed(2)}")',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionBox(
            _tr(
              'Instrucciones de Doblado 3-Bend Saddle:\n'
              '1. Marca el centro exacto del obstáculo en el tubo. Desplaza la marca ${result.shrinkFraction} hacia adelante para compensar el shrink.\n'
              '2. Desde esta nueva marca central, mide ${result.distanceFraction} hacia la izquierda y ${result.distanceFraction} hacia la derecha.\n'
              '3. Coloca la muesca de la dobladora (Notch) en la marca central y dobla a ${_saddle3CenterAngle.toStringAsFixed(0)}°.\n'
              '4. Gira el tubo 180°, alinea la flecha (Arrow) con las dos marcas exteriores y dobla cada una a ${result.sideAngle.toStringAsFixed(1)}°.',
              '3-Bend Saddle Steps:\n'
              '1. Find the center of the obstruction and mark it on the conduit. Shift this mark forward by ${result.shrinkFraction} to compensate for shrink.\n'
              '2. From the shifted center mark, measure ${result.distanceFraction} each way and make two outer marks.\n'
              '3. Place the bender RIM NOTCH on the center mark and bend to ${_saddle3CenterAngle.toStringAsFixed(0)}°.\n'
              '4. Reverse the bender, align the ARROW mark on each outer mark, and bend both to ${result.sideAngle.toStringAsFixed(1)}°.',
              'Passos:\n1. Marque o centro e desloque ${result.shrinkFraction}.\n2. Marque ${result.distanceFraction} para cada lado.\n3. Dobre o centro a ${_saddle3CenterAngle.toStringAsFixed(0)}° e as laterais a ${result.sideAngle.toStringAsFixed(1)}° girando 180°.',
            ),
          ),
        ],
      ),
    );
  }

  // ================= 4-BEND SADDLE TAB =================
  Widget _buildSaddle4Tab() {
    final result = ConduitBendingCalculator.calculate4BendSaddle(
      obstructionHeight: _saddle4Height,
      obstructionWidth: _saddle4Width,
      angle: _saddle4Angle,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            title: _tr('Montura de 4 Curvas (Obstáculo Ancho)', '4-Bend Saddle Parameters',
                'Parâmetros da Sela 4 Curvas'),
            icon: Icons.filter_hdr_rounded,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _saddle4HeightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: _tr('Altura obstáculo', 'Obstacle Height', 'Altura'),
                          suffixText: 'in (")',
                          filled: true,
                          fillColor: AppColors.surfaceCard,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          final d = double.tryParse(val.replaceAll(',', '.'));
                          if (d != null && d > 0) {
                            setState(() => _saddle4Height = d);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _saddle4WidthCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: _tr('Ancho obstáculo', 'Obstacle Width', 'Largura'),
                          suffixText: 'in (")',
                          filled: true,
                          fillColor: AppColors.surfaceCard,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          final d = double.tryParse(val.replaceAll(',', '.'));
                          if (d != null && d > 0) {
                            setState(() => _saddle4Width = d);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BendAngle>(
                  initialValue: _saddle4Angle,
                  decoration: InputDecoration(
                    labelText: _tr('Ángulo de las 4 Curvas', 'Angle for all 4 bends',
                        'Ângulo das 4 curvas'),
                    filled: true,
                    fillColor: AppColors.surfaceCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: BendAngle.values.map((angle) {
                    return DropdownMenuItem(
                      value: angle,
                      child: Text(
                        '${angle.degrees.toStringAsFixed(angle.degrees % 1 == 0 ? 0 : 1)}° (Multiplicador: ${angle.multiplier}x)',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _saddle4Angle = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildResultBanner(
            title: _tr('MEDICIÓN DE MARCAS PARA 4-BEND SADDLE', '4-BEND SADDLE MEASUREMENTS',
                'MEDIDAS DE TRAÇADO PARA 4 CURVAS'),
            color: AppColors.compliant,
            children: [
              _buildResultRow(
                _tr('Distancia entre cada par de marcas:', 'Distance between each offset pair:',
                    'Distância entre cada par:'),
                result.distanceBetweenOffsetMarksFraction,
                '(${result.distanceBetweenOffsetMarks.toStringAsFixed(2)}")',
                isHighlight: true,
              ),
              const Divider(color: Colors.white24, height: 16),
              _buildResultRow(
                _tr('Largo del puente horizontal:', 'Bridge / Top span length:',
                    'Comprimento do topo:'),
                '${result.obstructionWidth.toStringAsFixed(1)}"',
                _tr('Ancho exacto del obstáculo', 'Exact obstruction width', ''),
              ),
              const Divider(color: Colors.white24, height: 16),
              _buildResultRow(
                _tr('Acortamiento total acumulado:', 'Total conduit shrink:',
                    'Encurtamento total acumulado:'),
                result.totalShrinkFraction,
                '(${result.totalShrink.toStringAsFixed(2)}")',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionBox(
            _tr(
              'Instrucciones de Marcado 4 Curvas:\n'
              'Una montura de 4 curvas consiste en dos offsets tradicionales enfrentados:\n'
              '1. Marca 1: inicio del primer offset.\n'
              '2. Marca 2: a ${result.distanceBetweenOffsetMarksFraction} de Marca 1.\n'
              '3. Marca 3: a ${result.obstructionWidth.toStringAsFixed(1)}" de Marca 2 (cruza el obstáculo).\n'
              '4. Marca 4: a ${result.distanceBetweenOffsetMarksFraction} de Marca 3 (segundo offset hacia abajo).\n'
              '5. Dobla todas las 4 curvas a ${_saddle4Angle.degrees.toStringAsFixed(0)}° cuidando el sentido del giro para no revirar el tubo.',
              '4-Bend Saddle Instructions:\n'
              'Consists of two opposing offset bends facing each other:\n'
              '1. Mark 1: Start of first offset.\n'
              '2. Mark 2: At ${result.distanceBetweenOffsetMarksFraction} from Mark 1.\n'
              '3. Mark 3: At ${result.obstructionWidth.toStringAsFixed(1)}" from Mark 2 across obstruction.\n'
              '4. Mark 4: At ${result.distanceBetweenOffsetMarksFraction} from Mark 3 for return bend.\n'
              '5. Bend all 4 bends at ${_saddle4Angle.degrees.toStringAsFixed(0)}° maintaining flat plane.',
              'Instruções:\nMarque os dois offsets de cada lado do obstáculo a ${_saddle4Angle.degrees.toStringAsFixed(0)}°.',
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
              fontSize: 12,
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
    String primaryValue,
    String secondaryValue, {
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              primaryValue,
              style: TextStyle(
                fontSize: isHighlight ? 20 : 15,
                fontWeight: FontWeight.w900,
                color: isHighlight ? AppTheme.accent : Colors.white,
              ),
            ),
            if (secondaryValue.isNotEmpty)
              Text(
                secondaryValue,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
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
