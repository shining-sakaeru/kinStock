import os
import time
import math
import logging
from datetime import datetime, timezone, timedelta
from typing import Dict, Any, Optional, List, Tuple
from pydantic import BaseModel, Field

logger = logging.getLogger("KinStock.BatchProgressManager")

class BatchPredictionMetrics(BaseModel):
    total_target_companies: int = Field(2500, description="전체 수집 목표 기업 수 (코스피/코스닥/코넥스)")
    total_target_persons: int = Field(30000, description="전체 수집 목표 임원 수")
    processed_companies: int = Field(0, description="현재 누적 처리 완료 기업 수")
    processed_persons: int = Field(0, description="현재 누적 처리 완료 임원 수")
    remaining_companies: int = Field(2500, description="남은 처리 대상 기업 수")
    total_progress_pct: float = Field(0.0, description="전체 목표 대비 누적 진행률 (%)")
    
    # Throughput metrics
    avg_seconds_per_company: float = Field(1.5, description="기업당 평균 처리 시간 (초)")
    throughput_companies_per_min: float = Field(40.0, description="분당 처리량 (기업/분)")
    
    # Time estimation metrics
    est_remaining_seconds: float = Field(0.0, description="남은 총 작업 순수 연산 시간 (초)")
    est_remaining_hours: float = Field(0.0, description="남은 총 작업 순수 연산 시간 (시간)")
    nightly_window_hours_per_day: float = Field(9.0, description="일일 야간 가용 시간 (22:00 ~ 07:00, 9시간)")
    est_completion_date: str = Field("", description="일일 9시간 야간 배치 기준 최종 완료 예측 시점")
    
    # State tracking
    is_active: bool = Field(False, description="현재 배치 프로세스 가동 여부")
    current_phase: str = Field("IDLE", description="현재 작업 단계 (PHASE_1_COLLECT, PHASE_2_INFER, etc.)")
    current_company: Optional[str] = Field(None, description="현재 처리 중인 기업명")
    last_updated_at: str = Field("", description="최근 지표 갱신 시각 (ISO8601)")


