# Wire up the per-request GraphQL context object and seed it
# with a request correlation ID from X-Request-ID. Once auth is added
# the same context can also carry the authenticated `user_id`
# for resolvers.

# api/graphql/context.py
from __future__ import annotations
from fastapi import Request
from strawberry.fastapi import BaseContext  # <-- key import

# FastAPI requires that custom context must either be a dict or a class that
# inherits `BaseContext`. We use a class, so the router will merge
# the default context (request/response/background tasks) into the object.
class GQLContext(BaseContext):
    """
    Custom Strawberry context for FastAPI that *inherits* from BaseContext.
    BaseContext gives you .request, .response, .background_tasks.
    We add our own fields like user_id, request_id for convenience.
    """
    def __init__(self, *, user_id: str | None = None, request_id: str | None = None,) -> None:
        super().__init__()
        self.user_id = user_id
        self.request_id = request_id

def get_context_from_request(request: Request) -> GQLContext:
    # Build a string request ID.
    rid = (request.headers.get("X-Request-ID") or "").strip() or None
    # Return a BaseContext subclass instance.
    return GQLContext(user_id=None, request_id=rid)
