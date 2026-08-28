import 'dart:html' as html;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/models/event_poll_models.dart';

class EventStockImpactDrawer extends StatelessWidget {
  final EventStockImpactModel impactData;
  final VoidCallback onClose;
  final Function(String ticker, String companyName) onPivotToStock;

  const EventStockImpactDrawer({
    super.key,
    required this.impactData,
    required this.onClose,
    required this.onPivotToStock,
  });

  void _launchUrl(String? url) {
    if (url != null && url.isNotEmpty) {
      if (kIsWeb) {
        html.window.open(url, '_blank');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ev = impactData.event;
    final stocks = impactData.stocks;

    return Container(
      width: 440,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(left: BorderSide(color: Color(0xFF334155), width: 1)),
      ),
      child: Column(
        children: [
          // 1. Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              border: Border(bottom: BorderSide(color: Color(0xFF334155))),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.bolt_badge_a_fill, size: 20, color: Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ev.title,
                        style: const TextStyle(
                          color: Color(0xFFF8FAFC),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${ev.occurredAt} · ${ev.eventTypeLabel} (중대성 ${ev.significanceScore} / 5.0)',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 20, color: Color(0xFF64748B)),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // 2. Body
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Event Summary & Evidence Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.18),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                ev.evidenceTierBadge,
                                style: const TextStyle(color: Color(0xFF10B981), fontSize: 10.5, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              ev.sourceAgency,
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ev.summary,
                          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5, height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF38BDF8),
                              side: const BorderSide(color: Color(0xFF38BDF8)),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                            icon: const Icon(CupertinoIcons.link, size: 12),
                            label: const Text('공식 이벤트 원문 확인하기 ↗', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            onPressed: () => _launchUrl(ev.sourceUrl),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CAR Summary Metric Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCol('연관 종목 평균 D0', '+${impactData.avgD0Return.toStringAsFixed(1)}%', const Color(0xFFEF4444)),
                        Container(width: 1, height: 24, color: const Color(0xFF334155)),
                        _buildStatCol('평균 CAR[-3, +5]', '+${impactData.avgCarD5.toStringAsFixed(1)}%', const Color(0xFFF59E0B)),
                        Container(width: 1, height: 24, color: const Color(0xFF334155)),
                        _buildStatCol('반응 종목수', '${impactData.totalAffectedStocks}개', const Color(0xFF38BDF8)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section Title
                  Row(
                    children: const [
                      Icon(CupertinoIcons.chart_bar_square_fill, size: 14, color: Color(0xFF38BDF8)),
                      SizedBox(width: 6),
                      Text(
                        '이벤트 전후 테마주 주가 반응 (Event-Study Matrix)',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Affected Stocks List
                  ...stocks.map((stock) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${stock.companyName} (${stock.ticker})',
                                style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 13.5, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  stock.roleTierLabel,
                                  style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                stock.marketReactionGrade,
                                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11.5, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            stock.connectionHook,
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildPill('당일(D0)', '+${stock.d0Return.toStringAsFixed(1)}%', const Color(0xFFEF4444)),
                              const SizedBox(width: 6),
                              _buildPill('CAR 5일', '+${stock.carD5.toStringAsFixed(1)}%', const Color(0xFFF59E0B)),
                              const SizedBox(width: 6),
                              _buildPill('거래량 스파이크', '${stock.volumeSpikeRatio.toStringAsFixed(1)}x', const Color(0xFF38BDF8)),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => onPivotToStock(stock.ticker, stock.companyName),
                                child: Row(
                                  children: const [
                                    Text('피벗', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w700)),
                                    SizedBox(width: 2),
                                    Icon(CupertinoIcons.arrow_right, size: 10, color: Color(0xFF38BDF8)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text('$label $value', style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
    );
  }
}
