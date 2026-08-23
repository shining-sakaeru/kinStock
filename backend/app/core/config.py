import os
from pydantic import BaseModel

class Settings(BaseModel):
    API_V1_PREFIX: str = "/api/v1"
    PROJECT_NAME: str = "KinStock Relevance API"
    VERSION: str = "1.0.0"
    DEFAULT_DECAY_FACTOR: float = 0.80
    MAX_SEARCH_DEPTH: int = 3
    HOST: str = "0.0.0.0"
    PORT: int = 8000

settings = Settings()
