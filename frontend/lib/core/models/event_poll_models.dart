class PollCandidateModel {
  final String personId;
  final String personName;
  final String partyOrGroup;
  final String roleTitle;
  final double approvalRate;
  final int rank;
  final double deltaRate;
  final String badgeColor;

  PollCandidateModel({
    required this.personId,
    required this.personName,
    required this.partyOrGroup,
    required this.roleTitle,
    required this.approvalRate,
    required this.rank,
    required this.deltaRate,
    required this.badgeColor,
  });

  factory PollCandidateModel.fromJson(Map<String, dynamic> json) {
    return PollCandidateModel(
      personId: json['person_id'] as String? ?? '',
      personName: json['person_name'] as String? ?? '',
      partyOrGroup: json['party_or_group'] as String? ?? '',
      roleTitle: json['role_title'] as String? ?? '',
      approvalRate: (json['approval_rate'] as num?)?.toDouble() ?? 0.0,
      rank: json['rank'] as int? ?? 1,
      deltaRate: (json['delta_rate'] as num?)?.toDouble() ?? 0.0,
      badgeColor: json['badge_color'] as String? ?? '#38BDF8',
    );
  }
}

class PollSurveyModel {
  final String pollId;
  final String agency;
  final String surveyedAt;
  final int sampleSize;
  final double confidenceLevel;
  final double marginOfError;
  final String surveyMethod;
  final String sourceUrl;
  final List<PollCandidateModel> candidates;

  PollSurveyModel({
    required this.pollId,
    required this.agency,
    required this.surveyedAt,
    required this.sampleSize,
    required this.confidenceLevel,
    required this.marginOfError,
    required this.surveyMethod,
    required this.sourceUrl,
    required this.candidates,
  });

