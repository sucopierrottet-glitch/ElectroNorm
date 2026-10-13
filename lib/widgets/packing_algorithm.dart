import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/conductor.dart';
import '../theme/app_theme.dart';

/// Represents a single packed conductor rendered within the raceway cross-section.
class PackedConductorPosition {
  /// Normalized X coordinate in [-1.0, 1.0] relative to raceway lumen radius.
  final double normalizedX;

  /// Normalized Y coordinate in [-1.0, 1.0] relative to raceway lumen radius.
  final double normalizedY;

  /// Normalized radius in [0.0, 1.0] relative to raceway lumen radius.
  final double normalizedRadius;

  /// Exterior insulation jacket color.
  final Color color;

  /// Conductor gauge label (e.g., "#10 AWG", "12 AWG", "500 kcmil").
  final String label;

  /// Circuit role (e.g., "phaseA", "phaseB", "phaseC", "neutral", "ground").
  final String role;

  /// Optional high-contrast border color (e.g., silver for Phase A).
  final Color? borderColor;

  /// Color representing the metallic conductor core (copper vs. aluminum).
  final Color coreColor;

  /// Whether the core is copper (true) or aluminum (false).
  final bool isCopper;

  /// Conductor outside diameter in inches.
  final double diameterInches;

  const PackedConductorPosition({
    required this.normalizedX,
    required this.normalizedY,
    required this.normalizedRadius,
    required this.color,
    required this.label,
    this.role = '',
    this.borderColor,
    this.coreColor = AppColors.coreCopper,
    this.isCopper = true,
    this.diameterInches = 0.0,
  });
}

/// Abstract contract for conductor packing algorithms.
abstract class ConductorPackingAlgorithm {
  List<PackedConductorPosition> pack({
    required double conduitRadius,
    required List<ConductorGroup> groups,
  });
}

/// Deterministic Golden-Spiral seeded relaxation algorithm for real-time 2D circle packing.
///
/// Algorithmic properties:
/// 1. Initial Seeding: theta_i = i * 137.5°, r_i proportional to sqrt((i+1)/N).
///    Phase conductors are seeded first near the lumen core, followed by neutrals and grounds.
/// 2. Iterative Relaxation (30 iterations):
///    - Bundle centering tension (decaying in final iterations)
///    - Pairwise repulsion for overlapping circles
///    - Boundary clamping against circular raceway lumen (R = 1.0)
/// 3. Computational Complexity: deterministic, O(iterations * N^2) taking < 0.3ms for N <= 50.
class GoldenSpiralPackingAlgorithm implements ConductorPackingAlgorithm {
  final int iterations;

  const GoldenSpiralPackingAlgorithm({this.iterations = 30});

  static const GoldenSpiralPackingAlgorithm defaultInstance =
      GoldenSpiralPackingAlgorithm();

