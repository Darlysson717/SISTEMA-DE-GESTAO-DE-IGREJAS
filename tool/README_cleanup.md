Cleanup tool

This tool runs the cleanup that deletes events and appointments older than 2 months and removes related storage files.

Manual run

PowerShell:

```powershell
$env:SUPABASE_URL="https://YOUR-PROJECT.supabase.co"
$env:SUPABASE_SERVICE_ROLE_KEY="YOUR_SERVICE_ROLE_KEY"
dart run tool/cleanup_old_events_and_appointments.dart
# to actually delete, add --apply
dart run tool/cleanup_old_events_and_appointments.dart --apply
```

GitHub Actions

- Add repository secrets: `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` (Service Role key is sensitive).
- The workflow `.github/workflows/cleanup-monthly.yml` runs on the 1st day of every month and on manual dispatch.

Safety notes

- Always keep a recent database backup before running destructive operations.
- The Service Role key must be stored as a secret and never exposed in client code.
