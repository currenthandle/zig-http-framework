# Server Framework Plan

Build the boring correctness layer next.

## 1. Request Body Reader

- Handle `Content-Length` bodies
- Handle `Transfer-Encoding: chunked` bodies
- Return clean errors for too large, truncated, and invalid bodies
- Keep max body size enforcement

## 2. Expect Header Handling

- Handle `Expect: 100-continue`
- Send `100 Continue` before reading an accepted body
- Return `417 Expectation Failed` for unsupported `Expect` values
- Avoid calling `readerExpectNone` when `req.head.expect` is non-null

## 3. Error-To-Response Mapping

- `ContentTooLarge` -> `413`
- Bad target/query -> `400`
- Unsupported method -> `405`
- Unknown route -> `404`
- Unexpected bug -> `500`

## 4. Request Parsing Helpers

- `path`
- Query params
- Route params
- Maybe URL decoding

## 5. Response Builder

- `text(...)`
- `json(...)`
- `html(...)`
- Automatically set `Content-Type`
- Automatically set `Content-Length`

## 6. Raw HTTP Tests

- GET with no body
- POST with body
- POST with `Transfer-Encoding: chunked`
- POST with `Expect: 100-continue`
- Large body rejected
- Query params
- Route params
- Malformed request

After that, middleware and logging become useful. First, make request reading and error behavior solid.
