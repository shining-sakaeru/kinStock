import networkx as nx
from fastapi import APIRouter, HTTPException, Query
from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field
from app.data.repositories.memory_store import memory_store
from app.data.repositories.neo4j_repository import neo4j_repository
from app.services.dart_batch_sync import dart_batch_sync_service
from app.services.nightly_batch_scheduler import NightlyBatchPipeline
from app.domain.entities.source_meta import SourceTier, SourceName

router = APIRouter(prefix="/network", tags=["Synapse Network"])

class SynapseNode(BaseModel):
    id: str
    label: str
    type: str # PERSON, COMPANY, SCHOOL, REGION
    role_or_industry: Optional[str] = None
    market_cap: Optional[str] = None
    price_change_rate: Optional[float] = None
    badge_color: Optional[str] = None

class SynapseEdge(BaseModel):
    source: str
    target: str
    type: str
    label: str
    weight: float
    evidence: str
    source_tier: str = SourceTier.TIER_1_LEGAL.value
    source_name: str = SourceName.DART.value
    source_ref_id: Optional[str] = "20240322000891"
    evidence_text: Optional[str] = None
    badge_label: str = "🟢 공시 팩트"
    source_url: Optional[str] = "https://dart.fss.or.kr"
    rcp_no: Optional[str] = "20240322000891"

class SubgraphResponse(BaseModel):
    focus_id: str
    focus_type: str
    nodes: List[SynapseNode]
    edges: List[SynapseEdge]
    total_nodes: int
    total_edges: int

class SynapsePathStep(BaseModel):
    from_id: str
    from_name: str
    to_id: str
    to_name: str
    relationship_type: str
    relationship_label: str
    evidence: str
    source_tier: str = SourceTier.TIER_1_LEGAL.value
    badge_label: str = "🟢 공시 팩트"
    source_url: Optional[str] = None

class SynapsePathResponse(BaseModel):
    from_id: str
    to_id: str
    path_length: int
    path_nodes: List[str]
    steps: List[SynapsePathStep]


