import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DepthLevelSelector extends StatelessWidget {
  final int currentDepth;
  final int totalNodes;
  final Function(int newDepth) onDepthChanged;

  const DepthLevelSelector({
    super.key,
    required this.currentDepth,
    required this.totalNodes,
    required this.onDepthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.layers_alt_fill, size: 14, color: Color(0xFF38BDF8)),
          const SizedBox(width: 8),
          const Text(
            '계층 확장:',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),

          // Depth Segment Buttons
          _buildDepthButton(1, '1-Depth (직접 관계)', '직접 연결된 1차 임원 및 지분사'),
          const SizedBox(width: 6),
          _buildDepthButton(2, '2-Depth (2차 시냅스)', '동문·경력·지분을 공유하는 2차 연계망'),
          const SizedBox(width: 6),
          _buildDepthButton(3, '3-Depth (확장 네트워크)', '그룹사 및 인맥 전반의 3차 전체 관계망'),

          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Text(
              '표시 노드: $totalNodes개',
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepthButton(int depth, String label, String tooltip) {
    final isSelected = currentDepth == depth;

    return Tooltip(
      message: tooltip,
      textStyle: const TextStyle(fontSize: 11, color: Colors.white),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onDepthChanged(depth),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
