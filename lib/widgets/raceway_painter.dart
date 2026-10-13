import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/conductor.dart';
import '../theme/app_theme.dart';
import 'packing_algorithm.dart';

/// CustomPainter rendering the circular cross-section profile of the raceway
/// lumen, proportional packed conductors, color codes, reticle crosshairs,
/// and radial occupancy indicator.
class RacewayPainter extends CustomPainter {
  final double conduitRadiusInches;
  final List<PackedConductorPosition> positions;
  final double fillPercentage;
  final double maxAllowedFill;
  final bool showCrosshairs;
  final bool showAllowedFillRing;

  RacewayPainter({
    required this.conduitRadiusInches,
    required this.positions,
    required this.fillPercentage,
    required this.maxAllowedFill,
    this.showCrosshairs = true,
    this.showAllowedFillRing = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2.0, size.height / 2.0);
    final drawRadius = math.min(size.width, size.height) * 0.40;

    // 1. Draw Raceway Outer Wall (metallic conduit shell)
    final wallPaint = Paint()
      ..color = AppColors.conduitWall
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0;
    canvas.drawCircle(center, drawRadius + 4.5, wallPaint);

    // Subtle outer conduit rim highlight
    final wallRimPaint = Paint()
      ..color = AppColors.borderHighContrast.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, drawRadius + 9.0, wallRimPaint);

    // 2. Draw Raceway Inner Lumen / Bore (dark interior)
    final borePaint = Paint()
      ..color = AppColors.conduitBore
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, drawRadius, borePaint);

    final boreEdgePaint = Paint()
      ..color = AppColors.borderSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, drawRadius, boreEdgePaint);

    // 3. Draw Allowed Fill Limit Reference Ring
    if (showAllowedFillRing && maxAllowedFill > 0) {
      final allowedFraction = (maxAllowedFill / 100.0).clamp(0.0, 1.0);
      final allowedRadius = math.sqrt(allowedFraction) * drawRadius;
      final allowedPaint = Paint()
        ..color = AppColors.borderSubtle.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, allowedRadius, allowedPaint);
    }

    // 4. Draw Center Crosshairs (tactile engineering reticle)
    if (showCrosshairs) {
      final crosshairPaint = Paint()
        ..color = AppColors.conduitCrosshairs
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(center.dx - 14, center.dy),
        Offset(center.dx + 14, center.dy),
        crosshairPaint,
      );
      canvas.drawLine(
        Offset(center.dx, center.dy - 14),
        Offset(center.dx, center.dy + 14),
        crosshairPaint,
      );
    }

    // 5. Draw Occupancy Meter Sweep Arc along the outer conduit rim
    final statusColor = AppColors.getFillStatusColor(
      fillPercentage: fillPercentage,
      maxAllowedFill: maxAllowedFill,
    );
    final sweepFraction = (fillPercentage / 100.0).clamp(0.0, 1.0);
    final sweepAngle = 2.0 * math.pi * sweepFraction;
    if (sweepAngle > 0) {
      final meterPaint = Paint()
        ..color = statusColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: drawRadius + 4.5),
        -math.pi / 2.0, // start from 12 o'clock
        sweepAngle,
        false,
        meterPaint,
      );
    }

    // 6. Render Packed Conductors
    for (final conductor in positions) {
      final conductorCenter = center +
          Offset(
            conductor.normalizedX * drawRadius,
            conductor.normalizedY * drawRadius,
          );
      final conductorRadius = conductor.normalizedRadius * drawRadius;
      if (conductorRadius <= 0) continue;

      // Outer Insulation Jacket
      final jacketPaint = Paint()
        ..color = conductor.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(conductorCenter, conductorRadius, jacketPaint);

      // Conductor Border outline
      final borderCol = conductor.borderColor;
      if (borderCol != null) {
        final borderPaint = Paint()
          ..color = borderCol
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;
        canvas.drawCircle(conductorCenter, conductorRadius, borderPaint);
      } else {
        // Subtle outline for definition
        final subtleBorder = Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;
        canvas.drawCircle(conductorCenter, conductorRadius, subtleBorder);
      }

      // Inner Metallic Core (Copper / Aluminum)
      final coreRadius = conductorRadius * 0.70;
      if (coreRadius > 1.0) {
        final corePaint = Paint()
          ..color = conductor.coreColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(conductorCenter, coreRadius, corePaint);

        // Core highlight
        final coreHighlight = Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;
        canvas.drawCircle(conductorCenter, coreRadius, coreHighlight);
      }

      // Conductor Gauge Text Label
      if (conductorRadius >= 9.0) {
        final cleanLabel = _formatConductorLabel(conductor.label);
        final fontSize = math.max(7.5, math.min(13.0, conductorRadius * 0.48));
        final textPainter = TextPainter(
          text: TextSpan(
            text: cleanLabel,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(color: Color(0xCC000000), blurRadius: 2.0),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          conductorCenter - Offset(textPainter.width / 2.0, textPainter.height / 2.0),
        );
      }
    }
  }

  static String _formatConductorLabel(String raw) {
    var s = raw.replaceAll(' AWG', '').replaceAll(' kcmil', 'k').replaceAll(' mm²', 'mm');
    if (!s.startsWith('#') && int.tryParse(s) != null) {
      s = '#$s';
    }
    return s;
  }

  @override
  bool shouldRepaint(covariant RacewayPainter oldDelegate) {
    return oldDelegate.conduitRadiusInches != conduitRadiusInches ||
        oldDelegate.fillPercentage != fillPercentage ||
        oldDelegate.maxAllowedFill != maxAllowedFill ||
        oldDelegate.positions != positions;
  }
}

