import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PersonBondRadarCard extends StatelessWidget {
  final String person1Name;
  final String person1Id;
  final String person2Name;
  final String person2Id;
  final double finalKinScore;
  final Map<String, double> radarScores; // family, alumni, career, cohort, region (0~100)
  final List<String> badges;
  final Function(String nodeId, String nodeName) onNodePivot;

  const PersonBondRadarCard({
    super.key,
    required this.person1Name,
    required this.person1Id,
    required this.person2Name,
    required this.person2Id,
    required this.finalKinScore,
    required this.radarScores,
    required this.badges,
    required this.onNodePivot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Slate Surface
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: P2P Pair with Click-to-Pivot buttons on both entities
          Row(
            children: [
              _buildPivotEntityChip(person1Name, person1Id),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(CupertinoIcons.arrow_right_arrow_left, size: 14, color: Color(0xFF38BDF8)),
              ),
              _buildPivotEntityChip(person2Name, person2Id),
              const Spacer(),
              // Circular Kin-Bond Score Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF38BDF8)),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.bolt_fill, size: 12, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 4),
                    Text(
                      '결속도 $finalKinScore점',
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 5-Axis Radar Chart Visualization
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(
                painter: _KinBondRadarPainter(radarScores: radarScores),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Multi-Dimensional Affinity Badges
          const Text(
            '인맥 결속 근거 (DART Verified Badges)',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: badges.map((b) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Text(
                b,
                style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPivotEntityChip(String name, String id) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onNodePivot(id, name),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF818CF8)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.person_crop_circle_fill, size: 13, color: Color(0xFF818CF8)),
              const SizedBox(width: 5),
              Text(
                name,
                style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 4),
              const Icon(CupertinoIcons.scope, size: 10, color: Color(0xFF38BDF8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _KinBondRadarPainter extends CustomPainter {
  final Map<String, double> radarScores;

  _KinBondRadarPainter({required this.radarScores});

  static const _labels = ['혈연', '학연', '경력', '기수', '지연'];
  static const _keys = ['family', 'alumni', 'career', 'cohort', 'region'];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 25;
    const numPoints = 5;

    final gridPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // 1. Draw 3 concentric polygon rings (33%, 66%, 100%)
    for (int ring = 1; ring <= 3; ring++) {
      final r = radius * (ring / 3.0);
      final path = Path();
      for (int i = 0; i < numPoints; i++) {
        final angle = (i * 2 * math.pi / numPoints) - (math.pi / 2);
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // 2. Draw 5 radial axis lines & labels
    for (int i = 0; i < numPoints; i++) {
      final angle = (i * 2 * math.pi / numPoints) - (math.pi / 2);
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, end, gridPaint);

      // Label text
      final textPainter = TextPainter(
        text: TextSpan(
          text: _labels[i],
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelOffset = Offset(
        center.dx + (radius + 15) * math.cos(angle) - textPainter.width / 2,
        center.dy + (radius + 15) * math.sin(angle) - textPainter.height / 2,
      );
      textPainter.paint(canvas, labelOffset);
    }

    // 3. Draw Radar Area Polygon
    final polyPath = Path();
    final fillPaint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.35)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < numPoints; i++) {
      final key = _keys[i];
      final val = (radarScores[key] ?? 50.0).clamp(0.0, 100.0) / 100.0;
      final angle = (i * 2 * math.pi / numPoints) - (math.pi / 2);
      final x = center.dx + (radius * val) * math.cos(angle);
      final y = center.dy + (radius * val) * math.sin(angle);

      if (i == 0) polyPath.moveTo(x, y); else polyPath.lineTo(x, y);
    }
    polyPath.close();

    canvas.drawPath(polyPath, fillPaint);
    canvas.drawPath(polyPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _KinBondRadarPainter oldDelegate) => true;
}
