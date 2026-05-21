#!/usr/bin/env bash
set -euo pipefail

assert_route() {
	local url="$1"
	local expected_status="$2"
	local expected_body="$3"

	local body_file
	body_file="$(mktemp)"

	local status
	status="$(curl -s -o "$body_file" -w "%{http_code}" "$url")"

	local body
	body="$(cat "$body_file")"
	rm -f "$body_file"

	if [ "$status" != "$expected_status" ]; then
		echo "FAIL $url: expected status $expected_status, got $status"
		exit 1
	fi

	if [ "$body" != "$expected_body" ]; then
		echo "FAIL $url: expected body '$expected_body', got '$body'"
		exit 1
	fi

	echo "PASS $url"
}

# curl -s -o /tmp/body -w "%{http_code}" http://localhost:8082/
assert_route "http://localhost:8082/" "200" "Welcome to the root"
assert_route "http://localhost:8082/name" "200" "Casey"
assert_route "http://localhost:8082/person/8" "200" "8"
assert_route "http://localhost:8082/person/8?hair=green" "200" "8"
assert_route "http://localhost:8082/nope" "404" "Not found"
assert_route "http://localhost:8082/person" "404" "Not found"
assert_route "http://localhost:8082/person/8/extra" "404" "Not found"
