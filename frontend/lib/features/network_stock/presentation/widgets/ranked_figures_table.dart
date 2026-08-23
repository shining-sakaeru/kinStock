import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/url_helper.dart';
import '../../data/models/stock_related_figures_model.dart';
import 'relation_badge_chip.dart';

class RankedFiguresTable extends StatefulWidget {
  final List<RankedFigureItemModel> figures;
  final Function(RankedFigureItemModel) onFigureTap;

  const RankedFiguresTable({
    super.key,
    required this.figures,
    required this.onFigureTap,
  });

  @override
  State<RankedFiguresTable> createState() => _RankedFiguresTableState();
}

class _RankedFiguresTableState extends State<RankedFiguresTable> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredList = widget.figures.where((item) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.name.toLowerCase().contains(q) ||
          item.roleTitle.toLowerCase().contains(q) ||
          item.themeTitle.toLowerCase().contains(q) ||
          item.connectionPathSummary.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // 1. Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Icon(CupertinoIcons.person_2_fill, color: AppleColors.systemBlue, size: 16),
              const SizedBox(width: 6),
              const Text(
                '연관 인물 및 테마 역추적',
                style: TextStyle(
                  color: AppleColors.label,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppleColors.systemBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.figures.length}명',
                  style: const TextStyle(
                    color: AppleColors.systemBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 130,
                height: 28,
                child: CupertinoSearchTextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  placeholder: '인물/직책 필터',
                  placeholderStyle: const TextStyle(fontSize: 11, color: AppleColors.tertiaryLabel),
                  style: const TextStyle(fontSize: 11.5, color: AppleColors.label),
                  backgroundColor: AppleColors.tertiarySystemBackground,
                  borderRadius: BorderRadius.circular(8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: AppleColors.separator),

        // 2. Table Rows List (Apple HIG Inset List Style)
        Expanded(
          child: filteredList.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      '매칭된 연관 인물이 없습니다.',
                      style: TextStyle(color: AppleColors.tertiaryLabel, fontSize: 13),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: filteredList.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    indent: 48,
                    endIndent: 16,
                    color: AppleColors.separator,
                  ),
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    return _buildAppleFigureRow(context, item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAppleFigureRow(BuildContext context, RankedFigureItemModel item) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => widget.onFigureTap(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Rank Numeral
            SizedBox(
              width: 24,
              child: Text(
                '${item.rank}',
                style: TextStyle(
                  color: item.rank <= 3 ? AppleColors.label : AppleColors.tertiaryLabel,
                  fontWeight: item.rank <= 3 ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 6),

            // 2. Left Column: Figure Name, Theme Pill, Role
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            color: AppleColors.label,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppleColors.systemBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.themeTitle,
                          style: const TextStyle(
                            color: AppleColors.systemBlue,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.roleTitle,
                    style: const TextStyle(
                      color: AppleColors.secondaryLabel,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // 3. Right Column: Primary Badge + Score Pill
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.primaryBadge,
                  style: const TextStyle(
                    color: AppleColors.label,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppleColors.systemBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '연관 ${Formatters.formatScore(item.relevanceScore)}점',
                    style: const TextStyle(
                      color: AppleColors.systemBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
