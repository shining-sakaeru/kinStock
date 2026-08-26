class SearchItemModel {
  final String id;
  final String type; // PERSON, STOCK, THEME
  final String title;
  final String subtitle;
  final String badge;
  final String targetId;
  final String? sourceUrl;

  SearchItemModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.targetId,
    this.sourceUrl,
  });

  factory SearchItemModel.fromJson(Map<String, dynamic> json) {
    return SearchItemModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'PERSON',
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      badge: json['badge'] as String? ?? '',
      targetId: json['target_id'] as String,
      sourceUrl: json['source_url'] as String?,
    );
  }
}

class SearchUniversalResultModel {
  final String status;
  final String query;
  final int totalCount;
  final List<SearchItemModel> results;

  SearchUniversalResultModel({
    required this.status,
    required this.query,
    required this.totalCount,
    required this.results,
  });

  factory SearchUniversalResultModel.fromJson(Map<String, dynamic> json) {
    return SearchUniversalResultModel(
      status: json['status'] as String? ?? 'success',
      query: json['query'] as String? ?? '',
      totalCount: json['total_count'] as int? ?? 0,
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => SearchItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
