# swift-graphql-pagination

A Swift implementation of the [GraphQL Cursor Connections Specification](https://relay.dev/graphql/connections.htm).

## Purpose

This package provides an alternative to the pagination/connection tools provided by [Graphiti](https://github.com/GraphQLSwift/Graphiti/tree/main/Sources/Graphiti/Connection). Benefits include:

* Create your own `connection/edge` types that expose additional data
* An opaque `Cursor` type that supports identity-based or index-based cursors
* Converts GraphQL pagination model to offset pagination to give to your database, elasticsearch, etc.
* Offset pagination performs a "plus two" algorithm to efficiently calculate `hasNextPage` and `hasPreviousPage`

## Example

Add pagination to any arguments.

```swift
/// This supports forward and backward pagination. We could use `GraphForwardPaginatable` to simplify.
struct PeopleArguments: GraphPaginatable {
  // ... other inputs
  var first: Int?
  var after: Cursor?
  var last: Int?
  var before: Cursor?
}
```

Use pagination.

```swift
func people(context: Context, arguments: PeopleArguments) async throws -> BasicConnection<Person> {
  // Extract offset and count from the input, and query the database.
  let offsetPagination = arguments.pagination.makeOffsetPagination()
  let people = try await Person.all(
    offset: offsetPagination.offset,
    count: offsetPagination.count
  )
  // Create a connection data structure converting people into edges
  // with index-based cursors.
  return BasicConnection(
    nodes: people,
    pagination: arguments.pagination,
    cursor: .index
  )
}
```

GraphQL 

```json
{
  "people": {
    "edges": [
      {
        "cursor": "MA==",
        "node": { }
      },
      {
        "cursor": "MQ==", 
        "node": {  }
      }
    ],
    "pageInfo": {
      "hasPreviousPagePage": false,
      "hasNextPage": true,
      "startCursor": "MA==",
      "startCursor": "MQ=="
    }
  }
}
```

# License 

MIT
