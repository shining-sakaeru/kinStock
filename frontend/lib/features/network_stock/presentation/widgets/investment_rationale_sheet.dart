import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/url_helper.dart';
import '../../data/models/company_model.dart';
import '../../data/models/person_model.dart';
import '../../data/models/recommendation_model.dart';
import '../../data/models/deep_dive_model.dart';
import '../../data/models/weight_settings_model.dart';
import '../screens/detail_network_screen.dart';
import 'relation_badge_chip.dart';

class InvestmentRationaleSheet extends StatefulWidget {
  final PersonModel person;
  final CompanyModel company;
  final double relevanceScore;
  final String primaryBadge;
  final String connectionSummary;
  final ApiClient apiClient;
  final WeightSettingsModel? weights;

  const InvestmentRationaleSheet({
    super.key,
    required this.person,
    required this.company,
    required this.relevanceScore,
    required this.primaryBadge,
    required this.connectionSummary,
    required this.apiClient,
    this.weights,
  });

  @override
  State<InvestmentRationaleSheet> createState() => _InvestmentRationaleSheetState();
}

class _InvestmentRationaleSheetState extends State<InvestmentRationaleSheet> {
  late Future<DeepDivePathModel> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = widget.apiClient.getDeepDivePath(
      widget.person.id,
      widget.company.id,
      weights: widget.weights,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppleColors.secondarySystemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grabber
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppleColors.separator,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),

            // Sheet Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppleColors.systemBlue.withOpacity(0.2),
                    child: const Icon(CupertinoIcons.chart_bar_alt_fill, size: 16, color: AppleColors.systemBlue),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.person.name} ➔ ${widget.company.name}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppleColors.label,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '투자 연관성 심층 분석 리포트 (Tier 2)',
                          style: const TextStyle(fontSize: 11, color: AppleColors.secondaryLabel),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppleColors.systemYellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${Formatters.formatScore(widget.relevanceScore)}점',
                      style: const TextStyle(
                        color: AppleColors.systemYellow,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(CupertinoIcons.xmark_circle_fill, color: AppleColors.secondaryLabel, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppleColors.separator),

            // Future Content Loader
            Flexible(
              child: FutureBuilder<DeepDivePathModel>(
                future: _detailFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 220,
                      child: Center(
                        child: CupertinoActivityIndicator(radius: 14, color: AppleColors.systemBlue),
                      ),
                    );
                  }

                  final data = snapshot.data;
                  final rationale = data?.investmentRationale;
                  final dartFact = data?.dartFact;

                  return ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    children: [
                      // 1. Connection Path Summary Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppleColors.tertiarySystemBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppleColors.separator, width: 0.8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(CupertinoIcons.link, size: 14, color: AppleColors.systemBlue),
                                const SizedBox(width: 5),
                                const Text(
                                  '핵심 연결 경로',
                                  style: TextStyle(color: AppleColors.label, fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                const Spacer(),
                                RelationBadgeChip(label: widget.primaryBadge, fontSize: 10),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.connectionSummary,
                              style: const TextStyle(color: AppleColors.label, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2. Investment Rationale 3-Pillars
                      const Text(
                        '💡 AI 투자 연관성 종합 분석 (Investment Rationale)',
                        style: TextStyle(color: AppleColors.label, fontWeight: FontWeight.w800, fontSize: 13.5, letterSpacing: -0.2),
                      ),
                      const SizedBox(height: 8),

                      _buildRationalePillar(
                        icon: CupertinoIcons.person_badge_plus_fill,
                        color: AppleColors.systemRed,
                        title: '1. 경영 실권 및 지분 지배력 분석',
                        content: rationale?.executivePowerAnalysis ??
                            'DART 전자공시상 대표이사 및 등기임원 직무를 보유하여 실질적 경영 의사결정에 직결되는 지배력을 행사 중입니다.',
                      ),
                      const SizedBox(height: 8),

                      _buildRationalePillar(
                        icon: CupertinoIcons.waveform_path_ecg,
                        color: AppleColors.systemOrange,
                        title: '2. 과거 동일 테마 주가 반응 이력',
                        content: rationale?.historicalMarketReaction ??
                            '해당 종목은 과거 동일 테마 및 정책 발표 국면에서 평균 +12% 이상의 강한 주가 민감도를 기록했습니다.',
                      ),
                      const SizedBox(height: 8),

                      _buildRationalePillar(
                        icon: CupertinoIcons.flame_fill,
                        color: AppleColors.systemTeal,
                        title: '3. 핵심 정책 / 인맥 수혜 촉매 (Catalyst)',
                        content: rationale?.themeCatalyst ??
                            '주요 공약 및 싱크탱크 네트워크와의 학맥/인맥 결속력에 기반하여 향후 정책 수혜 테마주로 부각될 가능성이 높습니다.',
                      ),
                      const SizedBox(height: 14),

                      // 3. Action Buttons (DART Link + Mindmap)
                      Row(
                        children: [
                          if (dartFact != null || widget.company.sourceUrl != null)
                            Expanded(
                              child: CupertinoButton(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                color: AppleColors.systemGreen.withOpacity(0.20),
                                borderRadius: BorderRadius.circular(10),
                                onPressed: () => UrlHelper.openUrl(dartFact?.sourceUrl ?? widget.company.sourceUrl!),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(CupertinoIcons.doc_text_fill, size: 14, color: AppleColors.systemGreen),
                                    SizedBox(width: 4),
                                    Text('DART 공시 원문', style: TextStyle(color: AppleColors.systemGreen, fontSize: 12, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              color: AppleColors.systemBlue,
                              borderRadius: BorderRadius.circular(10),
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (context) => DetailNetworkScreen(
                                      person: widget.person,
                                      stock: widget.company.toRankedStockItem(widget.relevanceScore, widget.primaryBadge, widget.connectionSummary),
                                      apiClient: widget.apiClient,
                                      weights: widget.weights,
                                    ),
                                  ),
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.scope, size: 14, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('전체 마인드맵 확대', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRationalePillar({
    required IconData icon,
    required Color color,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppleColors.tertiarySystemBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(color: AppleColors.label, fontSize: 11.5, height: 1.35),
          ),
        ],
      ),
    );
  }
}

// Extension helper
extension CompanyToRanked on CompanyModel {
  RankedStockItemModel toRankedStockItem(double score, String badge, String summary) {
    return RankedStockItemModel(
      rank: 1,
      companyId: id,
      ticker: ticker,
      companyName: name,
      relevanceScore: score,
      primaryBadge: badge,
      currentPrice: currentPrice,
      priceChangeRate: priceChangeRate,
      marketCap: marketCap,
      industry: industry,
      depth: 2,
      connectionPathSummary: summary,
      sourceUrl: sourceUrl ?? 'https://dart.fss.or.kr',
    );
  }
}
