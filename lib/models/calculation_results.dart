enum JamRiskLevel {
  safeSingle,
  safeDual,
  safeClearance,
  highJamRisk,
  moderateRisk,
  safeConstrained,
  notApplicable,
}

extension JamRiskLevelExtension on JamRiskLevel {
  String get displayName {
    switch (this) {
      case JamRiskLevel.safeSingle:
        return 'Safe (Single Conductor)';
      case JamRiskLevel.safeDual:
        return 'Safe (Dual Conductors)';
      case JamRiskLevel.safeClearance:
        return 'Safe (Clearance > 3.20)';
      case JamRiskLevel.highJamRisk:
        return 'CRITICAL WARNING: High Jam Risk (2.80 - 3.20)';
      case JamRiskLevel.moderateRisk:
        return 'Moderate Risk (2.50 - 2.80)';
      case JamRiskLevel.safeConstrained:
        return 'Safe (Constrained < 2.50)';
      case JamRiskLevel.notApplicable:
        return 'N/A';
    }
  }

  bool get isHazardous => this == JamRiskLevel.highJamRisk;
}

enum VoltageDropComplianceStatus {
  pass, // <= 3.0%
  caution, // > 3.0% and <= 5.0%
  fail, // > 5.0%
}

extension VoltageDropComplianceStatusExtension on VoltageDropComplianceStatus {
  String get displayName {
    switch (this) {
      case VoltageDropComplianceStatus.pass:
        return 'PASS (<= 3.0%)';
      case VoltageDropComplianceStatus.caution:
        return 'CAUTION (3.0% - 5.0%)';
      case VoltageDropComplianceStatus.fail:
        return 'FAIL (> 5.0%)';
    }
  }
}

class ConduitFillResult {
  final double totalConductorArea;
  final double racewayInternalArea;
  final double fillPercentage;
  final double allowedFillPercentage;
  final double allowedFillArea;
  final bool isCompliant;
  final double? jamRatio;
  final bool hasJamRisk;
  final JamRiskLevel jamRiskLevel;
  final String? recommendedUpsizeTradeSize;
  final int totalConductorCount;
  final bool isNipple;

  const ConduitFillResult({
    required this.totalConductorArea,
    required this.racewayInternalArea,
    required this.fillPercentage,
    required this.allowedFillPercentage,
    required this.allowedFillArea,
    required this.isCompliant,
    this.jamRatio,
    this.hasJamRisk = false,
    this.jamRiskLevel = JamRiskLevel.notApplicable,
    this.recommendedUpsizeTradeSize,
    required this.totalConductorCount,
    this.isNipple = false,
  });

  Map<String, dynamic> toJson() => {
        'totalConductorArea': totalConductorArea,
        'racewayInternalArea': racewayInternalArea,
        'fillPercentage': fillPercentage,
        'allowedFillPercentage': allowedFillPercentage,
        'allowedFillArea': allowedFillArea,
        'isCompliant': isCompliant,
        'jamRatio': jamRatio,
        'hasJamRisk': hasJamRisk,
        'jamRiskLevel': jamRiskLevel.name,
        'recommendedUpsizeTradeSize': recommendedUpsizeTradeSize,
        'totalConductorCount': totalConductorCount,
        'isNipple': isNipple,
      };

  factory ConduitFillResult.fromJson(Map<String, dynamic> json) {
    return ConduitFillResult(
      totalConductorArea: (json['totalConductorArea'] as num).toDouble(),
      racewayInternalArea: (json['racewayInternalArea'] as num).toDouble(),
      fillPercentage: (json['fillPercentage'] as num).toDouble(),
      allowedFillPercentage: (json['allowedFillPercentage'] as num).toDouble(),
      allowedFillArea: (json['allowedFillArea'] as num).toDouble(),
      isCompliant: json['isCompliant'] as bool,
      jamRatio: (json['jamRatio'] as num?)?.toDouble(),
      hasJamRisk: json['hasJamRisk'] as bool? ?? false,
      jamRiskLevel: JamRiskLevel.values.firstWhere(
        (e) => e.name == json['jamRiskLevel'],
        orElse: () => JamRiskLevel.notApplicable,
      ),
      recommendedUpsizeTradeSize: json['recommendedUpsizeTradeSize'] as String?,
      totalConductorCount: json['totalConductorCount'] as int,
      isNipple: json['isNipple'] as bool? ?? false,
    );
  }
}

