/// Conduit types for hand bending take-up deductions
enum BendingConduitType {
  emt('EMT (Thinwall)'),
  rigid('RMC / IMC (Rigid)');

  final String displayName;
  const BendingConduitType(this.displayName);
}

/// Standard bend angles for offsets
enum BendAngle {
  deg10(10.0, 6.0, 0.0625, '1/16"'),
  deg22_5(22.5, 2.6, 0.1875, '3/16"'),
  deg30(30.0, 2.0, 0.25, '1/4"'),
  deg45(45.0, 1.414, 0.375, '3/8"'),
  deg60(60.0, 1.2, 0.50, '1/2"');

  final double degrees;
  final double multiplier;
  final double shrinkPerInch;
  final String shrinkFraction;

  const BendAngle(
    this.degrees,
    this.multiplier,
    this.shrinkPerInch,
    this.shrinkFraction,
  );
}

/// Result of an Offset Bend calculation
class OffsetBendResult {
  final double offsetHeight;
  final BendAngle angle;
  final double distanceBetweenMarks;
  final double totalShrink;
  final String distanceFraction;
  final String shrinkFraction;

  const OffsetBendResult({
    required this.offsetHeight,
    required this.angle,
    required this.distanceBetweenMarks,
    required this.totalShrink,
    required this.distanceFraction,
    required this.shrinkFraction,
  });
}

/// Result of a 90° Stub-Up calculation
class Stub90Result {
  final double desiredStubHeight;
  final BendingConduitType conduitType;
  final String tradeSize;
  final double takeUpDeduction;
  final double distanceToArrow;
  final String distanceToArrowFraction;
  final bool isValid;
  final String? warning;

  const Stub90Result({
    required this.desiredStubHeight,
    required this.conduitType,
    required this.tradeSize,
    required this.takeUpDeduction,
    required this.distanceToArrow,
    required this.distanceToArrowFraction,
    required this.isValid,
    this.warning,
  });
}

/// Result of a 3-Bend Saddle calculation
class Saddle3BendResult {
  final double obstructionHeight;
  final double centerAngle;
  final double sideAngle;
  final double distanceCenterToSide;
  final double totalShrink;
  final String distanceFraction;
  final String shrinkFraction;

  const Saddle3BendResult({
    required this.obstructionHeight,
    required this.centerAngle,
    required this.sideAngle,
    required this.distanceCenterToSide,
    required this.totalShrink,
    required this.distanceFraction,
    required this.shrinkFraction,
  });
}

/// Result of a 4-Bend Saddle calculation
class Saddle4BendResult {
  final double obstructionHeight;
  final double obstructionWidth;
  final BendAngle angle;
  final double offsetDistance;
  final double totalShrink;
  final double middleDistance;
  final String offsetDistanceFraction;
  final String middleDistanceFraction;
  final String shrinkFraction;

  double get distanceBetweenOffsetMarks => offsetDistance;
  String get distanceBetweenOffsetMarksFraction => offsetDistanceFraction;
  String get totalShrinkFraction => shrinkFraction;

  const Saddle4BendResult({
    required this.obstructionHeight,
    required this.obstructionWidth,
    required this.angle,
    required this.offsetDistance,
    required this.totalShrink,
    required this.middleDistance,
    required this.offsetDistanceFraction,
    required this.middleDistanceFraction,
    required this.shrinkFraction,
  });
}

/// Core engineering math for electric conduit bending calculations
class ConduitBendingCalculator {
  ConduitBendingCalculator._();

  static const List<String> supportedTradeSizes = ['1/2', '3/4', '1', '1-1/4'];

  /// Converts a decimal inch value to nearest fractional string (1/16" resolution)
  static String formatFraction(double inches) {
    if (inches.isNaN || inches.isInfinite || inches < 0) return '0"';

    final whole = inches.floor();
    final remainder = inches - whole;

    // Convert remainder to 16ths
    final sixteenths = (remainder * 16).round();

    if (sixteenths == 0) {
      return '$whole"';
    }
    if (sixteenths == 16) {
      return '${whole + 1}"';
    }

    // Simplify fraction
    int num = sixteenths;
    int den = 16;
    while (num % 2 == 0 && den % 2 == 0) {
      num ~/= 2;
      den ~/= 2;
    }

    if (whole == 0) {
      return '$num/$den"';
    }
    return '$whole $num/$den"';
  }

