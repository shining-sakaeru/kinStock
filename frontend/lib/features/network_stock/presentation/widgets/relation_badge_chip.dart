import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class RelationBadgeChip extends StatelessWidget {
  final String label;
  final double fontSize;
  final EdgeInsets padding;

  const RelationBadgeChip({
    super.key,
    required this.label,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
  });

  @override
  Widget build(BuildContext context) {
    final color = AppleColors.getBadgeColor(label);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.7),
      ),
      child: Text(
        label.startsWith('[') ? label : '[$label]',
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
