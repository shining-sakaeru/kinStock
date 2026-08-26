// ==============================================================================
// KinStock Enterprise DDL: Neo4j Schema & Unique Constraints Policy
// Philosophy: "Discard raw verbose data, index normalized facts with evidence"
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

// 3. Schema Documentation & Relationship Types
// ------------------------------------------------------------------------------
// Node Labels:
// (:Company {corp_code: String, stock_code: String, name: String, industry: String, market_type: String})
// (:Person {person_id: String, name: String, birth_ym: String, gender: String, current_role: String})
// (:Report {rcept_no: String, corp_code: String, report_name: String, filing_date: String, source_url: String})
// (:School {school_code: String, name: String, school_type: String})
// (:Region {region_code: String, name: String})
//
// Physical Relationships with Mandatory Audit Metadata:
// (:Person)-[:SERVES_AS {role: String, is_executive: Boolean, tenure: String, rcept_no: String, evidence: String, created_at: DateTime, updated_at: DateTime}]->(:Company)
// (:Person)-[:OWNS_STAKE {stake_ratio: Float, is_major_shareholder: Boolean, rcept_no: String, evidence: String, created_at: DateTime, updated_at: DateTime}]->(:Company)
// (:Person)-[:GRADUATED_FROM {degree: String, major: String, rcept_no: String, evidence: String, created_at: DateTime, updated_at: DateTime}]->(:School)
// (:Person)-[:ORIGINATES_FROM {rcept_no: String, evidence: String, created_at: DateTime, updated_at: DateTime}]->(:Region)
// (:Company)-[:AFFILIATED_WITH {stake_ratio: Float, relation_type: String, rcept_no: String, evidence: String, created_at: DateTime, updated_at: DateTime}]->(:Company)
// (:Company)-[:PUBLISHED_REPORT]->(:Report)
//
// Virtual Inference (No physical edge stored to prevent O(N^2) Graph Explosion):
// (p1:Person)-[:SERVES_AS]->(c:Company)<-[:SERVES_AS]-(p2:Person) => Real-time Colleague Synapse Query
