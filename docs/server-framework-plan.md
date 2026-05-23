# Server Framework Plan

Build the boring correctness layer next.

## 1. Request Body Reader

- Handle `Content-Length`
- Handle chunked bodies
- Return clean errors for too large, truncated, and invalid bodies
- Keep max body size enforcement

## 2. Error-To-Response Mapping

- `ContentTooLarge` -> `413`
- Bad target/query -> `400`
- Unsupported method -> `405`
- Unknown route -> `404`
- Unexpected bug -> `500`

## 3. Request Parsing Helpers

- `path`
- Query params
- Route params
- Maybe URL decoding

## 4. Response Builder

- `text(...)`
- `json(...)`
- `html(...)`
- Automatically set `Content-Type`
- Automatically set `Content-Length`

## 5. Raw HTTP Tests

- GET with no body
- POST with body
- Large body rejected
- Query params
- Route params
- Malformed request

After that, middleware and logging become useful. First, make request reading and error behavior solid.
