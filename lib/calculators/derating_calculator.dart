import '../models/calculation_results.dart';
import '../models/conductor.dart';

class DeratingCalculator {
  DeratingCalculator._();

  /// Ambient Temperature Correction Factor (CF_temp) per NEC Table 310.15(B)(1)
  /// based on 30°C (86°F) ambient reference.
  static double getTemperatureCorrectionFactor({
    required double ambientTempC,
    required double conductorRatingC,
  }) {
    // 60°C Column
    if (conductorRatingC <= 60.0) {
      if (ambientTempC <= 10.0) return 1.29;
      if (ambientTempC <= 15.0) return 1.22;
      if (ambientTempC <= 20.0) return 1.15;
      if (ambientTempC <= 25.0) return 1.08;
      if (ambientTempC <= 30.0) return 1.00;
      if (ambientTempC <= 35.0) return 0.91;
      if (ambientTempC <= 40.0) return 0.82;
      if (ambientTempC <= 45.0) return 0.71;
      if (ambientTempC <= 50.0) return 0.58;
      if (ambientTempC <= 55.0) return 0.41;
      return 0.00; // Above 55°C is prohibited for 60°C conductors
    }

    // 75°C Column
    if (conductorRatingC <= 75.0) {
      if (ambientTempC <= 10.0) return 1.20;
      if (ambientTempC <= 15.0) return 1.15;
      if (ambientTempC <= 20.0) return 1.11;
      if (ambientTempC <= 25.0) return 1.05;
      if (ambientTempC <= 30.0) return 1.00;
      if (ambientTempC <= 35.0) return 0.94;
      if (ambientTempC <= 40.0) return 0.88;
      if (ambientTempC <= 45.0) return 0.82;
      if (ambientTempC <= 50.0) return 0.75;
      if (ambientTempC <= 55.0) return 0.67;
      if (ambientTempC <= 60.0) return 0.58;
      if (ambientTempC <= 65.0) return 0.47;
      if (ambientTempC <= 70.0) return 0.33;
      return 0.00; // Above 70°C is prohibited for 75°C conductors
    }

    // 90°C Column (THHN, XHHW-2, USE-2)
    if (ambientTempC <= 10.0) return 1.15;
    if (ambientTempC <= 15.0) return 1.12;
    if (ambientTempC <= 20.0) return 1.08;
    if (ambientTempC <= 25.0) return 1.04;
    if (ambientTempC <= 30.0) return 1.00;
    if (ambientTempC <= 35.0) return 0.96;
    if (ambientTempC <= 40.0) return 0.91;
    if (ambientTempC <= 45.0) return 0.87;
    if (ambientTempC <= 50.0) return 0.82;
    if (ambientTempC <= 55.0) return 0.76;
    if (ambientTempC <= 60.0) return 0.71;
    if (ambientTempC <= 65.0) return 0.65;
    if (ambientTempC <= 70.0) return 0.58;
    if (ambientTempC <= 75.0) return 0.50;
    if (ambientTempC <= 80.0) return 0.41;
    if (ambientTempC <= 85.0) return 0.29;
    return 0.00; // Above 85°C is prohibited for 90°C conductors
  }

  /// Bundling Adjustment Factor (AF_bundle) per NEC Table 310.15(C)(1)
  /// for count of current-carrying conductors (CCC).
  /// Exemption: Conduit nipples <= 24 inches are exempt (factor = 1.00).
  static double getBundlingAdjustmentFactor({
    required int currentCarryingConductorsCount,
    bool isNipple = false,
  }) {
    if (isNipple) return 1.00;
    if (currentCarryingConductorsCount <= 3) return 1.00;
    if (currentCarryingConductorsCount <= 6) return 0.80;
    if (currentCarryingConductorsCount <= 9) return 0.70;
    if (currentCarryingConductorsCount <= 20) return 0.50;
    if (currentCarryingConductorsCount <= 30) return 0.45;
    if (currentCarryingConductorsCount <= 40) return 0.40;
    return 0.35; // 41 or more
  }

  /// Complete ampacity derating calculation with terminal rating clamping (NEC 110.14(C))
  static DeratingResult calculate({
    required ConductorSpec conductorSpec,
    required double ambientTempC,
    required int currentCarryingConductorsCount,
    double terminalRatingC = 75.0,
    bool isNipple = false,
  }) {
    // Determine base ampacity from insulation rating
    final conductorRatingC = conductorSpec.insulation.maxOperatingTemperatureC;
    double baseAmpacity;
    if (conductorRatingC <= 60.0) {
      baseAmpacity = conductorSpec.ampacity60C;
    } else if (conductorRatingC <= 75.0) {
      baseAmpacity = conductorSpec.ampacity75C;
    } else {
      baseAmpacity = conductorSpec.ampacity90C;
    }

    final cfTemp = getTemperatureCorrectionFactor(
      ambientTempC: ambientTempC,
      conductorRatingC: conductorRatingC,
    );

    final afBundle = getBundlingAdjustmentFactor(
      currentCarryingConductorsCount: currentCarryingConductorsCount,
      isNipple: isNipple,
    );

    // Derated ampacity before terminal clamping
    final deratedAmpacity = baseAmpacity * cfTemp * afBundle;

    // Terminal rating limit (e.g. 75°C or 60°C column)
    final terminalRatingLimit = (terminalRatingC <= 60.0)
        ? conductorSpec.ampacity60C
        : conductorSpec.ampacity75C;

    // NEC 110.14(C): Usable ampacity cannot exceed the termination rating
    final allowableAmpacity = (deratedAmpacity < terminalRatingLimit)
        ? deratedAmpacity
        : terminalRatingLimit;

    return DeratingResult(
      baseAmpacity: baseAmpacity,
      temperatureCorrectionFactor: cfTemp,
      bundlingAdjustmentFactor: afBundle,
      deratedAmpacity: deratedAmpacity,
      terminalRatingLimit: terminalRatingLimit,
      allowableAmpacity: allowableAmpacity,
      smallWireOcpdLimit: conductorSpec.maxOcpdAmps,
    );
  }
}
