import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ThemeStockRankCard extends StatelessWidget {
  final int rank;
  final String ticker;
  final String companyName;
  final String industry;
  final double kinScore;
  final String themeTierLabel;
  final String depth1Hook;
  final String marketCap;
  final int currentPrice;
  final double priceChangeRate;
  final VoidCallback onTap;
  final Function(String ticker, String companyName) onPivotToStock;

  const ThemeStockRankCard({
    super.key,
    required this.rank,
    required this.ticker,
    required this.companyName,
    required this.industry,
    required this.kinScore,
    required this.themeTierLabel,
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
          padding: const EdgeInsets.all(16),
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
              // Row 1: Rank Badge + Company Name + Ticker + Tier Badge + Kin-Score
              Row(
                children: [
                  // Rank Circle Badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isTop1
                          ? const Color(0xFFF59E0B)
                          : (isTop3 ? const Color(0xFF38BDF8) : const Color(0xFF334155)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: isTop1 || isTop3 ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Company Name & Ticker (Clickable to pivot)
                  GestureDetector(
                    onTap: () => onPivotToStock(ticker, companyName),
                    child: Row(
                      children: [
                        Text(
                          companyName,
                          style: const TextStyle(
                            color: Color(0xFFF8FAFC),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ticker,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Theme Tier Label Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Text(
                      themeTierLabel,
                      style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),

                  const Spacer(),

                  // Kin-Score Score Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF38BDF8)),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.bolt_fill, size: 12, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 4),
                        Text(
                          'Kin-Score ${kinScore.toStringAsFixed(1)}점',
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Row 2: Depth 1 Hook (One-line reason to buy)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.lightbulb_fill, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        depth1Hook,
                        style: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Row 3: Trading Metrics & Why Button
              Row(
                children: [
                  Text(
                    '시총 $marketCap',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${currentPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원',
                    style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${isPositive ? '+' : ''}${priceChangeRate.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: isPositive ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  // Why Inspector Trigger Link
                  Row(
                    children: const [
                      Text(
                        '3단계 인과 근거(Why) 확인',
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(CupertinoIcons.chevron_right, size: 12, color: Color(0xFF38BDF8)),
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
