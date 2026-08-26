class WeightSettingsModel {
  double executiveFamily; // 직무 실권 및 최대주주 (기본 0.95)
  double exclusiveCohort; // 폐쇄형 엘리트 네트워크 (기본 0.85)
  double directAlumni;    // 직접 학연 (기본 0.70)
  double regionalTies;    // 지연/동향 (기본 0.45)
  double decayFactor;     // 다단계 감가 계수 (기본 0.60)

  WeightSettingsModel({
    this.executiveFamily = 0.95,
    this.exclusiveCohort = 0.85,
    this.directAlumni = 0.70,
    this.regionalTies = 0.45,
    this.decayFactor = 0.60,
  });

  bool get isDefault {
    return (executiveFamily - 0.95).abs() < 0.001 &&
        (exclusiveCohort - 0.85).abs() < 0.001 &&
        (directAlumni - 0.70).abs() < 0.001 &&
        (regionalTies - 0.45).abs() < 0.001 &&
        (decayFactor - 0.60).abs() < 0.001;
  }

  void resetToAiDefaults() {
    executiveFamily = 0.95;
    exclusiveCohort = 0.85;
    directAlumni = 0.70;
    regionalTies = 0.45;
    decayFactor = 0.60;
  }

  WeightSettingsModel copyWith({
    double? executiveFamily,
    double? exclusiveCohort,
    double? directAlumni,
    double? regionalTies,
    double? decayFactor,
  }) {
    return WeightSettingsModel(
      executiveFamily: executiveFamily ?? this.executiveFamily,
      exclusiveCohort: exclusiveCohort ?? this.exclusiveCohort,
      directAlumni: directAlumni ?? this.directAlumni,
      regionalTies: regionalTies ?? this.regionalTies,
      decayFactor: decayFactor ?? this.decayFactor,
    );
  }

  Map<String, String> toQueryParams() {
    return {
      'w_executive': executiveFamily.toStringAsFixed(2),
      'w_cohort': exclusiveCohort.toStringAsFixed(2),
      'w_alumni': directAlumni.toStringAsFixed(2),
      'w_regional': regionalTies.toStringAsFixed(2),
      'decay_factor': decayFactor.toStringAsFixed(2),
    };
  }
}
