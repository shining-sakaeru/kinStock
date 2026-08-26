class ThemeModel {
  final String id;
  final String code;
  final String title;
  final String shortTitle;
  final String description;
  final String iconName;
  final String badgeColor;
  final int figureCount;

  ThemeModel({
    required this.id,
    required this.code,
    required this.title,
    required this.shortTitle,
    required this.description,
    required this.iconName,
    required this.badgeColor,
    this.figureCount = 0,
  });

  factory ThemeModel.fromJson(Map<String, dynamic> json) {
    return ThemeModel(
      id: json['id'] as String,
      code: json['code'] as String? ?? 'PRESIDENTIAL_ELECTION',
      title: json['title'] as String,
      shortTitle: json['short_title'] as String? ?? json['title'] as String,
      description: json['description'] as String? ?? '',
      iconName: json['icon_name'] as String? ?? 'hub',
      badgeColor: json['badge_color'] as String? ?? '#0A84FF',
      figureCount: json['figure_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'title': title,
    'short_title': shortTitle,
    'description': description,
    'icon_name': iconName,
    'badge_color': badgeColor,
    'figure_count': figureCount,
  };
}
