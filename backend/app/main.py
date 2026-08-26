import os
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.presentation.api.v1.search_router import router as search_router
from app.presentation.api.v1.themes_router import router as themes_router
from app.presentation.api.v1.figures_router import router as figures_router
from app.presentation.api.v1.stocks_router import router as stocks_router
from app.presentation.api.v1.relations_router import router as relations_router
from app.presentation.api.v1.weights_router import router as weights_router
from app.presentation.api.v1.network_router import router as network_router
from app.presentation.api.v1.admin_router import router as admin_router
from app.services.nightly_batch_scheduler import start_apscheduler
from app.services.seed_injector import inject_core_seed_data

logger = logging.getLogger("KinStock.Main")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Seed core data & Start APScheduler for Nightly Batch
    inject_core_seed_data()
    scheduler = start_apscheduler()
    logger.info("🚀 KinStock Server & Nightly Scheduler Started.")
    yield
    # Shutdown
    if scheduler:
        scheduler.shutdown()
        logger.info("🛑 KinStock Nightly Scheduler Shutdown.")

app = FastAPI(
    title="KinStock Clean Architecture API",
    description="Clean Architecture & DART Verified Open-Source Stock-Figure Network Intelligence Engine",
    version="2.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health Check Endpoints
@app.get("/api/health", tags=["System"])
@app.get("/health", tags=["System"])
def health_check():
    return {
        "status": "healthy",
        "service": "KinStock Backend Engine",
        "version": "2.0.0",
        "environment": "Oracle Cloud ARM64",
        "scheduler": "APScheduler 3-Phase Nightly Active (22:00~07:00 KST)"
    }

# 1. Register Clean Architecture API Routers
app.include_router(search_router, prefix="/api/v1", tags=["Universal Search"])
app.include_router(themes_router, prefix="/api/v1", tags=["Themes & Mode C Cluster"])
app.include_router(figures_router, prefix="/api/v1", tags=["Figures & Mode A Person-Hub"])
app.include_router(stocks_router, prefix="/api/v1", tags=["Stocks & Mode B Stock-Hub"])
app.include_router(relations_router, prefix="/api/v1", tags=["Tier 2 Relations & Rationale"])
app.include_router(weights_router, prefix="/api/v1", tags=["Weights & Baseline"])
app.include_router(network_router, prefix="/api/v1", tags=["Synapse Network"])
app.include_router(admin_router, prefix="/api/v1", tags=["Admin & Batch Monitoring"])

# 2. Mount Flutter Web SPA (All-in-One single port hosting for Mobile / Tunnels)
current_dir = os.path.dirname(os.path.abspath(__file__))
web_dist = os.path.abspath(os.path.join(current_dir, "../../frontend/build/web"))

if os.path.exists(web_dist):
    app.mount("/", StaticFiles(directory=web_dist, html=True), name="frontend")
else:
    @app.get("/")
    def root():
        return {
            "service": "KinStock Clean Architecture API",
            "version": "2.0.0",
            "docs": "/docs",
            "standards": "Robert C. Martin Clean Architecture & SOLID"
        }
