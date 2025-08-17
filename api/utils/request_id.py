# Ensures every HTTP request has a unique and traceable request ID.
# Make that ID appear in all logs produced while handling that request
# via structlog contextvars.
# Return the ID to the client in `X-Request-ID`, so clients, proxies
# and other services can use/propagate it.
# This dramatically improves observability and debugging.

# Creates a random unique ID for requests that did not supply one.
import uuid

# Starlette provides the core building blocks you need for an
# async web app or API.
from starlette.middleware.base import BaseHTTPMiddleware        # Handles boilerplate wrapping an ASGI app.
from starlette.responses import Response                        # Request/Response primitives you interact
from starlette.requests import Request                          # with inside Starlette/FastAPI middleware.
import structlog

REQUEST_ID_HEADER = "X-Request-ID"

class RequestIDMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        # Reset per-request context so nothing leaks across requests.
        structlog.contextvars.clear_contextvars()

        # Grab client-provided request ID if present...
        incoming = request.headers.get(REQUEST_ID_HEADER)
        request_id = (incoming.strip() if incoming else "") or str(uuid.uuid4()) # ... if not, create one.

        # Bind into structlog's context so all logs for this request carry it
        structlog.contextvars.bind_contextvars(request_id=request_id)

        try:
            response: Response = await call_next(request)
            # Starlette requires header values to be a string.
            # request_id is guaranteed string.
            response.headers[REQUEST_ID_HEADER] = request_id
            return response
        finally:
            # Clear again at the end of the request
            structlog.contextvars.clear_contextvars()