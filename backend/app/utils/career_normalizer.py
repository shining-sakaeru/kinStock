import re
from typing import Dict, Any, List, Optional

class CareerNormalizer:
    """
    DART Career & Past Affiliation Normalizer.
    Parses unstructured career descriptions (e.g. '전 현대자동차 전무', 'LG전자 상무 역임')
    into standardized past executive edges (:PAST_WORKED_AT) and colleague connections (:COLLEAGUE_WITH).
    """

    ROLE_PATTERNS: List[str] = [
        r"대표이사", r"회장", r"부회장", r"사장", r"부사장", r"전무", r"상무", r"이사",
        r"사외이사", r"감사", r"본부장", r"센터장", r"그룹장", r"실장", r"팀장",
        r"재판관", r"부장판사", r"검사장", r"부장검사", r"국회의원", r"장관", r"차관",
    ]

    PAST_INDICATORS: List[str] = [
        r"전\s*", r"역임", r"전임", r"퇴임", r"출신",
    ]

    CURRENT_INDICATORS: List[str] = [
        r"현\s*", r"현재", r"재직",
    ]

    @classmethod
    def parse_career_entry(cls, raw_career: str) -> List[Dict[str, Any]]:
        """
        Parses career text (e.g. '전 현대자동차 전무, 현 한국경영자총협회 부회장')
        into structured past/current career tokens.
        """
        if not raw_career or not raw_career.strip():
            return []

        results: List[Dict[str, Any]] = []
        segments = re.split(r"[,;\n/·]+", raw_career)

        for seg in segments:
            seg = seg.strip()
            if not seg or len(seg) < 2:
                continue

            # Detect is_past
            is_past = True
            for curr_pat in cls.CURRENT_INDICATORS:
                if re.search(curr_pat, seg):
                    is_past = False
                    break

            # Extract role
            extracted_role = "임원"
            for role_pat in cls.ROLE_PATTERNS:
                match = re.search(role_pat, seg)
                if match:
                    extracted_role = match.group(0)
                    break

            # Clean company or organization name
            cleaned_corp = seg
            for pat in cls.PAST_INDICATORS + cls.CURRENT_INDICATORS:
                cleaned_corp = re.sub(pat, "", cleaned_corp)
            for role_pat in cls.ROLE_PATTERNS:
                cleaned_corp = re.sub(role_pat, "", cleaned_corp)

            cleaned_corp = re.sub(r"[^\w가-힣a-zA-Z0-9\(\)]", "", cleaned_corp).strip()
            if len(cleaned_corp) < 2:
                cleaned_corp = "기타법인"

            results.append({
                "company_name": cleaned_corp,
                "role": extracted_role,
                "is_past": is_past,
                "relation_type": "PAST_WORKED_AT" if is_past else "SERVES_AS",
                "raw_text": seg,
            })

        return results

    @classmethod
    def create_past_worked_edge(
        cls,
        person_id: str,
        company_id_or_name: str,
        role: str,
        rcept_no: str,
        evidence_text: str,
    ) -> Dict[str, Any]:
        """
        Constructs deterministic :PAST_WORKED_AT relationship payload with Tier 1 Legal evidence.
        """
        return {
            "source": person_id,
            "target": company_id_or_name,
            "relation_type": "PAST_WORKED_AT",
            "role": role,
            "evidence": {
                "evidence_text": evidence_text,
                "source_tier": "TIER_1_LEGAL",
                "source_name": "OPEN_DART",
                "rcept_no": rcept_no,
                "source_url": f"https://dart.fss.or.kr/dsaf001/main.do?rcpNo={rcept_no}",
                "extracted_at": "2026-08-26T22:00:00",
            },
        }

career_normalizer = CareerNormalizer()
