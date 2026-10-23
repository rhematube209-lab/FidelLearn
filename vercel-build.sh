#!/bin/bash
set -e

# NOTE: Do NOT use `set -x` to avoid printing environment variables or build parameters in CI/CD logs.

echo "=== STEP 1: Determine Build Environment ==="

# Map environment explicitly:
# 1. If APP_ENVIRONMENT is set directly, honor it.
# 2. Otherwise map VERCEL_ENV:
#    - "production" -> "production"
#    - "preview"    -> "staging" (previews map to staging, NOT production)
# 3. Any other value (or unset) is rejected.

TARGET_ENV="${APP_ENVIRONMENT:-}"

if [ -z "$TARGET_ENV" ]; then
  if [ "$VERCEL_ENV" = "production" ]; then
    TARGET_ENV="production"
  elif [ "$VERCEL_ENV" = "preview" ]; then
    TARGET_ENV="staging"
  fi
fi

# Validation: release builds use a production-like environment or the
# explicitly selected, sample-data-only demo environment.
if [ -z "$TARGET_ENV" ]; then
  echo "ERROR: APP_ENVIRONMENT (or VERCEL_ENV) must be provided."
  echo "Valid values for release builds: 'demo', 'staging', 'pilot', 'production'."
  echo "Neither APP_ENVIRONMENT nor VERCEL_ENV was recognized."
  exit 1
fi

case "$TARGET_ENV" in
  demo|production|pilot|staging)
    echo "Configuring release build for environment: $TARGET_ENV"
    ;;
  development)
    echo "ERROR: Implicit or explicit 'development' environment is prohibited for Vercel releases."
    echo "Release builds must target 'staging', 'pilot', or 'production'."
    exit 1
    ;;
  *)
    echo "ERROR: Invalid environment '$TARGET_ENV'. Must be one of: 'demo', 'staging', 'pilot', 'production'."
    exit 1
    ;;
esac

echo "=== STEP 2: Resolve Client-Safe Supabase Configuration ==="

if [ "$TARGET_ENV" = "demo" ]; then
  # The demo is an isolated local-data build. Never embed Supabase settings,
  # even if this Vercel project also defines them for other environments.
  if [ "${VALIDATE_ONLY:-}" = "true" ] || [ "${1:-}" = "--validate-only" ]; then
    echo "Demo build selected; no Supabase configuration will be included."
    exit 0
  fi
  echo "Demo build selected; using sample data without Supabase."
else

# Check environment-specific or general variables for Supabase credentials.
TARGET_SUPABASE_URL="${SUPABASE_URL:-}"
TARGET_SUPABASE_KEY="${SUPABASE_PUBLISHABLE_KEY:-}"

# Check environment-specific fallbacks if general variables are not set
if [ -z "$TARGET_SUPABASE_URL" ]; then
  if [ "$TARGET_ENV" = "production" ] && [ -n "${SUPABASE_URL_PRODUCTION:-}" ]; then
    TARGET_SUPABASE_URL="$SUPABASE_URL_PRODUCTION"
  elif [ "$TARGET_ENV" = "staging" ] && [ -n "${SUPABASE_URL_STAGING:-}" ]; then
    TARGET_SUPABASE_URL="$SUPABASE_URL_STAGING"
  elif [ -n "${NEXT_PUBLIC_SUPABASE_URL:-}" ]; then
    TARGET_SUPABASE_URL="$NEXT_PUBLIC_SUPABASE_URL"
  fi
fi

if [ -z "$TARGET_SUPABASE_KEY" ]; then
  if [ "$TARGET_ENV" = "production" ] && [ -n "${SUPABASE_PUBLISHABLE_KEY_PRODUCTION:-}" ]; then
    TARGET_SUPABASE_KEY="$SUPABASE_PUBLISHABLE_KEY_PRODUCTION"
  elif [ "$TARGET_ENV" = "staging" ] && [ -n "${SUPABASE_PUBLISHABLE_KEY_STAGING:-}" ]; then
    TARGET_SUPABASE_KEY="$SUPABASE_PUBLISHABLE_KEY_STAGING"
  elif [ -n "${SUPABASE_ANON_KEY:-}" ]; then
    TARGET_SUPABASE_KEY="$SUPABASE_ANON_KEY"
  elif [ -n "${NEXT_PUBLIC_SUPABASE_ANON_KEY:-}" ]; then
    TARGET_SUPABASE_KEY="$NEXT_PUBLIC_SUPABASE_ANON_KEY"
  fi
fi

# Fail closed if required credentials are missing
if [ -z "$TARGET_SUPABASE_URL" ]; then
  echo "ERROR: Missing required Supabase URL for $TARGET_ENV release build."
  echo "Please set SUPABASE_URL (or SUPABASE_URL_PRODUCTION / SUPABASE_URL_STAGING) in Vercel project settings."
  exit 1
