import 'dart:html' as html;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ThreeDepthWhyDrawer extends StatelessWidget {
  final Map<String, dynamic> stockData;
  final VoidCallback onClose;
  final Function(String nodeId, String nodeName) onNodePivot;

  const ThreeDepthWhyDrawer({
    super.key,
    required this.stockData,
    required this.onClose,
    required this.onNodePivot,
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
    final companyName = stockData['company_name'] as String? ?? '종목명';
    final ticker = stockData['ticker'] as String? ?? '';
    final kinScore = (stockData['kin_score'] as num?)?.toDouble() ?? 90.0;
    final depth1Hook = stockData['depth1_hook'] as String? ?? '';
    final chain = stockData['depth2_causal_chain'] as Map<String, dynamic>? ?? {};
    final evidence = stockData['depth3_evidence'] as Map<String, dynamic>? ?? {};
    final metrics = stockData['trading_metrics'] as Map<String, dynamic>? ?? {};

    return Container(
      width: 420,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B), // Slate Surface
        border: Border(left: BorderSide(color: Color(0xFF334155), width: 1)),
      ),
      child: Column(
        children: [
          // 1. Header with Close Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              border: Border(bottom: BorderSide(color: Color(0xFF334155))),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.lightbulb_fill, size: 20, color: Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$companyName ($ticker)',
                        style: const TextStyle(
                          color: Color(0xFFF8FAFC),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        '3-Depth 투자 인과 근거 (Why Engine)',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF38BDF8)),
                  ),
                  child: Text(
                    'Kin-Score ${kinScore.toStringAsFixed(1)}점',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 20, color: Color(0xFF64748B)),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // 2. Scrollable Body
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Depth 1: One-line Hook Box
                  _buildSectionHeader('Depth 1: 핵심 인과 요약 (One-Line Hook)', CupertinoIcons.quote_bubble_fill),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
                    ),
                    child: Text(
                      depth1Hook,
                      style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Depth 2: 3-Step Causal Path Chain
                  _buildSectionHeader('Depth 2: 3단계 인과 사슬 (Causal Path Chain)', CupertinoIcons.arrow_branch),
                  _buildCausalChainDiagram(chain),
                  const SizedBox(height: 20),

                  // Depth 3: DART Audit Fact & Evidence
                  _buildSectionHeader('Depth 3: DART 공시 팩트 검증 (Tier 1 Evidence)', CupertinoIcons.checkmark_seal_fill),
                  _buildAuditFactBox(evidence),
                  const SizedBox(height: 20),

                  // Market Trading Metrics Box
                  _buildSectionHeader('테마 수급 및 매매 지표', CupertinoIcons.chart_bar_alt_fill),
                  _buildTradingMetricsBox(metrics),
                  const SizedBox(height: 16),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(CupertinoIcons.scope, size: 16),
                      label: Text(
                        '🎯 $companyName 중심으로 네트워크 탐색 (Pivot)',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      onPressed: () => onNodePivot(ticker, companyName),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF38BDF8)),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCausalChainDiagram(Map<String, dynamic> chain) {
    final p1 = chain['source_person'] as Map<String, dynamic>? ?? {};
    final edge1 = chain['p2p_edge'] as Map<String, dynamic>? ?? {};
    final p2 = chain['intermediary_person'] as Map<String, dynamic>? ?? {};
    final edge2 = chain['p2c_edge'] as Map<String, dynamic>? ?? {};
    final c = chain['target_company'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          // Step 1: Center Person
          _buildChainNodeCard(
            title: p1['name'] as String? ?? '중심 인물',
            subtitle: p1['role_or_title'] as String? ?? '',
            isPerson: true,
            nodeId: p1['id'] as String? ?? '',
          ),

          // Edge 1 (P2P)
          _buildChainConnector(
            label: edge1['relation_label'] as String? ?? '동문/인맥 연계',
            badge: edge1['badge'] as String? ?? '인맥 시냅스',
          ),

          // Step 2: Intermediary CEO / Shareholder
          _buildChainNodeCard(
            title: p2['name'] as String? ?? '대표이사 / 대주주',
            subtitle: p2['role_or_title'] as String? ?? '',
            isPerson: true,
            nodeId: p2['id'] as String? ?? '',
          ),

          // Edge 2 (P2C)
          _buildChainConnector(
            label: edge2['relation_label'] as String? ?? '최대주주 지분 보유 및 경영 총괄',
            badge: edge2['badge'] as String? ?? 'DART 지배구조',
          ),

          // Step 3: Target Company
          _buildChainNodeCard(
            title: c['name'] as String? ?? '타겟 상장사',
            subtitle: c['extra_info'] as String? ?? '',
            isPerson: false,
            nodeId: c['id'] as String? ?? '',
          ),
        ],
      ),
    );
  }

  Widget _buildChainNodeCard({
    required String title,
    required String subtitle,
    required bool isPerson,
    required String nodeId,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onNodePivot(nodeId, title),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isPerson ? const Color(0xFF818CF8) : const Color(0xFF38BDF8)),
          ),
          child: Row(
            children: [
              Icon(
                isPerson ? CupertinoIcons.person_crop_circle_fill : CupertinoIcons.building_2_fill,
                color: isPerson ? const Color(0xFF818CF8) : const Color(0xFF38BDF8),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.scope, size: 12, color: Color(0xFF38BDF8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChainConnector({required String label, required String badge}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Container(width: 1.5, height: 10, color: const Color(0xFF38BDF8)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
            ),
            child: Text(
              '$badge: $label',
              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
          Container(width: 1.5, height: 10, color: const Color(0xFF38BDF8)),
          const Icon(CupertinoIcons.chevron_down, size: 10, color: Color(0xFF38BDF8)),
        ],
      ),
    );
  }

  Widget _buildAuditFactBox(Map<String, dynamic> evidence) {
    final title = evidence['dart_filing_title'] as String? ?? 'DART 사업보고서';
    final rcpNo = evidence['rcp_no'] as String? ?? '20240321001201';
    final fact = evidence['verified_fact'] as String? ?? '';
    final url = evidence['dart_url'] as String? ?? 'https://dart.fss.or.kr';
    final track = evidence['market_track_record'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
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
                child: const Text('🟢 [TIER 1] 공시 원문 팩트', style: TextStyle(color: Color(0xFF10B981), fontSize: 10.5, fontWeight: FontWeight.w800)),
              ),
              const Spacer(),
              Text('접수번호: $rcpNo', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 12.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(fact, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.3)),
          if (track.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.chart_bar_fill, size: 12, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '시장 이력: $track',
                      style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // DART Outlink Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF10B981),
                side: const BorderSide(color: Color(0xFF10B981)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              icon: const Icon(CupertinoIcons.arrow_up_right_square, size: 13),
              label: const Text('DART 공시 원문 확인하기 ↗', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
              onPressed: () => _launchUrl(url),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradingMetricsBox(Map<String, dynamic> metrics) {
    final cap = metrics['market_cap_str'] as String? ?? '1,500억';
    final stake = (metrics['major_shareholder_ratio'] as num?)?.toDouble() ?? 26.4;
    final floatRatio = (metrics['floating_ratio'] as num?)?.toDouble() ?? 64.8;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricCol('시가총액', cap),
          Container(width: 1, height: 24, color: const Color(0xFF334155)),
          _buildMetricCol('최대주주 지분', '$stake%'),
          Container(width: 1, height: 24, color: const Color(0xFF334155)),
          _buildMetricCol('유통주식비율', '$floatRatio%'),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 12.5, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
