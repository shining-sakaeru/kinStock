import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum PerspectiveMode {
  comprehensive,   // 종합 Kin-Score
  alumniFocused,   // 학연 집중 모드
  legalElite,      // 법조/정치 카르텔 모드
  regionalTies,    // 지연/지역연고 모드
  chaerokNetwork,  // 대기업/재계 한솥밥 모드
}

class MultiPerspectiveSelector extends StatelessWidget {
  final PerspectiveMode currentPerspective;
  final int? selectedSeniorityGap;
  final Function(PerspectiveMode mode) onPerspectiveChanged;
  final Function(int? gap) onSeniorityGapChanged;

  const MultiPerspectiveSelector({
    super.key,
    required this.currentPerspective,
    this.selectedSeniorityGap,
    required this.onPerspectiveChanged,
    required this.onSeniorityGapChanged,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Perspective Preset Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(CupertinoIcons.slider_horizontal_below_rectangle, size: 14, color: Color(0xFF38BDF8)),
                const SizedBox(width: 8),
                const Text(
                  '분석 관점:',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                _buildPerspectiveChip(PerspectiveMode.comprehensive, '🌐 종합 Kin-Score', const Color(0xFF38BDF8)),
                const SizedBox(width: 6),
                _buildPerspectiveChip(PerspectiveMode.alumniFocused, '🎓 학연 집중 (70%)', const Color(0xFF10B981)),
                const SizedBox(width: 6),
                _buildPerspectiveChip(PerspectiveMode.legalElite, '⚖️ 법조·고시 기수 (75%)', const Color(0xFFA855F7)),
                const SizedBox(width: 6),
                _buildPerspectiveChip(PerspectiveMode.regionalTies, '🏠 지연·지역연고 (60%)', const Color(0xFFF97316)),
                const SizedBox(width: 6),
                _buildPerspectiveChip(PerspectiveMode.chaerokNetwork, '🏢 재계·대기업 (70%)', const Color(0xFF06B6D4)),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Row 2: Seniority Gap Tolerance Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(CupertinoIcons.time, size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                const Text(
                  '선후배 허용:',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                _buildGapChip(null, '전체 동문'),
                const SizedBox(width: 5),
                _buildGapChip(0, '동기만 (0년)'),
                const SizedBox(width: 5),
                _buildGapChip(3, '직속 (±3년)'),
                const SizedBox(width: 5),
                _buildGapChip(5, '±5년 이내'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerspectiveChip(PerspectiveMode mode, String label, Color color) {
    final isSelected = currentPerspective == mode;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onPerspectiveChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.18) : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : const Color(0xFF334155),
              width: isSelected ? 1.4 : 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : const Color(0xFF94A3B8),
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGapChip(int? gap, String label) {
    final isSelected = selectedSeniorityGap == gap;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onSeniorityGapChanged(gap),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF38BDF8).withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155),
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
