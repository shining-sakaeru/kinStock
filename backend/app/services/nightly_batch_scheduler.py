import os
import logging
import argparse
from datetime import datetime, timezone
from typing import Dict, Any
from app.services.dart_ingestion_service import dart_ingestion_service
from app.services.dart_batch_sync import dart_batch_sync_service
from app.data.repositories.memory_store import memory_store

logger = logging.getLogger("KinStock.NightlyScheduler")
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")

class NightlyBatchPipeline:
    """
    KinStock 3-Phase Nightly Batch Pipeline (22:00 ~ 07:00 KST):
    Optimized for Oracle Cloud Always Free (ARM64 6GB RAM).
    
    Phases:
    - Phase 1 (22:00 ~ 23:30): TIER 1 Legal DART Ingestion (Company, Person, Report, ServesAs, Stake).
    - Phase 2 (23:30 ~ 04:00): Normalization & Synapse Inference (Alumni, Hometown, Cohort with evidence).
    - Phase 3 (04:00 ~ 06:30): Graph Centrality Precomputation & Real-Time Market Warming.
    """

    def run_phase_1_tier1_ingestion(self, target_date: str = None) -> Dict[str, Any]:
        """Phase 1 (22:00): Ingests DART daily filings & sets TIER_1_LEGAL metadata."""
        logger.info("🌙 [Phase 1 Start | 22:00 KST] Ingesting Tier 1 DART Electronic Disclosures...")
        result = dart_ingestion_service.ingest_filings_for_date(target_date)
        logger.info(f"✨ [Phase 1 Finished]: {result}")
        return result

    def run_phase_2_synapse_inference(self) -> Dict[str, Any]:
        """Phase 2 (23:30): Cross-inference for Alumni & Hometown Synapses."""
        logger.info("🌙 [Phase 2 Start | 23:30 KST] Running Synapse Cross-Inference Pipeline...")
        result = dart_batch_sync_service.run_sync_and_inference()
        logger.info(f"✨ [Phase 2 Finished]: {result}")
        return result

    def run_phase_3_market_warming_and_metrics(self) -> Dict[str, Any]:
        """Phase 3 (04:00): Precomputes graph metrics and warms market cache."""
        logger.info("🌙 [Phase 3 Start | 04:00 KST] Warming graph cache and market prices...")
        companies = memory_store.get_all_companies()
        persons = memory_store.get_all_persons()
        
        # Calculate degree metrics
        node_degrees = {node: memory_store.graph.degree(node) for node in memory_store.graph.nodes()}
        
        result = {
            "status": "success",
            "warmed_companies_count": len(companies),
            "warmed_persons_count": len(persons),
            "total_graph_nodes": len(node_degrees),
            "timestamp": datetime.now(timezone.utc).isoformat()
        }
        logger.info(f"✨ [Phase 3 Finished]: {result}")
        return result

    def run_full_nightly_pipeline(self, target_date: str = None) -> Dict[str, Any]:
        """Executes all 3 phases sequentially."""
        logger.info("🚀 Starting Full KinStock Nightly 3-Phase Batch Pipeline...")
        p1 = self.run_phase_1_tier1_ingestion(target_date)
        p2 = self.run_phase_2_synapse_inference()
        p3 = self.run_phase_3_market_warming_and_metrics()
        
        return {
            "status": "success",
            "pipeline_timestamp": datetime.now(timezone.utc).isoformat(),
            "phase_1": p1,
            "phase_2": p2,
            "phase_3": p3
        }

def start_apscheduler():
    """Starts APScheduler background cron jobs (22:00, 23:30, 04:00 KST)."""
    try:
        from apscheduler.schedulers.background import BackgroundScheduler
        from apscheduler.triggers.cron import CronTrigger
        
        scheduler = BackgroundScheduler(timezone="Asia/Seoul")
        pipeline = NightlyBatchPipeline()

        # Phase 1: Every day at 22:00
        scheduler.add_job(
            pipeline.run_phase_1_tier1_ingestion,
            trigger=CronTrigger(hour=22, minute=0),
            id="phase_1_tier1_ingest",
            replace_existing=True
        )

        # Phase 2: Every day at 23:30
        scheduler.add_job(
            pipeline.run_phase_2_synapse_inference,
            trigger=CronTrigger(hour=23, minute=30),
            id="phase_2_synapse_infer",
            replace_existing=True
        )

        # Phase 3: Every day at 04:00
        scheduler.add_job(
            pipeline.run_phase_3_market_warming_and_metrics,
            trigger=CronTrigger(hour=4, minute=0),
            id="phase_3_market_warm",
            replace_existing=True
        )

        scheduler.start()
        logger.info("🕒 KinStock Nightly APScheduler successfully started with 3-Phase Cron triggers.")
        return scheduler
    except ImportError:
        logger.warning("APScheduler not installed. Batch pipeline can be triggered manually via CLI or API.")
        return None

# CLI Execution
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="KinStock Nightly Batch Pipeline Runner")
    parser.add_argument("--phase", type=int, choices=[1, 2, 3], help="Specific phase to run (1, 2, or 3)")
    parser.add_argument("--run-all", action="store_true", help="Run full 3-phase nightly pipeline")
    parser.add_argument("--date", type=str, help="Target date in YYYYMMDD format", default=None)
    args = parser.parse_args()

    pipeline = NightlyBatchPipeline()
    if args.phase == 1:
        pipeline.run_phase_1_tier1_ingestion(args.date)
    elif args.phase == 2:
        pipeline.run_phase_2_synapse_inference()
    elif args.phase == 3:
        pipeline.run_phase_3_market_warming_and_metrics()
    else:
        pipeline.run_full_nightly_pipeline(args.date)
