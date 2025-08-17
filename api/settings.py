# lru_cache: Caches function results so repeated calls with the same parameters
# return instantly without re-running the function.
from functools import lru_cache

# Field lets you set defaults, metadata, and validation options for each model field.
from pydantic import Field

# BaseSettings is a special pydantic class that can automatically read configuration
# values from environment variables and .env files.
from pydantic_settings import BaseSettings


# BaseSettings reads values from environment variables.
class Settings(BaseSettings):
    app_name: str = Field(default="sessionhub-api")
    environment: str = Field(default="local")
    log_level: str = Field(default="INFO")
    cors_allow_origins: list[str] = Field(default_factory=lambda: ["*"])

    # Placeholder for DB settings.
    db_host: str | None = None
    db_port: int = 5432
    db_user: str | None = None
    db_password: str | None = None
    db_name: str | None = None

    # load values from .env.
    # If extra, unexpected vars exist, ignore them.
    model_config = {"env_file": ".env", "extra": "ignore"}


# Pydantic Settings + @lru_cache pattern is the recommended way to load env variables.
@lru_cache
def get_settings() -> Settings:
    # Ensures the Settings object is read only once.
    # Settings are not needed on every request.
    return Settings()
