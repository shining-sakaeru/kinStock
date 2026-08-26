// ==============================================================================
// KinStock Synapse Network Graph Schema & Index DDL for Neo4j 5.x
// ==============================================================================

// 1. Uniqueness Constraints
CREATE CONSTRAINT person_id_unique IF NOT EXISTS
FOR (p:Person) REQUIRE p.id IS UNIQUE;

CREATE CONSTRAINT company_corp_code_unique IF NOT EXISTS
FOR (c:Company) REQUIRE c.corp_code IS UNIQUE;

CREATE CONSTRAINT company_stock_code_unique IF NOT EXISTS
FOR (c:Company) REQUIRE c.stock_code IS UNIQUE;

CREATE CONSTRAINT school_name_unique IF NOT EXISTS
FOR (s:School) REQUIRE s.name IS UNIQUE;

CREATE CONSTRAINT region_name_unique IF NOT EXISTS
FOR (r:Region) REQUIRE r.name IS UNIQUE;

CREATE CONSTRAINT theme_id_unique IF NOT EXISTS
FOR (t:Theme) REQUIRE t.id IS UNIQUE;

// 2. Performance Search Indices
CREATE INDEX person_name_idx IF NOT EXISTS
FOR (p:Person) ON (p.name);

CREATE INDEX company_name_idx IF NOT EXISTS
FOR (c:Company) ON (c.name);

CREATE INDEX company_industry_idx IF NOT EXISTS
FOR (c:Company) ON (c.industry);

CREATE INDEX school_type_idx IF NOT EXISTS
FOR (s:School) ON (s.type);

// 3. Schema Documentation & Synapse Modeling Rules
// ------------------------------------------------------------------------------
// Node Labels:
// (:Person {id, name, role_title, birth_year, birth_place, education: [], career: [], source_url})
// (:Company {id, corp_code, stock_code, name, industry, current_price, price_change_rate, market_cap, source_url})
// (:School {name, type}) // type: HIGH_SCHOOL, UNIVERSITY, GRAD_SCHOOL
// (:Region {name})
// (:Theme {id, code, title, short_title, description, badge_color})
//
// Relationship Types:
// (:Person)-[:WORKS_AT {role: String, is_executive: Boolean, tenure: String, source_url: String, rcp_no: String}]->(:Company)
// (:Person)-[:OWNS_STAKE {ratio: Float, is_major_shareholder: Boolean, source_url: String, rcp_no: String}]->(:Company)
// (:Person)-[:ALUMNI_WITH {school_name: String, major: String, period: String, weight: Float, evidence: String}]->(:Person)
// (:Person)-[:HOMETOWN_WITH {region_name: String, weight: Float, evidence: String}]->(:Person)
// (:Person)-[:COLLEAGUE_WITH {company_name: String, overlap_period: String, weight: Float, evidence: String}]->(:Person)
// (:Company)-[:AFFILIATE_WITH {type: String, stake_ratio: Float, evidence: String}]->(:Company)
// (:Person)-[:BELONGS_TO_THEME]->(:Theme)
