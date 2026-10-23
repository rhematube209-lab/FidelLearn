#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_SCRIPT="$REPO_ROOT/vercel-build.sh"

PASSED=0
FAILED=0

assert_fails() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "FAIL: $desc (expected failure but command succeeded)"
    FAILED=$((FAILED + 1))
  else
    echo "PASS: $desc"
    PASSED=$((PASSED + 1))
  fi
}

assert_succeeds() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $desc"
    PASSED=$((PASSED + 1))
  else
    echo "FAIL: $desc (expected success but command failed)"
    FAILED=$((FAILED + 1))
  fi
}

echo "=== Running vercel-build.sh Validation Tests ==="

# Synthetic test keys
SYNTHETIC_URL="https://synthetic-project.supabase.co"
SYNTHETIC_MODERN_PUBKEY="sb_publishable_synthetic1234567890abcdef"
SYNTHETIC_MODERN_SECRETKEY="sb_secret_synthetic1234567890abcdef"

# Synthetic JWTs
# Header: {"alg":"HS256","typ":"JWT"} -> eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
SYNTHETIC_ANON_JWT="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIn0.synthetic_sig"
SYNTHETIC_SERVICE_ROLE_JWT="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiaXNzIjoic3VwYWJhc2UifQ.synthetic_sig"
SYNTHETIC_AUTH_ROLE_JWT="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYXV0aGVudGljYXRlZCJ9.synthetic_sig"
SYNTHETIC_MALFORMED_KEY="malformed_random_key_value"

# 1. Missing environment
assert_fails "Missing APP_ENVIRONMENT and VERCEL_ENV rejects build" \
  env -i PATH="$PATH" bash "$BUILD_SCRIPT" --validate-only

# 2. Prohibited development environment
assert_fails "Explicit APP_ENVIRONMENT=development rejects build" \
  env -i PATH="$PATH" APP_ENVIRONMENT="development" bash "$BUILD_SCRIPT" --validate-only

# An explicit isolated demo release needs no backend settings. Stray cloud
# settings must not change the selected build path.
assert_succeeds "Explicit demo build needs no Supabase variables" \
  env -i PATH="$PATH" APP_ENVIRONMENT="demo" bash "$BUILD_SCRIPT" --validate-only
assert_succeeds "Explicit demo build ignores Supabase variables" \
  env -i PATH="$PATH" APP_ENVIRONMENT="demo" SUPABASE_URL="$SYNTHETIC_URL" SUPABASE_PUBLISHABLE_KEY="$SYNTHETIC_MODERN_SECRETKEY" bash "$BUILD_SCRIPT" --validate-only

# 3. Missing Supabase URL
assert_fails "Missing Supabase URL rejects build" \
  env -i PATH="$PATH" APP_ENVIRONMENT="production" SUPABASE_PUBLISHABLE_KEY="$SYNTHETIC_MODERN_PUBKEY" bash "$BUILD_SCRIPT" --validate-only

# 4. Missing Supabase Publishable Key
assert_fails "Missing Supabase Publishable Key rejects build" \
  env -i PATH="$PATH" APP_ENVIRONMENT="production" SUPABASE_URL="$SYNTHETIC_URL" bash "$BUILD_SCRIPT" --validate-only

# 5. Valid modern publishable key
assert_succeeds "Valid modern sb_publishable_ key passes validation" \
  env -i PATH="$PATH" APP_ENVIRONMENT="production" SUPABASE_URL="$SYNTHETIC_URL" SUPABASE_PUBLISHABLE_KEY="$SYNTHETIC_MODERN_PUBKEY" bash "$BUILD_SCRIPT" --validate-only

# 6. Modern secret key rejection
assert_fails "Modern sb_secret_ key is strictly rejected" \
  env -i PATH="$PATH" APP_ENVIRONMENT="production" SUPABASE_URL="$SYNTHETIC_URL" SUPABASE_PUBLISHABLE_KEY="$SYNTHETIC_MODERN_SECRETKEY" bash "$BUILD_SCRIPT" --validate-only

# 7. Valid legacy anon JWT
assert_succeeds "Valid legacy anon JWT passes validation" \
  env -i PATH="$PATH" APP_ENVIRONMENT="staging" SUPABASE_URL="$SYNTHETIC_URL" SUPABASE_PUBLISHABLE_KEY="$SYNTHETIC_ANON_JWT" bash "$BUILD_SCRIPT" --validate-only

# 8. Legacy service_role JWT rejection
assert_fails "Encoded legacy service_role JWT is strictly rejected" \
  env -i PATH="$PATH" APP_ENVIRONMENT="production" SUPABASE_URL="$SYNTHETIC_URL" SUPABASE_PUBLISHABLE_KEY="$SYNTHETIC_SERVICE_ROLE_JWT" bash "$BUILD_SCRIPT" --validate-only

# 9. Legacy non-anon role JWT rejection
assert_fails "Encoded legacy JWT with non-anon role is rejected" \
  env -i PATH="$PATH" APP_ENVIRONMENT="production" SUPABASE_URL="$SYNTHETIC_URL" SUPABASE_PUBLISHABLE_KEY="$SYNTHETIC_AUTH_ROLE_JWT" bash "$BUILD_SCRIPT" --validate-only

# 10. Malformed key format rejection
assert_fails "Malformed random string is rejected" \
  env -i PATH="$PATH" APP_ENVIRONMENT="production" SUPABASE_URL="$SYNTHETIC_URL" SUPABASE_PUBLISHABLE_KEY="$SYNTHETIC_MALFORMED_KEY" bash "$BUILD_SCRIPT" --validate-only

# 11. Preview environment mapping to staging
assert_succeeds "VERCEL_ENV=preview maps to staging and passes validation" \
  env -i PATH="$PATH" VERCEL_ENV="preview" SUPABASE_URL="$SYNTHETIC_URL" SUPABASE_PUBLISHABLE_KEY="$SYNTHETIC_MODERN_PUBKEY" bash "$BUILD_SCRIPT" --validate-only

# 12. Production environment mapping
assert_succeeds "VERCEL_ENV=production maps to production and passes validation" \
  env -i PATH="$PATH" VERCEL_ENV="production" SUPABASE_URL="$SYNTHETIC_URL" SUPABASE_PUBLISHABLE_KEY="$SYNTHETIC_MODERN_PUBKEY" bash "$BUILD_SCRIPT" --validate-only

echo "=== Results: $PASSED passed, $FAILED failed ==="
if [ $FAILED -gt 0 ]; then
  exit 1
fi
exit 0
