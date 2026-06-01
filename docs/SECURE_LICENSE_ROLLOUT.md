# TailorPro Secure License System Rollout

**Date:** April 8, 2026  
**Status:** Ready for staging deployment

## Timeline

- **Staging:** [date] — Deployed, tested on device
- **Production:** [date] — Deployed to Supabase production
- **App Release:** [date] — v1.0.1 to Play Store

## Migrations

- `android/app/supabase/20260408_secure_licenses.sql` — Main schema + RLS + RPCs
- `android/app/supabase/20260408_secure_licenses_v2.sql` — Hardening reference
- `android/app/supabase/20260408_seed_qa_licenses.sql` — QA keys (staging only)

## What Changed

- License keys are now server-issued, not client-generated.
- RPC functions enforce auth and prevent double-activation.
- Client can no longer forge keys.
- Free tier auto-creates on signup.

## Verification Checklist

- [ ] Migration deployed without errors
- [ ] All 4 tables exist
- [ ] All required functions exist in the deployed SQL version
- [ ] RLS enabled on `license_keys`
- [ ] Signup → free tier auto-create works
- [ ] License activation via key works
- [ ] License persists across restarts
- [ ] `license_audit_log` records all actions
- [ ] Play Store v1.0.1 live

## Deployment Notes

- `20260408_secure_licenses.sql` is the base migration.
- `20260408_secure_licenses_v2.sql` adds the stricter `license_keys` read policy with `USING (FALSE)`, `admin_create_license_key()`, and the deployment checklist comments.
- `20260408_seed_qa_licenses.sql` is for dev/staging only and should never be run in production.
- The schema uses `issued_to_user_id` and `created_by_user_id` in `license_keys`.
- All RPCs rely on `auth.uid()` internally and do not trust client-supplied user IDs.

## Rollback Plan

If critical issues occur in production:

1. Revert app to v1.0.0 in Play Store and pause new installs of v1.0.1.
2. Disable new license activation traffic while investigating.
3. Restore Supabase from backup or roll forward with a corrective migration instead of dropping live tables blindly.

