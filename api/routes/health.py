# Used to create modular groups of routes--essentially
# mini apps you can attach the main application.
from fastapi import APIRouter

# In FastAPI apps, setting are managed using Pydantic's
# BaseSettings, which can load configs from the .env file.
from ..settings import get_settings

# Router initialization.
# `tag["health"]` assigns this router to a health tag,
# useful for grouping in OpenAPI docs and improving
# discoverability.
router = APIRouter(tags=["health"])


@router.get("/healthz")         # Decorator registers the function below as a `GET` on endpoint `/healthz`
async def healthz():
    # Access configuration, like app name and environment.
    # If cached via `@lru_cache` avoids repeated reads of
    # variables and configurations.
    s = get_settings()
    return {
        "ok": True,
        "service": s.app_name,
        "env": s.environment
    }