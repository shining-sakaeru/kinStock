from fastapi import APIRouter
from app.data.dtos.common_dtos import WeightBaselineDto, WeightFactorDto
from app.domain.entities.weight_settings import AI_DEFAULT_WEIGHTS

router = APIRouter()

@router.get("/weights/baseline", response_model=WeightBaselineDto, summary="AI 최적 기본 가중치 및 산출 근거 메타데이터")
def get_weight_baseline():
    return WeightBaselineDto(
        status="success",
        factors={
            "executive_family": WeightFactorDto(
                key="executive_family",
                title="직무 실권 및 최대주주",
                default_value=0.95,
                description="DART 공시상 대표이사·사내이사 및 대주주 지배력 (대표이사 가중치 1.3배 보정)"
            ),
            "exclusive_cohort": WeightFactorDto(
                key="exclusive_cohort",
                title="폐쇄형 엘리트 네트워크",
                default_value=0.85,
                description="사법연수원·행정고시 등 폐쇄적 고위 기수 네트워크의 장기적 정책·이권 결속력"
            ),
            "direct_alumni": WeightFactorDto(
                key="direct_alumni",
                title="직접 학연 (동문)",
                default_value=0.70,
                description="동일 고등학교 및 대학교 동일 학과 출신 네트워크"
            ),
            "regional_ties": WeightFactorDto(
                key="regional_ties",
                title="지연 / 동향",
                default_value=0.45,
                description="동일 출신 지역 및 향우회 네트워크"
            ),
            "decay_factor": WeightFactorDto(
                key="decay_factor",
                title="다단계 감가 계수",
                default_value=0.60,
                description="2-Depth 이상 다단계 연결 시 적용되는 단계별 감가율 (기본 0.60x)"
            ),
        }
    )
