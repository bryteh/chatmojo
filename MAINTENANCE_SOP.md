# chatmojo — Production Maintenance SOP (BINDING)

> Right-sized from the chatmojo-omni master SOP (the full runbook lives there).
> Owner = the human with Coolify + GitHub access. Created 2026-07-10.

## Stack
- **Coolify app:** `chatmojo + chatmojo-worker` on panel.mojosense.co → https://chat.mojosense.co
- **Deploy trigger:** push to `main` → auto-build → auto-deploy to production
- **Stack:** Chatwoot fork (Rails). NOTE: default branch is `develop` but Coolify deploys `main` — pushes to main go straight to production.
- Dormant since 2026-03 but SERVING a live site. Any revival of work here follows this SOP from day one.

## Golden Rules (non-negotiable)
1. **NEVER push or merge to `main`.** Every change: feature branch → PR → audit
   evidence → the OWNER clicks Merge. AI prepares; the human deploys.
2. **One change per release**; watch every deploy to green in Coolify — never push-and-walk-away.
3. **Secrets never in chat, commits, code, or logs.** Anything pasted is burned — rotate same day.
4. **Database changes:** additive-only by default; back up before anything destructive.
   (Supabase-backed apps: the database is the shared Supabase — backups are managed there.)
5. **Stage explicit file paths** in git — never `git add -A` / `git add .`.
6. Every PR states: what changed, test evidence, migration note, rollback plan (usually "Revert this PR").

## Release flow (no staging app yet)
feature branch → PR → owner merges → Coolify auto-deploys → post-deploy check
(site loads, core flow works). **Rollback:** GitHub → the merged PR → Revert → merge → auto-redeploys.

## When this project needs a staging app
The moment it (a) serves real customer/patient data it didn't before, (b) takes payments, or
(c) gets schema-risky changes. Clone the chatmojo-omni pattern: `staging` branch → second
Coolify app → fresh secrets (never prod's) → synthetic data only.

## Incidents
Container up? → logs → what merged last? → revert first, debug later → never experiment on the live DB.
