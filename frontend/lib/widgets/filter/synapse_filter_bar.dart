import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum SynapseFilterType {
  all,
  stake,      // 👑 지분/오너
  executive,  // 👔 임원/재직
  alumni,     // 🎓 학연
  hometown,   // 🏠 지연
  colleague,  // 🤝 전직 동료
}

class SynapseFilterBar extends StatelessWidget {
  final Set<SynapseFilterType> selectedFilters;
  final Function(SynapseFilterType type) onFilterToggled;

  const SynapseFilterBar({
    super.key,
    required this.selectedFilters,
    required this.onFilterToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B), // Slate Surface
        border: Border(
          bottom: BorderSide(color: Color(0xFF334155), width: 0.8),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip(
              type: SynapseFilterType.all,
              label: '전체',
              icon: CupertinoIcons.circle_grid_hex_fill,
              activeColor: const Color(0xFF38BDF8),
            ),
            const SizedBox(width: 8),
            _buildChip(
              type: SynapseFilterType.stake,
              label: '👑 지분/오너',
              activeColor: const Color(0xFFF59E0B),
            ),
            const SizedBox(width: 8),
            _buildChip(
              type: SynapseFilterType.executive,
              label: '👔 임원/재직',
              activeColor: const Color(0xFF818CF8),
            ),
            const SizedBox(width: 8),
            _buildChip(
              type: SynapseFilterType.alumni,
              label: '🎓 학연',
              activeColor: const Color(0xFF10B981),
            ),
            const SizedBox(width: 8),
            _buildChip(
              type: SynapseFilterType.hometown,
              label: '🏠 지연',
              activeColor: const Color(0xFFF97316),
            ),
            const SizedBox(width: 8),
            _buildChip(
              type: SynapseFilterType.colleague,
              label: '🤝 전직 동료',
              activeColor: const Color(0xFF06B6D4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required SynapseFilterType type,
    required String label,
    IconData? icon,
    required Color activeColor,
  }) {
    final isSelected = selectedFilters.contains(type);

    return InkWell(
      onTap: () => onFilterToggled(type),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.18) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFF334155),
            width: isSelected ? 1.4 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.25),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: isSelected ? activeColor : const Color(0xFF94A3B8)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : const Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
