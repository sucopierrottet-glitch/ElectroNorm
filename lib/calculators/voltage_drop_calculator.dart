import 'dart:math' as math;
import '../models/calculation_results.dart';
import '../models/conductor.dart';

class VoltageDropCalculator {
  VoltageDropCalculator._();

  static const double sqrt3 = 1.7320508075688772;

  // Resistivity at 75°C (ohm * mm² / m)
  static const double rhoCu75 = 0.0225;
  static const double rhoAl75 = 0.0360;

  // K-factors at 75°C (ohm * cmil / ft)
  static const double kCopper = 12.9;
  static const double kAluminum = 21.2;

  /// Calculate voltage drop using the AC Effective Impedance (Z_eff) method
  /// per NEC Chapter 9 Table 9 and IEEE Std 141.
  static VoltageDropResult calculateEffectiveImpedance({
    required double nominalVoltage,
    required CircuitPhase phase,
    required double currentAmps,
    required double lengthFeet,
    required ConductorSpec conductorSpec,
    required bool isSteelConduit,
    double powerFactor = 0.90,
  }) {
    if (nominalVoltage <= 0) {
      throw ArgumentError('Nominal voltage must be positive');
    }
    if (currentAmps < 0) {
      throw ArgumentError('Current cannot be negative');
    }
    if (lengthFeet <= 0) {
      throw ArgumentError('Length must be positive');
    }

    final pfClamped = powerFactor.clamp(0.0, 1.0);
    final sinTheta = math.sqrt(math.max(0.0, 1.0 - pfClamped * pfClamped));

    final r = isSteelConduit
        ? conductorSpec.acResistanceSteel
        : conductorSpec.acResistancePvc;
    final xl = conductorSpec.reactanceXl;

    final zEff = (r * pfClamped) + (xl * sinTheta);
    final lengthKft = lengthFeet / 1000.0;

    final phaseMultiplier = (phase == CircuitPhase.threePhase) ? sqrt3 : 2.0;
    final vDrop = phaseMultiplier * currentAmps * lengthKft * zEff;

    final percentageDrop = (vDrop / nominalVoltage) * 100.0;
    final endVoltage = nominalVoltage - vDrop;

    final isCompliantBranch = percentageDrop <= 3.00 + 0.0001;
    final isCompliantTotal = percentageDrop <= 5.00 + 0.0001;

    VoltageDropComplianceStatus status;
    if (percentageDrop <= 3.00 + 0.0001) {
      status = VoltageDropComplianceStatus.pass;
    } else if (percentageDrop <= 5.00 + 0.0001) {
      status = VoltageDropComplianceStatus.caution;
    } else {
      status = VoltageDropComplianceStatus.fail;
    }

    return VoltageDropResult(
      voltageDropVolts: vDrop,
      percentageDrop: percentageDrop,
      endVoltage: endVoltage,
      isCompliantBranch: isCompliantBranch,
      isCompliantTotal: isCompliantTotal,
      effectiveImpedance: zEff,
      complianceStatus: status,
    );
  }

  /// Calculate voltage drop for metric circuits (IEC 60364 / REBT ITC-BT-19)
  /// using conductor resistivity rho at 75°C, length in meters, and area in mm².
  static VoltageDropResult calculateMetric({
    required double nominalVoltage,
    required CircuitPhase phase,
    required double currentAmps,
    required double lengthMeters,
    required double areaMm2,
    bool isCopper = true,
  }) {
    if (nominalVoltage <= 0) {
      throw ArgumentError('Nominal voltage must be positive');
    }
    if (areaMm2 <= 0) {
      throw ArgumentError('Conductor area must be positive');
    }
    if (lengthMeters <= 0) {
      throw ArgumentError('Length must be positive');
    }

    final rho = isCopper ? rhoCu75 : rhoAl75;
    final phaseMultiplier = (phase == CircuitPhase.threePhase) ? sqrt3 : 2.0;
    final vDrop = (phaseMultiplier * rho * lengthMeters * currentAmps) / areaMm2;

    final percentageDrop = (vDrop / nominalVoltage) * 100.0;
    final endVoltage = nominalVoltage - vDrop;

    final isCompliantBranch = percentageDrop <= 3.00 + 0.0001;
    final isCompliantTotal = percentageDrop <= 5.00 + 0.0001;

    VoltageDropComplianceStatus status;
    if (percentageDrop <= 3.00 + 0.0001) {
      status = VoltageDropComplianceStatus.pass;
    } else if (percentageDrop <= 5.00 + 0.0001) {
      status = VoltageDropComplianceStatus.caution;
    } else {
      status = VoltageDropComplianceStatus.fail;
    }

    return VoltageDropResult(
      voltageDropVolts: vDrop,
      percentageDrop: percentageDrop,
      endVoltage: endVoltage,
      isCompliantBranch: isCompliantBranch,
      isCompliantTotal: isCompliantTotal,
      effectiveImpedance: rho,
      complianceStatus: status,
    );
  }

  /// Fast circular-mil field approximation using standard K-factor
  static VoltageDropResult calculateKFactor({
    required double nominalVoltage,
    required CircuitPhase phase,
    required double currentAmps,
    required double lengthFeet,
    required double circularMils,
    bool isCopper = true,
  }) {
    if (nominalVoltage <= 0) throw ArgumentError('Nominal voltage must be positive');
    if (circularMils <= 0) throw ArgumentError('Circular mils must be positive');

    final k = isCopper ? kCopper : kAluminum;
    final phaseMultiplier = (phase == CircuitPhase.threePhase) ? sqrt3 : 2.0;
    final vDrop = (phaseMultiplier * k * currentAmps * lengthFeet) / circularMils;

    final percentageDrop = (vDrop / nominalVoltage) * 100.0;
    final endVoltage = nominalVoltage - vDrop;

    final isCompliantBranch = percentageDrop <= 3.00 + 0.0001;
    final isCompliantTotal = percentageDrop <= 5.00 + 0.0001;

    VoltageDropComplianceStatus status;
    if (percentageDrop <= 3.00 + 0.0001) {
      status = VoltageDropComplianceStatus.pass;
    } else if (percentageDrop <= 5.00 + 0.0001) {
      status = VoltageDropComplianceStatus.caution;
    } else {
      status = VoltageDropComplianceStatus.fail;
    }

    return VoltageDropResult(
      voltageDropVolts: vDrop,
      percentageDrop: percentageDrop,
      endVoltage: endVoltage,
      isCompliantBranch: isCompliantBranch,
      isCompliantTotal: isCompliantTotal,
      effectiveImpedance: k,
      complianceStatus: status,
    );
  }
}
