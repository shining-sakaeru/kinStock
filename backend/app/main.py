import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.presentation.api.v1.search_router import router as search_router
from app.presentation.api.v1.themes_router import router as themes_router
from app.presentation.api.v1.figures_router import router as figures_router
from app.presentation.api.v1.stocks_router import router as stocks_router
from app.presentation.api.v1.relations_router import router as relations_router
from app.presentation.api.v1.weights_router import router as weights_router

app = FastAPI(
    title="KinStock Clean Architecture API",
    description="Clean Architecture & DART Verified Open-Source Stock-Figure Network Intelligence Engine",
    version="2.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 1. Register Clean Architecture API Routers
app.include_router(search_router, prefix="/api/v1", tags=["Universal Search"])
app.include_router(themes_router, prefix="/api/v1", tags=["Themes & Mode C Cluster"])
app.include_router(figures_router, prefix="/api/v1", tags=["Figures & Mode A Person-Hub"])
app.include_router(stocks_router, prefix="/api/v1", tags=["Stocks & Mode B Stock-Hub"])
app.include_router(relations_router, prefix="/api/v1", tags=["Tier 2 Relations & Rationale"])
app.include_router(weights_router, prefix="/api/v1", tags=["Weights & Baseline"])

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