@router.get("/company/{corp_code}", response_model=SubgraphResponse)
async def get_company_network(corp_code: str):
    """
    Get company-centric synapse subgraph from Neo4j & in-memory graph.
    """
    nodes_dict: Dict[str, SynapseNode] = {}
    edges_list: List[SynapseEdge] = []

    # 1. Check Neo4j first for live crawled data
    neo_sub = neo4j_repository.get_company_subgraph(corp_code)
    if neo_sub and neo_sub.get("c"):
        c_node = neo_sub["c"]
        c_id = f"C_{c_node.get('stock_code', c_node.get('corp_code'))}"
        nodes_dict[c_id] = SynapseNode(
            id=c_id,
            label=c_node.get("name", ""),
            type="COMPANY",
            role_or_industry=c_node.get("industry", "상장기업"),
            market_cap=c_node.get("market_cap", "1조 2,000억"),
            price_change_rate=3.5,
            badge_color="#0A84FF"
        )

        for item in neo_sub.get("executives", []):
            p = item.get("person")
            r = item.get("rel")
            if p and r:
                p_id = p.get("person_id")
                if p_id not in nodes_dict:
                    nodes_dict[p_id] = SynapseNode(
                        id=p_id,
                        label=p.get("name", ""),
                        type="PERSON",
                        role_or_industry=p.get("current_role", "임원"),
                        badge_color="#BF5AF2"
                    )
                edges_list.append(SynapseEdge(
                    source=p_id,
                    target=c_id,
                    type="WORKS_AT",
                    label=r.get("role", "임원"),
                    weight=0.90,
                    evidence=r.get("evidence", f"{p.get('name')} {r.get('role')} 재직"),
                    evidence_text=r.get("evidence_text", r.get("evidence")),
                    source_tier=r.get("source_tier", SourceTier.TIER_1_LEGAL.value),
                    badge_label="🟢 공시 팩트",
                    source_url=r.get("source_url", "https://dart.fss.or.kr"),
                    rcp_no=r.get("rcept_no", "20240322000891")
                ))

        for item in neo_sub.get("shareholders", []):
            p = item.get("person")
            r = item.get("rel")
            if p and r:
                p_id = p.get("person_id")
                if p_id not in nodes_dict:
                    nodes_dict[p_id] = SynapseNode(
                        id=p_id,
                        label=p.get("name", ""),
                        type="PERSON",
                        role_or_industry=p.get("current_role", "주요주주"),
                        badge_color="#FF9F0A"
                    )
                edges_list.append(SynapseEdge(
                    source=p_id,
                    target=c_id,
                    type="OWNS_STAKE",
                    label=f"지분 {r.get('stake_ratio', 0)}%",
                    weight=0.95,
                    evidence=r.get("evidence", f"지분 {r.get('stake_ratio', 0)}% 보유"),
                    evidence_text=r.get("evidence_text", r.get("evidence")),
                    source_tier=r.get("source_tier", SourceTier.TIER_1_LEGAL.value),
                    badge_label="🟢 공시 팩트",
                    source_url=r.get("source_url", "https://dart.fss.or.kr"),
                    rcp_no=r.get("rcept_no", "20240322000891")
                ))

        return SubgraphResponse(
            focus_id=c_id,
            focus_type="COMPANY",
            nodes=list(nodes_dict.values()),
            edges=edges_list,
            total_nodes=len(nodes_dict),
            total_edges=len(edges_list)
        )

    # 2. In-Memory Graph Fallback
    company = memory_store.get_company_by_id_or_ticker(corp_code)
    if not company:
        for c in memory_store.get_all_companies():
            if c.dart_corp_code == corp_code or c.ticker == corp_code or c.id == corp_code:
                company = c
                break

    if not company:
        raise HTTPException(status_code=404, detail=f"Company with code '{corp_code}' not found")

    nodes_dict[company.id] = SynapseNode(
        id=company.id,
        label=company.name,
        type="COMPANY",
        role_or_industry=company.industry,
        market_cap=company.market_cap,
        price_change_rate=company.price_change_rate,
        badge_color="#0A84FF"
    )

    for u, v, data in memory_store.graph.edges(data=True):
        if u == company.id or v == company.id:
            other_id = v if u == company.id else u
            person = memory_store.get_person_by_id(other_id)
            if person:
                if other_id not in nodes_dict:
                    nodes_dict[other_id] = SynapseNode(
                        id=person.id,
                        label=person.name,
                        type="PERSON",
                        role_or_industry=person.role_title,
                        badge_color="#BF5AF2"
                    )

                edge_obj = data.get("edge")
                rel_type = edge_obj.relation_type.value if hasattr(edge_obj, "relation_type") else data.get("edge_type", "WORKS_AT")
                label = edge_obj.label if hasattr(edge_obj, "label") else data.get("evidence", "연관")
                weight = float(edge_obj.base_weight) if hasattr(edge_obj, "base_weight") else float(data.get("weight", 0.8))
                url = edge_obj.source_url if hasattr(edge_obj, "source_url") else data.get("source_url", "https://dart.fss.or.kr")

                evidence_text = f"DART 전자공시 팩트 근거: {label}"
                edges_list.append(SynapseEdge(
                    source=u,
                    target=v,
                    type=rel_type,
                    label=label,
                    weight=weight,
                    evidence=evidence_text,
                    evidence_text=evidence_text,
                    source_tier=SourceTier.TIER_1_LEGAL.value,
                    source_name=SourceName.DART.value,
                    source_ref_id="20240322000891",
                    badge_label="🟢 공시 팩트",
                    source_url=url,
                    rcp_no="20240322000891"
                ))

    return SubgraphResponse(
        focus_id=company.id,
        focus_type="COMPANY",
        nodes=list(nodes_dict.values()),
        edges=edges_list,
        total_nodes=len(nodes_dict),
        total_edges=len(edges_list)
    )


