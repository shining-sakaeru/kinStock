class BatchProgressModel {
  final int totalTargetCompanies;
  final int totalTargetPersons;
  final int processedCompanies;
  final int processedPersons;
  final int remainingCompanies;
  final double totalProgressPct;
  final double avgSecondsPerCompany;
  final double throughputCompaniesPerMin;
  final double estRemainingHours;
  final String estCompletionDate;
  final bool isActive;
  final String currentPhase;
  final String? currentCompany;
  final String lastUpdatedAt;

  BatchProgressModel({
    required this.totalTargetCompanies,
    required this.totalTargetPersons,
    required this.processedCompanies,
    required this.processedPersons,
    required this.remainingCompanies,
    required this.totalProgressPct,
    required this.avgSecondsPerCompany,
    required this.throughputCompaniesPerMin,
    required this.estRemainingHours,
    required this.estCompletionDate,
    required this.isActive,
    required this.currentPhase,
    this.currentCompany,
    required this.lastUpdatedAt,
  });

  factory BatchProgressModel.fromJson(Map<String, dynamic> json) {
    return BatchProgressModel(
      totalTargetCompanies: json['total_target_companies'] as int? ?? 2500,
      totalTargetPersons: json['total_target_persons'] as int? ?? 30000,
      processedCompanies: json['processed_companies'] as int? ?? 0,
      processedPersons: json['processed_persons'] as int? ?? 0,
      remainingCompanies: json['remaining_companies'] as int? ?? 2500,
      totalProgressPct: (json['total_progress_pct'] as num?)?.toDouble() ?? 0.0,
      avgSecondsPerCompany: (json['avg_seconds_per_company'] as num?)?.toDouble() ?? 1.5,
      throughputCompaniesPerMin: (json['throughput_companies_per_min'] as num?)?.toDouble() ?? 40.0,
      estRemainingHours: (json['est_remaining_hours'] as num?)?.toDouble() ?? 0.0,
      estCompletionDate: json['est_completion_date'] as String? ?? '계산 중...',
      isActive: json['is_active'] as bool? ?? false,
      currentPhase: json['current_phase'] as String? ?? 'IDLE',
      currentCompany: json['current_company'] as String?,
      lastUpdatedAt: json['last_updated_at'] as String? ?? '',
    );
  }
}
