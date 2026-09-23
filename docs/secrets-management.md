# FidelLearn — Secrets Management Reference

This document lists all required secret variable NAMES only.
**Values are never stored in source control, never printed in CI logs.**

---

## Flutter Client Secrets (dart-define — safe for client)

| Name | Description | Where to Store |
|---|---|---|
| `SUPABASE_URL` | Supabase project URL | `.env.local` (dev), GitHub Actions secret (CI) |
| `SUPABASE_PUBLISHABLE_KEY` | Client-safe public key (NOT service role) | `.env.local` (dev), GitHub Actions secret (CI) |
| `APP_ENVIRONMENT` | `development` \| `staging` \| `production` | CI workflow env var |

**Note:** `SUPABASE_PUBLISHABLE_KEY` is safe to embed in Flutter because RLS
enforces all authorization server-side. It is the "anon" key in Supabase's key
list and carries minimal privilege.

---

## CI/CD Secrets (GitHub Actions — never in source code)

| Name | Description | GitHub Secret Scope |
|---|---|---|
| `SUPABASE_ACCESS_TOKEN` | Personal access token for Supabase CLI | Repository |
| `SUPABASE_URL_STAGING` | Staging project URL | Repository or `staging` environment |
| `SUPABASE_PUBLISHABLE_KEY_STAGING` | Staging publishable key | Repository or `staging` environment |
| `SUPABASE_PROJECT_REF_STAGING` | Staging project reference ID | `staging` environment |
| `SUPABASE_DB_PASSWORD_STAGING` | Staging database password | `staging` environment |
| `SUPABASE_URL_PRODUCTION` | Production project URL | `production` environment |
| `SUPABASE_PUBLISHABLE_KEY_PRODUCTION` | Production publishable key | `production` environment |
| `SUPABASE_PROJECT_REF_PRODUCTION` | Production project reference ID | `production` environment |
| `SUPABASE_DB_PASSWORD_PRODUCTION` | Production database password | `production` environment |

Configure these in: **GitHub → Settings → Secrets and variables → Actions**

For environment-scoped secrets (recommended for production):
**GitHub → Settings → Environments → production → Environment secrets**

---

## Edge Function Runtime Secrets (Supabase Vault — never in GitHub)

These are injected by the Supabase runtime into Edge Functions.

| Name | Description | How to Set |
|---|---|---|
| `SUPABASE_SERVICE_ROLE_KEY` | Provided automatically by Supabase runtime | Automatic — do not set manually |
| `SUPABASE_URL` | Provided automatically by Supabase runtime | Automatic |

For additional Edge Function secrets:
```bash
# Set a secret (example: SMS provider key)
supabase secrets set MY_SECRET=value --project-ref your-project-ref

# List configured secrets (names only, values masked)
supabase secrets list --project-ref your-project-ref
```

---

## What Must NEVER Happen

| Action | Why |
|---|---|
| Commit `.env.local` or any file with credential values | Source control exposure |
| Log `SUPABASE_SERVICE_ROLE_KEY` in CI output | Leaked service key |
| Pass service role key to Flutter via `--dart-define` | Client-side key compromise |
| Print any secret value with `echo` in CI scripts | Log exposure |
| Store service key in `pubspec.yaml` or any Dart file | Source code exposure |
| Use service role key as the Flutter `anonKey` parameter | Bypasses all RLS |

---

## Key Rotation Procedure

1. Generate new key in Supabase dashboard (Auth → API → Rotate)
2. Update GitHub Actions secrets immediately
3. Update `.env.local` for local development
4. Trigger new CI/CD deployment to apply updated key
5. Verify app connects successfully before retiring old key
6. Old key can be retired after all active Flutter builds using it are replaced

---

## Audit

Review secret usage monthly:
- Check Supabase Access Tokens have not expired
- Verify no leaked keys appear in Supabase Security Advisor
- Confirm only authorized team members have GitHub secret access
- Review audit_log table in Supabase for unusual admin actions