fi

if [ -z "$TARGET_SUPABASE_KEY" ]; then
  echo "ERROR: Missing required Supabase publishable key for $TARGET_ENV release build."
  echo "Please set SUPABASE_PUBLISHABLE_KEY (or SUPABASE_PUBLISHABLE_KEY_PRODUCTION / SUPABASE_PUBLISHABLE_KEY_STAGING) in Vercel project settings."
  exit 1
fi

# Security check: Ensure service role key is NEVER passed to client build
if [ -n "${SUPABASE_SERVICE_ROLE_KEY:-}" ]; then
  echo "Security check: SUPABASE_SERVICE_ROLE_KEY detected in environment; excluded from client build arguments."
fi

# Rigorous validation of client-safe publishable key format
KEY_IS_VALID=false

# Format 1: Modern Supabase publishable key format (sb_publishable_...)
if [[ "$TARGET_SUPABASE_KEY" =~ ^sb_publishable_[A-Za-z0-9_-]{10,}$ ]]; then
  KEY_IS_VALID=true
fi

# Reject modern secret keys explicitly
if [[ "$TARGET_SUPABASE_KEY" =~ ^sb_secret_ ]]; then
  echo "ERROR: Security violation! SUPABASE_PUBLISHABLE_KEY starts with 'sb_secret_'. Secret keys are server-only and must never be exposed to client builds."
  exit 1
fi

# Format 2: Legacy Supabase anon JWT (header.payload.signature)
if [[ "$TARGET_SUPABASE_KEY" =~ ^eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$ ]]; then
  JWT_PAYLOAD=$(echo "$TARGET_SUPABASE_KEY" | cut -d'.' -f2)
  MOD=$(( ${#JWT_PAYLOAD} % 4 ))
  if [ $MOD -eq 2 ]; then
    JWT_PAYLOAD="${JWT_PAYLOAD}=="
  elif [ $MOD -eq 3 ]; then
    JWT_PAYLOAD="${JWT_PAYLOAD}="
  fi
  DECODED_PAYLOAD=$(echo "$JWT_PAYLOAD" | tr '_-' '/+' | base64 -d 2>/dev/null) || DECODED_PAYLOAD=""

  if echo "$DECODED_PAYLOAD" | grep -qi "service_role"; then
    echo "ERROR: Security violation! SUPABASE_PUBLISHABLE_KEY is an encoded legacy JWT containing 'service_role'. Service-role keys must never be exposed to client builds."
    exit 1
  fi

  if echo "$DECODED_PAYLOAD" | grep -q '"role"[[:space:]]*:[[:space:]]*"anon"'; then
    KEY_IS_VALID=true
  else
    echo "ERROR: Security violation! SUPABASE_PUBLISHABLE_KEY legacy JWT payload does not have 'anon' role."
    exit 1
  fi
fi

if [ "$KEY_IS_VALID" != "true" ]; then
  echo "ERROR: SUPABASE_PUBLISHABLE_KEY has an invalid or unrecognized format."
  echo "Accepted client-safe formats: modern 'sb_publishable_...' keys or legacy 3-part JWTs with role 'anon'."
  exit 1
fi

echo "Supabase client configuration validated for $TARGET_ENV."

fi

# Support dry-run validation without cloning Flutter or building
if [ "${VALIDATE_ONLY:-}" = "true" ] || [ "${1:-}" = "--validate-only" ]; then
  echo "Build arguments validated successfully (--validate-only). Exiting before build."
  exit 0
fi

echo "=== STEP 3: Git Safe Directory ==="
git config --global --add safe.directory "*" || true

echo "=== STEP 4: Clone Flutter Stable SDK ==="
if [ ! -d "$HOME/flutter" ]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$HOME/flutter"
fi

export PATH="$PATH:$HOME/flutter/bin"

echo "=== STEP 5: Configure Flutter Web ==="
flutter config --no-analytics
flutter config --enable-web

echo "=== STEP 6: Install Dependencies ==="
flutter pub get

echo "=== STEP 7: Compile Web Release ==="
if [ "$TARGET_ENV" = "demo" ]; then
  flutter build web --release --no-tree-shake-icons \
    --dart-define=APP_ENVIRONMENT=demo
else
  flutter build web --release --no-tree-shake-icons \
    --dart-define=APP_ENVIRONMENT="$TARGET_ENV" \
    --dart-define=SUPABASE_URL="$TARGET_SUPABASE_URL" \
    --dart-define=SUPABASE_PUBLISHABLE_KEY="$TARGET_SUPABASE_KEY"
fi

echo "=== STEP 8: Verify Output in build/web ==="
ls -la build/web

echo "=== BUILD COMPLETE ==="
