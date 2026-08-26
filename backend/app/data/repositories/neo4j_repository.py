import os
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime, timezone
try:
    from neo4j import GraphDatabase, Driver
except ImportError:
    GraphDatabase = None
    Driver = None

logger = logging.getLogger("KinStock.Neo4jRepository")

class Neo4jRepository:
    """
    High-Performance Batch Upsert DAO with Neo4j Python Driver:
    1. Uses UNWIND queries for single-transaction batch MERGE execution.
    2. Enforces strict audit metadata (rcept_no, evidence, created_at, updated_at).
    3. Live search and subgraph queries directly against Neo4j DB for frontend sync.
    """

    def __init__(self, uri: Optional[str] = None, user: Optional[str] = None, password: Optional[str] = None):
        self.uri = uri or os.getenv("NEO4J_URI", "bolt://localhost:7687")
        self.user = user or os.getenv("NEO4J_USER", "neo4j")
        self.password = password or os.getenv("NEO4J_PASSWORD", "kinstock2024!")
        self._driver: Optional[Driver] = None

    def get_driver(self) -> Optional[Driver]:
        if GraphDatabase is None:
            return None
        if self._driver is None:
            try:
                self._driver = GraphDatabase.driver(self.uri, auth=(self.user, self.password))
            except Exception as e:
                logger.warning(f"Failed to connect to Neo4j driver: {e}")
                return None
        return self._driver

    def close(self):
        if self._driver:
            self._driver.close()

    # --------------------------------------------------------------------------
    # 1. Search Query Methods (Direct Neo4j Real-Time Sync)
    # --------------------------------------------------------------------------
    def search_companies(self, query_str: str, limit: int = 5) -> List[Dict[str, Any]]:
        driver = self.get_driver()
        if not driver:
            return []
        cypher = """
        MATCH (c:Company)
        WHERE toLower(c.name) CONTAINS toLower($q) 
           OR c.stock_code CONTAINS $q 
           OR toLower(c.industry) CONTAINS toLower($q)
        RETURN c.corp_code AS corp_code, c.stock_code AS stock_code, c.name AS name, c.industry AS industry
        LIMIT $limit
        """
        try:
            with driver.session() as session:
                result = session.run(cypher, q=query_str, limit=limit)
                return [record.data() for record in result]
        except Exception as e:
            logger.warning(f"Neo4j search_companies error: {e}")
            return []

    def search_persons(self, query_str: str, limit: int = 5) -> List[Dict[str, Any]]:
        driver = self.get_driver()
        if not driver:
            return []
        cypher = """
        MATCH (p:Person)
        WHERE toLower(p.name) CONTAINS toLower($q)
           OR toLower(p.current_role) CONTAINS toLower($q)
        RETURN p.person_id AS person_id, p.name AS name, p.current_role AS current_role
        LIMIT $limit
        """
        try:
            with driver.session() as session:
                result = session.run(cypher, q=query_str, limit=limit)
                return [record.data() for record in result]
        except Exception as e:
            logger.warning(f"Neo4j search_persons error: {e}")
            return []

    def get_company_subgraph(self, identifier: str) -> Optional[Dict[str, Any]]:
        driver = self.get_driver()
        if not driver:
            return None
        cypher = """
        MATCH (c:Company)
        WHERE c.corp_code = $id OR c.stock_code = $id OR c.name = $id
        OPTIONAL MATCH (p:Person)-[r:SERVES_AS]->(c)
        OPTIONAL MATCH (p2:Person)-[r2:OWNS_STAKE]->(c)
        RETURN properties(c) AS c,
               [item IN collect(DISTINCT {person: properties(p), rel: properties(r)}) WHERE item.person IS NOT NULL] AS executives,
               [item IN collect(DISTINCT {person: properties(p2), rel: properties(r2)}) WHERE item.person IS NOT NULL] AS shareholders
        LIMIT 1
        """
        try:
            with driver.session() as session:
                result = session.run(cypher, id=identifier)
                record = result.single()
                if record and record.get("c"):
                    return record.data()
        except Exception as e:
            logger.warning(f"Neo4j get_company_subgraph error: {e}")
        return None

    def get_person_subgraph(self, identifier: str) -> Optional[Dict[str, Any]]:
        driver = self.get_driver()
        if not driver:
            return None
        cypher = """
        MATCH (p:Person)
        WHERE p.person_id = $id OR p.name = $id
        OPTIONAL MATCH (p)-[r:SERVES_AS]->(c:Company)
        OPTIONAL MATCH (p)-[r2:OWNS_STAKE]->(c2:Company)
        RETURN properties(p) AS p,
               [item IN collect(DISTINCT {company: properties(c), rel: properties(r)}) WHERE item.company IS NOT NULL] AS roles,
               [item IN collect(DISTINCT {company: properties(c2), rel: properties(r2)}) WHERE item.company IS NOT NULL] AS stakes
        LIMIT 1
        """
        try:
            with driver.session() as session:
                result = session.run(cypher, id=identifier)
                record = result.single()
                if record and record.get("p"):
                    return record.data()
        except Exception as e:
            logger.warning(f"Neo4j get_person_subgraph error: {e}")
        return None

    # --------------------------------------------------------------------------
    # 2. Batch Upsert Companies & Reports
    # --------------------------------------------------------------------------
    def upsert_companies(self, companies: List[Dict[str, Any]]) -> int:
        if not companies:
            return 0
        driver = self.get_driver()
        if not driver:
            return len(companies)
        query = """
        UNWIND $batch AS row
        MERGE (c:Company {corp_code: row.corp_code})
        ON CREATE SET
            c.stock_code = row.stock_code,
            c.name = row.name,
            c.industry = row.industry,
            c.market_type = row.market_type,
            c.created_at = datetime()
        ON MATCH SET
            c.stock_code = coalesce(row.stock_code, c.stock_code),
            c.name = coalesce(row.name, c.name),
            c.industry = coalesce(row.industry, c.industry),
            c.updated_at = datetime()
        """
        try:
            with driver.session() as session:
                session.run(query, batch=companies)
                return len(companies)
        except Exception as e:
            logger.warning(f"Neo4j offline fallback (upsert_companies): {e}")
            return len(companies)

    def upsert_reports(self, reports: List[Dict[str, Any]]) -> int:
        if not reports:
            return 0
        driver = self.get_driver()
        if not driver:
            return len(reports)
        query = """
        UNWIND $batch AS row
        MERGE (r:Report {rcept_no: row.rcept_no})
        ON CREATE SET
            r.corp_code = row.corp_code,
            r.report_name = row.report_name,
            r.filing_date = row.filing_date,
            r.source_url = row.source_url,
            r.created_at = datetime()
        ON MATCH SET
            r.report_name = row.report_name,
            r.updated_at = datetime()
        WITH r, row
        MATCH (c:Company {corp_code: row.corp_code})
        MERGE (r)-[:FILED_BY]->(c)
        """
        try:
            with driver.session() as session:
                session.run(query, batch=reports)
                return len(reports)
        except Exception as e:
            logger.warning(f"Neo4j offline fallback (upsert_reports): {e}")
            return len(reports)

    # --------------------------------------------------------------------------
    # 3. Batch Upsert Persons & Physical Edges with Audit Metadata
    # --------------------------------------------------------------------------
    def upsert_persons(self, persons: List[Dict[str, Any]]) -> int:
        if not persons:
            return 0
        driver = self.get_driver()
        if not driver:
            return len(persons)
        query = """
        UNWIND $batch AS row
        MERGE (p:Person {person_id: row.person_id})
        ON CREATE SET
            p.name = row.name,
            p.birth_ym = row.birth_ym,
            p.gender = row.gender,
            p.current_role = row.current_role,
            p.created_at = datetime()
        ON MATCH SET
            p.current_role = coalesce(row.current_role, p.current_role),
            p.updated_at = datetime()
        """
        try:
            with driver.session() as session:
                session.run(query, batch=persons)
                return len(persons)
        except Exception as e:
            logger.warning(f"Neo4j offline fallback (upsert_persons): {e}")
            return len(persons)

    def upsert_serves_as_edges(self, edges: List[Dict[str, Any]]) -> int:
        if not edges:
            return 0
        driver = self.get_driver()
        if not driver:
            return len(edges)
        query = """
        UNWIND $batch AS row
        MATCH (p:Person {person_id: row.person_id})
        MATCH (c:Company {corp_code: row.corp_code})
        MERGE (p)-[r:SERVES_AS]->(c)
        ON CREATE SET
            r.role = row.role,
            r.is_executive = row.is_executive,
            r.tenure = row.tenure,
            r.source_tier = row.source_tier,
            r.source_name = row.source_name,
            r.source_ref_id = row.source_ref_id,
            r.evidence_text = row.evidence_text,
            r.rcept_no = row.rcept_no,
            r.evidence = row.evidence,
            r.source_url = row.source_url,
            r.verified_at = row.verified_at,
            r.created_at = datetime(),
            r.updated_at = datetime()
        ON MATCH SET
            r.role = row.role,
            r.is_executive = row.is_executive,
            r.tenure = coalesce(row.tenure, r.tenure),
            r.source_ref_id = row.source_ref_id,
            r.evidence_text = row.evidence_text,
            r.rcept_no = row.rcept_no,
            r.evidence = row.evidence,
            r.source_url = row.source_url,
            r.verified_at = row.verified_at,
            r.updated_at = datetime()
        """
        try:
            with driver.session() as session:
                session.run(query, batch=edges)
                return len(edges)
        except Exception as e:
            logger.warning(f"Neo4j offline fallback (upsert_serves_as): {e}")
            return len(edges)

    def upsert_owns_stake_edges(self, edges: List[Dict[str, Any]]) -> int:
        if not edges:
            return 0
        driver = self.get_driver()
        if not driver:
            return len(edges)
        query = """
        UNWIND $batch AS row
        MATCH (p:Person {person_id: row.person_id})
        MATCH (c:Company {corp_code: row.corp_code})
        MERGE (p)-[r:OWNS_STAKE]->(c)
        ON CREATE SET
            r.stake_ratio = toFloat(row.stake_ratio),
            r.is_major_shareholder = row.is_major_shareholder,
            r.source_tier = row.source_tier,
            r.source_name = row.source_name,
            r.source_ref_id = row.source_ref_id,
            r.evidence_text = row.evidence_text,
            r.rcept_no = row.rcept_no,
            r.evidence = row.evidence,
            r.source_url = row.source_url,
            r.verified_at = row.verified_at,
            r.created_at = datetime(),
            r.updated_at = datetime()
        ON MATCH SET
            r.stake_ratio = toFloat(row.stake_ratio),
            r.is_major_shareholder = row.is_major_shareholder,
            r.source_ref_id = row.source_ref_id,
            r.evidence_text = row.evidence_text,
            r.rcept_no = row.rcept_no,
            r.evidence = row.evidence,
            r.source_url = row.source_url,
            r.verified_at = row.verified_at,
            r.updated_at = datetime()
        """
        try:
            with driver.session() as session:
                session.run(query, batch=edges)
                return len(edges)
        except Exception as e:
            logger.warning(f"Neo4j offline fallback (upsert_owns_stake): {e}")
            return len(edges)

    def upsert_graduated_from_edges(self, edges: List[Dict[str, Any]]) -> int:
        if not edges:
            return 0
        driver = self.get_driver()
        if not driver:
            return len(edges)
        query = """
        UNWIND $batch AS row
        MATCH (p:Person {person_id: row.person_id})
        MERGE (s:School {school_code: row.school_code})
        ON CREATE SET s.name = row.school_name, s.school_type = row.school_type
        MERGE (p)-[r:GRADUATED_FROM]->(s)
        ON CREATE SET
            r.degree = row.degree,
            r.major = row.major,
            r.source_tier = row.source_tier,
            r.source_name = row.source_name,
            r.source_ref_id = row.source_ref_id,
            r.evidence_text = row.evidence_text,
            r.rcept_no = row.rcept_no,
            r.evidence = row.evidence,
            r.source_url = row.source_url,
            r.verified_at = row.verified_at,
            r.created_at = datetime(),
            r.updated_at = datetime()
        ON MATCH SET
            r.major = coalesce(row.major, r.major),
            r.source_ref_id = row.source_ref_id,
            r.evidence_text = row.evidence_text,
            r.rcept_no = row.rcept_no,
            r.evidence = row.evidence,
            r.source_url = row.source_url,
            r.verified_at = row.verified_at,
            r.updated_at = datetime()
        """
        try:
            with driver.session() as session:
                session.run(query, batch=edges)
                return len(edges)
        except Exception as e:
            logger.warning(f"Neo4j offline fallback (upsert_graduated_from): {e}")
            return len(edges)

    # --------------------------------------------------------------------------
    # 4. Graph Explosion Prevention: Real-Time On-The-Fly Colleague Synapse Inference
    # --------------------------------------------------------------------------
    def get_inferred_colleagues(self, person_id: str) -> List[Dict[str, Any]]:
        driver = self.get_driver()
        if not driver:
            return []
        query = """
        MATCH (p1:Person {person_id: $person_id})-[r1:SERVES_AS]->(c:Company)<-[r2:SERVES_AS]-(p2:Person)
        WHERE p1.person_id <> p2.person_id
        RETURN
            p2.person_id AS colleague_id,
            p2.name AS colleague_name,
            c.name AS shared_company_name,
            c.corp_code AS shared_corp_code,
            r1.role AS person_role,
            r2.role AS colleague_role,
            r2.rcept_no AS latest_rcept_no,
            "DART 공시 기록 기준 " + c.name + " 공동 재직 (본인: " + r1.role + ", 동료: " + r2.role + ")" AS evidence
        ORDER BY c.name
        LIMIT 50
        """
        try:
            with driver.session() as session:
                result = session.run(query, person_id=person_id)
                return [record.data() for record in result]
        except Exception as e:
            logger.warning(f"Neo4j get_inferred_colleagues error: {e}")
            return []

neo4j_repository = Neo4jRepository()