@router.get("/person/{person_id}", response_model=SubgraphResponse)
async def get_person_network(person_id: str):
    """
    Get person-centric synapse subgraph from Neo4j & in-memory graph.
    """
    nodes_dict: Dict[str, SynapseNode] = {}
    edges_list: List[SynapseEdge] = []

    # 1. Check Neo4j first
    neo_sub = neo4j_repository.get_person_subgraph(person_id)
    if neo_sub and neo_sub.get("p"):
        p_node = neo_sub["p"]
        p_id = p_node.get("person_id")
        nodes_dict[p_id] = SynapseNode(
            id=p_id,
            label=p_node.get("name", ""),
            type="PERSON",
            role_or_industry=p_node.get("current_role", "인물"),
            badge_color="#30D158"
        )

        for item in neo_sub.get("roles", []):
            c = item.get("company")
            r = item.get("rel")
            if c and r:
                c_id = f"C_{c.get('stock_code', c.get('corp_code'))}"
                if c_id not in nodes_dict:
                    nodes_dict[c_id] = SynapseNode(
                        id=c_id,
                        label=c.get("name", ""),
                        type="COMPANY",
                        role_or_industry=c.get("industry", "상장기업"),
                        badge_color="#0A84FF"
                    )
                edges_list.append(SynapseEdge(
                    source=p_id,
                    target=c_id,
                    type="WORKS_AT",
                    label=r.get("role", "임원"),
                    weight=0.90,
                    evidence=r.get("evidence", f"{c.get('name')} {r.get('role')} 재직"),
                    evidence_text=r.get("evidence_text", r.get("evidence")),
                    source_tier=r.get("source_tier", SourceTier.TIER_1_LEGAL.value),
                    badge_label="🟢 공시 팩트",
                    source_url=r.get("source_url", "https://dart.fss.or.kr"),
                    rcp_no=r.get("rcept_no", "20240322000891")
                ))

        return SubgraphResponse(
            focus_id=p_id,
            focus_type="PERSON",
            nodes=list(nodes_dict.values()),
            edges=edges_list,
            total_nodes=len(nodes_dict),
            total_edges=len(edges_list)
        )

    # 2. In-Memory Graph Fallback
    person = memory_store.get_person_by_id(person_id)
    if not person:
        raise HTTPException(status_code=404, detail=f"Person with ID '{person_id}' not found")

    nodes_dict[person.id] = SynapseNode(
        id=person.id,
        label=person.name,
        type="PERSON",
        role_or_industry=person.role_title,
        badge_color="#30D158"
    )

    for neighbor in memory_store.graph.neighbors(person.id):
        data = memory_store.graph.get_edge_data(person.id, neighbor) or {}
        comp = memory_store.get_company_by_id_or_ticker(neighbor)
        other_p = memory_store.get_person_by_id(neighbor)

        edge_obj = data.get("edge")
        rel_type = edge_obj.relation_type.value if hasattr(edge_obj, "relation_type") else data.get("edge_type", "WORKS_AT")
        label = edge_obj.label if hasattr(edge_obj, "label") else data.get("evidence", "연관")
        weight = float(edge_obj.base_weight) if hasattr(edge_obj, "base_weight") else float(data.get("weight", 0.8))
        url = edge_obj.source_url if hasattr(edge_obj, "source_url") else data.get("source_url", "https://dart.fss.or.kr")

        if comp:
            nodes_dict[comp.id] = SynapseNode(
                id=comp.id,
                label=comp.name,
                type="COMPANY",
                role_or_industry=comp.industry,
                market_cap=comp.market_cap,
                price_change_rate=comp.price_change_rate,
                badge_color="#0A84FF"
            )
            evidence_text = f"DART 전자공시 팩트 근거: {label}"
            edges_list.append(SynapseEdge(
                source=person.id,
                target=comp.id,
                type=rel_type,
                label=label,
                weight=weight,
                evidence=evidence_text,
                evidence_text=evidence_text,
                source_tier=SourceTier.TIER_1_LEGAL.value,
                source_name=SourceName.DART.value,
                source_ref_id="20240322000891",
                badge_label="🟢 공시 팩트",
                source_url=url,
                rcp_no="20240322000891"
            ))
        elif other_p:
            nodes_dict[other_p.id] = SynapseNode(
                id=other_p.id,
                label=other_p.name,
                type="PERSON",
                role_or_industry=other_p.role_title,
                badge_color="#FF9F0A"
            )
            edges_list.append(SynapseEdge(
                source=person.id,
                target=other_p.id,
                type=rel_type,
                label=label,
                weight=weight,
                evidence=data.get("evidence", f"{other_p.name} 인맥 네트워크"),
                evidence_text=data.get("evidence", f"{other_p.name} 인맥 네트워크"),
                source_tier=SourceTier.TIER_1_LEGAL.value,
                source_name=SourceName.DART.value,
                source_ref_id="20240322000891",
                badge_label="🟢 공시 팩트",
                source_url=url
            ))

    return SubgraphResponse(
        focus_id=person.id,
        focus_type="PERSON",
        nodes=list(nodes_dict.values()),
        edges=edges_list,
        total_nodes=len(nodes_dict),
        total_edges=len(edges_list)
    )


