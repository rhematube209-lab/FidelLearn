# FidelLearn Environment Configuration

## Overview

FidelLearn uses three environments:

```
LOCAL (development)
    ↓
STAGING (develop branch)
    ↓
PRODUCTION (main branch)
```

Environment is selected at **compile time** via `--dart-define=APP_ENVIRONMENT=`.

---

## Environment Behavior

| Environment | Missing Supabase credentials | Supabase init failure |
|---|---|---|
| `development` | Falls back to offline/mock mode | Logged, continues offline |
| `staging` | **App crashes with StateError** | **App crashes, rethrows** |
| `production` | **App crashes with StateError** | **App crashes, rethrows** |

This is intentional. A staging or production build must never silently run
in mock mode because a CI variable was omitted.

---

## Required Variables

| Variable | Used In | Description |
|---|---|---|
| `SUPABASE_URL` | Flutter (dart-define) | Project URL from Supabase dashboard |
| `SUPABASE_PUBLISHABLE_KEY` | Flutter (dart-define) | Public/anon key (safe for client) |
| `APP_ENVIRONMENT` | Flutter (dart-define) | `development` \| `staging` \| `production` |

**Never use** `SUPABASE_SERVICE_ROLE_KEY` or `SUPABASE_SECRET_KEY` in Flutter.
Server-side keys belong only in Supabase Vault and CI/CD secrets.

---

## LOCAL Development

Copy `.env.example` to `.env.local` and fill in your local/dev Supabase values.

Run the app without Supabase (fully offline/mock):
```powershell
flutter run -d windows
# APP_ENVIRONMENT defaults to 'development', Supabase not required
```

Run with a local Supabase instance:
```powershell
supabase start
flutter run -d windows `
  --dart-define=SUPABASE_URL=http://localhost:54321 `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-local-anon-key `
  --dart-define=APP_ENVIRONMENT=development
```

Run against the cloud staging project:
```powershell
flutter run -d windows `
  --dart-define=SUPABASE_URL=https://your-staging-ref.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-staging-publishable-key `
  --dart-define=APP_ENVIRONMENT=staging
```

---

## STAGING (CI/CD — develop branch)

GitHub Actions secrets required:

```
SUPABASE_URL_STAGING
SUPABASE_PUBLISHABLE_KEY_STAGING
SUPABASE_PROJECT_REF_STAGING
SUPABASE_DB_PASSWORD_STAGING
SUPABASE_ACCESS_TOKEN
```

The workflow (`deploy-staging.yml`) validates these are present before proceeding.
Missing credentials cause the workflow to fail at the validation step.

---

## PRODUCTION (CI/CD — main branch)

GitHub Actions secrets required:

```
SUPABASE_URL_PRODUCTION
SUPABASE_PUBLISHABLE_KEY_PRODUCTION
SUPABASE_PROJECT_REF_PRODUCTION
SUPABASE_DB_PASSWORD_PRODUCTION
SUPABASE_ACCESS_TOKEN
```

Additionally, a GitHub Environment named `production` must be configured with
required reviewers. The production workflow pauses at the `approve-production`
job until a reviewer approves in the GitHub UI.

---

## Edge Function Secrets (Supabase Vault Only)

Edge Functions require the Supabase service key at runtime.
This is provided automatically by the Supabase runtime environment.
You do NOT need to configure it — it is available as `SUPABASE_SERVICE_ROLE_KEY`
inside every Edge Function automatically.

For any additional Edge Function secrets (e.g., SMS provider API key):
```bash
supabase secrets set SMS_PROVIDER_API_KEY=your_key --project-ref your-ref
```

These are stored in Supabase Vault and never appear in GitHub or source code.

---

## Supabase CLI Setup

```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Apply migrations
supabase db push

# Deploy a function
supabase functions deploy claim-reward

# Start local instance
supabase start
```