  factory PollSurveyModel.fromJson(Map<String, dynamic> json) {
    return PollSurveyModel(
      pollId: json['poll_id'] as String? ?? '',
      agency: json['agency'] as String? ?? '',
      surveyedAt: json['surveyed_at'] as String? ?? '',
      sampleSize: json['sample_size'] as int? ?? 1000,
      confidenceLevel: (json['confidence_level'] as num?)?.toDouble() ?? 95.0,
      marginOfError: (json['margin_of_error'] as num?)?.toDouble() ?? 3.1,
      surveyMethod: json['survey_method'] as String? ?? '',
      sourceUrl: json['source_url'] as String? ?? '',
      candidates: (json['candidates'] as List<dynamic>?)
              ?.map((e) => PollCandidateModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PollLeaderboardModel {
  final String status;
  final PollSurveyModel latestPoll;
  final List<PollCandidateModel> leaderboard;
  final List<Map<String, dynamic>> historicalTrends;

  PollLeaderboardModel({
    required this.status,
    required this.latestPoll,
    required this.leaderboard,
    required this.historicalTrends,
  });

  factory PollLeaderboardModel.fromJson(Map<String, dynamic> json) {
    return PollLeaderboardModel(
      status: json['status'] as String? ?? 'success',
      latestPoll: PollSurveyModel.fromJson(json['latest_poll'] as Map<String, dynamic>? ?? {}),
      leaderboard: (json['leaderboard'] as List<dynamic>?)
              ?.map((e) => PollCandidateModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      historicalTrends: (json['historical_trends'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}

class PoliticalEventModel {
  final String eventId;
  final String personId;
  final String personName;
  final String title;
  final String eventType;
  final String eventTypeLabel;
  final String occurredAt;
  final double significanceScore;
  final String evidenceTier;
  final String evidenceTierBadge;
  final String summary;
  final String sourceAgency;
  final String sourceUrl;

  PoliticalEventModel({
    required this.eventId,
    required this.personId,
    required this.personName,
    required this.title,
    required this.eventType,
    required this.eventTypeLabel,
    required this.occurredAt,
    required this.significanceScore,
    required this.evidenceTier,
    required this.evidenceTierBadge,
    required this.summary,
    required this.sourceAgency,
    required this.sourceUrl,
  });

  factory PoliticalEventModel.fromJson(Map<String, dynamic> json) {
    return PoliticalEventModel(
      eventId: json['event_id'] as String? ?? '',
      personId: json['person_id'] as String? ?? '',
      personName: json['person_name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      eventType: json['event_type'] as String? ?? 'DECLARATION',
      eventTypeLabel: json['event_type_label'] as String? ?? '주요 일정',
      occurredAt: json['occurred_at'] as String? ?? '',
      significanceScore: (json['significance_score'] as num?)?.toDouble() ?? 3.0,
      evidenceTier: json['evidence_tier'] as String? ?? 'TIER_1_LEGAL',
      evidenceTierBadge: json['evidence_tier_badge'] as String? ?? '🟢 공시 팩트',
      summary: json['summary'] as String? ?? '',
      sourceAgency: json['source_agency'] as String? ?? '',
      sourceUrl: json['source_url'] as String? ?? '',
    );
  }
}

class StockImpactDetailModel {
  final String corpCode;
  final String ticker;
  final String companyName;
  final String roleTier;
  final String roleTierLabel;
  final String factorGrade;
  final double d0Return;
  final double carD5;
  final double volumeSpikeRatio;
  final double peakReturn;
  final String marketReactionGrade;
  final String connectionHook;

  StockImpactDetailModel({
    required this.corpCode,
    required this.ticker,
    required this.companyName,
    required this.roleTier,
    required this.roleTierLabel,
    required this.factorGrade,
    required this.d0Return,
    required this.carD5,
    required this.volumeSpikeRatio,
    required this.peakReturn,
    required this.marketReactionGrade,
    required this.connectionHook,
  });

  factory StockImpactDetailModel.fromJson(Map<String, dynamic> json) {
    return StockImpactDetailModel(
      corpCode: json['corp_code'] as String? ?? '',
      ticker: json['ticker'] as String? ?? '',
      companyName: json['company_name'] as String? ?? '',
      roleTier: json['role_tier'] as String? ?? 'PRIMARY_ANCHOR',
      roleTierLabel: json['role_tier_label'] as String? ?? '👑 1티어 대장주',
      factorGrade: json['factor_grade'] as String? ?? 'A+',
      d0Return: (json['d0_return'] as num?)?.toDouble() ?? 0.0,
      carD5: (json['car_d5'] as num?)?.toDouble() ?? 0.0,
      volumeSpikeRatio: (json['volume_spike_ratio'] as num?)?.toDouble() ?? 1.0,
      peakReturn: (json['peak_return'] as num?)?.toDouble() ?? 0.0,
      marketReactionGrade: json['market_reaction_grade'] as String? ?? '⚡ 강세',
      connectionHook: json['connection_hook'] as String? ?? '',
    );
  }
}

class EventStockImpactModel {
  final String status;
  final PoliticalEventModel event;
  final int totalAffectedStocks;
  final double avgD0Return;
  final double avgCarD5;
  final List<StockImpactDetailModel> stocks;

  EventStockImpactModel({
    required this.status,
    required this.event,
    required this.totalAffectedStocks,
    required this.avgD0Return,
    required this.avgCarD5,
    required this.stocks,
  });

  factory EventStockImpactModel.fromJson(Map<String, dynamic> json) {
    return EventStockImpactModel(
      status: json['status'] as String? ?? 'success',
      event: PoliticalEventModel.fromJson(json['event'] as Map<String, dynamic>? ?? {}),
      totalAffectedStocks: json['total_affected_stocks'] as int? ?? 0,
      avgD0Return: (json['avg_d0_return'] as num?)?.toDouble() ?? 0.0,
      avgCarD5: (json['avg_car_d5'] as num?)?.toDouble() ?? 0.0,
      stocks: (json['stocks'] as List<dynamic>?)
              ?.map((e) => StockImpactDetailModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
