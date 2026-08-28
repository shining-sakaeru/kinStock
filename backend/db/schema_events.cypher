// ============================================================================
// KinStock Event-Study & Poll Survey Schema Constraints & Indexes
// ============================================================================

CREATE CONSTRAINT unique_poll_id IF NOT EXISTS FOR (p:PollSurvey) REQUIRE p.poll_id IS UNIQUE;
CREATE CONSTRAINT unique_event_id IF NOT EXISTS FOR (e:PoliticalEvent) REQUIRE e.event_id IS UNIQUE;
CREATE CONSTRAINT unique_impact_id IF NOT EXISTS FOR (i:PriceImpact) REQUIRE i.impact_id IS UNIQUE;

CREATE INDEX event_date_idx IF NOT EXISTS FOR (e:PoliticalEvent) ON (e.occurred_at);
CREATE INDEX event_person_idx IF NOT EXISTS FOR (e:PoliticalEvent) ON (e.person_id);
CREATE INDEX poll_survey_date_idx IF NOT EXISTS FOR (p:PollSurvey) ON (p.surveyed_at);
CREATE INDEX impact_corp_idx IF NOT EXISTS FOR (i:PriceImpact) ON (i.corp_code);
