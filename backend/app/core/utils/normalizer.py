import re
from typing import Tuple, Optional, Dict

class TextNormalizer:
    """
    DART Fact Normalizer:
    Converts raw unstructured school and region strings from corporate filings
    into deterministic, standardized codes and entities to prevent entity duplication.
    """

    # 1. School Normalization Dictionary (Standard Code -> Pattern & Metadata)
    SCHOOL_MAP: Dict[str, Dict[str, str]] = {
        "SCH_SNU": {"name": "서울대학교", "type": "UNIVERSITY", "pattern": r"(서울대|서울대학교|SNU)"},
        "SCH_KU": {"name": "고려대학교", "type": "UNIVERSITY", "pattern": r"(고려대|고려대학교|Korea University)"},
        "SCH_YU": {"name": "연세대학교", "type": "UNIVERSITY", "pattern": r"(연세대|연세대학교|Yonsei)"},
        "SCH_CAU": {"name": "중앙대학교", "type": "UNIVERSITY", "pattern": r"(중앙대|중앙대학교)"},
        "SCH_SKKU": {"name": "성균관대학교", "type": "UNIVERSITY", "pattern": r"(성균관대|성균관대학교|SKKU)"},
        "SCH_HYU": {"name": "한양대학교", "type": "UNIVERSITY", "pattern": r"(한양대|한양대학교)"},
        "SCH_SOGANG": {"name": "서강대학교", "type": "UNIVERSITY", "pattern": r"(서강대|서강대학교)"},
        "SCH_KAIST": {"name": "KAIST", "type": "UNIVERSITY", "pattern": r"(카이스트|KAIST|한국과학기술원)"},
        "SCH_POSTECH": {"name": "POSTECH", "type": "UNIVERSITY", "pattern": r"(포항공대|포항공과대|POSTECH)"},
        "SCH_HARVARD": {"name": "하버드대학교", "type": "UNIVERSITY", "pattern": r"(하버드|Harvard)"},
        "SCH_WHARTON": {"name": "펜실베이니아대 와튼스쿨", "type": "GRAD_SCHOOL", "pattern": r"(와튼|Wharton|펜실베이니아)"},
        "SCH_BERKELEY": {"name": "UC 버클리", "type": "UNIVERSITY", "pattern": r"(버클리|UC Berkeley|UC버클리)"},
        "SCH_COLUMBIA": {"name": "컬럼비아대학교", "type": "UNIVERSITY", "pattern": r"(컬럼비아|Columbia)"},
        "SCH_CORNELL": {"name": "코넬대학교", "type": "UNIVERSITY", "pattern": r"(코넬|Cornell)"},
        
        # High Schools
        "SCH_HYUNDAI_HS": {"name": "현대고등학교", "type": "HIGH_SCHOOL", "pattern": r"(현대고|현대고등학교)"},
        "SCH_CHUNGAM_HS": {"name": "충암고등학교", "type": "HIGH_SCHOOL", "pattern": r"(충암고|충암고등학교)"},
        "SCH_SEOUL_SCI_HS": {"name": "서울과학고등학교", "type": "HIGH_SCHOOL", "pattern": r"(서울과학고|서울과학고등학교)"},
        "SCH_KYUNGBOK_HS": {"name": "경복고등학교", "type": "HIGH_SCHOOL", "pattern": r"(경복고|경복고등학교)"},
        "SCH_WHIMOON_HS": {"name": "휘문고등학교", "type": "HIGH_SCHOOL", "pattern": r"(휘문고|휘문고등학교)"},
        "SCH_BUSAN_HS": {"name": "부산고등학교", "type": "HIGH_SCHOOL", "pattern": r"(부산고|부산고등학교)"},
        "SCH_HYEGWANG_HS": {"name": "혜광고등학교", "type": "HIGH_SCHOOL", "pattern": r"(혜광고|혜광고등학교)"},
        "SCH_DAEIL_HS": {"name": "대일고등학교", "type": "HIGH_SCHOOL", "pattern": r"(대일고|대일고등학교)"},
        "SCH_OSAN_HS": {"name": "오산고등학교", "type": "HIGH_SCHOOL", "pattern": r"(오산고|오산고등학교)"},
        "SCH_KYUNGMUN_HS": {"name": "경문고등학교", "type": "HIGH_SCHOOL", "pattern": r"(경문고|경문고등학교)"},
    }

    # 2. Region Normalization Dictionary
    REGION_MAP: Dict[str, Dict[str, str]] = {
        "REG_SEOUL": {"name": "서울특별시", "pattern": r"(서울|서울특별시)"},
        "REG_ANDONG": {"name": "경상북도 안동시", "pattern": r"(안동|안동시|경북 안동)"},
        "REG_CHUNCHEON": {"name": "강원특별자치도 춘천시", "pattern": r"(춘천|춘천시|강원 춘천)"},
        "REG_BUSAN": {"name": "부산광역시", "pattern": r"(부산|부산광역시)"},
        "REG_DAEGU": {"name": "대구광역시", "pattern": r"(대구|대구광역시)"},
        "REG_CHANGNYEONG": {"name": "경상남도 창녕군", "pattern": r"(창녕|창녕군|경남 창녕)"},
        "REG_GONGJU": {"name": "충청남도 공주시", "pattern": r"(공주|공주시|충남 공주)"},
        "REG_SEONGNAM": {"name": "경기도 성남시", "pattern": r"(성남|성남시|분당)"},
    }

    @classmethod
    def generate_person_id(cls, name: str, birth_ym: Optional[str], gender: Optional[str] = "M") -> str:
        """
        Generates deterministic person_id: {name}_{YYYYMM}_{GENDER}
        Example: 이재명_196412_M, 한동훈_197304_M
        """
        clean_name = re.sub(r"[^\w]", "", name or "").strip()
        
        # Clean birth year/month (YYYYMM or YYYY)
        clean_ym = "UNKNOWN"
        if birth_ym:
            extracted_digits = re.sub(r"[^\d]", "", birth_ym)
            if len(extracted_digits) >= 6:
                clean_ym = extracted_digits[:6]
            elif len(extracted_digits) == 4:
                clean_ym = f"{extracted_digits}01"
            elif len(extracted_digits) > 0:
                clean_ym = extracted_digits

        clean_gender = (gender or "M").upper()
        if clean_gender not in ["M", "F"]:
            clean_gender = "M"

        return f"{clean_name}_{clean_ym}_{clean_gender}"

    @classmethod
    def normalize_school(cls, raw_school: str) -> Tuple[str, str, str, str]:
        """
        Normalizes raw school string.
        Returns: (school_code, standard_name, school_type, major)
        """
        if not raw_school or not raw_school.strip():
            return ("SCH_UNKNOWN", "기타", "UNKNOWN", "")

        clean_text = raw_school.strip()

        # Extract major if present (e.g. "법학과", "경영학 학사", "컴퓨터공학과")
        major = ""
        major_match = re.search(r"([가-힣a-zA-Z\s]+(학과|학부|과|전공|MBA|석사|박사|학사))", clean_text)
        if major_match:
            major = major_match.group(1).strip()

        for code, meta in cls.SCHOOL_MAP.items():
            if re.search(meta["pattern"], clean_text, re.IGNORECASE):
                return (code, meta["name"], meta["type"], major)

        # Fallback for unrecognized school
        fallback_code = f"SCH_{abs(hash(clean_text)) % 1000000:06d}"
        return (fallback_code, clean_text.split()[0], "OTHER", major)

    @classmethod
    def normalize_region(cls, raw_region: str) -> Tuple[str, str]:
        """
        Normalizes raw region string.
        Returns: (region_code, standard_name)
        """
        if not raw_region or not raw_region.strip():
            return ("REG_UNKNOWN", "미상")

        clean_text = raw_region.strip()

        for code, meta in cls.REGION_MAP.items():
            if re.search(meta["pattern"], clean_text, re.IGNORECASE):
                return (code, meta["name"])

        fallback_code = f"REG_{abs(hash(clean_text)) % 1000000:06d}"
        return (fallback_code, clean_text)

# Singleton helper instance
normalizer = TextNormalizer()