class BatchProgressManager:
    """
    Batch Progress & ETA Calculation Engine:
    1. Sets target to ~2,500 listed companies (KOSPI, KOSDAQ, KONEX) and ~30,000 executives.
    2. Calculates throughput based on real/simulated processing speed.
    3. Factors in the Nightly Active Window (22:00 ~ 07:00 KST, 9 hours/day = 540 min/day).
    4. Dynamically advances progress and estimates completion date.
    """

    TOTAL_TARGET_COMPANIES = 2500
    TOTAL_TARGET_PERSONS = 30000
    NIGHTLY_START_HOUR = 22 # 22:00 KST
    NIGHTLY_END_HOUR = 7    # 07:00 KST
    DAILY_WINDOW_HOURS = 9.0

    SAMPLE_COMPANIES = [
        "삼성전자 (005930)", "SK하이닉스 (000660)", "LG에너지솔루션 (373220)", "삼성바이오로직스 (207940)",
        "현대자동차 (005380)", "기아 (000270)", "셀트리온 (068270)", "KB금융 (105560)",
        "에이텍 (045660)", "동신건설 (025950)", "오리엔트정공 (065500)", "안랩 (053800)",
        "써니전자 (004770)", "대상홀딩스 (084690)", "태양금속 (004100)", "덕성 (004830)",
        "NE능률 (053290)", "대영포장 (014160)", "현대글로비스 (086280)", "이마트 (139480)",
        "신세계 (004170)", "한화에어로스페이스 (012450)", "한국항공우주 (047810)", "두산에너빌리티 (034020)",
        "카카오 (035720)", "NAVER (035420)", "포스코홀딩스 (005490)", "HD현대중공업 (329180)"
    ]

    def __init__(self):
        self.processed_companies = 45
        self.processed_persons = 142
        self.is_active = True
        self.current_phase = "PHASE_1_DART_INGESTION"
        self.current_company = "에이텍 (045660)"
        self.last_tick_time = time.time()
        self.recent_latencies: List[float] = [1.2, 1.4, 1.1, 1.5, 1.3, 1.6, 1.2, 1.4] # seconds per corp
        self.last_updated_at = datetime.now(timezone.utc)

    def trigger_step(self, count: int = 1) -> Dict[str, Any]:
        """Manually or dynamically advances the batch ingestion progress."""
        for _ in range(count):
            comp_idx = self.processed_companies % len(self.SAMPLE_COMPANIES)
            self.processed_companies = min(self.TOTAL_TARGET_COMPANIES, self.processed_companies + 1)
            self.processed_persons += 3
            self.current_company = self.SAMPLE_COMPANIES[comp_idx]
            self.recent_latencies.append(1.35)
            if len(self.recent_latencies) > 100:
                self.recent_latencies.pop(0)

        self.is_active = True
        self.last_updated_at = datetime.now(timezone.utc)
        return {
            "status": "success",
            "processed_companies": self.processed_companies,
            "processed_persons": self.processed_persons,
            "current_company": self.current_company,
            "progress_pct": round((self.processed_companies / self.TOTAL_TARGET_COMPANIES) * 100.0, 2)
        }

    def record_company_processed(self, company_name: str, duration_sec: float, persons_count: int = 3):
        self.processed_companies += 1
        self.processed_persons += persons_count
        self.current_company = company_name
        self.is_active = True
        self.last_updated_at = datetime.now(timezone.utc)
        
        self.recent_latencies.append(duration_sec)
        if len(self.recent_latencies) > 100:
            self.recent_latencies.pop(0)

    def calculate_eta_completion_date(self, remaining_work_seconds: float, now_dt: Optional[datetime] = None) -> Tuple[datetime, int]:
        kst = timezone(timedelta(hours=9))
        current_dt = (now_dt or datetime.now(timezone.utc)).astimezone(kst)
        remaining_sec = remaining_work_seconds

        cursor = current_dt
        max_iterations = 365
        iter_count = 0

        while remaining_sec > 0 and iter_count < max_iterations:
            iter_count += 1
            hour = cursor.hour
            in_night_window = (hour >= self.NIGHTLY_START_HOUR or hour < self.NIGHTLY_END_HOUR)

            if in_night_window:
                if hour >= self.NIGHTLY_START_HOUR:
                    next_boundary = cursor.replace(hour=self.NIGHTLY_END_HOUR, minute=0, second=0, microsecond=0) + timedelta(days=1)
                else:
                    next_boundary = cursor.replace(hour=self.NIGHTLY_END_HOUR, minute=0, second=0, microsecond=0)

                seconds_available = (next_boundary - cursor).total_seconds()
                if seconds_available <= 0:
                    cursor = cursor + timedelta(minutes=1)
                    continue

                if remaining_sec <= seconds_available:
                    cursor = cursor + timedelta(seconds=remaining_sec)
                    remaining_sec = 0
                    break
                else:
                    remaining_sec -= seconds_available
                    cursor = next_boundary
            else:
                next_start = cursor.replace(hour=self.NIGHTLY_START_HOUR, minute=0, second=0, microsecond=0)
                if next_start <= cursor:
                    next_start += timedelta(days=1)
                cursor = next_start

        days_diff = (cursor.date() - current_dt.date()).days
        return cursor, days_diff

    def get_metrics(self) -> BatchPredictionMetrics:
        # Auto-advance progress dynamically based on time passage
        now = time.time()
        elapsed = now - self.last_tick_time
        if elapsed >= 2.0 and self.is_active and self.processed_companies < self.TOTAL_TARGET_COMPANIES:
            steps = int(elapsed // 2.0)
            self.last_tick_time = now
            self.trigger_step(steps)

        # Calculate throughput
        if self.recent_latencies:
            avg_sec = sum(self.recent_latencies) / len(self.recent_latencies)
        else:
            avg_sec = 1.35
        avg_sec = max(0.2, avg_sec)

        throughput_per_min = 60.0 / avg_sec
        remaining = max(0, self.TOTAL_TARGET_COMPANIES - self.processed_companies)
        progress_pct = round((self.processed_companies / self.TOTAL_TARGET_COMPANIES) * 100.0, 2)

        est_rem_seconds = remaining * avg_sec
        est_rem_hours = round(est_rem_seconds / 3600.0, 2)

        completion_dt, d_days = self.calculate_eta_completion_date(est_rem_seconds)
        formatted_date = completion_dt.strftime("%Y-%m-%d %H:%M")
        
        if d_days == 0:
            eta_str = f"{formatted_date} 완료 예상 (오늘 밤 완료)"
        elif d_days == 1:
            eta_str = f"{formatted_date} 완료 예상 (내일 아침 완료)"
        else:
            eta_str = f"{formatted_date} 완료 예상 (D-{d_days}일)"

        return BatchPredictionMetrics(
            total_target_companies=self.TOTAL_TARGET_COMPANIES,
            total_target_persons=self.TOTAL_TARGET_PERSONS,
            processed_companies=self.processed_companies,
            processed_persons=self.processed_persons,
            remaining_companies=remaining,
            total_progress_pct=progress_pct,
            avg_seconds_per_company=round(avg_sec, 2),
            throughput_companies_per_min=round(throughput_per_min, 1),
            est_remaining_seconds=round(est_rem_seconds, 1),
            est_remaining_hours=est_rem_hours,
            nightly_window_hours_per_day=self.DAILY_WINDOW_HOURS,
            est_completion_date=eta_str,
            is_active=self.is_active,
            current_phase=self.current_phase,
            current_company=self.current_company,
            last_updated_at=self.last_updated_at.isoformat()
        )

# Singleton instance
progress_manager = BatchProgressManager()
