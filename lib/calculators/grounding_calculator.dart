/// NEC Article 250 Grounding and Bonding Calculator
/// Implements NEC Table 250.122 (Equipment Grounding Conductors - EGC)
/// and NEC Table 250.66 (Grounding Electrode Conductors - GEC).
library;

enum GroundingConductorMaterial {
  copper('Cobre (Cu)', 'Copper (Cu)'),
  aluminum('Aluminio (Al)', 'Aluminum (Al)');

  final String nameEs;
  final String nameEn;
  const GroundingConductorMaterial(this.nameEs, this.nameEn);
}

enum ElectrodeType {
  waterPipeOrBuildingSteel(
    'Tubería de agua metálica / Estructura del edificio (NEC 250.52(A)(1)/(2))',
    'Metal Water Pipe / Building Steel (NEC 250.52(A)(1)/(2))',
    null,
  ),
  rodPipePlate(
    'Electrodo de varilla, tubo o placa (NEC 250.52(A)(5))',
    'Rod, Pipe, or Plate Electrode (NEC 250.52(A)(5))',
    '6 AWG Cu / 4 AWG Al (NEC 250.66(A))',
  ),
  concreteEncasedUfer(
    'Electrodo embebido en concreto / Ufer (NEC 250.52(A)(3))',
    'Concrete-Encased Electrode / Ufer (NEC 250.52(A)(3))',
    '4 AWG Cu (NEC 250.66(B))',
  ),
  groundRing(
    'Anillo de tierra perimetral (NEC 250.52(A)(4))',
    'Ground Ring (NEC 250.52(A)(4))',
    '2 AWG Cu (NEC 250.66(C))',
  );

  final String nameEs;
  final String nameEn;
  final String? ruleCap;
  const ElectrodeType(this.nameEs, this.nameEn, this.ruleCap);
}

class EgcResult {
  final int ocpdRating;
  final String cuSize;
  final String alSize;
  final bool isAdjustedForVoltageDrop;
  final String? adjustmentNote;
  final String necReference;

  const EgcResult({
    required this.ocpdRating,
    required this.cuSize,
    required this.alSize,
    this.isAdjustedForVoltageDrop = false,
    this.adjustmentNote,
    this.necReference = 'NEC Table 250.122',
  });
}

class GecResult {
  final String serviceSize;
  final GroundingConductorMaterial serviceMaterial;
  final ElectrodeType electrodeType;
  final String cuSize;
  final String alSize;
  final String? appliedException;
  final String necReference;

  const GecResult({
    required this.serviceSize,
    required this.serviceMaterial,
    required this.electrodeType,
    required this.cuSize,
    required this.alSize,
    this.appliedException,
    this.necReference = 'NEC Table 250.66',
  });
}

class GroundingCalculator {
  // Circular mils table for standard AWG/kcmil conductors
  static const Map<String, int> wireCircularMils = {
    '14 AWG': 4110,
    '12 AWG': 6530,
    '10 AWG': 10380,
    '8 AWG': 16510,
    '6 AWG': 26240,
    '4 AWG': 41740,
    '3 AWG': 52620,
    '2 AWG': 66360,
    '1 AWG': 83690,
    '1/0 AWG': 105600,
    '2/0 AWG': 133100,
    '3/0 AWG': 167800,
    '4/0 AWG': 211600,
    '250 kcmil': 250000,
    '300 kcmil': 300000,
    '350 kcmil': 350000,
    '400 kcmil': 400000,
    '500 kcmil': 500000,
    '600 kcmil': 600000,
    '700 kcmil': 700000,
    '750 kcmil': 750000,
    '800 kcmil': 800000,
    '1000 kcmil': 1000000,
    '1200 kcmil': 1200000,
    '1500 kcmil': 1500000,
    '1750 kcmil': 1750000,
    '2000 kcmil': 2000000,
  };

