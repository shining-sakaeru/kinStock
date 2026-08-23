from typing import List, Optional
from fastapi import APIRouter, HTTPException, Query
from app.data.dtos.person_dtos import PersonDto, FigureStocksResponseDto
from app.data.mappers.domain_dto_mapper import DomainDtoMapper
from app.domain.entities.weight_settings import WeightSettings
from app.data.repositories.memory_store import memory_store
from app.presentation.dependencies import person_recommendations_use_case

router = APIRouter()

@router.get("/persons", response_model=List[PersonDto], summary="전체 주요 인물 목록 조회")
def get_persons():
    persons = memory_store.get_all_persons()
    return [DomainDtoMapper.to_person_dto(p) for p in persons]

@router.get("/persons/{person_id}", response_model=PersonDto, summary="특정 인물 상세 정보 조회")
def get_person(person_id: str):
    person = memory_store.get_person_by_id(person_id)
    if not person:
        raise HTTPException(status_code=404, detail=f"Person '{person_id}' not found")
    return DomainDtoMapper.to_person_dto(person)

@router.get("/figures/{figure_id}/stocks", response_model=FigureStocksResponseDto, summary="Mode A [Person-Hub]: 인물 중심 DART 공시 연관 수혜주 랭킹 조회")
@router.get("/figures/{figure_id}/related-stocks", response_model=FigureStocksResponseDto, summary="인물 중심 연관 수혜주 랭킹 (Alias)")
def get_figure_stocks(
    figure_id: str,
    theme_id: Optional[str] = Query(None, description="선택적 테마 ID"),
    w_executive: Optional[float] = Query(None, description="직무 실권 가중치", ge=0.0, le=1.0),
    w_cohort: Optional[float] = Query(None, description="폐쇄형 엘리트 가중치", ge=0.0, le=1.0),
    w_alumni: Optional[float] = Query(None, description="직접 학연 가중치", ge=0.0, le=1.0),
    w_regional: Optional[float] = Query(None, description="지연/동향 가중치", ge=0.0, le=1.0),
    decay_factor: Optional[float] = Query(None, description="다단계 감가 계수", ge=0.1, le=1.0)
):
    w_dict = {}
    if w_executive is not None: w_dict["executive_family"] = w_executive
    if w_cohort is not None: w_dict["exclusive_cohort"] = w_cohort
    if w_alumni is not None: w_dict["direct_alumni"] = w_alumni
    if w_regional is not None: w_dict["regional_ties"] = w_regional
    if decay_factor is not None: w_dict["decay_factor"] = decay_factor

    weights = WeightSettings.from_dict(w_dict) if w_dict else None
    res = person_recommendations_use_case.execute(person_id=figure_id, weights=weights)
    if not res:
        raise HTTPException(status_code=404, detail=f"Figure '{figure_id}' not found")
    return res