  @override
  List<PackedConductorPosition> pack({
    required double conduitRadius,
    required List<ConductorGroup> groups,
  }) {
    if (conduitRadius <= 0) return const [];

    // 1. Expand groups into individual conductor instances
    final items = <_ConductorItem>[];
    for (final group in groups) {
      if (group.count <= 0) continue;
      final spec = group.spec;
      final wireRadius = spec.outerDiameterInches / 2.0;
      final normRadius = wireRadius / conduitRadius;
      final role = group.role;
      final isCu = spec.material.isCopper;

      final jacketColor = AppColors.getConductorColor(
        role,
        explicitColorHex: group.colorHex,
      );
      final border = AppColors.getConductorBorderColor(role);
      final core = isCu ? AppColors.coreCopper : AppColors.coreAluminum;

      for (int i = 0; i < group.count; i++) {
        items.add(_ConductorItem(
          radiusInches: wireRadius,
          normalizedRadius: normRadius,
          color: jacketColor,
          borderColor: border,
          coreColor: core,
          label: spec.gauge,
          role: role,
          isCopper: isCu,
          diameterInches: spec.outerDiameterInches,
        ));
      }
    }

    final n = items.length;
    if (n == 0) return const [];

    // Special single-conductor case: place right at center
    if (n == 1) {
      final single = items.first;
      return [
        PackedConductorPosition(
          normalizedX: 0.0,
          normalizedY: 0.0,
          normalizedRadius: single.normalizedRadius,
          color: single.color,
          label: single.label,
          role: single.role,
          borderColor: single.borderColor,
          coreColor: single.coreColor,
          isCopper: single.isCopper,
          diameterInches: single.diameterInches,
        )
      ];
    }

    // 2. Sort conductors: larger phase conductors placed first near core
    // Priority: Phase conductors (3) > Neutrals (2) > Grounds (1)
    items.sort((a, b) {
      // Primary: radius descending
      final rCmp = b.normalizedRadius.compareTo(a.normalizedRadius);
      if (rCmp != 0) return rCmp;

      // Secondary: role priority descending
      final pA = _rolePriority(a.role);
      final pB = _rolePriority(b.role);
      final pCmp = pB.compareTo(pA);
      if (pCmp != 0) return pCmp;

      return a.label.compareTo(b.label);
    });

    // 3. Golden-Spiral Initial Seeding
    // Golden angle = 137.50776405003785 degrees in radians
    const goldenAngleRad = 137.50776405003785 * (math.pi / 180.0);
    final px = List<double>.filled(n, 0.0);
    final py = List<double>.filled(n, 0.0);
    final nr = List<double>.generate(n, (i) => items[i].normalizedRadius);

    for (int i = 0; i < n; i++) {
      final theta = i * goldenAngleRad;
      // Proportional to sqrt((i + 1) / n), scaled to comfortably fit inside lumen
      final rSeed = 0.35 * math.sqrt((i + 1) / n);
      px[i] = rSeed * math.cos(theta);
      py[i] = rSeed * math.sin(theta);
    }

    // 4. Iterative Relaxation Loop (Pairwise repulsion, boundary clamping, centering pull)
    for (int iter = 0; iter < iterations; iter++) {
      // (a) Centering pull (bundle tension) - active during initial 75% of iterations,
      // disabled in final iterations so pairwise repulsion settles strictly non-overlapping.
      final isFinalSettling = iter >= (iterations * 0.75);
      if (!isFinalSettling) {
        for (int i = 0; i < n; i++) {
          px[i] -= px[i] * 0.010;
          py[i] -= py[i] * 0.010;
        }
      }

      // (b) Pairwise repulsion
      for (int i = 0; i < n; i++) {
        for (int j = i + 1; j < n; j++) {
          double dx = px[i] - px[j];
          double dy = py[i] - py[j];
          double dist = math.sqrt(dx * dx + dy * dy);
          final minDist = nr[i] + nr[j] + 0.005;

          if (dist < minDist) {
            if (dist < 1e-6) {
              // Deterministic separation for perfectly coincident points
              final angle = (i * 1.7 + j * 2.3);
              const push = 0.03;
              px[i] += push * math.cos(angle);
              py[i] += push * math.sin(angle);
              px[j] -= push * math.cos(angle);
              py[j] -= push * math.sin(angle);
            } else {
              final overlap = minDist - dist;
              final nx = dx / dist;
              final ny = dy / dist;
              final step = overlap * 0.52;
              px[i] += nx * step;
              py[i] += ny * step;
              px[j] -= nx * step;
              py[j] -= ny * step;
            }
          }
        }
      }

      // (c) Boundary containment (clamp inside raceway lumen R = 1.0)
      for (int i = 0; i < n; i++) {
        final maxR = math.max(0.0, 1.0 - nr[i]);
        final d = math.sqrt(px[i] * px[i] + py[i] * py[i]);
        if (d > maxR && d > 1e-6) {
          final s = maxR / d;
          px[i] *= s;
          py[i] *= s;
        }
      }
    }

    // Final boundary safeguard
    for (int i = 0; i < n; i++) {
      final maxR = math.max(0.0, 1.0 - nr[i]);
      final d = math.sqrt(px[i] * px[i] + py[i] * py[i]);
      if (d > maxR && d > 1e-6) {
        final s = maxR / d;
        px[i] *= s;
        py[i] *= s;
      }
    }

    // 5. Build packed positions result
    final result = <PackedConductorPosition>[];
    for (int i = 0; i < n; i++) {
      final item = items[i];
      result.add(PackedConductorPosition(
        normalizedX: px[i],
        normalizedY: py[i],
        normalizedRadius: item.normalizedRadius,
        color: item.color,
        label: item.label,
        role: item.role,
        borderColor: item.borderColor,
        coreColor: item.coreColor,
        isCopper: item.isCopper,
        diameterInches: item.diameterInches,
      ));
    }

    return result;
  }

  static int _rolePriority(String role) {
    final lower = role.toLowerCase().trim();
    if (lower.contains('phase') || lower == 'l1' || lower == 'l2' || lower == 'l3') {
      return 3;
    }
    if (lower.contains('neutral') || lower == 'n') {
      return 2;
    }
    return 1; // Ground / EGC
  }
}

class _ConductorItem {
  final double radiusInches;
  final double normalizedRadius;
  final Color color;
  final Color? borderColor;
  final Color coreColor;
  final String label;
  final String role;
  final bool isCopper;
  final double diameterInches;

  _ConductorItem({
    required this.radiusInches,
    required this.normalizedRadius,
    required this.color,
    this.borderColor,
    required this.coreColor,
    required this.label,
    required this.role,
    required this.isCopper,
    required this.diameterInches,
  });
}
