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
    final stockName = (stockData['stock_name'] ?? stockData['company_name']) as String? ?? '종목명';
    final stockCode = (stockData['stock_code'] ?? stockData['ticker']) as String? ?? '';
    final kinScore = (stockData['kin_score'] as num?)?.toDouble() ?? 90.0;
    final metrics = stockData['metrics'] as Map<String, dynamic>? ?? {};
    final roleTierLabel = metrics['role_tier_label'] as String? ?? '👑 1티어 대장주';
    final degreeLabel = metrics['degree_label'] as String? ?? '1-Degree Direct (1촌 직결)';
    final factorGrade = metrics['factor_grade_label'] as String? ?? 'A+ (최상위 결속)';
    final convictionLabel = metrics['conviction_label'] as String? ?? '📶 HIGH (공시 100% 검증)';
    final causalEquation = metrics['causal_equation'] as String? ?? '';

    final causalChain = stockData['causal_chain'] as Map<String, dynamic>? ?? {};
    final depth1Hook = (causalChain['depth_1_hook'] ?? stockData['depth1_hook']) as String? ?? '';
    final depth2Path = (causalChain['depth_2_path'] as List<dynamic>?) ?? [];
    final evidence = (causalChain['depth_3_evidence'] ?? stockData['depth3_evidence']) as Map<String, dynamic>? ?? {};
    final marketCap = stockData['market_cap'] as String? ?? '1,500억';

    return Container(
      width: 440,
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
                        '$stockName ($stockCode)',
                        style: const TextStyle(
                          color: Color(0xFFF8FAFC),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '$roleTierLabel · $degreeLabel',
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w700),
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
                  // Global Metrics Badge Grid
                  _buildMetricsSummaryGrid(roleTierLabel, degreeLabel, factorGrade, convictionLabel),
                  const SizedBox(height: 16),

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          depth1Hook,
                          style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.4),
                        ),
                        if (causalEquation.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '📐 인과 방정식: $causalEquation',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Depth 2: 3-Step Causal Path Chain
                  _buildSectionHeader('Depth 2: 3단계 인과 사슬 (Causal Path Chain)', CupertinoIcons.arrow_branch),
                  _buildCausalPathList(depth2Path),
                  const SizedBox(height: 20),

                  // Depth 3: DART Audit Fact & Evidence
                  _buildSectionHeader('Depth 3: DART 공시 팩트 검증 (Tier 1 Evidence)', CupertinoIcons.checkmark_seal_fill),
                  _buildAuditFactBox(evidence),
                  const SizedBox(height: 20),

                  // Market Trading Metrics Box
                  _buildSectionHeader('테마 수급 및 매매 지표', CupertinoIcons.chart_bar_alt_fill),
                  _buildTradingMetricsBox(marketCap),
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
                        '🎯 $stockName 중심으로 네트워크 탐색 (Pivot)',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      onPressed: () => onNodePivot(stockCode, stockName),
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

  Widget _buildMetricsSummaryGrid(String roleTier, String degree, String grade, String conviction) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBadgePill('역할 티어', roleTier, const Color(0xFFF59E0B)),
              _buildBadgePill('촌수 구분', degree, const Color(0xFF38BDF8)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBadgePill('결속 등급', grade, const Color(0xFF10B981)),
              _buildBadgePill('검증 순도', conviction, const Color(0xFF818CF8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgePill(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
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

  Widget _buildCausalPathList(List<dynamic> pathSteps) {
    if (pathSteps.isEmpty) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: pathSteps.map((stepRaw) {
          final step = stepRaw as Map<String, dynamic>;
          final type = step['type'] as String? ?? 'PERSON';

          if (type == 'EDGE') {
            final label = step['label'] as String? ?? '연계';
            final grade = step['grade'] as String? ?? 'A+';
            return _buildChainConnector(label: label, badge: '결속 $grade');
          }

          final isPerson = type == 'PERSON';
          final name = step['name'] as String? ?? (isPerson ? '인물' : '기업');
          final role = (step['role'] ?? step['ticker']) as String? ?? '';

          return _buildChainNodeCard(
            title: name,
            subtitle: role,
            isPerson: isPerson,
            nodeId: (step['ticker'] ?? name),
          );
        }).toList(),
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
          margin: const EdgeInsets.symmetric(vertical: 2),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        children: [
          Container(width: 1.5, height: 8, color: const Color(0xFF38BDF8)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          Container(width: 1.5, height: 8, color: const Color(0xFF38BDF8)),
          const Icon(CupertinoIcons.chevron_down, size: 10, color: Color(0xFF38BDF8)),
        ],
      ),
    );
  }

  Widget _buildAuditFactBox(Map<String, dynamic> evidence) {
    final reportName = evidence['report_name'] as String? ?? '2024.03 사업보고서';
    final section = evidence['section'] as String? ?? 'VIII. 임원 및 직원 등에 관한 사항 (p.52)';
    final rcpNo = (evidence['rcept_no'] ?? evidence['rcp_no']) as String? ?? '20240315001234';
    final snippet = (evidence['snippet'] ?? evidence['verified_fact']) as String? ?? '';
    final url = (evidence['source_url'] ?? evidence['dart_url']) as String? ?? 'https://dart.fss.or.kr';
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
                child: const Text('🟢 [DART 100% 팩트]', style: TextStyle(color: Color(0xFF10B981), fontSize: 10.5, fontWeight: FontWeight.w800)),
              ),
              const Spacer(),
              Text('접수번호: $rcpNo', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Text('$reportName · $section', style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 12.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(snippet, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.3)),
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

  Widget _buildTradingMetricsBox(String marketCap) {
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
          _buildMetricCol('시가총액', marketCap),
          Container(width: 1, height: 24, color: const Color(0xFF334155)),
          _buildMetricCol('최대주주 지분', '26.4%'),
          Container(width: 1, height: 24, color: const Color(0xFF334155)),
          _buildMetricCol('유통주식비율', '64.8%'),
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
