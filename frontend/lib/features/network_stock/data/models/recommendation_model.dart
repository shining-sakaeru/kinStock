class DartFactModel {
  final String reportTitle;
  final String reportCode;
  final String rcpNo;
  final String filingDate;
  final String verifiedFact;
  final String sourceUrl;

  DartFactModel({
    required this.reportTitle,
    required this.reportCode,
    this.rcpNo = '',
    required this.filingDate,
    required this.verifiedFact,
    required this.sourceUrl,
  });

  factory DartFactModel.fromJson(Map<String, dynamic> json) {
    return DartFactModel(
      reportTitle: json['report_title'] as String? ?? 'DART 공시',
      reportCode: json['report_code'] as String? ?? '',
      rcpNo: json['rcp_no'] as String? ?? '',
      filingDate: json['filing_date'] as String? ?? '',
      verifiedFact: json['verified_fact'] as String? ?? '',
      sourceUrl: json['source_url'] as String? ?? 'https://dart.fss.or.kr',
    );
  }

  Map<String, dynamic> toJson() => {
    'report_title': reportTitle,
    'report_code': reportCode,
    'rcp_no': rcpNo,
    'filing_date': filingDate,
    'verified_fact': verifiedFact,
    'source_url': sourceUrl,
  };
}

class RankedStockItemModel {
  final int rank;
  final String companyId;
  final String ticker;
  final String companyName;
  final double relevanceScore;
  final String primaryBadge;
  final double currentPrice;
  final double priceChangeRate;
  final String marketCap;
  final String industry;
  final int depth;
  final String connectionPathSummary;
  final DartFactModel? dartFact;
  final bool isDartVerified;
  final String sourceUrl;

  RankedStockItemModel({
    required this.rank,
    required this.companyId,
    required this.ticker,
    required this.companyName,
    required this.relevanceScore,
    required this.primaryBadge,
    required this.currentPrice,
    required this.priceChangeRate,
    required this.marketCap,
    required this.industry,
    required this.depth,
    required this.connectionPathSummary,
    this.dartFact,
    this.isDartVerified = true,
    this.sourceUrl = 'https://dart.fss.or.kr',
  });

  factory RankedStockItemModel.fromJson(Map<String, dynamic> json) {
    return RankedStockItemModel(
      rank: json['rank'] as int? ?? 0,
      companyId: json['company_id'] as String,
      ticker: json['ticker'] as String,
      companyName: json['company_name'] as String,
      relevanceScore: (json['relevance_score'] as num?)?.toDouble() ?? 0.0,
      primaryBadge: json['primary_badge'] as String? ?? '',
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      priceChangeRate: (json['price_change_rate'] as num?)?.toDouble() ?? 0.0,
      marketCap: json['market_cap'] as String? ?? '',
      industry: json['industry'] as String? ?? '',
      depth: json['depth'] as int? ?? 1,
      connectionPathSummary: json['connection_path_summary'] as String? ?? '',
      dartFact: json['dart_fact'] != null
          ? DartFactModel.fromJson(json['dart_fact'] as Map<String, dynamic>)
          : null,
      isDartVerified: json['is_dart_verified'] as bool? ?? true,
      sourceUrl: json['source_url'] as String? ?? 'https://dart.fss.or.kr',
    );
  }
}

class RecommendationsModel {
  final String status;
  final String personId;
  final String personName;
  final List<RankedStockItemModel> recommendations;

  RecommendationsModel({
    required this.status,
    required this.personId,
    required this.personName,
    required this.recommendations,
  });

  factory RecommendationsModel.fromJson(Map<String, dynamic> json) {
    return RecommendationsModel(
      status: json['status'] as String? ?? 'success',
      personId: json['person_id'] as String,
      personName: json['person_name'] as String? ?? '',
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => RankedStockItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
