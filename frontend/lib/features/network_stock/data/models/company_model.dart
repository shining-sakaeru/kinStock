class CompanyModel {
  final String id;
  final String ticker;
  final String name;
  final String industry;
  final double currentPrice;
  final double priceChangeRate;
  final String marketCap;
  final String? dartCorpCode;
  final String? sourceUrl;

  CompanyModel({
    required this.id,
    required this.ticker,
    required this.name,
    required this.industry,
    required this.currentPrice,
    required this.priceChangeRate,
    required this.marketCap,
    this.dartCorpCode,
    this.sourceUrl,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] as String,
      ticker: json['ticker'] as String,
      name: json['name'] as String,
      industry: json['industry'] as String? ?? '',
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      priceChangeRate: (json['price_change_rate'] as num?)?.toDouble() ?? 0.0,
      marketCap: json['market_cap'] as String? ?? '',
      dartCorpCode: json['dart_corp_code'] as String?,
      sourceUrl: json['source_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ticker': ticker,
    'name': name,
    'industry': industry,
    'current_price': currentPrice,
    'price_change_rate': priceChangeRate,
    'market_cap': marketCap,
    'dart_corp_code': dartCorpCode,
    'source_url': sourceUrl,
  };
}
