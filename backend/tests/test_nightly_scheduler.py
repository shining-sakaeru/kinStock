import pytest
from app.domain.entities.source_meta import SourceTier, SourceName, EvidenceMeta
from app.services.dart_ingestion_service import DartIngestionService
from app.services.nightly_batch_scheduler import NightlyBatchPipeline

def test_evidence_meta_model():
    """Test EvidenceMeta model attributes and badge labels"""
    meta_legal = EvidenceMeta(
        source_tier=SourceTier.TIER_1_LEGAL,
        source_name=SourceName.DART,
        source_ref_id="20240322000891",
        evidence_text="2024.03 사업보고서 임원의 현황 - 서울대 경영학 학사",
        source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240322000891"
    )
    assert meta_legal.source_tier == "TIER_1_LEGAL"
    assert meta_legal.badge_label == "🟢 공시 팩트"

    meta_news = EvidenceMeta(
        source_tier=SourceTier.TIER_3_NEWS,
        source_name=SourceName.BIG_KINDS,
        source_ref_id="NEWS_102030",
        evidence_text="조선일보 기사 인터뷰 인용",
        source_url="https://www.kinds.or.kr"
    )
    assert meta_news.source_tier == "TIER_3_NEWS"
    assert meta_news.badge_label == "🟡 언론 보도"

def test_dart_ingestion_service():
    """Test Tier 1 DART ingestion and batch generation"""
    service = DartIngestionService()
    result = service.ingest_filings_for_date("20260823")
    assert result["status"] == "success"
    assert result["filings_count"] >= 1
    assert "stats" in result

def test_nightly_batch_pipeline_phases():
    """Test execution of 3-Phase Nightly Batch Pipeline"""
    pipeline = NightlyBatchPipeline()
    p1 = pipeline.run_phase_1_tier1_ingestion("20260823")
    assert p1["status"] == "success"

    p2 = pipeline.run_phase_2_synapse_inference()
    assert p2["status"] == "success"
    assert p2["inferred_synapses_count"] > 0

    p3 = pipeline.run_phase_3_market_warming_and_metrics()
    assert p3["status"] == "success"
    assert p3["warmed_companies_count"] > 0
