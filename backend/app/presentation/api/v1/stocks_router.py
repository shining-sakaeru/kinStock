from typing import List, Optional
from fastapi import APIRouter, HTTPException, Query
from app.data.dtos.stock_dtos import CompanyDto, StockFiguresResponseDto
from app.data.mappers.domain_dto_mapper import DomainDtoMapper
from app.domain.entities.weight_settings import WeightSettings
from app.domain.entities.company import Company
from app.domain.services.realtime_stock_service import realtime_stock_service
from app.data.repositories.memory_store import memory_store
from app.presentation.dependencies import stock_related_figures_use_case

router = APIRouter()

@router.get("/stocks", response_model=List[CompanyDto], summary="전체 상장 기업 목록 조회 (실시간 시세 연동)")
def get_stocks():
    companies = memory_store.get_all_companies()
    result = []
    for c in companies:
        price, change, cap = realtime_stock_service.fetch_quote(c.ticker, fallback_company=c)
        updated_c = Company(
            id=c.id,
            ticker=c.ticker,
            name=c.name,
            industry=c.industry,
            current_price=price,
            price_change_rate=change,
            market_cap=cap,
            dart_corp_code=c.dart_corp_code,
            source_url=c.source_url
        )
        result.append(DomainDtoMapper.to_company_dto(updated_c))
    return result

@router.get("/stocks/{stock_code}/figures", response_model=StockFiguresResponseDto, summary="Mode B [Stock-Hub]: 주식 중심 연관 인물 및 테마 역추적 랭킹 조회")
@router.get("/stocks/{stock_code}/related-figures", response_model=StockFiguresResponseDto, summary="주식 중심 인물 역추적 (Alias)")
def get_stock_related_figures(
    stock_code: str,
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
    res = stock_related_figures_use_case.execute(stock_code_or_id=stock_code, weights=weights)
    if not res:
        raise HTTPException(status_code=404, detail=f"Stock '{stock_code}' not found")
    return res
