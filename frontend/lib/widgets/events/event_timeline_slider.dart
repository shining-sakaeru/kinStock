import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/models/event_poll_models.dart';

class EventTimelineSlider extends StatelessWidget {
  final List<PoliticalEventModel> events;
  final bool isLoading;
  final String? selectedEventId;
  final Function(PoliticalEventModel event) onSelectEvent;

  const EventTimelineSlider({
    super.key,
    required this.events,
    required this.isLoading,
    this.selectedEventId,
    required this.onSelectEvent,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: const Color(0xFF0F172A),
        child: const Row(
          children: [
            CupertinoActivityIndicator(radius: 10, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('정치 이벤트 타임라인 로드 중...', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5)),
          ],
        ),
      );
    }

    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          // Left Label
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  Icon(CupertinoIcons.calendar, size: 12, color: Color(0xFFF59E0B)),
                  SizedBox(width: 4),
                  Text(
                    '이벤트 타임라인',
                    style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              SizedBox(height: 2),
              Text(
                '사건별 주가 반응(CAR)',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 40, color: const Color(0xFF334155)),
          const SizedBox(width: 12),

          // Horizontal Event Carousel
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: events.length,
              itemBuilder: (context, index) {
                final ev = events[index];
                final isSelected = ev.eventId == selectedEventId;

                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => onSelectEvent(ev),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF59E0B).withOpacity(0.18) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF334155),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  ev.eventTypeLabel,
                                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                ev.occurredAt,
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                ev.evidenceTierBadge,
                                style: const TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 220,
                            child: Text(
                              ev.title,
                              style: const TextStyle(
                                color: Color(0xFFF8FAFC),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
