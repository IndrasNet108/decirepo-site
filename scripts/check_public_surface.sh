#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:8000}"

fail() {
  echo "ERROR: $1" >&2
  exit 1
}

check_contains() {
  local url="$1"
  local needle="$2"
  local body
  body="$(curl -fsSL "$url")" || fail "failed to fetch $url"
  echo "$body" | grep -F "$needle" >/dev/null || fail "missing '$needle' in $url"
}

check_not_contains() {
  local url="$1"
  local needle="$2"
  local body
  body="$(curl -fsSL "$url")" || fail "failed to fetch $url"
  if echo "$body" | grep -F "$needle" >/dev/null; then
    fail "unexpected '$needle' found in $url"
  fi
}

check_200() {
  local url="$1"
  local code
  code="$(curl -s -o /dev/null -w '%{http_code}' "$url")"
  [ "$code" = "200" ] || fail "$url returned HTTP $code"
}

INDEX_URL="$BASE_URL/pages/index.html"
BILLING_URL="$BASE_URL/pages/billing.html"
TERMS_URL="$BASE_URL/pages/terms.html"
PRIVACY_URL="$BASE_URL/pages/privacy.html"
DISCLAIMER_URL="$BASE_URL/pages/disclaimer.html"
FEED_URL="$BASE_URL/api/feed.json"

echo "Checking landing page CTA..."
check_contains "$INDEX_URL" "Request Pilot"

echo "Checking forbidden commerce wording..."
check_not_contains "$INDEX_URL" "Buy now"
check_not_contains "$INDEX_URL" "Subscribe"

echo "Checking billing posture..."
check_contains "$BILLING_URL" "pilot-by-agreement"
check_contains "$BILLING_URL" "Request Pilot"

echo "Checking feed and legal pages..."
check_200 "$FEED_URL"
check_200 "$TERMS_URL"
check_200 "$PRIVACY_URL"
check_200 "$DISCLAIMER_URL"
check_200 "$BILLING_URL"

echo "All public surface checks passed."