  /// Table 250.122 Minimum Size Equipment Grounding Conductors for Grounding Raceway and Equipment
  static const List<Map<String, dynamic>> _table250_122 = [
    {'maxOcpd': 15, 'cu': '14 AWG', 'al': '12 AWG'},
    {'maxOcpd': 20, 'cu': '12 AWG', 'al': '10 AWG'},
    {'maxOcpd': 30, 'cu': '10 AWG', 'al': '8 AWG'},
    {'maxOcpd': 40, 'cu': '10 AWG', 'al': '8 AWG'},
    {'maxOcpd': 60, 'cu': '10 AWG', 'al': '8 AWG'},
    {'maxOcpd': 100, 'cu': '8 AWG', 'al': '6 AWG'},
    {'maxOcpd': 200, 'cu': '6 AWG', 'al': '4 AWG'},
    {'maxOcpd': 300, 'cu': '4 AWG', 'al': '2 AWG'},
    {'maxOcpd': 400, 'cu': '3 AWG', 'al': '1 AWG'},
    {'maxOcpd': 500, 'cu': '2 AWG', 'al': '1/0 AWG'},
    {'maxOcpd': 600, 'cu': '1 AWG', 'al': '2/0 AWG'},
    {'maxOcpd': 800, 'cu': '1/0 AWG', 'al': '3/0 AWG'},
    {'maxOcpd': 1000, 'cu': '2/0 AWG', 'al': '4/0 AWG'},
    {'maxOcpd': 1200, 'cu': '3/0 AWG', 'al': '250 kcmil'},
    {'maxOcpd': 1600, 'cu': '4/0 AWG', 'al': '350 kcmil'},
    {'maxOcpd': 2000, 'cu': '250 kcmil', 'al': '400 kcmil'},
    {'maxOcpd': 2500, 'cu': '350 kcmil', 'al': '600 kcmil'},
    {'maxOcpd': 3000, 'cu': '400 kcmil', 'al': '600 kcmil'},
    {'maxOcpd': 4000, 'cu': '500 kcmil', 'al': '750 kcmil'},
    {'maxOcpd': 5000, 'cu': '700 kcmil', 'al': '1200 kcmil'},
    {'maxOcpd': 6000, 'cu': '800 kcmil', 'al': '1200 kcmil'},
  ];

  /// Calculate Equipment Grounding Conductor (EGC) per NEC 250.122
  /// [ocpdRating]: Overcurrent protective device rating in Amps (e.g. 15, 20, 60, 100, 200...)
  /// [upsizedPhase]: Optional upsized phase conductor for voltage drop adjustment (NEC 250.122(B))
  /// [standardPhase]: Standard phase conductor before upsizing
  static EgcResult calculateEGC({
    required int ocpdRating,
    String? standardPhase,
    String? upsizedPhase,
  }) {
    // Find matching row in Table 250.122
    Map<String, dynamic> row = _table250_122.firstWhere(
      (entry) => ocpdRating <= (entry['maxOcpd'] as int),
      orElse: () => _table250_122.last,
    );

    String cu = row['cu'] as String;
    String al = row['al'] as String;

    // Check NEC 250.122(B) proportional increase
    if (standardPhase != null &&
        upsizedPhase != null &&
        standardPhase != upsizedPhase) {
      final stdCm = wireCircularMils[standardPhase];
      final upCm = wireCircularMils[upsizedPhase];

      if (stdCm != null && upCm != null && upCm > stdCm) {
        final ratio = upCm / stdCm;
        final baseCuCm = wireCircularMils[cu] ?? 1;
        final reqCuCm = baseCuCm * ratio;

        final adjustedCu = _findNextWireSize(reqCuCm);
        final baseAlCm = wireCircularMils[al] ?? 1;
        final reqAlCm = baseAlCm * ratio;
        final adjustedAl = _findNextWireSize(reqAlCm);

        return EgcResult(
          ocpdRating: ocpdRating,
          cuSize: adjustedCu,
          alSize: adjustedAl,
          isAdjustedForVoltageDrop: true,
          adjustmentNote:
              'Aumentado proporcionalmente por NEC 250.122(B) (+${((ratio - 1) * 100).toStringAsFixed(0)}% por caída de tensión). Base: $cu Cu / $al Al.',
          necReference: 'NEC Table 250.122 & 250.122(B)',
        );
      }
    }

    return EgcResult(
      ocpdRating: ocpdRating,
      cuSize: cu,
      alSize: al,
      isAdjustedForVoltageDrop: false,
      necReference: 'NEC Table 250.122',
    );
  }

