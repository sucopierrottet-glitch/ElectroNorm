enum ConductorInsulation {
  thhn,
  thwn,
  xhhw,
  use2,
}

extension ConductorInsulationExtension on ConductorInsulation {
  String get displayName {
    switch (this) {
      case ConductorInsulation.thhn:
        return 'THHN / THWN-2';
      case ConductorInsulation.thwn:
        return 'THWN';
      case ConductorInsulation.xhhw:
        return 'XHHW / XHHW-2';
      case ConductorInsulation.use2:
        return 'USE-2';
    }
  }

  double get maxOperatingTemperatureC {
    switch (this) {
      case ConductorInsulation.thhn:
        return 90.0;
      case ConductorInsulation.thwn:
        return 75.0;
      case ConductorInsulation.xhhw:
        return 90.0;
      case ConductorInsulation.use2:
        return 90.0;
    }
  }
}

enum ConductorMaterial {
  copper,
  aluminum,
}

extension ConductorMaterialExtension on ConductorMaterial {
  String get displayName {
    switch (this) {
      case ConductorMaterial.copper:
        return 'Copper (Cu)';
      case ConductorMaterial.aluminum:
        return 'Aluminum (Al)';
    }
  }

  bool get isCopper => this == ConductorMaterial.copper;
}

enum CircuitPhase {
  singlePhase,
  threePhase,
}

class ConductorSpec {
  final String gauge; // e.g. "14 AWG", "500 kcmil", "2.5 mm²"
  final ConductorInsulation insulation;
  final ConductorMaterial material;
  final double outerDiameterInches;
  final double outerDiameterMm;
  final double areaSqInches;
  final double areaSqMm;
  final double ampacity60C;
  final double ampacity75C;
  final double ampacity90C;
  final int? maxOcpdAmps;
  final double circularMils;
  final double dcResistanceCu75C; // ohm/kft
  final double dcResistanceAl75C; // ohm/kft
  final double acResistanceSteel; // ohm/kft
  final double acResistancePvc; // ohm/kft
  final double reactanceXl; // ohm/kft

  const ConductorSpec({
    required this.gauge,
    required this.insulation,
    required this.material,
    required this.outerDiameterInches,
    required this.outerDiameterMm,
    required this.areaSqInches,
    required this.areaSqMm,
    required this.ampacity60C,
    required this.ampacity75C,
    required this.ampacity90C,
    this.maxOcpdAmps,
    this.circularMils = 0.0,
    this.dcResistanceCu75C = 0.0,
    this.dcResistanceAl75C = 0.0,
    this.acResistanceSteel = 0.0,
    this.acResistancePvc = 0.0,
    this.reactanceXl = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'gauge': gauge,
        'insulation': insulation.name,
        'material': material.name,
        'outerDiameterInches': outerDiameterInches,
        'outerDiameterMm': outerDiameterMm,
        'areaSqInches': areaSqInches,
        'areaSqMm': areaSqMm,
        'ampacity60C': ampacity60C,
        'ampacity75C': ampacity75C,
        'ampacity90C': ampacity90C,
        'maxOcpdAmps': maxOcpdAmps,
        'circularMils': circularMils,
        'dcResistanceCu75C': dcResistanceCu75C,
        'dcResistanceAl75C': dcResistanceAl75C,
        'acResistanceSteel': acResistanceSteel,
        'acResistancePvc': acResistancePvc,
        'reactanceXl': reactanceXl,
      };

  factory ConductorSpec.fromJson(Map<String, dynamic> json) {
    return ConductorSpec(
      gauge: json['gauge'] as String,
      insulation: ConductorInsulation.values
          .firstWhere((e) => e.name == json['insulation']),
      material: ConductorMaterial.values
          .firstWhere((e) => e.name == json['material']),
      outerDiameterInches: (json['outerDiameterInches'] as num).toDouble(),
      outerDiameterMm: (json['outerDiameterMm'] as num).toDouble(),
      areaSqInches: (json['areaSqInches'] as num).toDouble(),
      areaSqMm: (json['areaSqMm'] as num).toDouble(),
      ampacity60C: (json['ampacity60C'] as num).toDouble(),
      ampacity75C: (json['ampacity75C'] as num).toDouble(),
      ampacity90C: (json['ampacity90C'] as num).toDouble(),
      maxOcpdAmps: json['maxOcpdAmps'] as int?,
      circularMils: (json['circularMils'] as num?)?.toDouble() ?? 0.0,
      dcResistanceCu75C:
          (json['dcResistanceCu75C'] as num?)?.toDouble() ?? 0.0,
      dcResistanceAl75C:
          (json['dcResistanceAl75C'] as num?)?.toDouble() ?? 0.0,
      acResistanceSteel:
          (json['acResistanceSteel'] as num?)?.toDouble() ?? 0.0,
      acResistancePvc: (json['acResistancePvc'] as num?)?.toDouble() ?? 0.0,
      reactanceXl: (json['reactanceXl'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() => '$gauge ${insulation.name.toUpperCase()} (${material.name})';
}

class ConductorGroup {
  final String id;
  final ConductorSpec spec;
  final int count;
  final String role; // "phaseA", "phaseB", "phaseC", "neutral", "ground"
  final int? colorHex;

  const ConductorGroup({
    required this.id,
    required this.spec,
    required this.count,
    required this.role,
    this.colorHex,
  });

  double get totalAreaSqInches => spec.areaSqInches * count;
  double get totalAreaSqMm => spec.areaSqMm * count;

  bool get isGround => role.toLowerCase() == 'ground';

  ConductorGroup copyWith({
    String? id,
    ConductorSpec? spec,
    int? count,
    String? role,
    int? colorHex,
  }) {
    return ConductorGroup(
      id: id ?? this.id,
      spec: spec ?? this.spec,
      count: count ?? this.count,
      role: role ?? this.role,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'spec': spec.toJson(),
        'count': count,
        'role': role,
        'colorHex': colorHex,
      };

  factory ConductorGroup.fromJson(Map<String, dynamic> json) {
    return ConductorGroup(
      id: json['id'] as String,
      spec: ConductorSpec.fromJson(json['spec'] as Map<String, dynamic>),
      count: json['count'] as int,
      role: json['role'] as String,
      colorHex: json['colorHex'] as int?,
    );
  }
}
