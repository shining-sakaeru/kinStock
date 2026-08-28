import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/models/event_poll_models.dart';
import '../../core/utils/url_launcher_helper.dart';

class PollLeaderboardPanel extends StatelessWidget {
  final PollLeaderboardModel? pollData;
  final bool isLoading;
  final String currentPersonId;
  final Function(String personId, String personName) onSelectCandidate;

  const PollLeaderboardPanel({
    super.key,
    required this.pollData,
    required this.isLoading,
    required this.currentPersonId,
    required this.onSelectCandidate,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CupertinoActivityIndicator(radius: 12, color: Color(0xFF38BDF8)),
        ),
      );
    }

    if (pollData == null || pollData!.leaderboard.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('여론조사 데이터가 없습니다.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
      );
    }

    final latest = pollData!.latestPoll;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Poll Agency & Date Header with Direct Official URL
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: const Color(0xFF0F172A),
          child: Row(
            children: [
              const Icon(CupertinoIcons.chart_pie_fill, size: 13, color: Color(0xFF38BDF8)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => UrlLauncherHelper.launch(latest.sourceUrl),
                child: Row(
                  children: [
                    Text(
                      '${latest.agency} (${latest.surveyedAt})',
                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 4),
                    const Icon(CupertinoIcons.link, size: 10, color: Color(0xFF38BDF8)),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '표본 ${latest.sampleSize}명 (±${latest.marginOfError}%)',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
              ),
            ],
          ),
        ),

        // Candidate List
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              itemCount: pollData!.leaderboard.length,
              itemBuilder: (context, idx) {
                final cand = pollData!.leaderboard[idx];
                final isSelected = cand.personId == currentPersonId || currentPersonId.contains(cand.personName);
                final isPositiveDelta = cand.deltaRate >= 0;

                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF38BDF8).withOpacity(0.15) : const Color(0xFF0F172A).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      leading: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: cand.rank == 1
                              ? const Color(0xFFF59E0B)
                              : (cand.rank <= 3 ? const Color(0xFF38BDF8) : const Color(0xFF334155)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${cand.rank}',
                          style: TextStyle(
                            color: cand.rank <= 3 ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w900,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            cand.personName,
                            style: const TextStyle(
                              color: Color(0xFFF8FAFC),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: Text(
                              cand.partyOrGroup,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        cand.roleTitle,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${cand.approvalRate.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPositiveDelta ? CupertinoIcons.arrow_up : CupertinoIcons.arrow_down,
                                    size: 9,
                                    color: isPositiveDelta ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                                  ),
                                  Text(
                                    '${isPositiveDelta ? '+' : ''}${cand.deltaRate.toStringAsFixed(1)}%p',
                                    style: TextStyle(
                                      color: isPositiveDelta ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(width: 6),
                          const Icon(CupertinoIcons.chevron_right, size: 12, color: Color(0xFF64748B)),
                        ],
                      ),
                      onTap: () => onSelectCandidate(cand.personId, cand.personName),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
