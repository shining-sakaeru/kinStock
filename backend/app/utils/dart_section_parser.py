import datetime
from typing import Dict, Any, List, Optional
from app.utils.edu_normalizer import edu_normalizer
from app.utils.career_normalizer import career_normalizer

class DartSectionParser:
    """
    DART Multi-Section Fact & Legal Evidence Ingestion Parser.
    Extracts high-precision factual entities from 4 core periodic report sections.
    """

    @classmethod
    def parse_section_viii_executives(
        cls,
        corp_code: str,
        corp_name: str,
        rcept_no: str,
        executives_raw_list: List[Dict[str, Any]],
        report_name: str = "사업보고서",
    ) -> Dict[str, Any]:
        """
        섹션 VIII. 임원 및 직원 등에 관한 사항 -> 1. 임원의 현황 파싱
        """
        persons: List[Dict[str, Any]] = []
        serves_edges: List[Dict[str, Any]] = []
        edu_edges: List[Dict[str, Any]] = []
        past_edges: List[Dict[str, Any]] = []

        now_str = datetime.datetime.now(datetime.timezone.utc).isoformat()
        source_url = f"https://dart.fss.or.kr/dsaf001/main.do?rcpNo={rcept_no}"

        for item in executives_raw_list:
            name = item.get("name", "").strip()
            if not name:
                continue

            birth_ym = item.get("birth_ym", "").strip()
            gender = item.get("gender", "M").strip()
            position = item.get("position", "임원").strip()
            is_registered = bool(item.get("is_registered", False))
            tenure = item.get("tenure", "").strip()
            edu_raw = item.get("education_raw", "").strip()
            career_raw = item.get("career_raw", "").strip()

            person_id = edu_normalizer.generate_person_id(name, birth_ym, gender)
            evidence_text = f"[{report_name}] 임원의 현황: 성명 {name}({birth_ym or '미상'}), 직위 {position}, 등기여부 {'등기' if is_registered else '미등기'}, 최종학력 {edu_raw or '미기재'}"

            # 1. Person Node Payload
            persons.append({
                "id": person_id,
                "name": name,
                "birth_ym": birth_ym,
                "gender": gender,
                "position": position,
                "is_registered": is_registered,
                "tenure": tenure,
                "education_raw": edu_raw,
                "career_raw": career_raw,
                "source_url": source_url,
            })

            # 2. SERVES_AS Edge (Person -> Company)
            serves_edges.append({
                "source": person_id,
                "target": f"C_{corp_code}",
                "corp_code": corp_code,
                "relation_type": "SERVES_AS",
                "position": position,
                "is_registered": is_registered,
                "weight": 0.95 if is_registered else 0.85,
                "evidence_text": evidence_text,
                "source_tier": "TIER_1_LEGAL",
                "source_name": "OPEN_DART",
                "rcept_no": rcept_no,
                "source_url": source_url,
                "extracted_at": now_str,
            })

            # 3. Education / School Nodes & GRADUATED_FROM
            edu_parsed = edu_normalizer.parse_education_entry(edu_raw)
            for edu_entry in edu_parsed:
                edu_edges.append({
                    "source": person_id,
                    "target": edu_entry["school_code"],
                    "school_code": edu_entry["school_code"],
                    "school_name": edu_entry["school_name"],
                    "school_type": edu_entry["school_type"],
                    "degree": edu_entry["degree"],
                    "major": edu_entry["major"],
                    "relation_type": "GRADUATED_FROM",
                    "evidence_text": f"[{report_name}] 임원 학력 기재: {edu_entry['raw_text']}",
                    "source_tier": "TIER_1_LEGAL",
                    "source_name": "OPEN_DART",
                    "rcept_no": rcept_no,
                    "source_url": source_url,
                    "extracted_at": now_str,
                })

            # 4. Past Careers
            career_parsed = career_normalizer.parse_career_entry(career_raw)
            for car_entry in career_parsed:
                if car_entry["is_past"]:
                    past_edges.append({
                        "source": person_id,
                        "target_company_name": car_entry["company_name"],
                        "relation_type": "PAST_WORKED_AT",
                        "role": car_entry["role"],
                        "evidence_text": f"[{report_name}] 임원 주요경력 기재: {car_entry['raw_text']}",
                        "source_tier": "TIER_1_LEGAL",
                        "source_name": "OPEN_DART",
                        "rcept_no": rcept_no,
                        "source_url": source_url,
                        "extracted_at": now_str,
                    })

        return {
            "persons": persons,
            "serves_edges": serves_edges,
            "edu_edges": edu_edges,
            "past_edges": past_edges,
        }

    @classmethod
    def parse_section_vii_shareholders(
        cls,
        corp_code: str,
        corp_name: str,
        rcept_no: str,
        shareholders_raw_list: List[Dict[str, Any]],
        report_name: str = "사업보고서",
    ) -> Dict[str, Any]:
        """
        섹션 VII. 주주에 관한 사항 -> 1. 최대주주 및 특수관계인의 주식소유 현황 파싱
        """
        stake_edges: List[Dict[str, Any]] = []
        family_edges: List[Dict[str, Any]] = []
        now_str = datetime.datetime.now(datetime.timezone.utc).isoformat()
        source_url = f"https://dart.fss.or.kr/dsaf001/main.do?rcpNo={rcept_no}"

        max_shareholder_id: Optional[str] = None

        for idx, item in enumerate(shareholders_raw_list):
            name = item.get("shareholder_name", "").strip()
            if not name:
                continue

            relation = item.get("relation", "본인").strip()
            share_count = int(item.get("share_count", 0))
            share_ratio = float(item.get("share_ratio", 0.0))
            is_max = (relation == "본인" or idx == 0)

            person_id = edu_normalizer.generate_person_id(name)
            if is_max:
                max_shareholder_id = person_id

            evidence_text = f"[{report_name}] 최대주주 및 특수관계인 주식소유: {name}(관계: {relation}), 소유주식수 {share_count:,}주 ({share_ratio:.2f}%)"

            # 1. OWNS_STAKE Edge (Person/Entity -> Company)
            stake_edges.append({
                "source": person_id,
                "target": f"C_{corp_code}",
                "corp_code": corp_code,
                "relation_type": "OWNS_STAKE",
                "relation_label": relation,
                "share_count": share_count,
                "share_ratio": share_ratio,
                "is_max_shareholder": is_max,
                "weight": 0.98 if is_max else 0.85,
                "evidence_text": evidence_text,
                "source_tier": "TIER_1_LEGAL",
                "source_name": "OPEN_DART",
                "rcept_no": rcept_no,
                "source_url": source_url,
                "extracted_at": now_str,
            })

            # 2. FAMILY_WITH Edge (if relative)
            if not is_max and max_shareholder_id and person_id != max_shareholder_id:
                if any(k in relation for k in ["배우자", "자", "녀", "친인척", "모", "부", "형제", "자매"]):
                    family_edges.append({
                        "source": max_shareholder_id,
                        "target": person_id,
                        "relation_type": "FAMILY_WITH",
                        "relation_detail": relation,
                        "evidence_text": f"[{report_name}] 친인척 특수관계인 공시: {name} (최대주주와의 관계: {relation})",
                        "source_tier": "TIER_1_LEGAL",
                        "source_name": "OPEN_DART",
                        "rcept_no": rcept_no,
                        "source_url": source_url,
                        "extracted_at": now_str,
                    })

        return {
            "stake_edges": stake_edges,
            "family_edges": family_edges,
        }

    @classmethod
    def parse_section_ix_affiliates(
        cls,
        parent_corp_code: str,
        parent_corp_name: str,
        rcept_no: str,
        affiliates_raw_list: List[Dict[str, Any]],
        report_name: str = "사업보고서",
    ) -> List[Dict[str, Any]]:
        """
        섹션 IX. 계열회사 등에 관한 사항 -> 1. 계열회사 및 타법인 출자현황 파싱
        """
        affiliate_edges: List[Dict[str, Any]] = []
        now_str = datetime.datetime.now(datetime.timezone.utc).isoformat()
        source_url = f"https://dart.fss.or.kr/dsaf001/main.do?rcpNo={rcept_no}"

        for item in affiliates_raw_list:
            investee_name = item.get("investee_corp_name", "").strip()
            investee_code = item.get("investee_corp_code", "").strip()
            if not investee_name:
                continue

            ratio = float(item.get("ownership_ratio", 0.0))
            book_value = int(item.get("book_value", 0))
            affiliate_type = "SUBSIDIARY" if ratio >= 50.0 else "AFFILIATE"

            target_id = f"C_{investee_code}" if investee_code else f"C_{investee_name}"
            evidence_text = f"[{report_name}] 계열회사/타법인 출자현황: 피출자법인 {investee_name}, 지분율 {ratio:.2f}%, 장부가액 {book_value:,}백만원"

            affiliate_edges.append({
                "source": f"C_{parent_corp_code}",
                "target": target_id,
                "investee_corp_name": investee_name,
                "investee_corp_code": investee_code,
                "ownership_ratio": ratio,
                "book_value": book_value,
                "type": affiliate_type,
                "relation_type": "AFFILIATED_WITH",
                "evidence_text": evidence_text,
                "source_tier": "TIER_1_LEGAL",
                "source_name": "OPEN_DART",
                "rcept_no": rcept_no,
                "source_url": source_url,
                "extracted_at": now_str,
            })

        return affiliate_edges

dart_section_parser = DartSectionParser()
