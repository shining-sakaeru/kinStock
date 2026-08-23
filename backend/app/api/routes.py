from typing import List, Optional, Dict
from fastapi import APIRouter, HTTPException, Query, Response
from app.services.relevance_service import relevance_service
from app.core.models import (
    Theme, Person, Company, MicroGraphResponse, RecommendationsResponse,
    StockRelatedFiguresResponse, DeepDivePathResponse, FigureRelatedStocksResponse,
    WeightBaselineResponse, AI_DEFAULT_WEIGHTS
)

router = APIRouter()

# ----------------------------------------------------
# 1. 5 Core Themes System Interfaces
# ----------------------------------------------------
@router.get("/themes", response_model=List[Theme], summary="5대 핵심 테마 목록 조회")
def get_themes():
    return relevance_service.get_themes()

@router.get("/themes/{theme_id}", response_model=Theme, summary="특정 테마 상세 정보 조회")
def get_theme(theme_id: str):
    theme = relevance_service.get_theme(theme_id)
    if not theme:
        raise HTTPException(status_code=404, detail=f"Theme '{theme_id}' not found")
    return theme

@router.get("/themes/{theme_id}/figures", response_model=List[Person], summary="특정 테마 소속 핵심 인물 목록 조회")
def get_theme_figures(theme_id: str):
    return relevance_service.get_figures_by_theme(theme_id)

# ----------------------------------------------------
# 2. AI Weights Baseline & Custom Weights API
# ----------------------------------------------------
@router.get("/weights/baseline", response_model=WeightBaselineResponse, summary="AI 최적 기본 가중치 및 산출 근거 메타데이터")
def get_weight_baseline():
    return relevance_service.get_weight_baseline()

# ----------------------------------------------------
# 3. Focus Mode 1: 인물 중심 모드 (Person-Centric)
# ----------------------------------------------------
@router.get("/figures/{figure_id}/stocks", response_model=FigureRelatedStocksResponse, summary="인물 중심 DART 공시 팩트 매칭 기업 및 랭킹 조회")
def get_figure_stocks(
    figure_id: str,
    theme_id: Optional[str] = Query(None, description="선택적 테마 ID 필터"),
    w_executive: Optional[float] = Query(None, description="직무 실권 및 최대주주 가중치 (기본 0.95)", ge=0.0, le=1.0),
    w_cohort: Optional[float] = Query(None, description="폐쇄형 엘리트 네트워크 가중치 (기본 0.85)", ge=0.0, le=1.0),
    w_alumni: Optional[float] = Query(None, description="직접 학연 가중치 (기본 0.70)", ge=0.0, le=1.0),
    w_regional: Optional[float] = Query(None, description="지연/동향 가중치 (기본 0.45)", ge=0.0, le=1.0),
    decay_factor: Optional[float] = Query(None, description="다단계 감가 계수 (기본 0.60)", ge=0.1, le=1.0)
):
    custom_weights = dict(AI_DEFAULT_WEIGHTS)
    if w_executive is not None:
        custom_weights["executive_family"] = w_executive
    if w_cohort is not None:
        custom_weights["exclusive_cohort"] = w_cohort
    if w_alumni is not None:
        custom_weights["direct_alumni"] = w_alumni
    if w_regional is not None:
        custom_weights["regional_ties"] = w_regional
    if decay_factor is not None:
        custom_weights["decay_factor"] = decay_factor

    res = relevance_service.get_figure_related_stocks(figure_id, weight_overrides=custom_weights)
    if not res:
        raise HTTPException(status_code=404, detail=f"Figure '{figure_id}' not found")
    return res

@router.get("/figures/{figure_id}/related-stocks", response_model=FigureRelatedStocksResponse, summary="인물 중심 연관 주식 랭킹 조회 (Alias)")
def get_figure_related_stocks(
    figure_id: str,
    w_executive: Optional[float] = Query(None),
    w_cohort: Optional[float] = Query(None),
    w_alumni: Optional[float] = Query(None),
    w_regional: Optional[float] = Query(None),
    decay_factor: Optional[float] = Query(None)
):
    return get_figure_stocks(
        figure_id=figure_id,
        w_executive=w_executive,
        w_cohort=w_cohort,
        w_alumni=w_alumni,
        w_regional=w_regional,
        decay_factor=decay_factor
    )

