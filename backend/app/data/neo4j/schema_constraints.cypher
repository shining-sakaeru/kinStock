// ==============================================================================
// KinStock Enterprise DDL: Source Tier & Audit Constraints Policy
// Philosophy: "Strict audit metadata & 3-Tier Source Provenance on all Graph Edges"
// ==============================================================================

// 1. Uniqueness Constraints (Physical Duplication Prevention)
CREATE CONSTRAINT company_corp_code_unique IF NOT EXISTS
FOR (c:Company) REQUIRE c.corp_code IS UNIQUE;

CREATE CONSTRAINT person_id_unique IF NOT EXISTS
FOR (p:Person) REQUIRE p.person_id IS UNIQUE;

CREATE CONSTRAINT report_rcept_no_unique IF NOT EXISTS
FOR (r:Report) REQUIRE r.rcept_no IS UNIQUE;

CREATE CONSTRAINT school_code_unique IF NOT EXISTS
FOR (s:School) REQUIRE s.school_code IS UNIQUE;

CREATE CONSTRAINT region_code_unique IF NOT EXISTS
FOR (r:Region) REQUIRE r.region_code IS UNIQUE;

// 2. High-Performance B-Tree Search Indices
CREATE INDEX company_stock_code_idx IF NOT EXISTS
FOR (c:Company) ON (c.stock_code);

CREATE INDEX company_name_idx IF NOT EXISTS
FOR (c:Company) ON (c.name);

CREATE INDEX person_name_idx IF NOT EXISTS
FOR (p:Person) ON (p.name);

CREATE INDEX report_filing_date_idx IF NOT EXISTS
FOR (r:Report) ON (r.filing_date);

CREATE INDEX school_type_idx IF NOT EXISTS
FOR (s:School) ON (s.school_type);

// 3. Audit Provenance Indices on Relationship Properties
// ------------------------------------------------------------------------------
// All Relationships strictly enforce the following 6 audit metadata properties:
// - source_tier: 'TIER_1_LEGAL' | 'TIER_2_PUBLIC' | 'TIER_3_NEWS'
// - source_name: 'DART' | 'KIND' | 'DATA_GO_KR' | 'BIG_KINDS' | 'NAVER_FINANCE'
// - source_ref_id: String (14-digit rcept_no or document ID)
// - evidence_text: String (exact quotation of filing/document)
// - source_url: String (direct HTTPS link to official web viewer)
// - verified_at: DateTime / ISO8601 String
//
// Core Relationship Schema:
// (:Person)-[:SERVES_AS {role, is_executive, tenure, source_tier, source_name, source_ref_id, evidence_text, source_url, verified_at, created_at, updated_at}]->(:Company)
// (:Person)-[:OWNS_STAKE {stake_ratio, is_major_shareholder, source_tier, source_name, source_ref_id, evidence_text, source_url, verified_at, created_at, updated_at}]->(:Company)
// (:Person)-[:ALUMNI_WITH {school_name, school_code, major, source_tier, source_name, source_ref_id, evidence_text, source_url, verified_at}]->(:Person)
// (:Person)-[:HOMETOWN_WITH {region_name, region_code, source_tier, source_name, source_ref_id, evidence_text, source_url, verified_at}]->(:Person)
// (:Person)-[:GRADUATED_FROM {degree, major, source_tier, source_name, source_ref_id, evidence_text, source_url, verified_at}]->(:School)
// (:Person)-[:ORIGINATES_FROM {source_tier, source_name, source_ref_id, evidence_text, source_url, verified_at}]->(:Region)
// (:Company)-[:PUBLISHED_REPORT]->(:Report)
