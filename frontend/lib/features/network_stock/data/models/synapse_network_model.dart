class SynapseNodeModel {
  final String id;
  final String label;
  final String type; // PERSON, COMPANY, SCHOOL, REGION
  final String? roleOrIndustry;
  final String? marketCap;
  final double? priceChangeRate;
  final String? badgeColor;

  SynapseNodeModel({
    required this.id,
    required this.label,
    required this.type,
    this.roleOrIndustry,
    this.marketCap,
    this.priceChangeRate,
    this.badgeColor,
  });

  factory SynapseNodeModel.fromJson(Map<String, dynamic> json) {
    return SynapseNodeModel(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      type: json['type'] as String? ?? 'PERSON',
      roleOrIndustry: json['role_or_industry'] as String?,
      marketCap: json['market_cap'] as String?,
      priceChangeRate: (json['price_change_rate'] as num?)?.toDouble(),
      badgeColor: json['badge_color'] as String?,
    );
  }
}

class SynapseEdgeModel {
  final String source;
  final String target;
  final String type;
  final String label;
  final double weight;
  final String evidence;
  final String sourceTier;
  final String sourceName;
  final String badgeLabel;
  final String? sourceUrl;
  final String? rcpNo;

  SynapseEdgeModel({
    required this.source,
    required this.target,
    required this.type,
    required this.label,
    required this.weight,
    required this.evidence,
    this.sourceTier = 'TIER_1_LEGAL',
    this.sourceName = 'DART',
    this.badgeLabel = '🟢 공시 팩트',
    this.sourceUrl,
    this.rcpNo,
  });

  factory SynapseEdgeModel.fromJson(Map<String, dynamic> json) {
    return SynapseEdgeModel(
      source: json['source'] as String? ?? '',
      target: json['target'] as String? ?? '',
      type: json['type'] as String? ?? 'WORKS_AT',
      label: json['label'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.8,
      evidence: json['evidence'] as String? ?? json['evidence_text'] as String? ?? '',
      sourceTier: json['source_tier'] as String? ?? 'TIER_1_LEGAL',
      sourceName: json['source_name'] as String? ?? 'DART',
      badgeLabel: json['badge_label'] as String? ?? (json['source_tier'] == 'TIER_3_NEWS' ? '🟡 언론 보도' : '🟢 공시 팩트'),
      sourceUrl: json['source_url'] as String?,
      rcpNo: json['rcp_no'] as String?,
    );
  }
}

class SynapseSubgraphModel {
  final String focusId;
  final String focusType;
  final List<SynapseNodeModel> nodes;
  final List<SynapseEdgeModel> edges;
  final int totalNodes;
  final int totalEdges;

  SynapseSubgraphModel({
    required this.focusId,
    required this.focusType,
    required this.nodes,
    required this.edges,
    required this.totalNodes,
    required this.totalEdges,
  });

  factory SynapseSubgraphModel.fromJson(Map<String, dynamic> json) {
    return SynapseSubgraphModel(
      focusId: json['focus_id'] as String? ?? '',
      focusType: json['focus_type'] as String? ?? '',
      nodes: (json['nodes'] as List<dynamic>?)
              ?.map((e) => SynapseNodeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      edges: (json['edges'] as List<dynamic>?)
              ?.map((e) => SynapseEdgeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalNodes: json['total_nodes'] as int? ?? 0,
      totalEdges: json['total_edges'] as int? ?? 0,
    );
  }
}
