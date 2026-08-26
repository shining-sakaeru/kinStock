import re
from typing import Dict, Any, Optional, List, Tuple

class EduNormalizer:
    """
    DART Education Entity Resolution & Degree Normalizer.
    Converts raw unstructured educational background into standardized School entities,
    degree types, and deterministic ALUMNI_WITH edges.
    """

    SCHOOL_DICTIONARY: Dict[str, Dict[str, Any]] = {
        # Major Universities (Korea)
        "SCH_UNIV_SEOUL_NATL": {
            "name": "서울대학교",
            "type": "UNIVERSITY",
            "aliases": [r"서울대", r"서울대학교", r"SNU", r"Seoul National Univ"],
        },
        "SCH_UNIV_KOREA": {
            "name": "고려대학교",
            "type": "UNIVERSITY",
            "aliases": [r"고려대", r"고려대학교", r"Korea University", r"KU"],
        },
        "SCH_UNIV_YONSEI": {
            "name": "연세대학교",
            "type": "UNIVERSITY",
            "aliases": [r"연세대", r"연세대학교", r"Yonsei"],
        },
        "SCH_UNIV_SOGANG": {
            "name": "서강대학교",
            "type": "UNIVERSITY",
            "aliases": [r"서강대", r"서강대학교", r"Sogang"],
        },
        "SCH_UNIV_SKKU": {
            "name": "성균관대학교",
            "type": "UNIVERSITY",
            "aliases": [r"성균관대", r"성균관대학교", r"SKKU"],
        },
        "SCH_UNIV_HANYANG": {
            "name": "한양대학교",
            "type": "UNIVERSITY",
            "aliases": [r"한양대", r"한양대학교", r"Hanyang"],
        },
        "SCH_UNIV_KAIST": {
            "name": "KAIST",
            "type": "UNIVERSITY",
            "aliases": [r"카이스트", r"KAIST", r"한국과학기술원"],
        },
        "SCH_UNIV_POSTECH": {
            "name": "POSTECH",
            "type": "UNIVERSITY",
            "aliases": [r"포항공대", r"포항공과대", r"POSTECH"],
        },
        "SCH_UNIV_CHUNGANG": {
            "name": "중앙대학교",
            "type": "UNIVERSITY",
            "aliases": [r"중앙대", r"중앙대학교"],
        },
        # Global Universities & Business Schools
        "SCH_UNIV_HARVARD": {
            "name": "하버드대학교",
            "type": "UNIVERSITY",
            "aliases": [r"하버드", r"Harvard"],
        },
        "SCH_GRAD_WHARTON": {
            "name": "펜실베이니아대 와튼스쿨",
            "type": "GRAD_SCHOOL",
            "aliases": [r"와튼", r"Wharton", r"펜실베이니아대.*MBA"],
        },
        "SCH_UNIV_BERKELEY": {
            "name": "UC 버클리",
            "type": "UNIVERSITY",
            "aliases": [r"버클리", r"UC Berkeley", r"UC버클리"],
        },
        "SCH_UNIV_STANFORD": {
            "name": "스탠퍼드대학교",
            "type": "UNIVERSITY",
            "aliases": [r"스탠퍼드", r"스탠포드", r"Stanford"],
        },
        "SCH_UNIV_COLUMBIA": {
            "name": "컬럼비아대학교",
            "type": "UNIVERSITY",
            "aliases": [r"컬럼비아", r"Columbia"],
        },
        # Major High Schools (Traditional Power Elite Networks)
        "SCH_HIGH_GYEONGGI": {
            "name": "경기고등학교",
            "type": "HIGH_SCHOOL",
            "aliases": [r"경기고", r"경기고등학교", r"경기고\s*\d+회"],
        },
        "SCH_HIGH_KYUNGBOK": {
            "name": "경복고등학교",
            "type": "HIGH_SCHOOL",
            "aliases": [r"경복고", r"경복고등학교", r"경복고\s*\d+회"],
        },
        "SCH_HIGH_SEOUL": {
            "name": "서울고등학교",
            "type": "HIGH_SCHOOL",
            "aliases": [r"서울고", r"서울고등학교", r"서울고\s*\d+회"],
        },
        "SCH_HIGH_HYUNDAI": {
            "name": "현대고등학교",
            "type": "HIGH_SCHOOL",
            "aliases": [r"현대고", r"현대고등학교"],
        },
        "SCH_HIGH_CHUNGAM": {
            "name": "충암고등학교",
            "type": "HIGH_SCHOOL",
            "aliases": [r"충암고", r"충암고등학교"],
        },
        "SCH_HIGH_WHIMOON": {
            "name": "휘문고등학교",
            "type": "HIGH_SCHOOL",
            "aliases": [r"휘문고", r"휘문고등학교"],
        },
        "SCH_HIGH_BUSAN": {
            "name": "부산고등학교",
            "type": "HIGH_SCHOOL",
            "aliases": [r"부산고", r"부산고등학교"],
        },
        "SCH_HIGH_DAEWON_FL": {
            "name": "대원외국어고등학교",
            "type": "HIGH_SCHOOL",
            "aliases": [r"대원외고", r"대원외국어고등학교"],
        },
    }

    DEGREE_PATTERNS: List[Tuple[str, str]] = [
        (r"(최고위|최고경영자|AMP|Executive)", "EXECUTIVE_COURSE"),
        (r"(박사|Ph\.?D)", "DOCTOR"),
        (r"(MBA|경영학\s*석사)", "MBA"),
        (r"(석사|Master)", "MASTER"),
        (r"(학사|Bachelor|졸업|과정)", "BACHELOR"),
    ]

    @classmethod
    def generate_person_id(cls, name: str, birth_ym: Optional[str] = None, gender: Optional[str] = "M") -> str:
        """
        Creates deterministic Person Node ID: P_{name}_{birth_ym}_{gender}
        Example: P_이재용_196806_M, P_최태원_196012_M
        """
        clean_name = re.sub(r"[^\w가-힣a-zA-Z]", "", name or "").strip()
        
        clean_ym = "UNKNOWN"
        if birth_ym:
            digits = re.sub(r"[^\d]", "", birth_ym)
            if len(digits) >= 6:
                clean_ym = digits[:6]
            elif len(digits) == 4:
                clean_ym = f"{digits}01"
            elif len(digits) > 0:
                clean_ym = digits

        clean_gender = (gender or "M").upper()
        if clean_gender not in ["M", "F"]:
            clean_gender = "M"

        return f"P_{clean_name}_{clean_ym}_{clean_gender}"

    @classmethod
    def parse_education_entry(cls, raw_edu: str) -> List[Dict[str, Any]]:
        """
        Parses raw education string (e.g. '서울대 경영학 학사 / 하버드대 MBA / 경기고')
        into structured standardized school entries.
        """
        if not raw_edu or not raw_edu.strip():
            return []

        results: List[Dict[str, Any]] = []
        # Split multiple educations by '/', ',', '\n', ';'
        segments = re.split(r"[/,\n;·]+", raw_edu)
        for seg in segments:
            seg = seg.strip()
            if not seg or len(seg) < 2:
                continue

            matched_school = None
            school_code = None
            for s_code, meta in cls.SCHOOL_DICTIONARY.items():
                for pat in meta["aliases"]:
                    if re.search(pat, seg, re.IGNORECASE):
                        matched_school = meta
                        school_code = s_code
                        break
                if matched_school:
                    break

            # Degree Extraction
            degree = "BACHELOR"
            for deg_pat, deg_type in cls.DEGREE_PATTERNS:
                if re.search(deg_pat, seg, re.IGNORECASE):
                    degree = deg_type
                    break

            # Major Extraction
            major = ""
            major_match = re.search(r"([가-힣a-zA-Z\s]+(학과|학부|전공|과|경영학|경제학|법학|전자공학|기계공학))", seg)
            if major_match:
                major = major_match.group(1).strip()

            if matched_school and school_code:
                results.append({
                    "school_code": school_code,
                    "school_name": matched_school["name"],
                    "school_type": matched_school["type"],
                    "degree": degree,
                    "major": major,
                    "raw_text": seg,
                })
            else:
                # Fallback for unrecognized school
                fallback_code = f"SCH_{abs(hash(seg)) % 1000000:06d}"
                results.append({
                    "school_code": fallback_code,
                    "school_name": seg.split()[0] if seg else "기타",
                    "school_type": "HIGH_SCHOOL" if "고" in seg else "UNIVERSITY",
                    "degree": degree,
                    "major": major,
                    "raw_text": seg,
                })

        return results

    @classmethod
    def create_alumni_edge(
        cls,
        person1_id: str,
        person2_id: str,
        school_info: Dict[str, Any],
        rcept_no: str,
        evidence_text: str,
    ) -> Dict[str, Any]:
        """
        Constructs deterministic :ALUMNI_WITH relationship payload with Tier 1 Legal evidence.
        """
        return {
            "source": person1_id,
            "target": person2_id,
            "relation_type": "ALUMNI_WITH",
            "school_code": school_info["school_code"],
            "school_name": school_info["school_name"],
            "degree": school_info.get("degree", "BACHELOR"),
            "major": school_info.get("major", ""),
            "evidence": {
                "evidence_text": evidence_text,
                "source_tier": "TIER_1_LEGAL",
                "source_name": "OPEN_DART",
                "rcept_no": rcept_no,
                "source_url": f"https://dart.fss.or.kr/dsaf001/main.do?rcpNo={rcept_no}",
                "extracted_at": "2026-08-26T22:00:00",
            },
        }

edu_normalizer = EduNormalizer()