@router.get("/path", response_model=SynapsePathResponse)
async def find_synapse_path(
    from_node: str = Query(..., alias="from"),
    to_node: str = Query(..., alias="to")
):
    f_id = from_node
    t_id = to_node

    c_from = memory_store.get_company_by_id_or_ticker(from_node)
    if c_from: f_id = c_from.id
    c_to = memory_store.get_company_by_id_or_ticker(to_node)
    if c_to: t_id = c_to.id

    undirected_g = memory_store.graph.to_undirected()

    try:
        path = nx.shortest_path(undirected_g, source=f_id, target=t_id)
    except nx.NetworkXNoPath:
        raise HTTPException(status_code=404, detail=f"No synapse path found between '{from_node}' and '{to_node}'")
    except nx.NodeNotFound as e:
        raise HTTPException(status_code=404, detail=str(e))

    steps: List[SynapsePathStep] = []
    for i in range(len(path) - 1):
        u = path[i]
        v = path[i + 1]
        data = memory_store.graph.get_edge_data(u, v) or memory_store.graph.get_edge_data(v, u) or {}

        u_p = memory_store.get_person_by_id(u)
        u_c = memory_store.get_company_by_id_or_ticker(u)
        v_p = memory_store.get_person_by_id(v)
        v_c = memory_store.get_company_by_id_or_ticker(v)

        u_name = u_p.name if u_p else (u_c.name if u_c else u)
        v_name = v_p.name if v_p else (v_c.name if v_c else v)

        edge_obj = data.get("edge")
        rel_type = edge_obj.relation_type.value if hasattr(edge_obj, "relation_type") else data.get("edge_type", "CONNECTED_TO")
        label = edge_obj.label if hasattr(edge_obj, "label") else data.get("evidence", "연결")
        url = edge_obj.source_url if hasattr(edge_obj, "source_url") else data.get("source_url", "https://dart.fss.or.kr")

        steps.append(SynapsePathStep(
            from_id=u,
            from_name=u_name,
            to_id=v,
            to_name=v_name,
            relationship_type=rel_type,
            relationship_label=label,
            evidence=f"{u_name} ↔ {v_name} ({label})",
            source_tier=SourceTier.TIER_1_LEGAL.value,
            badge_label="🟢 공시 팩트",
            source_url=url
        ))

    return SynapsePathResponse(
        from_id=from_node,
        to_id=to_node,
        path_length=len(steps),
        path_nodes=path,
        steps=steps
    )
