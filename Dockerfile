ARG PYTHON_IMAGE=python:3.12-slim

# ---------- base (shared setup) ----------
FROM ${PYTHON_IMAGE} AS base
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Install OS deps (kept minimal for slim images).
# RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*.

# Copy only files needed to resolve Python deps (layer cache).
COPY pyproject.toml README.md ./
# Install runtime + dev deps for the dev image (editable so hot-reload sees code).
RUN python -m pip install --upgrade pip && \
    pip install -e ".[dev]"

# ---------- dev ----------
FROM base AS dev
# Create a non-root user.
ARG APP_USER=app
ARG APP_UID=1000
ARG APP_GID=1000
RUN groupadd -g ${APP_GID} -r ${APP_USER} && \
    useradd -r -g ${APP_GID} -u ${APP_UID} ${APP_USER} && \
    chown -R ${APP_USER}:${APP_USER} /app
USER ${APP_USER}

# Copy the rest of the source.
# Compose will bind-mount for hot reload.
COPY --chown=${APP_USER}:${APP_USER} . .

EXPOSE 8000
# Dev command: Uvicorn with auto-reload (docs: --reload)--watch whole repo.
# Defined in docker-compose.
CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

# ---------- prod (for later) ----------
FROM base AS prod
# (Optional) Copy just the package and runtime assets, then run without --reload.
COPY . .
EXPOSE 8000
CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]