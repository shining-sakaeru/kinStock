import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
              // Row 1: Rank Badge + Stock Name + Ticker + Role Tier Badge + Factor Grade + Kin-Score
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

                  // Stock Name & Ticker (Clickable to pivot)
                  GestureDetector(
                    onTap: () => onPivotToStock(stockCode, stockName),
                    child: Row(
                      children: [
                        Text(
                          stockName,
                          style: const TextStyle(
                            color: Color(0xFFF8FAFC),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          stockCode,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Role Tier Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Text(
                      roleTierLabel,
                      style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Factor Grade Badge (A+, A, B)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: factorGrade.contains('A')
                          ? const Color(0xFF10B981).withOpacity(0.2)
                          : const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: factorGrade.contains('A') ? const Color(0xFF10B981) : const Color(0xFF64748B),
                      ),
                    ),
                    child: Text(
                      '등급 $factorGrade',
                      style: TextStyle(
                        color: factorGrade.contains('A') ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
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
              const SizedBox(height: 8),

              // Row 3: Causal Equation Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.equal_circle_fill, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '인과 방정식: $causalEquation',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      convictionLabel,
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Row 4: Trading Metrics & Why Trigger Link
              Row(
                children: [
                  Text(
                    degreeLabel,
                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 10),
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