  /// Calculate Grounding Electrode Conductor (GEC) per NEC Table 250.66
  /// [serviceSize]: Largest service-entrance conductor or equivalent parallel sum (e.g. '2/0 AWG', '500 kcmil')
  /// [serviceMaterial]: Copper or Aluminum
  /// [electrodeType]: Type of electrode to apply caps per 250.66(A), (B), or (C)
  static GecResult calculateGEC({
    required String serviceSize,
    required GroundingConductorMaterial serviceMaterial,
    required ElectrodeType electrodeType,
  }) {
    final cm = wireCircularMils[serviceSize] ?? 66360; // Default to 2 AWG if not found

    String cu;
    String al;

    if (serviceMaterial == GroundingConductorMaterial.copper) {
      if (cm <= 66360) {
        // 2 AWG or smaller
        cu = '8 AWG';
        al = '6 AWG';
      } else if (cm <= 105600) {
        // 1 or 1/0 AWG
        cu = '6 AWG';
        al = '4 AWG';
      } else if (cm <= 167800) {
        // 2/0 or 3/0 AWG
        cu = '4 AWG';
        al = '2 AWG';
      } else if (cm <= 350000) {
        // Over 3/0 through 350 kcmil
        cu = '2 AWG';
        al = '1/0 AWG';
      } else if (cm <= 600000) {
        // Over 350 through 600 kcmil
        cu = '1/0 AWG';
        al = '3/0 AWG';
      } else if (cm <= 1100000) {
        // Over 600 through 1100 kcmil
        cu = '2/0 AWG';
        al = '4/0 AWG';
      } else {
        // Over 1100 kcmil
        cu = '3/0 AWG';
        al = '250 kcmil';
      }
    } else {
      // Aluminum service conductor
      if (cm <= 105600) {
        // 1/0 AWG or smaller
        cu = '8 AWG';
        al = '6 AWG';
      } else if (cm <= 167800) {
        // 2/0 or 3/0 AWG
        cu = '6 AWG';
        al = '4 AWG';
      } else if (cm <= 250000) {
        // 4/0 AWG or 250 kcmil
        cu = '4 AWG';
        al = '2 AWG';
      } else if (cm <= 500000) {
        // Over 250 through 500 kcmil
        cu = '2 AWG';
        al = '1/0 AWG';
      } else if (cm <= 900000) {
        // Over 500 through 900 kcmil
        cu = '1/0 AWG';
        al = '3/0 AWG';
      } else if (cm <= 1750000) {
        // Over 900 through 1750 kcmil
        cu = '2/0 AWG';
        al = '4/0 AWG';
      } else {
        // Over 1750 kcmil
        cu = '3/0 AWG';
        al = '250 kcmil';
      }
    }

    String? appliedException;

    // Apply specific electrode rules
    switch (electrodeType) {
      case ElectrodeType.rodPipePlate:
        // NEC 250.66(A): Max 6 AWG Cu or 4 AWG Al required
        if ((wireCircularMils[cu] ?? 0) > (wireCircularMils['6 AWG'] ?? 0)) {
          appliedException =
              'Limitado por NEC 250.66(A): No se requiere mayor a 6 AWG Cu (o 4 AWG Al) para electrodo de varilla/tubo/placa.';
          cu = '6 AWG';
          al = '4 AWG';
        }
        break;
      case ElectrodeType.concreteEncasedUfer:
        // NEC 250.66(B): Max 4 AWG Cu required
        if ((wireCircularMils[cu] ?? 0) > (wireCircularMils['4 AWG'] ?? 0)) {
          appliedException =
              'Limitado por NEC 250.66(B): No se requiere mayor a 4 AWG Cu para electrodo embebido en concreto (Ufer).';
          cu = '4 AWG';
          al = '2 AWG';
        }
        break;
      case ElectrodeType.groundRing:
        // NEC 250.66(C): Not required to be larger than ring conductor (min 2 AWG Cu)
        if ((wireCircularMils[cu] ?? 0) > (wireCircularMils['2 AWG'] ?? 0)) {
          appliedException =
              'Limitado por NEC 250.66(C): No se requiere mayor al conductor del anillo perimetral (mín. 2 AWG Cu).';
          cu = '2 AWG';
          al = '1/0 AWG';
        }
        break;
      case ElectrodeType.waterPipeOrBuildingSteel:
        // Full Table 250.66 applies without cap
        break;
    }

    return GecResult(
      serviceSize: serviceSize,
      serviceMaterial: serviceMaterial,
      electrodeType: electrodeType,
      cuSize: cu,
      alSize: al,
      appliedException: appliedException,
      necReference: electrodeType.ruleCap != null
          ? 'NEC Table 250.66 & ${electrodeType.ruleCap}'
          : 'NEC Table 250.66',
    );
  }

  static String _findNextWireSize(double targetCircularMils) {
    for (final entry in wireCircularMils.entries) {
      if (entry.value >= targetCircularMils) {
        return entry.key;
      }
    }
    return '2000 kcmil';
  }
}
