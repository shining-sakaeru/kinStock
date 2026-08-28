import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/utils/url_launcher_helper.dart';

class ThemeStockRankCard extends StatelessWidget {
  final int rank;
  final String stockCode;
  final String stockName;
  final String industry;
  final double kinScore;
  final String roleTierLabel;
  final String degreeLabel;
  final String factorGrade;
  final String convictionLabel;
  final String causalEquation;
  final String depth1Hook;
  final String marketCap;
  final int currentPrice;
  final double priceChangeRate;
  final VoidCallback onTap;
  final Function(String ticker, String companyName) onPivotToStock;

  const ThemeStockRankCard({
    super.key,
    required this.rank,
    required this.stockCode,
    required this.stockName,
    required this.industry,
    required this.kinScore,
    required this.roleTierLabel,
    required this.degreeLabel,
    required this.factorGrade,
    required this.convictionLabel,
    required this.causalEquation,
    required this.depth1Hook,
    required this.marketCap,
    required this.currentPrice,
    required this.priceChangeRate,
    required this.onTap,
    required this.onPivotToStock,
  });

  @override
  Widget build(BuildContext context) {
    final isTop1 = rank == 1;
    final isTop3 = rank <= 3;
    final isPositive = priceChangeRate >= 0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B), // Slate Surface
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isTop1
                  ? const Color(0xFFF59E0B) // Amber for Rank 1
                  : (isTop3 ? const Color(0xFF38BDF8) : const Color(0xFF334155)),
              width: isTop1 ? 1.5 : 1.0,
            ),
            boxShadow: isTop1
                ? [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Rank Badge + Stock Name + Ticker + Role Tier Badge + Factor Grade + Kin-Score
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Rank Circle Badge
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isTop1
                              ? const Color(0xFFF59E0B)
                              : (isTop3 ? const Color(0xFF38BDF8) : const Color(0xFF334155)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$rank',
                          style: TextStyle(
                            color: isTop1 || isTop3 ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Stock Name & Ticker
                      GestureDetector(
                        onTap: () => onPivotToStock(stockCode, stockName),
                        child: Text(
                          stockName,
                          style: const TextStyle(
                            color: Color(0xFFF8FAFC),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        stockCode,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                      ),
                      const SizedBox(width: 6),

                      // Direct Naver Finance Outlink
                      GestureDetector(
                        onTap: () => UrlLauncherHelper.launch(UrlLauncherHelper.getStockUrl(stockCode)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF03C75A).withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('네이버증권 ↗', style: TextStyle(color: Color(0xFF03C75A), fontSize: 9.5, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Role Tier & Grade Badges
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: Text(
                          roleTierLabel,
                          style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 10.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: factorGrade.contains('A')
                              ? const Color(0xFF10B981).withOpacity(0.2)
                              : const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: factorGrade.contains('A') ? const Color(0xFF10B981) : const Color(0xFF64748B),
                          ),
                        ),
                        child: Text(
                          '등급 $factorGrade',
                          style: TextStyle(
                            color: factorGrade.contains('A') ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      // Kin-Score Score Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF38BDF8)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.bolt_fill, size: 11, color: Color(0xFF38BDF8)),
                            const SizedBox(width: 3),
                            Text(
                              'Kin-Score ${kinScore.toStringAsFixed(1)}점',
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: Depth 1 Hook (One-line reason to buy)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.lightbulb_fill, size: 13, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        depth1Hook,
                        style: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Row 3: Causal Equation Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.equal_circle_fill, size: 11, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          '인과 방정식: $causalEquation',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Text(
                      convictionLabel,
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 10.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Row 4: Trading Metrics & Why Trigger Link
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        degreeLabel,
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '시총 $marketCap',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${currentPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원',
                        style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? '+' : ''}${priceChangeRate.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: isPositive ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  // Why Inspector Trigger Link
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        '3단계 인과 근거(Why) 확인 ↗',
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(CupertinoIcons.chevron_right, size: 11, color: Color(0xFF38BDF8)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