class VoltageDropResult {
  final double voltageDropVolts;
  final double percentageDrop;
  final double endVoltage;
  final bool isCompliantBranch; // <= 3.0%
  final bool isCompliantTotal; // <= 5.0%
  final double effectiveImpedance;
  final VoltageDropComplianceStatus complianceStatus;

  const VoltageDropResult({
    required this.voltageDropVolts,
    required this.percentageDrop,
    required this.endVoltage,
    required this.isCompliantBranch,
    required this.isCompliantTotal,
    required this.effectiveImpedance,
    required this.complianceStatus,
  });

  Map<String, dynamic> toJson() => {
        'voltageDropVolts': voltageDropVolts,
        'percentageDrop': percentageDrop,
        'endVoltage': endVoltage,
        'isCompliantBranch': isCompliantBranch,
        'isCompliantTotal': isCompliantTotal,
        'effectiveImpedance': effectiveImpedance,
        'complianceStatus': complianceStatus.name,
      };

  factory VoltageDropResult.fromJson(Map<String, dynamic> json) {
    return VoltageDropResult(
      voltageDropVolts: (json['voltageDropVolts'] as num).toDouble(),
      percentageDrop: (json['percentageDrop'] as num).toDouble(),
      endVoltage: (json['endVoltage'] as num).toDouble(),
      isCompliantBranch: json['isCompliantBranch'] as bool,
      isCompliantTotal: json['isCompliantTotal'] as bool,
      effectiveImpedance: (json['effectiveImpedance'] as num).toDouble(),
      complianceStatus: VoltageDropComplianceStatus.values
          .firstWhere((e) => e.name == json['complianceStatus']),
    );
  }
}

class DeratingResult {
  final double baseAmpacity;
  final double temperatureCorrectionFactor;
  final double bundlingAdjustmentFactor;
  final double deratedAmpacity;
  final double terminalRatingLimit;
  final double allowableAmpacity;
  final int? smallWireOcpdLimit;

  const DeratingResult({
    required this.baseAmpacity,
    required this.temperatureCorrectionFactor,
    required this.bundlingAdjustmentFactor,
    required this.deratedAmpacity,
    required this.terminalRatingLimit,
    required this.allowableAmpacity,
    this.smallWireOcpdLimit,
  });

  Map<String, dynamic> toJson() => {
        'baseAmpacity': baseAmpacity,
        'temperatureCorrectionFactor': temperatureCorrectionFactor,
        'bundlingAdjustmentFactor': bundlingAdjustmentFactor,
        'deratedAmpacity': deratedAmpacity,
        'terminalRatingLimit': terminalRatingLimit,
        'allowableAmpacity': allowableAmpacity,
        'smallWireOcpdLimit': smallWireOcpdLimit,
      };

  factory DeratingResult.fromJson(Map<String, dynamic> json) {
    return DeratingResult(
      baseAmpacity: (json['baseAmpacity'] as num).toDouble(),
      temperatureCorrectionFactor:
          (json['temperatureCorrectionFactor'] as num).toDouble(),
      bundlingAdjustmentFactor:
          (json['bundlingAdjustmentFactor'] as num).toDouble(),
      deratedAmpacity: (json['deratedAmpacity'] as num).toDouble(),
      terminalRatingLimit: (json['terminalRatingLimit'] as num).toDouble(),
      allowableAmpacity: (json['allowableAmpacity'] as num).toDouble(),
      smallWireOcpdLimit: json['smallWireOcpdLimit'] as int?,
    );
  }
}
