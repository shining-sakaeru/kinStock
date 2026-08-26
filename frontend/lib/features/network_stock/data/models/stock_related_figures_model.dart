import 'company_model.dart';
import 'micro_graph_model.dart';
import 'recommendation_model.dart';

class RankedFigureItemModel {
  final int rank;
  final String figureId;
  final String name;
  final String roleTitle;
  final String themeId;
  final String themeTitle;
  final double relevanceScore;
  final String primaryBadge;
  final int depth;
  final String connectionPathSummary;
  final DartFactModel? dartFact;
  final String sourceUrl;

  RankedFigureItemModel({
    required this.rank,
    required this.figureId,
    required this.name,
    required this.roleTitle,
    required this.themeId,
    required this.themeTitle,
    required this.relevanceScore,
    required this.primaryBadge,
    required this.depth,
    required this.connectionPathSummary,
    this.dartFact,
    required this.sourceUrl,
  });

  factory RankedFigureItemModel.fromJson(Map<String, dynamic> json) {
    return RankedFigureItemModel(
      rank: json['rank'] as int? ?? 0,
      figureId: json['figure_id'] as String,
      name: json['name'] as String,
      roleTitle: json['role_title'] as String? ?? '',
      themeId: json['theme_id'] as String? ?? 'theme_presidential',
      themeTitle: json['theme_title'] as String? ?? '테마',
      relevanceScore: (json['relevance_score'] as num?)?.toDouble() ?? 0.0,
      primaryBadge: json['primary_badge'] as String? ?? '',
      depth: json['depth'] as int? ?? 1,
      connectionPathSummary: json['connection_path_summary'] as String? ?? '',
      dartFact: json['dart_fact'] != null
          ? DartFactModel.fromJson(json['dart_fact'] as Map<String, dynamic>)
          : null,
      sourceUrl: json['source_url'] as String? ?? 'https://open.assembly.go.kr',
    );
  }
}

class StockRelatedFiguresModel {
  final String status;
  final CompanyModel company;
  final MicroGraphModel microGraph;
  final List<RankedFigureItemModel> relatedFigures;
  final Map<String, dynamic>? appliedWeights;

  StockRelatedFiguresModel({
    required this.status,
    required this.company,
    required this.microGraph,
    required this.relatedFigures,
    this.appliedWeights,
  });

  factory StockRelatedFiguresModel.fromJson(Map<String, dynamic> json) {
    return StockRelatedFiguresModel(
      status: json['status'] as String? ?? 'success',
      company: CompanyModel.fromJson(json['company'] as Map<String, dynamic>),
      microGraph: MicroGraphModel.fromJson(json['micro_graph'] as Map<String, dynamic>),
      relatedFigures: (json['related_figures'] as List<dynamic>?)
              ?.map((e) => RankedFigureItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      appliedWeights: json['applied_weights'] as Map<String, dynamic>?,
    );
  }
}
