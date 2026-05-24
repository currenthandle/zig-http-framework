#!/usr/bin/env bash
set -euo pipefail

assert_route() {
	local url="$1"
	local expected_status="$2"
	local expected_body="$3"
	local spec_name="$4"
	local path="${url#http://localhost:8082}"

	local body_file
	body_file="$(mktemp)"

	local status
	status="$(curl -s -o "$body_file" -w "%{http_code}" "$url")"

	local body
	body="$(cat "$body_file")"
	rm -f "$body_file"

	if [ "$status" != "$expected_status" ]; then
		echo "FAIL $spec_name"
		echo "GET $path: expected status $expected_status, got $status"
		exit 1
	fi

	if [ "$body" != "$expected_body" ]; then
		echo "FAIL $spec_name"
		echo "GET $path: expected body '$expected_body', got '$body'"
		exit 1
	fi

	echo "PASS $spec_name"
	echo "GET $path"
	echo
}

assert_post() {
	local url="$1"
	local request_body="$2"
	local expected_status="$3"
	local expected_body="$4"
	local spec_name="$5"
	local path="${url#http://localhost:8082}"
	shift 5

	local body_file
	body_file="$(mktemp)"

	local status
	status="$(curl --http1.1 -s -o "$body_file" -w "%{http_code}" "$@" --data-binary "$request_body" "$url")"

	local body
	body="$(cat "$body_file")"
	rm -f "$body_file"

	if [ "$status" != "$expected_status" ]; then
		echo "FAIL $spec_name"
		echo "POST $path: expected status $expected_status, got $status"
		exit 1
	fi

	if [ "$body" != "$expected_body" ]; then
		echo "FAIL $spec_name"
		echo "POST $path: expected body '$expected_body', got '$body'"
		exit 1
	fi

	echo "PASS $spec_name"
	echo "POST $path"
	echo
}

# curl -s -o /tmp/body -w "%{http_code}" http://localhost:8082/
assert_route "http://localhost:8082/" "200" "Welcome to the root" "Welcome route"
assert_route "http://localhost:8082/name" "200" "Casey" "Name route"
assert_route "http://localhost:8082/person/8" "200" "8" "Route params"
assert_route "http://localhost:8082/person/8?hair=green" "200" "8" "Query string route"
assert_route "http://localhost:8082/nope" "404" "Not found" "Unknown route"
assert_route "http://localhost:8082/person" "404" "Not found" "Missing route param"
assert_route "http://localhost:8082/person/8/extra" "404" "Not found" "Extra route segment"
assert_post "http://localhost:8082/user" "Casey" "201" "Created new user Casey" "Content-Length body"
assert_post "http://localhost:8082/user" "Casey" "201" "Created new user Casey" "Chunked body" -H "Transfer-Encoding: chunked"
assert_post "http://localhost:8082/user" "Casey" "201" "Created new user Casey" "Expect 100 continue" -H "Expect: 100-continue"
assert_post "http://localhost:8082/user" "Casey" "417" "" "Unsupported Expect header" -H "Expect: nope"
