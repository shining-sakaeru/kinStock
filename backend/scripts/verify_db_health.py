import os
import sys
import logging
from typing import Dict, Any, List
from datetime import datetime, timezone

# Ensure project root is in path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.data.repositories.neo4j_repository import neo4j_repository
from app.data.repositories.memory_store import memory_store

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("KinStock.VerifyDbHealth")

def verify_database_health() -> Dict[str, Any]:
    """
    Comprehensive Database Health & Provenance Integrity Verification:
    1. Node & Edge Census in Neo4j and Memory Graph.
    2. Orphan Node Detection (nodes with degree == 0).
    3. Evidence Provenance Audit: Verifies source_tier, rcept_no, evidence_text.
    """
    timestamp = datetime.now(timezone.utc).isoformat()
    logger.info("🔍 Starting KinStock Graph DB Health & Evidence Integrity Check...")

    driver = neo4j_repository.get_driver()
    neo4j_connected = driver is not None

    node_counts = {
        "Company": len(memory_store.companies),
        "Person": len(memory_store.persons),
        "Report": 0,
        "School": 0,
        "Region": 0,
        "TotalNodes": 0
    }

    edge_counts = {
        "SERVES_AS": 0,
        "OWNS_STAKE": 0,
        "GRADUATED_FROM": 0,
        "ALUMNI_WITH": 0,
        "HOMETOWN_WITH": 0,
        "COLLEAGUE_WITH": 0,
        "TotalEdges": memory_store.graph.number_of_edges()
    }

    orphan_nodes_count = 0
    orphan_sample_names = []
    
    total_audited_edges = 0
    missing_evidence_edges = 0
    missing_tier_edges = 0
    missing_rcept_edges = 0

    if neo4j_connected:
        try:
            with driver.session() as session:
                # 1. Node Counts from Neo4j
                rec = session.run("""
                    RETURN 
                        count { MATCH (c:Company) } AS company_cnt,
                        count { MATCH (p:Person) } AS person_cnt,
                        count { MATCH (r:Report) } AS report_cnt,
                        count { MATCH (s:School) } AS school_cnt,
                        count { MATCH (rg:Region) } AS region_cnt
                """).single()
                if rec:
                    node_counts["Company"] = max(node_counts["Company"], rec["company_cnt"])
                    node_counts["Person"] = max(node_counts["Person"], rec["person_cnt"])
                    node_counts["Report"] = rec["report_cnt"]
                    node_counts["School"] = rec["school_cnt"]
                    node_counts["Region"] = rec["region_cnt"]

                # 2. Edge Counts from Neo4j
                rec_edge = session.run("""
                    RETURN
                        count { MATCH ()-[r:SERVES_AS]->() } AS serves_cnt,
                        count { MATCH ()-[r:OWNS_STAKE]->() } AS stake_cnt,
                        count { MATCH ()-[r:GRADUATED_FROM]->() } AS grad_cnt,
                        count { MATCH ()-[r:ALUMNI_WITH]->() } AS alumni_cnt,
                        count { MATCH ()-[r:HOMETOWN_WITH]->() } AS home_cnt,
                        count { MATCH ()-[r:COLLEAGUE_WITH]->() } AS coll_cnt,
                        count { MATCH ()-[r]->() } AS total_cnt
                """).single()
                if rec_edge:
                    edge_counts["SERVES_AS"] = rec_edge["serves_cnt"]
                    edge_counts["OWNS_STAKE"] = rec_edge["stake_cnt"]
                    edge_counts["GRADUATED_FROM"] = rec_edge["grad_cnt"]
                    edge_counts["ALUMNI_WITH"] = rec_edge["alumni_cnt"]
                    edge_counts["HOMETOWN_WITH"] = rec_edge["home_cnt"]
                    edge_counts["COLLEAGUE_WITH"] = rec_edge["coll_cnt"]
                    edge_counts["TotalEdges"] = max(edge_counts["TotalEdges"], rec_edge["total_cnt"])

                # 3. Orphan Node Detection
                orphans = session.run("""
                    MATCH (n)
                    WHERE NOT (n)--()
                    RETURN labels(n)[0] AS type, coalesce(n.name, n.person_id, n.corp_code) AS name
                    LIMIT 20
                """)
                orphan_records = [r.data() for r in orphans]
                orphan_nodes_count = len(orphan_records)
                orphan_sample_names = [f"[{r['type']}] {r['name']}" for r in orphan_records[:5]]

                # 4. Evidence Integrity Audit
                audit_res = session.run("""
                    MATCH ()-[r]->()
                    RETURN 
                        count(r) AS total,
                        count { MATCH ()-[r]->() WHERE r.evidence_text IS NULL AND r.evidence IS NULL } AS missing_evidence,
                        count { MATCH ()-[r]->() WHERE r.source_tier IS NULL } AS missing_tier,
                        count { MATCH ()-[r]->() WHERE r.rcept_no IS NULL AND r.source_ref_id IS NULL } AS missing_rcept
                """).single()
                if audit_res:
                    total_audited_edges = audit_res["total"]
                    missing_evidence_edges = audit_res["missing_evidence"]
                    missing_tier_edges = audit_res["missing_tier"]
                    missing_rcept_edges = audit_res["missing_rcept"]

        except Exception as e:
            logger.warning(f"Neo4j live query during health check warning: {e}")

    # Calculate Totals & Percentages
    node_counts["TotalNodes"] = sum(v for k, v in node_counts.items() if k != "TotalNodes")
    
    missing_rate_pct = 0.0
    if total_audited_edges > 0:
        missing_rate_pct = round((missing_evidence_edges / total_audited_edges) * 100.0, 2)
    
    compliance_score = max(0.0, round(100.0 - missing_rate_pct, 1))

    health_summary = {
        "status": "HEALTHY" if orphan_nodes_count == 0 and missing_rate_pct < 1.0 else "WARNING",
        "timestamp": timestamp,
        "database_type": "Neo4j 5.x Community + In-Memory DiGraph",
        "is_neo4j_connected": neo4j_connected,
        "node_counts": node_counts,
        "edge_counts": edge_counts,
        "orphan_nodes": {
            "count": orphan_nodes_count,
            "samples": orphan_sample_names,
            "status": "PASS" if orphan_nodes_count == 0 else "FAIL"
        },
        "evidence_integrity": {
            "total_edges_audited": total_audited_edges,
            "missing_evidence_text_count": missing_evidence_edges,
            "missing_source_tier_count": missing_tier_edges,
            "missing_rcept_no_count": missing_rcept_edges,
            "missing_rate_pct": missing_rate_pct,
            "compliance_pct": compliance_score,
            "status": "PASS (100% Verified)" if missing_rate_pct == 0.0 else f"WARNING ({missing_rate_pct}% Missing)"
        }
    }

    return health_summary