  /// Calculates an offset bend: distance between marks and total conduit shrink
  static OffsetBendResult calculateOffset({
    required double offsetHeight,
    required BendAngle angle,
  }) {
    final distance = offsetHeight * angle.multiplier;
    final shrink = offsetHeight * angle.shrinkPerInch;

    return OffsetBendResult(
      offsetHeight: offsetHeight,
      angle: angle,
      distanceBetweenMarks: distance,
      totalShrink: shrink,
      distanceFraction: formatFraction(distance),
      shrinkFraction: formatFraction(shrink),
    );
  }

  /// Take-up deduction table for hand benders (in inches)
  static const Map<BendingConduitType, Map<String, double>> takeUpTable = {
    BendingConduitType.emt: {
      '1/2"': 5.0,
      '1/2': 5.0,
      '3/4"': 6.0,
      '3/4': 6.0,
      '1"': 8.0,
      '1': 8.0,
      '1-1/4"': 11.0,
      '1-1/4': 11.0,
    },
    BendingConduitType.rigid: {
      '1/2"': 6.0,
      '1/2': 6.0,
      '3/4"': 8.0,
      '3/4': 8.0,
      '1"': 10.0,
      '1': 10.0,
      '1-1/4"': 12.0,
      '1-1/4': 12.0,
    },
  };

  /// Calculates a 90-degree stub-up bend distance to bender arrow
  static Stub90Result calculateStub90({
    required double desiredStubHeight,
    required BendingConduitType conduitType,
    required String tradeSize,
  }) {
    final deduction = takeUpTable[conduitType]?[tradeSize] ?? 5.0;
    final distance = desiredStubHeight - deduction;
    final isValid = distance >= 0;

    return Stub90Result(
      desiredStubHeight: desiredStubHeight,
      conduitType: conduitType,
      tradeSize: tradeSize,
      takeUpDeduction: deduction,
      distanceToArrow: isValid ? distance : 0.0,
      distanceToArrowFraction: isValid ? formatFraction(distance) : '0"',
      isValid: isValid,
      warning: isValid
          ? null
          : 'Stub height must be at least $deduction" for $tradeSize ${conduitType.displayName}.',
    );
  }

  /// Calculates a 3-bend saddle (standard 45° center with 22.5° side bends)
  static Saddle3BendResult calculate3BendSaddle({
    required double obstructionHeight,
    double centerAngle = 45.0,
  }) {
    double mult;
    double shrinkFactor;
    double sideAngle;

    if (centerAngle == 30.0) {
      sideAngle = 15.0;
      mult = 3.0;
      shrinkFactor = 0.125; // 1/8" per inch
    } else if (centerAngle == 60.0) {
      sideAngle = 30.0;
      mult = 2.0;
      shrinkFactor = 0.50; // 1/2" per inch
    } else {
      // Default standard 45°
      centerAngle = 45.0;
      sideAngle = 22.5;
      mult = 2.5;
      shrinkFactor = 0.1875; // 3/16" per inch
    }

    final distance = obstructionHeight * mult;
    final shrink = obstructionHeight * shrinkFactor;

    return Saddle3BendResult(
      obstructionHeight: obstructionHeight,
      centerAngle: centerAngle,
      sideAngle: sideAngle,
      distanceCenterToSide: distance,
      totalShrink: shrink,
      distanceFraction: formatFraction(distance),
      shrinkFraction: formatFraction(shrink),
    );
  }

  /// Calculates a 4-bend saddle around a rectangular obstacle
  static Saddle4BendResult calculate4BendSaddle({
    required double obstructionHeight,
    required double obstructionWidth,
    required BendAngle angle,
  }) {
    final offsetDist = obstructionHeight * angle.multiplier;
    final shrink = obstructionHeight * angle.shrinkPerInch * 2.0; // Two offsets
    final middleDist = obstructionWidth + shrink;

    return Saddle4BendResult(
      obstructionHeight: obstructionHeight,
      obstructionWidth: obstructionWidth,
      angle: angle,
      offsetDistance: offsetDist,
      totalShrink: shrink,
      middleDistance: middleDist,
      offsetDistanceFraction: formatFraction(offsetDist),
      middleDistanceFraction: formatFraction(middleDist),
      shrinkFraction: formatFraction(shrink),
    );
  }
}