@router.get("/persons", response_model=List[Person], summary="전체 주요 인물 목록 조회")
def get_persons():
    return relevance_service.get_all_persons()

@router.get("/persons/{person_id}", response_model=Person, summary="특정 인물 상세 정보 조회")
def get_person(person_id: str):
    person = relevance_service.get_person(person_id)
    if not person:
        raise HTTPException(status_code=404, detail=f"Person '{person_id}' not found")
    return person

# ----------------------------------------------------
# 4. Focus Mode 2: 주식 중심 모드 (Stock-Centric)
# ----------------------------------------------------
@router.get("/stocks", response_model=List[Company], summary="전체 상장 기업 목록 조회")
def get_stocks():
    return relevance_service.get_all_companies()

@router.get("/stocks/{stock_code}/related-figures", response_model=StockRelatedFiguresResponse, summary="주식 중심 연관 인물/테마 역추적 랭킹 조회")
def get_stock_related_figures(
    stock_code: str,
    w_executive: Optional[float] = Query(None),
    w_cohort: Optional[float] = Query(None),
    w_alumni: Optional[float] = Query(None),
    w_regional: Optional[float] = Query(None),
    decay_factor: Optional[float] = Query(None)
):
    custom_weights = dict(AI_DEFAULT_WEIGHTS)
    if w_executive is not None:
        custom_weights["executive_family"] = w_executive
    if w_cohort is not None:
        custom_weights["exclusive_cohort"] = w_cohort
    if w_alumni is not None:
        custom_weights["direct_alumni"] = w_alumni
    if w_regional is not None:
        custom_weights["regional_ties"] = w_regional
    if decay_factor is not None:
        custom_weights["decay_factor"] = decay_factor

    res = relevance_service.get_stock_related_figures(stock_code, weight_overrides=custom_weights)
    if not res:
        raise HTTPException(status_code=404, detail=f"Stock '{stock_code}' not found")
    return res

# ----------------------------------------------------
# 5. Tier 2: Relations Detail & Deep Dive Report
# ----------------------------------------------------
@router.get("/relations/detail", response_model=DeepDivePathResponse, summary="인물-주식 간의 심층 연관성 상세 리포트 및 DART 공시 원문")
@router.get("/network/path", response_model=DeepDivePathResponse, summary="Detail 화면 전체화면 마인드맵 데이터 (Alias)")
def get_relation_detail(
    source_id: Optional[str] = Query(None, description="인물 ID (또는 person_id)"),
    target_id: Optional[str] = Query(None, description="기업 ID (또는 company_id)"),
    person_id: Optional[str] = Query(None),
    company_id: Optional[str] = Query(None),
    w_executive: Optional[float] = Query(None),
    w_cohort: Optional[float] = Query(None),
    w_alumni: Optional[float] = Query(None),
    w_regional: Optional[float] = Query(None),
    decay_factor: Optional[float] = Query(None)
):
    p_id = source_id or person_id
    c_id = target_id or company_id

    if not p_id or not c_id:
        raise HTTPException(status_code=400, detail="Both person_id/source_id and company_id/target_id are required")

    custom_weights = dict(AI_DEFAULT_WEIGHTS)
    if w_executive is not None:
        custom_weights["executive_family"] = w_executive
    if w_cohort is not None:
        custom_weights["exclusive_cohort"] = w_cohort
    if w_alumni is not None:
        custom_weights["direct_alumni"] = w_alumni
    if w_regional is not None:
        custom_weights["regional_ties"] = w_regional
    if decay_factor is not None:
        custom_weights["decay_factor"] = decay_factor

    res = relevance_service.get_deep_dive_path(person_id=p_id, company_id=c_id, weight_overrides=custom_weights)
    if not res:
        raise HTTPException(status_code=404, detail=f"No path found between person '{p_id}' and company '{c_id}'")
    return res

@router.get("/export/neo4j-cypher", summary="Neo4j Community Edition 시드 Cypher 스크립트")
def export_neo4j_cypher():
    cypher_text = relevance_service.export_cypher()
    return Response(content=cypher_text, media_type="text/plain")
