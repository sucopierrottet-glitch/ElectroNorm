// ignore_for_file: avoid_print

import 'dart:math' as math;
import 'package:electronorm/models/conductor.dart';
import 'package:electronorm/catalogs/conductor_catalog.dart';
import 'package:electronorm/calculators/voltage_drop_calculator.dart';
import 'package:electronorm/calculators/derating_calculator.dart';

void main() {
  print('================================================================');
  print('ELECTRONORM PRO - INDEPENDENT EMPIRICAL VERIFICATION HARNESS');
  print('Challenger: challenger_m1_2');
  print('================================================================\n');

  int totalTests = 0;
  int passedTests = 0;
  int failedTests = 0;

  void reportTest(String name, bool passed, {String? details}) {
    totalTests++;
    if (passed) {
      passedTests++;
      print('  [PASS] $name');
    } else {
      failedTests++;
      print('  [FAIL] $name');
      if (details != null) print('         Error: $details');
    }
  }

  // -------------------------------------------------------------
  // 1. AC VOLTAGE DROP: SINGLE-PHASE (120V, 240V) & THREE-PHASE (208V, 480V)
  // -------------------------------------------------------------
  print('=== DOMAIN 1: AC VOLTAGE DROP INDEPENDENT BENCHMARK ORACLE ===');

  // Independent oracle calculations
  const double sqrt3 = 1.7320508075688772;

  double calcOracleDrop({
    required double vNominal,
    required bool isThreePhase,
    required double amps,
    required double lengthFt,
    required double r,
    required double xl,
    required double pf,
  }) {
    final sinTheta = math.sqrt(math.max(0.0, 1.0 - pf * pf));
    final zEff = (r * pf) + (xl * sinTheta);
    final mult = isThreePhase ? sqrt3 : 2.0;
    return mult * amps * (lengthFt / 1000.0) * zEff;
  }

  // Test Matrix: (name, nominalV, 3Phase, amps, lengthFt, gauge, isSteel, pf, rExpected, xlExpected)
  final vdCases = [
    // 120V Single-Phase
    {
      'desc': '120V 1-Ph 15A 50ft #14 Cu Steel (PF 0.95)',
      'v': 120.0, '3p': false, 'i': 15.0, 'l': 50.0, 'g': '14 AWG',
      'cu': true, 'steel': true, 'pf': 0.95, 'r': 3.10, 'xl': 0.058
    },
    {
      'desc': '120V 1-Ph 16A 75ft #12 Cu Steel (PF 0.95) [VD-01]',
      'v': 120.0, '3p': false, 'i': 16.0, 'l': 75.0, 'g': '12 AWG',
      'cu': true, 'steel': true, 'pf': 0.95, 'r': 1.98, 'xl': 0.054
    },
    {
      'desc': '120V 1-Ph 12A 50ft #12 Cu Steel (PF 1.00) [VD-02]',
      'v': 120.0, '3p': false, 'i': 12.0, 'l': 50.0, 'g': '12 AWG',
      'cu': true, 'steel': true, 'pf': 1.00, 'r': 1.98, 'xl': 0.054
    },
    {
      'desc': '120V 1-Ph 20A 100ft #10 Cu PVC (PF 0.85)',
      'v': 120.0, '3p': false, 'i': 20.0, 'l': 100.0, 'g': '10 AWG',
      'cu': true, 'steel': false, 'pf': 0.85, 'r': 1.24, 'xl': 0.050
    },
    // 240V Single-Phase
    {
      'desc': '240V 1-Ph 40A 120ft #8 Cu Steel (PF 0.90) [VD-04]',
      'v': 240.0, '3p': false, 'i': 40.0, 'l': 120.0, 'g': '8 AWG',
      'cu': true, 'steel': true, 'pf': 0.90, 'r': 0.78, 'xl': 0.052
    },
    {
      'desc': '240V 1-Ph 50A 200ft #6 Cu Steel (PF 0.85)',
      'v': 240.0, '3p': false, 'i': 50.0, 'l': 200.0, 'g': '6 AWG',
      'cu': true, 'steel': true, 'pf': 0.85, 'r': 0.49, 'xl': 0.051
    },
    {
      'desc': '240V 1-Ph 70A 250ft #4 Cu PVC (PF 0.92)',
      'v': 240.0, '3p': false, 'i': 70.0, 'l': 250.0, 'g': '4 AWG',
      'cu': true, 'steel': false, 'pf': 0.92, 'r': 0.31, 'xl': 0.048
    },
    // 208V Three-Phase
    {
      'desc': '208V 3-Ph 100A 150ft #1 Cu PVC (PF 0.90) [VD-03]',
      'v': 208.0, '3p': true, 'i': 100.0, 'l': 150.0, 'g': '1 AWG',
      'cu': true, 'steel': false, 'pf': 0.90, 'r': 0.154, 'xl': 0.044
    },
    {
      'desc': '208V 3-Ph 150A 250ft 2/0 Cu Steel (PF 0.80)',
      'v': 208.0, '3p': true, 'i': 150.0, 'l': 250.0, 'g': '2/0 AWG',
      'cu': true, 'steel': true, 'pf': 0.80, 'r': 0.101, 'xl': 0.042
    },
    {
      'desc': '208V 3-Ph 100A 150ft 1/0 Al Steel (PF 0.85)',
      'v': 208.0, '3p': true, 'i': 100.0, 'l': 150.0, 'g': '1/0 AWG',
      'cu': false, 'steel': true, 'pf': 0.85, 'r': 0.21, 'xl': 0.043
    },
    // 480V Three-Phase
    {
      'desc': '480V 3-Ph 250A 400ft 350 kcmil Al Steel (PF 0.85) [VD-05]',
      'v': 480.0, '3p': true, 'i': 250.0, 'l': 400.0, 'g': '350 kcmil',
      'cu': false, 'steel': true, 'pf': 0.85, 'r': 0.066, 'xl': 0.040
    },
    {
      'desc': '480V 3-Ph 250A 800ft 350 kcmil Al Steel (PF 0.85) [VD-06]',
      'v': 480.0, '3p': true, 'i': 250.0, 'l': 800.0, 'g': '350 kcmil',
      'cu': false, 'steel': true, 'pf': 0.85, 'r': 0.066, 'xl': 0.040
    },
    {
      'desc': '480V 3-Ph 350A 600ft 500 kcmil Cu Steel (PF 0.85)',
      'v': 480.0, '3p': true, 'i': 350.0, 'l': 600.0, 'g': '500 kcmil',
      'cu': true, 'steel': true, 'pf': 0.85, 'r': 0.032, 'xl': 0.039
    },
    {
      'desc': '480V 3-Ph 350A 600ft 500 kcmil Al Steel (PF 0.85)',
      'v': 480.0, '3p': true, 'i': 350.0, 'l': 600.0, 'g': '500 kcmil',
      'cu': false, 'steel': true, 'pf': 0.85, 'r': 0.050, 'xl': 0.039
    },
  ];

  for (final tc in vdCases) {
    final spec = ConductorCatalog.getSpec(
      gauge: tc['g'] as String,
      material: (tc['cu'] as bool) ? ConductorMaterial.copper : ConductorMaterial.aluminum,
      insulation: ConductorInsulation.thhn,
    );
    final res = VoltageDropCalculator.calculateEffectiveImpedance(
      nominalVoltage: tc['v'] as double,
      phase: (tc['3p'] as bool) ? CircuitPhase.threePhase : CircuitPhase.singlePhase,
      currentAmps: tc['i'] as double,
      lengthFeet: tc['l'] as double,
      conductorSpec: spec,
      isSteelConduit: tc['steel'] as bool,
      powerFactor: tc['pf'] as double,
    );

    final expectedDrop = calcOracleDrop(
      vNominal: tc['v'] as double,
      isThreePhase: tc['3p'] as bool,
      amps: tc['i'] as double,
      lengthFt: tc['l'] as double,
      r: tc['r'] as double,
      xl: tc['xl'] as double,
      pf: tc['pf'] as double,
    );

    final delta = (res.voltageDropVolts - expectedDrop).abs();
    final pass = delta < 0.005;
    reportTest(
      tc['desc'] as String,
      pass,
      details: 'Engine=${res.voltageDropVolts.toStringAsFixed(4)}V, Oracle=${expectedDrop.toStringAsFixed(4)}V, Delta=$delta',
    );
  }

  // -------------------------------------------------------------
  // 2. COPPER VS ALUMINUM RESISTANCE AND POWER FACTOR SCALING
  // -------------------------------------------------------------
  print('\n=== DOMAIN 2: COPPER VS ALUMINUM MATERIAL & PF SCALING ===');

  // Verify DC resistance scaling across standard AWG sizes
  final awgList = [
    '12 AWG', '10 AWG', '8 AWG', '6 AWG', '4 AWG', '3 AWG',
    '2 AWG', '1 AWG', '1/0 AWG', '2/0 AWG', '3/0 AWG', '4/0 AWG',
    '250 kcmil', '300 kcmil', '350 kcmil', '400 kcmil', '500 kcmil',
  ];

  print('Testing Cu vs Al DC Resistance Ratios (NEC Chapter 9 Table 8):');
  for (final gauge in awgList) {
    final specCu = ConductorCatalog.getSpec(gauge: gauge, material: ConductorMaterial.copper);
    final specAl = ConductorCatalog.getSpec(gauge: gauge, material: ConductorMaterial.aluminum);

    final ratio = specAl.dcResistanceAl75C / specCu.dcResistanceCu75C;
    // Expected physical resistivity ratio for Aluminum/Copper is between 1.63 and 1.66
    final pass = ratio >= 1.63 && ratio <= 1.66;
    reportTest(
      'DC Resist. Ratio for $gauge (Al/Cu = ${ratio.toStringAsFixed(4)})',
      pass,
      details: 'R_Al=${specAl.dcResistanceAl75C}, R_Cu=${specCu.dcResistanceCu75C}, ratio=$ratio',
    );
  }

  // Test Power Factor Scaling Convergence
  // When PF = 1.0, inductive reactance drops out: Z_eff = R
  // When PF = 0.0, resistance drops out: Z_eff = X_L (Cu and Al should be IDENTICAL)
  print('\nTesting Power Factor Scaling Extremes (500 kcmil in Steel Conduit):');
  final cu500 = ConductorCatalog.getSpec(gauge: '500 kcmil', material: ConductorMaterial.copper);
  final al500 = ConductorCatalog.getSpec(gauge: '500 kcmil', material: ConductorMaterial.aluminum);

  final resCuUnity = VoltageDropCalculator.calculateEffectiveImpedance(
    nominalVoltage: 480.0,
    phase: CircuitPhase.threePhase,
    currentAmps: 100.0,
    lengthFeet: 1000.0,
    conductorSpec: cu500,
    isSteelConduit: true,
    powerFactor: 1.0,
  );

  final resAlUnity = VoltageDropCalculator.calculateEffectiveImpedance(
    nominalVoltage: 480.0,
    phase: CircuitPhase.threePhase,
    currentAmps: 100.0,
    lengthFeet: 1000.0,
    conductorSpec: al500,
    isSteelConduit: true,
    powerFactor: 1.0,
  );

  final unityRatio = resAlUnity.effectiveImpedance / resCuUnity.effectiveImpedance;
  reportTest(
    'Unity PF (PF=1.0) matches pure AC resistance ratio (0.050 / 0.032 = 1.5625)',
    (unityRatio - 1.5625).abs() < 0.001,
    details: 'Z_Al=${resAlUnity.effectiveImpedance}, Z_Cu=${resCuUnity.effectiveImpedance}, ratio=$unityRatio',
  );

  final resCuZeroPf = VoltageDropCalculator.calculateEffectiveImpedance(
    nominalVoltage: 480.0,
    phase: CircuitPhase.threePhase,
    currentAmps: 100.0,
    lengthFeet: 1000.0,
    conductorSpec: cu500,
    isSteelConduit: true,
    powerFactor: 0.0,
  );

  final resAlZeroPf = VoltageDropCalculator.calculateEffectiveImpedance(
    nominalVoltage: 480.0,
    phase: CircuitPhase.threePhase,
    currentAmps: 100.0,
    lengthFeet: 1000.0,
    conductorSpec: al500,
    isSteelConduit: true,
    powerFactor: 0.0,
  );

  reportTest(
    'Zero PF (PF=0.0) inductive convergence (Z_eff = X_L = 0.039 for both Cu & Al)',
    (resCuZeroPf.effectiveImpedance - 0.039).abs() < 0.0001 &&
    (resAlZeroPf.effectiveImpedance - 0.039).abs() < 0.0001,
    details: 'Cu_Z=${resCuZeroPf.effectiveImpedance}, Al_Z=${resAlZeroPf.effectiveImpedance}',
  );

  // K-Factor ratio verification
  final kRatio = VoltageDropCalculator.kAluminum / VoltageDropCalculator.kCopper;
  reportTest(
    'K-Factor ratio (21.2 / 12.9 = 1.6434)',
    (kRatio - (21.2 / 12.9)).abs() < 0.0001,
  );

  // -------------------------------------------------------------
  // 3. TEMPERATURE CORRECTION FACTORS (10°C TO 80°C) & BUNDLING MULTIPLIERS (4 TO 40+)
  // -------------------------------------------------------------
  print('\n=== DOMAIN 3: TEMPERATURE & BUNDLING FACTORS FULL SWEEP ===');

  // Complete sweep of Temperature Correction Factor Table
  // (temp, expected60, expected75, expected90)
  final tempSweeps = [
    {'t': 10.0, '60': 1.29, '75': 1.20, '90': 1.15},
    {'t': 13.0, '60': 1.22, '75': 1.15, '90': 1.12},
    {'t': 15.0, '60': 1.22, '75': 1.15, '90': 1.12},
    {'t': 18.0, '60': 1.15, '75': 1.11, '90': 1.08},
    {'t': 20.0, '60': 1.15, '75': 1.11, '90': 1.08},
    {'t': 23.0, '60': 1.08, '75': 1.05, '90': 1.04},
    {'t': 25.0, '60': 1.08, '75': 1.05, '90': 1.04},
    {'t': 28.0, '60': 1.00, '75': 1.00, '90': 1.00},
    {'t': 30.0, '60': 1.00, '75': 1.00, '90': 1.00},
    {'t': 33.0, '60': 0.91, '75': 0.94, '90': 0.96},
    {'t': 35.0, '60': 0.91, '75': 0.94, '90': 0.96},
    {'t': 38.0, '60': 0.82, '75': 0.88, '90': 0.91},
    {'t': 40.0, '60': 0.82, '75': 0.88, '90': 0.91},
    {'t': 43.0, '60': 0.71, '75': 0.82, '90': 0.87},
    {'t': 45.0, '60': 0.71, '75': 0.82, '90': 0.87},
    {'t': 48.0, '60': 0.58, '75': 0.75, '90': 0.82},
    {'t': 50.0, '60': 0.58, '75': 0.75, '90': 0.82},
    {'t': 53.0, '60': 0.41, '75': 0.67, '90': 0.76},
    {'t': 55.0, '60': 0.41, '75': 0.67, '90': 0.76},
    {'t': 58.0, '60': 0.00, '75': 0.58, '90': 0.71},
    {'t': 60.0, '60': 0.00, '75': 0.58, '90': 0.71},
    {'t': 63.0, '60': 0.00, '75': 0.47, '90': 0.65},
    {'t': 65.0, '60': 0.00, '75': 0.47, '90': 0.65},
    {'t': 68.0, '60': 0.00, '75': 0.33, '90': 0.58},
    {'t': 70.0, '60': 0.00, '75': 0.33, '90': 0.58},
    {'t': 73.0, '60': 0.00, '75': 0.00, '90': 0.50},
    {'t': 75.0, '60': 0.00, '75': 0.00, '90': 0.50},
    {'t': 78.0, '60': 0.00, '75': 0.00, '90': 0.41},
    {'t': 80.0, '60': 0.00, '75': 0.00, '90': 0.41},
    {'t': 83.0, '60': 0.00, '75': 0.00, '90': 0.29},
    {'t': 85.0, '60': 0.00, '75': 0.00, '90': 0.29},
    {'t': 88.0, '60': 0.00, '75': 0.00, '90': 0.00},
  ];

  for (final sweep in tempSweeps) {
    final t = sweep['t'] as double;
    final f60 = DeratingCalculator.getTemperatureCorrectionFactor(ambientTempC: t, conductorRatingC: 60.0);
    final f75 = DeratingCalculator.getTemperatureCorrectionFactor(ambientTempC: t, conductorRatingC: 75.0);
    final f90 = DeratingCalculator.getTemperatureCorrectionFactor(ambientTempC: t, conductorRatingC: 90.0);

    final pass60 = (f60 == sweep['60']);
    final pass75 = (f75 == sweep['75']);
    final pass90 = (f90 == sweep['90']);

    reportTest('Temp $t°C (60°C col = ${sweep['60']})', pass60, details: 'Got $f60');
    reportTest('Temp $t°C (75°C col = ${sweep['75']})', pass75, details: 'Got $f75');
    reportTest('Temp $t°C (90°C col = ${sweep['90']})', pass90, details: 'Got $f90');
  }

  // Bundling Multipliers Sweep from 1 to 45+ Conductors
  final bundlingSweeps = [
    {'count': 1, 'af': 1.00},
    {'count': 2, 'af': 1.00},
    {'count': 3, 'af': 1.00},
    {'count': 4, 'af': 0.80},
    {'count': 5, 'af': 0.80},
    {'count': 6, 'af': 0.80},
    {'count': 7, 'af': 0.70},
    {'count': 8, 'af': 0.70},
    {'count': 9, 'af': 0.70},
    {'count': 10, 'af': 0.50},
    {'count': 15, 'af': 0.50},
    {'count': 20, 'af': 0.50},
    {'count': 21, 'af': 0.45},
    {'count': 25, 'af': 0.45},
    {'count': 30, 'af': 0.45},
    {'count': 31, 'af': 0.40},
    {'count': 35, 'af': 0.40},
    {'count': 40, 'af': 0.40},
    {'count': 41, 'af': 0.35},
    {'count': 50, 'af': 0.35},
    {'count': 100, 'af': 0.35},
  ];

  print('\nTesting Bundling Adjustment Factors Table 310.15(C)(1):');
  for (final bs in bundlingSweeps) {
    final count = bs['count'] as int;
    final expectedAf = bs['af'] as double;
    final af = DeratingCalculator.getBundlingAdjustmentFactor(currentCarryingConductorsCount: count);
    reportTest('Bundling for $count CCC = $expectedAf', af == expectedAf, details: 'Got $af');
  }

  print('\nTesting Conduit Nipple Bundling Exemption (Note 4):');
  for (final count in [4, 8, 12, 25, 42]) {
    final afNipple = DeratingCalculator.getBundlingAdjustmentFactor(
      currentCarryingConductorsCount: count,
      isNipple: true,
    );
    reportTest('Nipple <= 24" with $count CCC is exempt (AF = 1.00)', afNipple == 1.00, details: 'Got $afNipple');
  }

  // -------------------------------------------------------------
  // 4. TERMINAL RATING CLAMPING VERIFICATION (NEC 110.14(C))
  // -------------------------------------------------------------
  print('\n=== DOMAIN 4: TERMINAL RATING CLAMPING VERIFICATION ===');

  // Test that 75°C terminal limit overrides 90°C derated rating that is higher
  // Case A: No derating applied (30°C, 3 CCC) -> 90°C base ampacity is higher than 75°C terminal limit
  print('Testing 75°C terminal clamp overriding un-derated 90°C rating:');
  for (final gauge in awgList) {
    final spec = ConductorCatalog.getSpec(gauge: gauge, insulation: ConductorInsulation.thhn);
    final res = DeratingCalculator.calculate(
      conductorSpec: spec,
      ambientTempC: 30.0,
      currentCarryingConductorsCount: 3,
      terminalRatingC: 75.0,
    );

    // deratedAmpacity is 90°C base, terminalRatingLimit is 75°C base
    // allowableAmpacity MUST be clamped to 75°C base!
    final expectedAllowable = spec.ampacity75C;
    final pass = (res.allowableAmpacity == expectedAllowable) &&
                 (res.deratedAmpacity == spec.ampacity90C);
    reportTest(
      '75°C Clamp for $gauge THHN (90C=${spec.ampacity90C}A -> clamped to 75C=${expectedAllowable}A)',
      pass,
      details: 'Allowable=${res.allowableAmpacity}, Derated=${res.deratedAmpacity}, Limit=${res.terminalRatingLimit}',
    );
  }

  // Case B: Moderate derating where derated 90°C rating is STILL higher than 75°C terminal limit
  // Example: 500 kcmil Cu (430A @ 90°C, 380A @ 75°C) at 35°C (CF=0.96), 3 CCC (AF=1.00)
  // Derated = 430 * 0.96 * 1.00 = 412.8A. Since 412.8A > 380A, allowable MUST BE 380A!
  final res500Moderate = DeratingCalculator.calculate(
    conductorSpec: cu500,
    ambientTempC: 35.0,
    currentCarryingConductorsCount: 3,
    terminalRatingC: 75.0,
  );
  reportTest(
    '500 kcmil Cu at 35°C (Derated 412.8A > 380A terminal -> Clamped to 380A)',
    res500Moderate.deratedAmpacity == 412.8 && res500Moderate.allowableAmpacity == 380.0,
    details: 'Derated=${res500Moderate.deratedAmpacity}, Allowable=${res500Moderate.allowableAmpacity}',
  );

  // Case C: Heavy derating where derated 90°C rating is LOWER than 75°C terminal limit
  // Derated rating must NOT be clamped UP to terminal limit!
  // Example: 4/0 AWG THHN Cu (260A @ 90°C, 230A @ 75°C) at 45°C (CF=0.87), 9 CCC (AF=0.70)
  // Derated = 260 * 0.87 * 0.70 = 158.34A. Since 158.34A < 230A, allowable MUST BE 158.34A!
  final spec40 = ConductorCatalog.getSpec(gauge: '4/0 AWG', insulation: ConductorInsulation.thhn);
  final res40Heavy = DeratingCalculator.calculate(
    conductorSpec: spec40,
    ambientTempC: 45.0,
    currentCarryingConductorsCount: 9,
    terminalRatingC: 75.0,
  );
  reportTest(
    '4/0 AWG Cu heavy derating (158.34A < 230A terminal -> Allowable remains 158.34A)',
    (res40Heavy.deratedAmpacity - 158.34).abs() < 0.01 &&
    (res40Heavy.allowableAmpacity - 158.34).abs() < 0.01,
    details: 'Derated=${res40Heavy.deratedAmpacity}, Allowable=${res40Heavy.allowableAmpacity}',
  );

  // Case D: 60°C terminal rating clamp
  // #10 AWG THHN Cu (40A @ 90°C, 30A @ 60°C) with terminalRatingC = 60.0
  final spec10 = ConductorCatalog.getSpec(gauge: '10 AWG', insulation: ConductorInsulation.thhn);
  final res10Term60 = DeratingCalculator.calculate(
    conductorSpec: spec10,
    ambientTempC: 30.0,
    currentCarryingConductorsCount: 3,
    terminalRatingC: 60.0,
  );
  reportTest(
    '#10 AWG Cu with 60°C terminal clamp (40A base @ 90°C -> Clamped to 30A @ 60°C)',
    res10Term60.allowableAmpacity == 30.0 && res10Term60.terminalRatingLimit == 30.0,
    details: 'Allowable=${res10Term60.allowableAmpacity}, Limit=${res10Term60.terminalRatingLimit}',
  );

  print('\n================================================================');
  print('VERIFICATION SUMMARY:');
  print('Total tests executed: $totalTests');
  print('Passed: $passedTests');
  print('Failed: $failedTests');
  print('Pass Rate: ${(passedTests / totalTests * 100.0).toStringAsFixed(2)}%');
  print('================================================================');
}
