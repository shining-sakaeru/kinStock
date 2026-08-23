import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/url_helper.dart';
import '../../data/models/recommendation_model.dart';
import 'relation_badge_chip.dart';

class RankedStockTable extends StatefulWidget {
  final List<RankedStockItemModel> recommendations;
  final Function(RankedStockItemModel) onStockTap;

  const RankedStockTable({
    super.key,
    required this.recommendations,
    required this.onStockTap,
  });

  @override
  State<RankedStockTable> createState() => _RankedStockTableState();
}

class _RankedStockTableState extends State<RankedStockTable> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredList = widget.recommendations.where((item) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.companyName.toLowerCase().contains(q) ||
          item.ticker.contains(q) ||
          item.primaryBadge.toLowerCase().contains(q) ||
          (item.dartFact?.verifiedFact.toLowerCase().contains(q) ?? false);
    }).toList();

    return Column(
      children: [
        // 1. Header with iOS title and search box
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Icon(CupertinoIcons.checkmark_shield_fill, color: AppleColors.systemGreen, size: 16),
              const SizedBox(width: 6),
              const Text(
                'DART 공시 연관 수혜주',
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
                  '${widget.recommendations.length}개',
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
                  placeholder: '종목/공시 필터',
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

        // 2. Table Rows List (Apple Stocks Inset List Style)
        Expanded(
          child: filteredList.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      '매칭된 DART 공시 테마주가 없습니다.',
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
                    return _buildAppleStocksRow(context, item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAppleStocksRow(BuildContext context, RankedStockItemModel item) {
    final isPositive = item.priceChangeRate > 0;
    final isNegative = item.priceChangeRate < 0;
    final pillBgColor = isPositive
        ? const Color(0xFFE02020) // Apple Stocks Korea Red
        : isNegative
            ? const Color(0xFF007AFF) // Apple Blue
            : AppleColors.tertiarySystemBackground;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => widget.onStockTap(item),
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

            // 2. Left Column: Company Name, Ticker, Relation Chip, DART Tag
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.companyName,
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
                      const SizedBox(width: 5),
                      Text(
                        item.ticker,
                        style: const TextStyle(
                          color: AppleColors.tertiaryLabel,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.primaryBadge,
                          style: const TextStyle(
                            color: AppleColors.secondaryLabel,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.dartFact != null) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppleColors.systemGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'DART',
                            style: TextStyle(
                              color: AppleColors.systemGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // 3. Right Column (Apple Stocks Style): Price + Change Rate Pill + Score
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Formatters.formatCurrency(item.currentPrice),
                  style: const TextStyle(
                    color: AppleColors.label,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Relevance Score Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppleColors.systemBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${Formatters.formatScore(item.relevanceScore)}점',
                        style: const TextStyle(
                          color: AppleColors.systemBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Apple Stocks Change Pill
                    Container(
                      width: 64,
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      decoration: BoxDecoration(
                        color: pillBgColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        Formatters.formatChangeRate(item.priceChangeRate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
