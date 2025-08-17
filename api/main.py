# FastAPI is the application class used to build an ASGI app.
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import structlog
from fastapi import FastAPI

# Adds proper CORS headers to responses and handles
# preflight requests. Useful when the frontend runs on
# a different origin.
from fastapi.middleware.cors import CORSMiddleware

# Strawberry's router that plugs a GraphQL schema into
# FastAPI.
from strawberry.fastapi import GraphQLRouter

from .graphql.context import (
    get_context_from_request,  # builds the sberry context object for each request
)
from .graphql.schema import schema  # strawberry graphql schema
from .routes import health as health_routes  # an APIRouter with our endpoint(s)
from .settings import get_settings  # configuration accessor
from .utils.logger import configure_logging  # wires stdlib logging + structlog
from .utils.request_id import RequestIDMiddleware  # propagate X-Request-ID for log correlation

# Configure logging.
configure_logging(level=get_settings().log_level)
log = structlog.get_logger(__name__)


# Lifecycle Events
# Register a function to run at startup (warm caches, connect to DB).
# An async context manager is passed via the lifespan parameter.
# Code before yield runs at startup, after yield runs at shutdown.
@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    # Startup phase
    log = structlog.get_logger(__name__)
    settings = get_settings()
    log.info("startup", service=settings.app_name, env=settings.environment)

    yield  # app starts handling requests here.

    # Shutdown phase
    log.info("shutdown")


app = FastAPI(title="SessionHub API", lifespan=lifespan)

# Middleware
app.add_middleware(RequestIDMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=get_settings().cors_allow_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Takes our router defined in health.py and integrates it's
# defined routes into the main FastAPI application.
# It registers all the routes defined in health.py
# to the application.
app.include_router(health_routes.router)

# GraphQL Router
# Create sberry GraphQL router with defined schema.
graphql_app = GraphQLRouter(
    schema, context_getter=get_context_from_request, graphql_ide="apollo-sandbox"
)
app.include_router(graphql_app, prefix="/graphql")
