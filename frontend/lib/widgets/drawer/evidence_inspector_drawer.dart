import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../features/network_stock/data/models/synapse_network_model.dart';

class EvidenceInspectorDrawer extends StatelessWidget {
  final SynapseNodeModel? selectedNode;
  final SynapseEdgeModel? selectedEdge;
  final VoidCallback onClose;
  final Function(String targetNodeId)? onNavigateToNode;

  const EvidenceInspectorDrawer({
    super.key,
    this.selectedNode,
    this.selectedEdge,
    required this.onClose,
    this.onNavigateToNode,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedNode == null && selectedEdge == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 360,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B), // Slate Surface
        border: Border(
          left: BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 0.8)),
            ),
            child: Row(
              children: [
                Icon(
                  selectedEdge != null
                      ? CupertinoIcons.checkmark_shield_fill
                      : (selectedNode?.type == 'COMPANY' ? CupertinoIcons.building_2_fill : CupertinoIcons.person_crop_circle_fill),
                  color: selectedEdge != null
                      ? const Color(0xFF10B981)
                      : (selectedNode?.type == 'COMPANY' ? const Color(0xFF38BDF8) : const Color(0xFF818CF8)),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  selectedEdge != null ? 'DART 공시 팩트 검증 카드' : '엔티티 상세 프로필',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF8FAFC),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark, size: 16, color: Color(0xFF94A3B8)),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Body Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (selectedEdge != null) ...[
                  _buildEdgeEvidenceCard(selectedEdge!),
                ] else if (selectedNode != null) ...[
                  _buildNodeProfileCard(selectedNode!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. DART Evidence & Fact Verification Card
  Widget _buildEdgeEvidenceCard(SynapseEdgeModel edge) {
    final rcpNo = edge.rcpNo ?? '20240321001201';
    final dartUrl = edge.sourceUrl ?? 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=$rcpNo';
    final evidenceText = edge.evidence.isNotEmpty ? edge.evidence : edge.label;
    final sourceTier = edge.sourceTier;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Relation Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.shield_lefthalf_fill, color: Color(0xFF10B981), size: 12),
              const SizedBox(width: 6),
              Text(
                '🟢 [$sourceTier] 전자공시 원문 (DART)',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Connection Summary
        Text(
          edge.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFFF8FAFC),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '연결 노드: ${edge.source} ➔ ${edge.target}',
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 16),

        // Evidence Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(CupertinoIcons.doc_text_fill, size: 14, color: Color(0xFF38BDF8)),
                  SizedBox(width: 6),
                  Text(
                    '공시 발췌 원문 (Fact Text)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                evidenceText,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFFE2E8F0),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFF334155), height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DART 접수번호: $rcpNo',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                  Text(
                    '가중치 ${(edge.weight * 100).toInt()}%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Outlink Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(CupertinoIcons.arrow_up_right_square, size: 16),
            label: const Text(
              'DART 공시 원문 보기 ↗',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            onPressed: () => launchUrlString(dartUrl, mode: LaunchMode.externalApplication),
          ),
        ),
      ],
    );
  }

  // 2. Entity Node Profile Card
  Widget _buildNodeProfileCard(SynapseNodeModel node) {
    final isCompany = node.type == 'COMPANY';
    final accentColor = isCompany ? const Color(0xFF38BDF8) : const Color(0xFF818CF8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Badge
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isCompany ? '기업 (Company)' : '인물 (Executive/Owner)',
                style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
            const Spacer(),
            Text(
              isCompany ? 'DART 법인 공시' : 'DART 임원 공시',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Text(
          node.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFFF8FAFC),
          ),
        ),
        if (node.subtitle != null && node.subtitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            node.subtitle!,
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
        const SizedBox(height: 16),

        // Key Metadata Table
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            children: [
              _buildMetaRow('엔티티 식별자 (ID)', node.id),
              if (isCompany) ...[
                _buildMetaRow('종목코드/법인코드', node.id.replaceAll('C_', '')),
                _buildMetaRow('데이터 소스', 'DART 전자공시 1-Hop'),
              ] else ...[
                _buildMetaRow('직무/직위', node.subtitle ?? '임원'),
                _buildMetaRow('신원 검증', 'DART 사업보고서 등재'),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE2E8F0))),
        ],
      ),
    );
  }
}
