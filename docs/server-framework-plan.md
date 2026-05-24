# Server Framework Plan

Build the boring correctness layer next.

## 1. Request Body Reader

- Done: handle `Content-Length` bodies
- Done: handle `Transfer-Encoding: chunked` bodies
- Done: return clean errors for too large, truncated, and invalid bodies
- Done: keep max body size enforcement

## 2. Expect Header Handling

- Done: handle `Expect: 100-continue`
- Done: send `100 Continue` before reading an accepted body
- Done: return `417 Expectation Failed` for unsupported `Expect` values
- Done: avoid calling `readerExpectNone` when `req.head.expect` is non-null

## 3. Error-To-Response Mapping

- Done: `ContentTooLarge` -> `413`
- Done: invalid body framing -> `400`
- Done: truncated or invalid body -> `400`
- Next: route-level empty body validation where a body is required
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

- Done: GET with no body
- Done: POST with `Content-Length`
- Done: POST with `Transfer-Encoding: chunked`
- Done: POST with `Expect: 100-continue`
- Done: unsupported `Expect` rejected
- Done: large body rejected
- Done: invalid body framing rejected
- Done: query params
- Done: route params
- Malformed request

After that, middleware and logging become useful. First, make request reading and error behavior solid.
