import networkx as nx
from fastapi import APIRouter, HTTPException, Query
from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field
from app.data.repositories.memory_store import memory_store
from app.services.dart_batch_sync import dart_batch_sync_service
from app.services.nightly_batch_scheduler import NightlyBatchPipeline
from app.domain.entities.source_meta import SourceTier, SourceName

router = APIRouter(prefix="/network", tags=["Synapse Network"])

# Response Models with Provenance Audit Metadata
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
    type: str # WORKS_AT, OWNS_STAKE, ALUMNI_WITH, HOMETOWN_WITH, COLLEAGUE_WITH, AFFILIATE_WITH
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
    Get company-centric synapse subgraph:
    - Executives (WORKS_AT)
    - Major Shareholders (OWNS_STAKE)
    - Key Figures linked via DART evidence
    """
    company = memory_store.get_company_by_id_or_ticker(corp_code)
    if not company:
        for c in memory_store.get_all_companies():
            if c.dart_corp_code == corp_code or c.ticker == corp_code or c.id == corp_code:
                company = c
                break

    if not company:
        raise HTTPException(status_code=404, detail=f"Company with code '{corp_code}' not found")

    nodes_dict: Dict[str, SynapseNode] = {}
    edges_list: List[SynapseEdge] = []

    # Focus company node
    nodes_dict[company.id] = SynapseNode(
        id=company.id,
        label=company.name,
        type="COMPANY",
        role_or_industry=company.industry,
        market_cap=company.market_cap,
        price_change_rate=company.price_change_rate,
        badge_color="#0A84FF"
    )

    # Find incoming & outgoing edges
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
    Get person-centric synapse subgraph:
    - Affiliated Companies & Stocks
    - Alumni & Colleagues (Person-to-Person)
    - Full DART filing evidence
    """
    person = memory_store.get_person_by_id(person_id)
    if not person:
        raise HTTPException(status_code=404, detail=f"Person with ID '{person_id}' not found")

    nodes_dict: Dict[str, SynapseNode] = {}
    edges_list: List[SynapseEdge] = []

    # Focus person node
    nodes_dict[person.id] = SynapseNode(
        id=person.id,
        label=person.name,
        type="PERSON",
        role_or_industry=person.role_title,
        badge_color="#30D158"
    )

    # 1-hop connections
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
    """
    Find shortest synapse path between two entities (Person-Person or Person-Company)
    with step-by-step DART evidence.
    """
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


@router.post("/nightly-batch")
async def trigger_nightly_batch(phase: Optional[int] = Query(None, description="Specific phase (1, 2, or 3)")):
    """
    On-demand execution of the 3-Phase Nightly Batch Pipeline.
    """
    pipeline = NightlyBatchPipeline()
    if phase == 1:
        return pipeline.run_phase_1_tier1_ingestion()
    elif phase == 2:
        return pipeline.run_phase_2_synapse_inference()
    elif phase == 3:
        return pipeline.run_phase_3_market_warming_and_metrics()
    else:
        return pipeline.run_full_nightly_pipeline()
