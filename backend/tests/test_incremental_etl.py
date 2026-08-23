import pytest
from app.core.utils.normalizer import TextNormalizer
from app.services.dart_incremental_worker import DartIncrementalWorker

def test_person_id_generation():
    """Test deterministic Person ID generation rule: {name}_{YYYYMM}_{GENDER}"""
    pid1 = TextNormalizer.generate_person_id("홍길동", "196503", "M")
    assert pid1 == "홍길동_196503_M"

    pid2 = TextNormalizer.generate_person_id("이재명", "196412", "m")
    assert pid2 == "이재명_196412_M"

    pid3 = TextNormalizer.generate_person_id("한동훈", "19730425", "M")
    assert pid3 == "한동훈_197304_M"

def test_school_normalization():
    """Test school string normalization to standard code & type"""
    code, name, s_type, major = TextNormalizer.normalize_school("서울대학교 법과대학 법학과")
    assert code == "SCH_SNU"
    assert name == "서울대학교"
    assert s_type == "UNIVERSITY"
    assert "법학과" in major or "법과대학" in major

    code2, name2, s_type2, _ = TextNormalizer.normalize_school("현대고등학교 졸업")
    assert code2 == "SCH_HYUNDAI_HS"
    assert name2 == "현대고등학교"
    assert s_type2 == "HIGH_SCHOOL"

    code3, name3, s_type3, _ = TextNormalizer.normalize_school("하버드 비즈니스스쿨 MBA")
    assert code3 == "SCH_HARVARD"
    assert name3 == "하버드대학교"

def test_region_normalization():
    """Test region string normalization to standard code"""
    code, name = TextNormalizer.normalize_region("경북 안동시 삼계리")
    assert code == "REG_ANDONG"
    assert name == "경상북도 안동시"

def test_dart_incremental_filing_parser():
    """Test parsing DART filing into normalized UNWIND batches"""
    worker = DartIncrementalWorker()
    filings = worker.fetch_today_filings("20260823")
    assert len(filings) >= 1

    extracted = worker.parse_and_normalize_filing(filings[0])
    assert "companies" in extracted
    assert "persons" in extracted
    assert "serves_as" in extracted
    assert len(extracted["companies"]) == 1
    assert len(extracted["persons"]) >= 1

    # Verify audit metadata is attached to all edges
    for edge in extracted["serves_as"]:
        assert "rcept_no" in edge
        assert "evidence" in edge
        assert len(edge["rcept_no"]) == 14