/// Interactive high-contrast Raceway Cross-Section Visualizer Widget.
/// Displays vector conduit cross-section, dynamic occupancy badge,
/// real-time fill percentage, and jam ratio hazard alert.
class RacewayVisualizer extends StatelessWidget {
  final double conduitRadiusInches;
  final List<ConductorGroup> groups;
  final double fillPercentage;
  final double maxAllowedFill;
  final String tradeSize;
  final String racewayType;
  final double? jamRatio;
  final bool hasJamRisk;
  final bool isNipple;
  final ConductorPackingAlgorithm packingAlgorithm;

  const RacewayVisualizer({
    super.key,
    required this.conduitRadiusInches,
    required this.groups,
    required this.fillPercentage,
    required this.maxAllowedFill,
    required this.tradeSize,
    required this.racewayType,
    this.jamRatio,
    this.hasJamRisk = false,
    this.isNipple = false,
    this.packingAlgorithm = GoldenSpiralPackingAlgorithm.defaultInstance,
  });

  @override
  Widget build(BuildContext context) {
    final packed = packingAlgorithm.pack(
      conduitRadius: conduitRadiusInches,
      groups: groups,
    );

    final statusColor = AppColors.getFillStatusColor(
      fillPercentage: fillPercentage,
      maxAllowedFill: maxAllowedFill,
    );

    final statusText = fillPercentage <= maxAllowedFill + 0.0001
        ? 'COMPLIANT'
        : (fillPercentage <= 50.0 ? 'CAUTION' : 'OVERFILLED');

    final statusIcon = fillPercentage <= maxAllowedFill + 0.0001
        ? Icons.check_circle
        : (fillPercentage <= 50.0 ? Icons.warning_amber_rounded : Icons.error);

    final totalWires = groups.fold<int>(0, (sum, g) => sum + g.count);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Occupancy Badge & Percentage Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Occupancy Pill
              Flexible(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '$statusText — ${fillPercentage.toStringAsFixed(1)}% / ${maxAllowedFill.toStringAsFixed(0)}% max',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Conduit spec subtitle
              Flexible(
                flex: 2,
                child: Text(
                  '$tradeSize" $racewayType',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // Jam Ratio Warning Pill (if within hazard zone: 2.80 <= R_jam <= 3.20)
          if (hasJamRisk || (jamRatio != null && jamRatio! >= 2.80 && jamRatio! <= 3.20)) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.caution.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.caution, width: 1.2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, size: 16, color: AppColors.caution),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'CRITICAL JAM RISK (Ratio ${jamRatio?.toStringAsFixed(2) ?? "3.00"}): Conductors may wedge tight on bends (NEC Ch 9)',
                      style: const TextStyle(
                        color: AppColors.caution,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Canvas Vector Cross-Section
          SizedBox(
            height: 190,
            width: double.infinity,
            child: CustomPaint(
              painter: RacewayPainter(
                conduitRadiusInches: conduitRadiusInches,
                positions: packed,
                fillPercentage: fillPercentage,
                maxAllowedFill: maxAllowedFill,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Footer Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'ID: ${(conduitRadiusInches * 2.0).toStringAsFixed(3)}" (${(conduitRadiusInches * 50.8).toStringAsFixed(1)} mm)',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '$totalWires conductor${totalWires == 1 ? "" : "s"} packed',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
