# Runbook: Content Package Corruption & Download Failure

## 1. Severity
- **Classification**: SEV-2 (High)
- **Impact**: Students unable to download or update offline curriculum subject packages (`.flpkg`). Existing installed packages remain intact and functional.

## 2. Symptoms
- Client download fails with `PACKAGE_INTEGRITY_FAILED` or `PACKAGE_DOWNLOAD_FAILED`.
- Hash mismatch error logged during atomic install verification.
- Storage quota or partial download reported in error telemetry.

## 3. How to Confirm
1. Test download endpoint and SHA-256 hash matching from terminal:
   ```bash
   curl -s -O "https://$STORAGE_HOST/storage/v1/object/public/content_packages/grade12_biology_2026.flpkg"
   sha256sum grade12_biology_2026.flpkg
   ```
2. Compare calculated hash against manifest package metadata in Supabase:
   ```sql
   SELECT id, code, package_version, package_hash, file_size_bytes
   FROM public.curriculum_packages
   WHERE id = 'bio_12';
   ```
3. Inspect client error logs for `AtomicPackageInstaller` failure events.

## 4. Likely Causes
- Interrupted cellular download resulting in truncated `.flpkg.tmp` file.
- Manifest database record updated with new SHA-256 before storage bucket upload completed.
- CDN cache serving stale/partial chunks.
- Insufficient disk space on student mobile device.

## 5. Safe Diagnostic Steps
1. Verify storage bucket file accessibility and HTTP Range header support.
2. Verify package database hash matches storage object actual hash.
3. Check student device free storage via diagnostic report.

## 6. Safe Mitigation
1. **Atomic Install Protection**: `AtomicPackageInstaller` downloads strictly to `.flpkg.tmp`, verifies SHA-256 hash, and performs atomic rename only upon verified match. Existing working `.flpkg` is never overwritten with corrupt data.
2. If CDN cache is stale:
   - Invalidate CDN cache for the specific package URL path.
3. If database hash is desynchronized:
   - Update `curriculum_packages.package_hash` with the true verified SHA-256 hash of the storage asset.

## 7. Rollback / Recovery
- If a newly published curriculum package version has defective question content:
  - Re-point manifest record to previous stable version hash.
  - Client rollback logic retains the previous valid version automatically.

## 8. Verification
1. Download full package via `AtomicPackageInstaller` test runner.
2. Confirm SHA-256 hash matches without error.
3. Verify questions and diagrams render accurately in exam runner.

## 9. Escalation
- **Primary**: Content Operations Lead.
- **Secondary**: Mobile Application Lead.
