import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../data/models/synapse_network_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/url_helper.dart';

class SynapseEvidenceSheet extends StatelessWidget {
  final SynapseEdgeModel edge;
  final String sourceName;
  final String targetName;

  const SynapseEvidenceSheet({
    super.key,
    required this.edge,
    required this.sourceName,
    required this.targetName,
  });

  static void show(
    BuildContext context, {
    required SynapseEdgeModel edge,
    required String sourceName,
    required String targetName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SynapseEvidenceSheet(
        edge: edge,
        sourceName: sourceName,
        targetName: targetName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLegal = edge.sourceTier == 'TIER_1_LEGAL';
    final badgeColor = isLegal
        ? AppleColors.systemGreen
        : (edge.sourceTier == 'TIER_2_PUBLIC' ? AppleColors.systemBlue : AppleColors.systemOrange);

    return Container(
      decoration: const BoxDecoration(
        color: AppleColors.secondarySystemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppleColors.separator, width: 0.5),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header: Connection Title + Provenance Tier Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(CupertinoIcons.link, color: badgeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$sourceName ↔ $targetName',
                      style: const TextStyle(
                        color: AppleColors.label,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '연관도: ${(edge.weight * 100).toStringAsFixed(0)}점 · ${edge.label}',
                      style: const TextStyle(
                        color: AppleColors.secondaryLabel,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Source Tier Badge (🟢 공시 팩트 / 🟡 언론 보도)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withOpacity(0.4), width: 0.5),
                ),
                child: Text(
                  edge.badgeLabel,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Evidence Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppleColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppleColors.separator, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.checkmark_shield_fill, color: badgeColor, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      '${edge.sourceName} 출처 팩트 검증 근거',
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  edge.evidence,
                  style: const TextStyle(
                    color: AppleColors.label,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // DART / Document Link Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              color: AppleColors.systemBlue,
              borderRadius: BorderRadius.circular(12),
              onPressed: () {
                final targetUrl = edge.rcpNo != null
                    ? UrlHelper.getDartViewerUrl(edge.rcpNo!)
                    : (edge.sourceUrl ?? 'https://dart.fss.or.kr');
                UrlHelper.openUrl(targetUrl);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.doc_text, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    '출처 공시/문서 원문 검증 보기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
}
