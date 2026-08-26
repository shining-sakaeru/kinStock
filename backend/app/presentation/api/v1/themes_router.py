from typing import List, Optional
from fastapi import APIRouter, HTTPException, Query
from app.data.dtos.theme_dtos import ThemeDto, ThemeClusterResponseDto
from app.data.dtos.person_dtos import PersonDto
from app.data.mappers.domain_dto_mapper import DomainDtoMapper
from app.domain.entities.weight_settings import WeightSettings
from app.data.repositories.memory_store import memory_store
from app.presentation.dependencies import theme_cluster_use_case
from app.schemas.theme_stock_response import PersonThemeStocksResponse
from app.services.scoring.theme_stock_ranker import theme_stock_ranker

router = APIRouter()

@router.get("/themes/stocks", response_model=PersonThemeStocksResponse, summary="인물 기준 Kin-Score 랭킹 및 3-Depth 인과 사슬 조회")
def get_person_theme_stocks(
    person_id: str = Query(..., description="조회할 인물 ID 또는 이름 (예: P_이재용_196806_M, 이재명, 한동훈)")
):
    """
    Returns investor-centric Kin-Score ranking and 3-Depth Causal Chain (Why Engine) for the selected person.
    """
    return theme_stock_ranker.get_ranked_theme_stocks(person_id)

@router.get("/themes", response_model=List[ThemeDto], summary="5대 핵심 테마 목록 조회")
def get_themes():
    themes = memory_store.get_all_themes()
    return [DomainDtoMapper.to_theme_dto(t) for t in themes]

@router.get("/themes/{theme_id}/cluster", response_model=ThemeClusterResponseDto, summary="Mode C [Theme-Preset]: 테마 내 핵심 인물군 및 대장주 클러스터 조회")
def get_theme_cluster(
    theme_id: str,
    w_executive: Optional[float] = Query(None, ge=0.0, le=1.0),
    w_cohort: Optional[float] = Query(None, ge=0.0, le=1.0),
    w_alumni: Optional[float] = Query(None, ge=0.0, le=1.0),
    w_regional: Optional[float] = Query(None, ge=0.0, le=1.0),
    decay_factor: Optional[float] = Query(None, ge=0.1, le=1.0)
):
    w_dict = {}
    if w_executive is not None: w_dict["executive_family"] = w_executive
    if w_cohort is not None: w_dict["exclusive_cohort"] = w_cohort
    if w_alumni is not None: w_dict["direct_alumni"] = w_alumni
    if w_regional is not None: w_dict["regional_ties"] = w_regional
    if decay_factor is not None: w_dict["decay_factor"] = decay_factor

    weights = WeightSettings.from_dict(w_dict) if w_dict else None
    res = theme_cluster_use_case.execute(theme_id=theme_id, weights=weights)
    if not res:
        raise HTTPException(status_code=404, detail=f"Theme '{theme_id}' not found")
    return res

@router.get("/themes/{theme_id}/figures", response_model=List[PersonDto], summary="특정 테마 소속 핵심 인물 목록 조회")
def get_theme_figures(theme_id: str):
    figures = memory_store.get_persons_by_theme(theme_id)
    return [DomainDtoMapper.to_person_dto(f) for f in figures]

@router.get("/themes/{theme_id}", response_model=ThemeDto, summary="특정 테마 상세 정보 조회")
def get_theme(theme_id: str):
    theme = memory_store.get_theme_by_id(theme_id)
    if not theme:
        raise HTTPException(status_code=404, detail=f"Theme '{theme_id}' not found")
    return DomainDtoMapper.to_theme_dto(theme)
