# GraphQL framework.
import strawberry

# Decorates as a GraphQL object type, this class becomes
# a GraphQL `type` in the schema.
@strawberry.type
# The root `Query` type for the GraphQL schema.
# Query is the entry point for all read operations.
class Query:
    # Marks the method as a GraphQL resolver (field) of the `Query` type.
    # It tells Strawberry how to fetch data when the client request this field.
    @strawberry.field()
    # When GraphQL requests `ping`, Strawberry will execute this method to
    # provide the value.
    def ping(self) -> str:
        return "pong"

# Constructs the GraphQL schema by designating `Query` as the root query type.
# Now the schema knows there is a `ping` field available under `Query`, which
# clients can query.
schema = strawberry.Schema(query=Query)