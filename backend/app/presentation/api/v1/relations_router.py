from typing import Optional
from fastapi import APIRouter, HTTPException, Query
from app.data.dtos.detail_dtos import DeepDivePathResponseDto
from app.domain.entities.weight_settings import WeightSettings
from app.presentation.dependencies import deep_dive_path_use_case

router = APIRouter()

@router.get("/relations/detail", response_model=DeepDivePathResponseDto, summary="Tier 2: 인물-주식 간 투자 연관성 심층 리포트 (Investment Rationale)")
@router.get("/network/path", response_model=DeepDivePathResponseDto, summary="마인드맵 전체 서브그래프 경로 (Alias)")
def get_relation_detail(
    source_id: Optional[str] = Query(None, description="인물 ID"),
    target_id: Optional[str] = Query(None, description="기업 ID 또는 티커"),
    person_id: Optional[str] = Query(None),
    company_id: Optional[str] = Query(None),
    w_executive: Optional[float] = Query(None, ge=0.0, le=1.0),
    w_cohort: Optional[float] = Query(None, ge=0.0, le=1.0),
    w_alumni: Optional[float] = Query(None, ge=0.0, le=1.0),
    w_regional: Optional[float] = Query(None, ge=0.0, le=1.0),
    decay_factor: Optional[float] = Query(None, ge=0.1, le=1.0)
):
    p_id = source_id or person_id
    c_id = target_id or company_id
    if not p_id or not c_id:
        raise HTTPException(status_code=400, detail="Both source_id and target_id are required")

    w_dict = {}
    if w_executive is not None: w_dict["executive_family"] = w_executive
    if w_cohort is not None: w_dict["exclusive_cohort"] = w_cohort
    if w_alumni is not None: w_dict["direct_alumni"] = w_alumni
    if w_regional is not None: w_dict["regional_ties"] = w_regional
    if decay_factor is not None: w_dict["decay_factor"] = decay_factor

    weights = WeightSettings.from_dict(w_dict) if w_dict else None
    res = deep_dive_path_use_case.execute(person_id=p_id, company_id_or_ticker=c_id, weights=weights)
    if not res:
        raise HTTPException(status_code=404, detail=f"No connection path found between '{p_id}' and '{c_id}'")
    return res
