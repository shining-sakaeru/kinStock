class PersonModel {
  final String id;
  final String name;
  final String category;
  final String roleTitle;
  final String themeId;
  final String? profileImgUrl;
  final String? hometown;
  final List<String> almaMater;
  final String? cohortInfo;
  final String? keySummary;
  final String sourceUrl;

  PersonModel({
    required this.id,
    required this.name,
    required this.category,
    required this.roleTitle,
    this.themeId = 'theme_presidential',
    this.profileImgUrl,
    this.hometown,
    this.almaMater = const [],
    this.cohortInfo,
    this.keySummary,
    this.sourceUrl = 'https://open.assembly.go.kr',
  });

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    return PersonModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'POLITICIAN',
      roleTitle: json['role_title'] as String? ?? '',
      themeId: json['theme_id'] as String? ?? 'theme_presidential',
      profileImgUrl: json['profile_img_url'] as String?,
      hometown: json['hometown'] as String?,
      almaMater: (json['alma_mater'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      cohortInfo: json['cohort_info'] as String?,
      keySummary: json['key_summary'] as String?,
      sourceUrl: json['source_url'] as String? ?? 'https://open.assembly.go.kr',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'role_title': roleTitle,
    'theme_id': themeId,
    'profile_img_url': profileImgUrl,
    'hometown': hometown,
    'alma_mater': almaMater,
    'cohort_info': cohortInfo,
    'key_summary': keySummary,
    'source_url': sourceUrl,
  };
}
