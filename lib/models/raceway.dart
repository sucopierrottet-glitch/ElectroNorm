enum RacewayType {
  emt,
  pvcSch40,
  pvcSch80,
  imc,
  rmc,
  fmc,
}

extension RacewayTypeExtension on RacewayType {
  String get displayName {
    switch (this) {
      case RacewayType.emt:
        return 'EMT';
      case RacewayType.pvcSch40:
        return 'PVC Sch 40';
      case RacewayType.pvcSch80:
        return 'PVC Sch 80';
      case RacewayType.imc:
        return 'IMC';
      case RacewayType.rmc:
        return 'RMC';
      case RacewayType.fmc:
        return 'FMC';
    }
  }

  String get fullName {
    switch (this) {
      case RacewayType.emt:
        return 'Electrical Metallic Tubing (EMT - Art. 358)';
      case RacewayType.pvcSch40:
        return 'Rigid PVC Schedule 40 (Art. 352)';
      case RacewayType.pvcSch80:
        return 'Rigid PVC Schedule 80 (Art. 352)';
      case RacewayType.imc:
        return 'Intermediate Metal Conduit (IMC - Art. 342)';
      case RacewayType.rmc:
        return 'Rigid Metal Conduit (RMC - Art. 344)';
      case RacewayType.fmc:
        return 'Flexible Metal Conduit (FMC - Art. 348)';
    }
  }

  bool get isMetallic {
    switch (this) {
      case RacewayType.emt:
      case RacewayType.imc:
      case RacewayType.rmc:
      case RacewayType.fmc:
        return true;
      case RacewayType.pvcSch40:
      case RacewayType.pvcSch80:
        return false;
    }
  }
}

class RacewayProfile {
  final RacewayType type;
  final String tradeSize; // e.g. "1/2", "3/4", "1", "1-1/4", "1-1/2", "2", "2-1/2", "3", "3-1/2", "4"
  final String metricDesignator; // e.g. "16", "21", "27", "35", "41", "53", "63", "78", "91", "103"
  final double internalDiameterInches;
  final double internalDiameterMm;
  final double internalAreaSqInches;
  final double internalAreaSqMm;
  final double fill40AreaSqInches;
  final double fill40AreaSqMm;
  final double fill53AreaSqInches;
  final double fill31AreaSqInches;
  final double fill60AreaSqInches;

  const RacewayProfile({
    required this.type,
    required this.tradeSize,
    required this.metricDesignator,
    required this.internalDiameterInches,
    required this.internalDiameterMm,
    required this.internalAreaSqInches,
    required this.internalAreaSqMm,
    required this.fill40AreaSqInches,
    required this.fill40AreaSqMm,
    required this.fill53AreaSqInches,
    required this.fill31AreaSqInches,
    required this.fill60AreaSqInches,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'tradeSize': tradeSize,
        'metricDesignator': metricDesignator,
        'internalDiameterInches': internalDiameterInches,
        'internalDiameterMm': internalDiameterMm,
        'internalAreaSqInches': internalAreaSqInches,
        'internalAreaSqMm': internalAreaSqMm,
        'fill40AreaSqInches': fill40AreaSqInches,
        'fill40AreaSqMm': fill40AreaSqMm,
        'fill53AreaSqInches': fill53AreaSqInches,
        'fill31AreaSqInches': fill31AreaSqInches,
        'fill60AreaSqInches': fill60AreaSqInches,
      };

  factory RacewayProfile.fromJson(Map<String, dynamic> json) {
    return RacewayProfile(
      type: RacewayType.values.firstWhere((e) => e.name == json['type']),
      tradeSize: json['tradeSize'] as String,
      metricDesignator: json['metricDesignator'] as String,
      internalDiameterInches: (json['internalDiameterInches'] as num).toDouble(),
      internalDiameterMm: (json['internalDiameterMm'] as num).toDouble(),
      internalAreaSqInches: (json['internalAreaSqInches'] as num).toDouble(),
      internalAreaSqMm: (json['internalAreaSqMm'] as num).toDouble(),
      fill40AreaSqInches: (json['fill40AreaSqInches'] as num).toDouble(),
      fill40AreaSqMm: (json['fill40AreaSqMm'] as num).toDouble(),
      fill53AreaSqInches: (json['fill53AreaSqInches'] as num).toDouble(),
      fill31AreaSqInches: (json['fill31AreaSqInches'] as num).toDouble(),
      fill60AreaSqInches: (json['fill60AreaSqInches'] as num).toDouble(),
    );
  }

  @override
  String toString() => '${type.displayName} $tradeSize" (DN $metricDesignator)';
}
