import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/company_model.dart';
import '../../data/models/micro_graph_model.dart';
import '../../data/models/person_model.dart';

class MicroRadialGraphView extends StatefulWidget {
  final PersonModel? centerPerson;
  final CompanyModel? centerCompany;
  final List<RadialNodeModel> radialNodes;
  final Function(RadialNodeModel)? onNodeTap;

  const MicroRadialGraphView({
    super.key,
    this.centerPerson,
    this.centerCompany,
    required this.radialNodes,
    this.onNodeTap,
  });

  @override
  State<MicroRadialGraphView> createState() => _MicroRadialGraphViewState();
}

class _MicroRadialGraphViewState extends State<MicroRadialGraphView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final center = Offset(w / 2, h / 2);
        
        // Ensure healthy radius that fits both width and height without colliding
        final radius = math.max(48.0, math.min(w * 0.38, h * 0.42));

        final nodeCount = widget.radialNodes.length;
        final List<Offset> positions = [];

        for (int i = 0; i < nodeCount; i++) {
          final angle = (2 * math.pi / nodeCount) * i - (math.pi / 2);
          final x = center.dx + radius * math.cos(angle);
          final y = center.dy + radius * math.sin(angle);
          positions.add(Offset(x, y));
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Radar background with canvas painter
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(w, h),
                  painter: _AppleRadialGraphPainter(
                    center: center,
                    radius: radius,
                    nodePositions: positions,
                    weights: widget.radialNodes.map((n) => n.weight).toList(),
                    pulseValue: _animController.value,
                  ),
                );
              },
            ),

            // 2. Satellite Nodes (Compact Apple Capsules)
            for (int i = 0; i < nodeCount; i++)
              Positioned(
                left: positions[i].dx - 44,
                top: positions[i].dy - 16,
                child: _buildCompactSatelliteNode(widget.radialNodes[i]),
              ),

            // 3. Center Node (Minimalist Apple Icon Circle)
            Positioned(
              left: center.dx - 26,
              top: center.dy - 26,
              child: _buildCompactCenterNode(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactCenterNode() {
    final isCompany = widget.centerCompany != null;
    final name = widget.centerPerson?.name ?? widget.centerCompany?.name ?? '중심';
    final initial = name.isNotEmpty ? name.substring(0, 1) : 'K';
    final accentColor = isCompany ? AppleColors.systemOrange : AppleColors.systemBlue;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppleColors.secondarySystemBackground,
        shape: BoxShape.circle,
        border: Border.all(color: accentColor, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            initial,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
          Text(
            name,
            style: const TextStyle(
              color: AppleColors.label,
              fontWeight: FontWeight.w600,
              fontSize: 9,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSatelliteNode(RadialNodeModel node) {
    final isCompany = node.nodeType == 'COMPANY';
    final badgeColor = isCompany ? AppleColors.systemOrange : AppleColors.systemBlue;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => widget.onNodeTap?.call(node),
      child: Container(
        width: 88,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppleColors.secondarySystemBackground.withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppleColors.separator,
            width: 0.8,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x30000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              node.nodeName,
              style: const TextStyle(
                color: AppleColors.label,
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${node.relationBadge} · ${(node.weight * 100).toInt()}%',
              style: TextStyle(
                color: badgeColor,
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppleRadialGraphPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final List<Offset> nodePositions;
  final List<double> weights;
  final double pulseValue;

  _AppleRadialGraphPainter({
    required this.center,
    required this.radius,
    required this.nodePositions,
    required this.weights,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Hairline radar circles
    final ringPaint = Paint()
      ..color = AppleColors.separator.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    canvas.drawCircle(center, radius * 0.5, ringPaint);
    canvas.drawCircle(center, radius, ringPaint);

    // 2. Connectors
    for (int i = 0; i < nodePositions.length; i++) {
      final target = nodePositions[i];
      final weight = i < weights.length ? weights[i] : 0.5;

      final linePaint = Paint()
        ..color = AppleColors.systemBlue.withOpacity(0.2 + weight * 0.3)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(center, target, linePaint);

      // Particle
      final particleProgress = (pulseValue + (i * 0.25)) % 1.0;
      final particlePos = Offset.lerp(center, target, particleProgress)!;

      final particlePaint = Paint()
        ..color = AppleColors.systemBlue.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(particlePos, 2.0, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AppleRadialGraphPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.center != center ||
        oldDelegate.nodePositions != nodePositions;
  }
}
