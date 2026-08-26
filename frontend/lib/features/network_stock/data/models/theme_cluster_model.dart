import 'theme_model.dart';
import 'person_model.dart';
import 'recommendation_model.dart';

class ThemeClusterModel {
  final String status;
  final ThemeModel theme;
  final List<PersonModel> keyFigures;
  final List<RankedStockItemModel> topThemeStocks;

  ThemeClusterModel({
    required this.status,
    required this.theme,
    required this.keyFigures,
    required this.topThemeStocks,
  });

  factory ThemeClusterModel.fromJson(Map<String, dynamic> json) {
    return ThemeClusterModel(
      status: json['status'] as String? ?? 'success',
      theme: ThemeModel.fromJson(json['theme'] as Map<String, dynamic>),
      keyFigures: (json['key_figures'] as List<dynamic>?)
              ?.map((e) => PersonModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topThemeStocks: (json['top_theme_stocks'] as List<dynamic>?)
              ?.map((e) => RankedStockItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
