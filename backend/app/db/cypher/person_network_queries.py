"""
Cypher Query Definitions for Person-to-Person Multi-Dimensional Kin-Bond & Corporate Trace
"""

# 1. Person-to-Person Multi-Dimensional Synergy Query
P2P_MULTI_DIMENSIONAL_QUERY = """
MATCH (p1:Person {id: $person1_id})
MATCH (p2:Person {id: $person2_id})
OPTIONAL MATCH (p1)-[r_alm:ALUMNI_WITH]-(p2)
OPTIONAL MATCH (p1)-[r_jud:JUDICIAL_COHORT_WITH]-(p2)
OPTIONAL MATCH (p1)-[r_reg:HOMETOWN_WITH]-(p2)
OPTIONAL MATCH (p1)-[r_car:CO_WORKED_WITH]-(p2)
OPTIONAL MATCH (p1)-[r_fam:FAMILY_WITH]-(p2)
RETURN
    properties(p1) AS p1,
    properties(p2) AS p2,
    properties(r_alm) AS alumni_edge,
    properties(r_jud) AS judicial_edge,
    properties(r_reg) AS hometown_edge,
    properties(r_car) AS career_edge,
    properties(r_fam) AS family_edge
"""

# 2. Person Network Subgraph with Perspective & Seniority Filtering
PERSON_PERSPECTIVE_SUBGRAPH_QUERY = """
MATCH (p1:Person {id: $person_id})
MATCH (p1)-[r]-(p2:Person)
WHERE (
    ($perspective = 'COMPREHENSIVE') OR
    ($perspective = 'ALUMNI_FOCUSED' AND type(r) = 'ALUMNI_WITH') OR
    ($perspective = 'LEGAL_ELITE' AND (type(r) = 'JUDICIAL_COHORT_WITH' OR (type(r) = 'ALUMNI_WITH' AND r.major CONTAINS '법'))) OR
    ($perspective = 'REGIONAL_TIES' AND type(r) = 'HOMETOWN_WITH') OR
    ($perspective = 'CHAEROK_NETWORK' AND type(r) = 'CO_WORKED_WITH')
)
AND ($max_seniority_gap IS NULL OR r.delta_years IS NULL OR abs(r.delta_years) <= $max_seniority_gap)
OPTIONAL MATCH (p2)-[r_corp:SERVES_AS|OWNS_STAKE]->(c:Company)
RETURN
    properties(p1) AS center_person,
    properties(p2) AS related_person,
    type(r) AS p2p_relation_type,
    properties(r) AS p2p_edge,
    properties(r_corp) AS corp_edge,
    properties(c) AS target_company
LIMIT $limit
"""

# 3. Person-to-Person ➔ Company Trace Path
PERSON_TO_COMPANY_TRACE_QUERY = """
MATCH (p1:Person {id: $person_id})
MATCH (p1)-[r1:ALUMNI_WITH|JUDICIAL_COHORT_WITH|HOMETOWN_WITH|CO_WORKED_WITH|FAMILY_WITH]-(p2:Person)
MATCH (p2)-[r2:SERVES_AS|OWNS_STAKE]->(c:Company {ticker: $ticker})
RETURN
    properties(p1) AS source_person,
    type(r1) AS p2p_relation_type,
    properties(r1) AS p2p_edge,
    properties(p2) AS intermediary_person,
    type(r2) AS corp_relation_type,
    properties(r2) AS corp_edge,
    properties(c) AS target_company
"""
