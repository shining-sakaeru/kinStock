import 'company_model.dart';
import 'person_model.dart';
import 'recommendation_model.dart';

class InvestmentRationaleModel {
  final String executivePowerAnalysis;
  final String historicalMarketReaction;
  final String themeCatalyst;

  InvestmentRationaleModel({
    required this.executivePowerAnalysis,
    required this.historicalMarketReaction,
    required this.themeCatalyst,
  });

  factory InvestmentRationaleModel.fromJson(Map<String, dynamic> json) {
    return InvestmentRationaleModel(
      executivePowerAnalysis: json['executive_power_analysis'] as String? ?? '',
      historicalMarketReaction: json['historical_market_reaction'] as String? ?? '',
      themeCatalyst: json['theme_catalyst'] as String? ?? '',
    );
  }
}

class GraphPathNodeModel {
  final String id;
  final String label;
  final String type;
  final String? subtitle;
  final bool isSource;
  final bool isTarget;
  final String? sourceUrl;

  GraphPathNodeModel({
    required this.id,
    required this.label,
    required this.type,
    this.subtitle,
    this.isSource = false,
    this.isTarget = false,
    this.sourceUrl,
  });

  factory GraphPathNodeModel.fromJson(Map<String, dynamic> json) {
    return GraphPathNodeModel(
      id: json['id'] as String,
      label: json['label'] as String,
      type: json['type'] as String? ?? 'PERSON',
      subtitle: json['subtitle'] as String?,
      isSource: json['is_source'] as bool? ?? false,
      isTarget: json['is_target'] as bool? ?? false,
      sourceUrl: json['source_url'] as String?,
    );
  }
}

class GraphPathEdgeModel {
  final String source;
  final String target;
  final String relationType;
  final String label;
  final double weight;
  final String? dartRef;
  final String? sourceUrl;

  GraphPathEdgeModel({
    required this.source,
    required this.target,
    required this.relationType,
    required this.label,
    required this.weight,
    this.dartRef,
    this.sourceUrl,
  });

  factory GraphPathEdgeModel.fromJson(Map<String, dynamic> json) {
    return GraphPathEdgeModel(
      source: json['source'] as String,
      target: json['target'] as String,
      relationType: json['relation_type'] as String? ?? '',
      label: json['label'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.5,
      dartRef: json['dart_ref'] as String?,
      sourceUrl: json['source_url'] as String?,
    );
  }
}

class DeepDivePathModel {
  final String status;
  final PersonModel? sourcePerson;
  final CompanyModel? targetCompany;
  final double relevanceScore;
  final int depth;
  final String primaryBadge;
  final DartFactModel? dartFact;
  final InvestmentRationaleModel? investmentRationale;
  final List<GraphPathNodeModel> nodes;
  final List<GraphPathEdgeModel> edges;

  DeepDivePathModel({
    required this.status,
    this.sourcePerson,
    this.targetCompany,
    required this.relevanceScore,
    required this.depth,
    required this.primaryBadge,
    this.dartFact,
    this.investmentRationale,
    required this.nodes,
    required this.edges,
  });

  factory DeepDivePathModel.fromJson(Map<String, dynamic> json) {
    return DeepDivePathModel(
      status: json['status'] as String? ?? 'success',
      sourcePerson: json['source_person'] != null
          ? PersonModel.fromJson(json['source_person'] as Map<String, dynamic>)
          : null,
      targetCompany: json['target_company'] != null
          ? CompanyModel.fromJson(json['target_company'] as Map<String, dynamic>)
          : null,
      relevanceScore: (json['relevance_score'] as num?)?.toDouble() ?? 0.0,
      depth: json['depth'] as int? ?? 1,
      primaryBadge: json['primary_badge'] as String? ?? '',
      dartFact: json['dart_fact'] != null
          ? DartFactModel.fromJson(json['dart_fact'] as Map<String, dynamic>)
          : null,
      investmentRationale: json['investment_rationale'] != null
          ? InvestmentRationaleModel.fromJson(json['investment_rationale'] as Map<String, dynamic>)
          : null,
      nodes: (json['nodes'] as List<dynamic>?)
              ?.map((e) => GraphPathNodeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      edges: (json['edges'] as List<dynamic>?)
              ?.map((e) => GraphPathEdgeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