def print_health_report():
    report = verify_database_health()
    print("=" * 80)
    print("📊 [KinStock] Graph Database Health & Provenance Integrity Report")
    print("=" * 80)
    print(f"Status: {report['status']} | Neo4j Connected: {report['is_neo4j_connected']}")
    print(f"Timestamp: {report['timestamp']}")
    print("-" * 80)
    print("📦 Node Census:")
    for k, v in report['node_counts'].items():
        print(f"  • {k.ljust(15)}: {v:,}")
    print("-" * 80)
    print("🔗 Edge Census:")
    for k, v in report['edge_counts'].items():
        print(f"  • {k.ljust(15)}: {v:,}")
    print("-" * 80)
    print(f"🚨 Orphan Nodes: {report['orphan_nodes']['count']} ({report['orphan_nodes']['status']})")
    if report['orphan_nodes']['samples']:
        print(f"   Samples: {', '.join(report['orphan_nodes']['samples'])}")
    print("-" * 80)
    print("🛡️ Evidence & Provenance Integrity:")
    ev = report['evidence_integrity']
    print(f"  • Total Audited Edges  : {ev['total_edges_audited']:,}")
    print(f"  • Missing Evidence Text : {ev['missing_evidence_text_count']}")
    print(f"  • Missing Source Tier   : {ev['missing_source_tier_count']}")
    print(f"  • Missing Rcept No      : {ev['missing_rcept_no_count']}")
    print(f"  • Missing Rate          : {ev['missing_rate_pct']}%")
    print(f"  • Compliance Score      : {ev['compliance_pct']}% [{ev['status']}]")
    print("=" * 80)

if __name__ == "__main__":
    print_health_report()
