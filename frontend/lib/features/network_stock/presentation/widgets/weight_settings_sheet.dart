import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/weight_settings_model.dart';
import 'apple_frosted_card.dart';

class WeightSettingsSheet extends StatefulWidget {
  final WeightSettingsModel initialWeights;
  final Function(WeightSettingsModel) onApplyWeights;

  const WeightSettingsSheet({
    super.key,
    required this.initialWeights,
    required this.onApplyWeights,
  });

  @override
  State<WeightSettingsSheet> createState() => _WeightSettingsSheetState();
}

class _WeightSettingsSheetState extends State<WeightSettingsSheet> {
  late WeightSettingsModel _currentWeights;

  @override
  void initState() {
    super.initState();
    _currentWeights = widget.initialWeights.copyWith();
  }

  void _resetToDefaults() {
    setState(() {
      _currentWeights.resetToAiDefaults();
    });
    widget.onApplyWeights(_currentWeights);
  }

  void _updateWeight({
    double? executive,
    double? cohort,
    double? alumni,
    double? regional,
    double? decay,
  }) {
    setState(() {
      _currentWeights = _currentWeights.copyWith(
        executiveFamily: executive,
        exclusiveCohort: cohort,
        directAlumni: alumni,
        regionalTies: regional,
        decayFactor: decay,
      );
    });
    widget.onApplyWeights(_currentWeights);
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
            // Top Grabber & Header
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppleColors.separator,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppleColors.systemIndigo.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(CupertinoIcons.slider_horizontal_3, color: AppleColors.systemIndigo, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI 가중치 커스텀 설정',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppleColors.label,
                        ),
                      ),
                      Text(
                        '시장 상관관계 팩터별 가중치 실시간 조절',
                        style: TextStyle(fontSize: 11, color: AppleColors.secondaryLabel),
                      ),
                    ],
                  ),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(CupertinoIcons.xmark_circle_fill, color: AppleColors.secondaryLabel, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppleColors.separator),

            // Scrollable Factor Sliders
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  // 1. Executive / Family
                  _buildSliderCard(
                    title: '직무 실권 및 최대주주 (Executive/Family)',
                    value: _currentWeights.executiveFamily,
                    defaultValue: 0.95,
                    color: AppleColors.systemRed,
                    aiRationale: 'DART 공시상 대표이사·사내이사 및 대주주 지분은 실질적 의사결정권과 시세 직결도가 가장 높음 (대표이사 가중치 1.3배 보정)',
                    onChanged: (v) => _updateWeight(executive: v),
                  ),
                  const SizedBox(height: 10),

                  // 2. Exclusive Cohort
                  _buildSliderCard(
                    title: '폐쇄형 엘리트 네트워크 (Exclusive Cohort)',
                    value: _currentWeights.exclusiveCohort,
                    defaultValue: 0.85,
                    color: AppleColors.systemOrange,
                    aiRationale: '사법연수원·행정고시 등 한정된 기수 네트워크는 장기적 정책·이권 연대 신뢰도가 매우 높음',
                    onChanged: (v) => _updateWeight(cohort: v),
                  ),
                  const SizedBox(height: 10),

                  // 3. Direct Alumni
                  _buildSliderCard(
                    title: '직접 학연 (Direct Alumni)',
                    value: _currentWeights.directAlumni,
                    defaultValue: 0.70,
                    color: AppleColors.systemBlue,
                    aiRationale: '동일 고교 및 대학 동일 학과 학맥은 전통적인 기업-정계 테마의 핵심 연결고리',
                    onChanged: (v) => _updateWeight(alumni: v),
                  ),
                  const SizedBox(height: 10),

                  // 4. Regional Ties
                  _buildSliderCard(
                    title: '지연 / 동향 (Regional Ties)',
                    value: _currentWeights.regionalTies,
                    defaultValue: 0.45,
                    color: AppleColors.systemTeal,
                    aiRationale: '단순 고향 연관성은 상대적으로 구속력이 낮아 낮은 기본 가중치 부여',
                    onChanged: (v) => _updateWeight(regional: v),
                  ),
                  const SizedBox(height: 10),

                  // 5. Decay Factor
                  _buildSliderCard(
                    title: '다단계 감가 계수 (Decay Factor per Depth)',
                    value: _currentWeights.decayFactor,
                    defaultValue: 0.60,
                    color: AppleColors.systemPurple,
                    aiRationale: '2단계(2-Hop) 이상 매개 노드 통과 시 테마 지속성 급감 현상 반영 (0.60x 감가)',
                    onChanged: (v) => _updateWeight(decay: v),
                  ),
                  const SizedBox(height: 16),

                  // Reset Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: CupertinoButton(
                      color: _currentWeights.isDefault
                          ? AppleColors.tertiarySystemBackground
                          : AppleColors.systemBlue,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _currentWeights.isDefault ? null : _resetToDefaults,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.arrow_counterclockwise,
                            size: 16,
                            color: _currentWeights.isDefault ? AppleColors.tertiaryLabel : Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'AI 추천 기본값으로 초기화 (Default Reset)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _currentWeights.isDefault ? AppleColors.tertiaryLabel : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderCard({
    required String title,
    required double value,
    required double defaultValue,
    required Color color,
    required String aiRationale,
    required ValueChanged<double> onChanged,
  }) {
    final isCustomized = (value - defaultValue).abs() > 0.01;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppleColors.tertiarySystemBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCustomized ? color.withOpacity(0.6) : AppleColors.separator,
          width: isCustomized ? 1.2 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppleColors.label,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Cupertino Slider
          SizedBox(
            height: 32,
            child: CupertinoSlider(
              value: value,
              min: 0.10,
              max: 1.00,
              divisions: 18,
              activeColor: color,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: 4),
          // AI Rationale Callout
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppleColors.secondarySystemBackground.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(CupertinoIcons.sparkles, size: 12, color: AppleColors.systemYellow),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    aiRationale,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppleColors.secondaryLabel,
                      height: 1.3,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
