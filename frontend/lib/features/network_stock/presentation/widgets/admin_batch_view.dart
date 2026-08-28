import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/batch_progress_model.dart';
import 'apple_frosted_card.dart';

class AdminBatchView extends StatefulWidget {
  final ApiClient apiClient;

  const AdminBatchView({super.key, required this.apiClient});

  static void show(BuildContext context, ApiClient apiClient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdminBatchView(apiClient: apiClient),
    );
  }

  @override
  State<AdminBatchView> createState() => _AdminBatchViewState();
}

class _AdminBatchViewState extends State<AdminBatchView> {
  late Future<BatchProgressModel> _progressFuture;
  Map<String, dynamic>? _healthReport;
  Map<String, dynamic>? _searchTestReport;
  bool _isCheckingHealth = false;
  bool _isRunningSearchTest = false;
  bool _isTriggeringBatch = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchProgress();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) _fetchProgress();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _fetchProgress() {
    setState(() {
      _progressFuture = widget.apiClient.getBatchProgressStatus();
    });
  }

  Future<void> _triggerLiveBatch() async {
    setState(() => _isTriggeringBatch = true);
    try {
      await widget.apiClient.triggerBatchStep(count: 10);
      if (mounted) {
        _fetchProgress();
        setState(() => _isTriggeringBatch = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isTriggeringBatch = false);
    }
  }

  Future<void> _runHealthCheck() async {
    setState(() => _isCheckingHealth = true);
    try {
      final res = await widget.apiClient.runDbHealthCheck();
      setState(() {
        _healthReport = res;
        _isCheckingHealth = false;
      });
    } catch (e) {
      setState(() => _isCheckingHealth = false);
    }
  }

  Future<void> _runSearchTest() async {
    setState(() => _isRunningSearchTest = true);
    try {
      final res = await widget.apiClient.runSearchE2EVerify();
      setState(() {
        _searchTestReport = res;
        _isRunningSearchTest = false;
      });
    } catch (e) {
      setState(() => _isRunningSearchTest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppleColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle & Header
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppleColors.tertiaryLabel,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppleColors.systemBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(CupertinoIcons.chart_bar_square_fill, color: AppleColors.systemBlue, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '배치 모니터링 & 데이터 검증 센터',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppleColors.label),
                    ),
                    Text(
                      '야간 가동(22:00~07:00) 기반 ETA 예측 및 무결성 자체 검증',
                      style: TextStyle(fontSize: 11.5, color: AppleColors.secondaryLabel),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(CupertinoIcons.refresh, size: 18, color: AppleColors.systemBlue),
                  onPressed: _fetchProgress,
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark_circle_fill, color: AppleColors.tertiaryLabel),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppleColors.separator),

          Expanded(
            child: FutureBuilder<BatchProgressModel>(
              future: _progressFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CupertinoActivityIndicator(radius: 14));
                }
                final progress = snapshot.data;
                if (progress == null) {
                  return const Center(child: Text('배치 상태 데이터를 불러올 수 없습니다.'));
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 1. Overall Progress & ETA Card
                    AppleFrostedCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppleColors.systemGreen.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(CupertinoIcons.moon_stars_fill, color: AppleColors.systemGreen, size: 13),
                                    SizedBox(width: 5),
                                    Text(
                                      '야간 집중 스케줄 (22:00 ~ 07:00 / 9시간)',
                                      style: TextStyle(color: AppleColors.systemGreen, fontSize: 11.5, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${progress.processedCompanies} / ${progress.totalTargetCompanies} 기업 (${progress.totalProgressPct}%)',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppleColors.label),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress.totalProgressPct / 100.0,
                              minHeight: 10,
                              backgroundColor: AppleColors.separator,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppleColors.systemBlue),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppleColors.systemBlue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppleColors.systemBlue.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(CupertinoIcons.time_solid, color: AppleColors.systemBlue, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '최종 전체 DB 초기 적재 예상 완료 시점 (ETA)',
                                        style: TextStyle(fontSize: 11, color: AppleColors.secondaryLabel),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        progress.estCompletionDate,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppleColors.systemBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMetricItem('처리 속도', '${progress.throughputCompaniesPerMin}개/분', '(기업당 ${progress.avgSecondsPerCompany}초)'),
                              _buildMetricItem('남은 기업', '${progress.remainingCompanies}개', '전체 ${progress.totalTargetCompanies}개 중'),
                              _buildMetricItem('순수 소요시간', '${progress.estRemainingHours}시간', '야간 가동 분할'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Trigger Action Buttons
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppleColors.systemBlue.withOpacity(0.2),
                          foregroundColor: AppleColors.systemBlue,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppleColors.systemBlue, width: 1),
                          ),
                        ),
                        onPressed: _isTriggeringBatch ? null : _triggerLiveBatch,
                        icon: _isTriggeringBatch
                            ? const CupertinoActivityIndicator(radius: 8, color: AppleColors.systemBlue)
                            : const Icon(CupertinoIcons.play_circle_fill, size: 16),
                        label: Text(
                          _isTriggeringBatch ? 'DART 기업 및 임원 데이터 파싱/적재 중...' : '⚡ 실시간 10개 기업 즉시 수집/적재 실행',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppleColors.systemGreen.withOpacity(0.15),
                              foregroundColor: AppleColors.systemGreen,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _isCheckingHealth ? null : _runHealthCheck,
                            icon: _isCheckingHealth
                                ? const CupertinoActivityIndicator(radius: 8, color: AppleColors.systemGreen)
                                : const Icon(CupertinoIcons.checkmark_shield_fill, size: 16),
                            label: const Text('DB 무결성 검증', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppleColors.systemOrange.withOpacity(0.15),
                              foregroundColor: AppleColors.systemOrange,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _isRunningSearchTest ? null : _runSearchTest,
                            icon: _isRunningSearchTest
                                ? const CupertinoActivityIndicator(radius: 8, color: AppleColors.systemOrange)
                                : const Icon(CupertinoIcons.play_arrow_solid, size: 16),
                            label: const Text('검색 E2E 테스트', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3. Health Check Results
                    if (_healthReport != null)
                      AppleFrostedCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(CupertinoIcons.checkmark_shield_fill, color: AppleColors.systemGreen, size: 16),
                                const SizedBox(width: 8),
                                const Text('DB 데이터 정합성 & 출처 검증 리포트', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppleColors.label)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppleColors.systemGreen.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${_healthReport!['evidence_integrity']['compliance_pct']}% 검증 완료',
                                    style: const TextStyle(color: AppleColors.systemGreen, fontSize: 10.5, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text('• 총 노드 수: ${_healthReport!['node_counts']['TotalNodes']}개 (기업 ${_healthReport!['node_counts']['Company']}개, 인물 ${_healthReport!['node_counts']['Person']}명)', style: const TextStyle(fontSize: 12, color: AppleColors.secondaryLabel)),
                            Text('• 총 엣지 수: ${_healthReport!['edge_counts']['TotalEdges']}개 (재직 ${_healthReport!['edge_counts']['SERVES_AS']}건, 지분 ${_healthReport!['edge_counts']['OWNS_STAKE']}건)', style: const TextStyle(fontSize: 12, color: AppleColors.secondaryLabel)),
                            Text('• 고립 노드(Orphan): ${_healthReport!['orphan_nodes']['count']}건 (${_healthReport!['orphan_nodes']['status']})', style: const TextStyle(fontSize: 12, color: AppleColors.secondaryLabel)),
                            Text('• DART 출처 무결성: 누락률 ${_healthReport!['evidence_integrity']['missing_rate_pct']}% (${_healthReport!['evidence_integrity']['status']})', style: const TextStyle(fontSize: 12, color: AppleColors.secondaryLabel)),
                          ],
                        ),
                      ),

                    // 4. Search E2E Test Results
                    if (_searchTestReport != null)
                      AppleFrostedCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(CupertinoIcons.search_circle_fill, color: AppleColors.systemOrange, size: 16),
                                const SizedBox(width: 8),
                                const Text('검색창 모의 쿼리 E2E 테스트 리포트', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppleColors.label)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppleColors.systemGreen.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${_searchTestReport!['passed_tests']}/${_searchTestReport!['total_tests']} PASS (${_searchTestReport!['total_duration_ms']}ms)',
                                    style: const TextStyle(color: AppleColors.systemGreen, fontSize: 10.5, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...(_searchTestReport!['results'] as List<dynamic>? ?? []).map((t) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Icon(
                                    t['passed'] == true ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.xmark_circle_fill,
                                    size: 14,
                                    color: t['passed'] == true ? AppleColors.systemGreen : AppleColors.systemRed,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${t['name']} (${t['latency_ms']}ms)',
                                      style: const TextStyle(fontSize: 12, color: AppleColors.label),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppleColors.secondaryLabel)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppleColors.label)),
        Text(sub, style: const TextStyle(fontSize: 10, color: AppleColors.tertiaryLabel)),
      ],
    );
  }
}
