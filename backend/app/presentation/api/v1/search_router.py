from fastapi import APIRouter, Query
from app.data.dtos.search_dtos import SearchUniversalResponseDto
from app.presentation.dependencies import universal_search_use_case

router = APIRouter()

@router.get("/search", response_model=SearchUniversalResponseDto, summary="인물/주식/테마 통합 실시간 검색 (Universal Search)")
def search_universal(
    q: str = Query(..., description="검색 키워드 (인물명, 기업명, 종목코드, 테마명)"),
    limit: int = Query(10, description="최대 반환 개수", ge=1, le=50)
):
    return universal_search_use_case.execute(query=q, limit=limit)
