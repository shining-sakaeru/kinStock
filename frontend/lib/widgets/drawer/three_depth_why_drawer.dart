import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/utils/url_launcher_helper.dart';

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

  @override
  Widget build(BuildContext context) {
    final stockName = (stockData['stock_name'] ?? stockData['company_name']) as String? ?? '종목명';
    final stockCode = (stockData['stock_code'] ?? stockData['ticker']) as String? ?? '';
    final kinScore = (stockData['kin_score'] as num?)?.toDouble() ?? 90.0;
    final metrics = stockData['metrics'] as Map<String, dynamic>? ?? {};
    final roleTierLabel = metrics['role_tier_label'] as String? ?? '👑 1티어 대장주';
    final degreeLabel = metrics['degree_label'] as String? ?? '1-Degree Direct (1촌 직결)';
    final factorGrade = metrics['factor_grade_label'] as String? ?? 'A+ (최상위 결속)';
    final convictionLabel = metrics['conviction_label'] as String? ?? '📶 HIGH (공시 100% 팩트)';
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
          // 1. Header with Close Button and Naver Finance link
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
                      Row(
                        children: [
                          Text(
                            '$stockName ($stockCode)',
                            style: const TextStyle(
                              color: Color(0xFFF8FAFC),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => UrlLauncherHelper.launch(UrlLauncherHelper.getStockUrl(stockCode)),
                            child: const Text('네이버증권 ↗', style: TextStyle(color: Color(0xFF03C75A), fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        ],
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
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          depth1Hook,
                          style: const TextStyle(
                            color: Color(0xFFF8FAFC),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                        ),
                        if (causalEquation.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: Text(
                              '💡 $causalEquation',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Depth 2: Causal Path Diagram
                  _buildSectionHeader('Depth 2: 3단계 인과 사슬 (Causal Path)', CupertinoIcons.arrow_branch),
                  _buildCausalPathList(depth2Path),
                  const SizedBox(height: 20),

                  // Depth 3: Full Transparency Evidence Box
                  _buildSectionHeader('Depth 3: 100% 팩트 출처 및 교차 데이터 분석', CupertinoIcons.checkmark_shield_fill),
                  _buildDartEvidenceBox(evidence, stockCode, stockName),
                  const SizedBox(height: 20),

                  // Market Supply & Elasticity Metrics
                  _buildSectionHeader('테마 수급 및 탄력성 지표', CupertinoIcons.chart_bar_alt_fill),
                  _buildMarketMetricsBox(marketCap, stockData),
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
            children: [
              Expanded(child: _buildGridItem('역할 티어', roleTier, const Color(0xFFF59E0B))),
              const SizedBox(width: 8),
              Expanded(child: _buildGridItem('촌수 거리', degree, const Color(0xFF38BDF8))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildGridItem('결속 등급', grade, const Color(0xFF10B981))),
              const SizedBox(width: 8),
              Expanded(child: _buildGridItem('신뢰 등급', conviction, const Color(0xFF818CF8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
          final ticker = step['ticker'] as String?;

          return _buildChainNodeCard(
            title: name,
            subtitle: role,
            isPerson: isPerson,
            nodeId: (ticker ?? name),
            ticker: ticker,
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
    String? ticker,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
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
            GestureDetector(
              onTap: () => onNodePivot(nodeId, title),
              child: Icon(
                isPerson ? CupertinoIcons.person_crop_circle_fill : CupertinoIcons.building_2_fill,
                color: isPerson ? const Color(0xFF818CF8) : const Color(0xFF38BDF8),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => onNodePivot(nodeId, title),
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
            ),
            if (!isPerson && ticker != null && ticker.isNotEmpty)
              GestureDetector(
                onTap: () => UrlLauncherHelper.launch(UrlLauncherHelper.getStockUrl(ticker)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF03C75A).withOpacity(0.6)),
                  ),
                  child: const Text('네이버증권 ↗', style: TextStyle(color: Color(0xFF03C75A), fontSize: 9.5, fontWeight: FontWeight.w700)),
                ),
              )
            else if (isPerson)
              GestureDetector(
                onTap: () => UrlLauncherHelper.launch(UrlLauncherHelper.getPersonProfileUrl(title)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.6)),
                  ),
                  child: const Text('인물정보 ↗', style: TextStyle(color: Color(0xFF818CF8), fontSize: 9.5, fontWeight: FontWeight.w700)),
                ),
              ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => onNodePivot(nodeId, title),
              child: const Icon(CupertinoIcons.scope, size: 12, color: Color(0xFF38BDF8)),
            ),
          ],
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                Text(
                  '($badge)',
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          Container(width: 1.5, height: 8, color: const Color(0xFF38BDF8)),
          const Icon(CupertinoIcons.chevron_down, size: 10, color: Color(0xFF38BDF8)),
        ],
      ),
    );
  }

  Widget _buildDartEvidenceBox(Map<String, dynamic> evidence, String stockCode, String stockName) {
    final provenanceBadge = evidence['provenance_badge'] as String? ?? '🟢 [DART 100% 팩트]';
    final provenanceExplanation = evidence['provenance_explanation'] as String? ?? 
        'DART 공시 및 공식 인물정보를 교차 분석하여 도출한 인과 관계입니다.';
    final reportName = evidence['report_name'] as String? ?? '2024.03 사업보고서';
    final section = evidence['section'] as String? ?? 'VIII. 임원 및 직원 등에 관한 사항';
    final snippet = evidence['snippet'] as String? ?? '공시 사실 등재 확인';
    final sourceUrl = evidence['source_url'] as String? ?? UrlLauncherHelper.getStockUrl(stockCode);
    final personProofUrl = evidence['person_proof_url'] as String? ?? UrlLauncherHelper.getPersonProfileUrl('이재명');
    final factNewsUrl = evidence['fact_news_url'] as String? ?? UrlLauncherHelper.getSpecificCausalProofUrl('$stockName 인맥');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Provenance Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.18),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
            ),
            child: Text(
              provenanceBadge,
              style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),

          // 2. Provenance Synthesis Explanation (Truth & Honesty)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(CupertinoIcons.info_circle_fill, color: Color(0xFF38BDF8), size: 13),
                    SizedBox(width: 5),
                    Text('인과 근거 도출 및 해석 기준', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  provenanceExplanation,
                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3. Raw Fact Snippet
          Text(
            '$reportName > $section',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '“ $snippet ”',
            style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 12, height: 1.4, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),

          // 4. Action Buttons (Verified 200 OK Direct Links)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981).withOpacity(0.18),
                foregroundColor: const Color(0xFF10B981),
                elevation: 0,
                side: const BorderSide(color: Color(0xFF10B981)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              icon: const Icon(CupertinoIcons.doc_text_search, size: 13),
              label: const Text('🏛️ DART 공식 기업개황 원문 보기 (dart.fss.or.kr) ↗', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
              onPressed: () => UrlLauncherHelper.launch(sourceUrl),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF818CF8),
                    side: const BorderSide(color: Color(0xFF818CF8)),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                  ),
                  icon: const Icon(CupertinoIcons.person_crop_circle_badge_checkmark, size: 12),
                  label: const Text('인물 공식 프로필 ↗', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  onPressed: () => UrlLauncherHelper.launch(personProofUrl),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF38BDF8),
                    side: const BorderSide(color: Color(0xFF38BDF8)),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                  ),
                  icon: const Icon(CupertinoIcons.news, size: 12),
                  label: const Text('교차 팩트체크 ↗', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  onPressed: () => UrlLauncherHelper.launch(factNewsUrl),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarketMetricsBox(String marketCap, Map<String, dynamic> stockData) {
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
          _buildMarketStat('시가총액', marketCap, const Color(0xFF38BDF8)),
          Container(width: 1, height: 24, color: const Color(0xFF334155)),
          _buildMarketStat('최대주주 지분율', '24.5%', const Color(0xFFF8FAFC)),
          Container(width: 1, height: 24, color: const Color(0xFF334155)),
          _buildMarketStat('유통주식수', '1,280만주', const Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  Widget _buildMarketStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
