# Database Seeding Guide

This document explains how to seed the database with unit data for the FAF CN application.

## Overview

The application uses a **two-step seeding system** to balance convenience for new developers with the ability to update unit data from the FAF API.

### The Problem We Solved

**Before:** Every developer had to fetch unit data from FAF's external API during setup, which:
- Took 10-30 seconds per setup
- Required internet connectivity
- Could fail if the API was down
- Wasted bandwidth for 405 identical units

**After:** Unit data is stored in a local JSON file (`priv/repo/units_seed.json`) that:
- Loads instantly from local disk
- Works offline
- Is version-controlled with the code
- Can be updated occasionally via a separate command

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Two-Step Seeding System                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐         ┌─────────────────────────────┐  │
│  │   Local Seed     │         │      API Refresh            │  │
│  │   (Fast Path)    │         │      (Slow Path)            │  │
│  └──────────────────┘         └─────────────────────────────┘  │
│           │                              │                      │
│           ▼                              ▼                      │
│  ┌──────────────────┐         ┌─────────────────────────────┐  │
│  │ units_seed.json  │         │  FAF spooky-db API          │  │
│  │ (Git-tracked)    │         │  (External)                 │  │
│  └──────────────────┘         └─────────────────────────────┘  │
│           │                              │                      │
│           └──────────┬───────────────────┘                      │
│                      ▼                                           │
│           ┌──────────────────┐                                  │
│           │  Database        │                                  │
│           │  (units table)   │                                  │
│           └──────────────────┘                                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### When to Use Each Path

| Scenario | Command | Duration | Use Case |
|----------|---------|----------|----------|
| **New developer setup** | `mix ecto.setup` | ~2 seconds | First time setup |
| **Reset local DB** | `mix ecto.reset` | ~2 seconds | After schema changes |
| **Production seeding** | `/app/bin/faf_cn eval 'FafCn.Release.seed()'` | ~2 seconds | After deployment |
| **Update unit data** | `mix faf_cn.refresh_units` | ~30 seconds | Every few months |

---

## For New Developers

### Quick Start

After cloning the repository and setting up dependencies:

```bash
# This will create DB, run migrations, AND seed units
mix ecto.setup
```

That's it! The database will be populated with 405 units instantly.

### What's Happening

1. `ecto.create` - Creates the database
2. `ecto.migrate` - Runs all migrations
3. `ecto.seed` - Loads units from `priv/repo/units_seed.json`

### Verify Seeding Worked

```bash
# Check unit count
mix run -e "IO.puts(FafCn.Repo.aggregate(FafCn.Units.Unit, :count, :id))"
# Should output: 405

# Or visit the eco-guides page
open http://localhost:4000/eco-guides
```

---

## For Production Deployment

### Initial Production Seeding

After the first deployment to Fly.io:

```bash
# SSH into the app and run the seed command
fly ssh console --app faf-cn --command "/app/bin/faf_cn eval 'FafCn.Release.seed()'"
```

Expected output:
```
Loading unit data from /app/lib/faf_cn-0.1.0/priv/repo/units_seed.json...
Found 405 units in seed file
Cleared existing units
Successfully inserted 405 units
```

### Re-seeding After Data Loss

If you need to re-seed (e.g., after `fly postgres connect` and `DROP TABLE units;`):

```bash
fly ssh console --app faf-cn --command "/app/bin/faf_cn eval 'FafCn.Release.seed()'"
```

### Important Notes

- **Idempotent**: Running seed multiple times is safe - it clears and re-inserts
- **No Mix in production**: Use `FafCn.Release.seed()` function, not Mix tasks
- **Seed file included in release**: The JSON file is bundled in the Docker image

---

## Refreshing Unit Data from FAF API

Over time, unit stats may change in the game. To update the seed file with fresh data:

### Step 1: Fetch Fresh Data

```bash
# This fetches from FAF API and updates units_seed.json
mix faf_cn.refresh_units
```

Expected output:
```
[info] Fetching unit data from FAF spooky-db API...
[info] Fetched 405 units from API
[info] Saved 405 units to priv/repo/units_seed.json
[info] Next steps:
[info]   1. Review the changes: git diff priv/repo/units_seed.json
[info]   2. Commit the updated seed file: git add priv/repo/units_seed.json
[info]   3. Run seeds to update database: mix ecto.seed
```

### Step 2: Review Changes

```bash
# See what changed
git diff priv/repo/units_seed.json

# Check file size
ls -lh priv/repo/units_seed.json
```

### Step 3: Commit the Update

```bash
git add priv/repo/units_seed.json
git commit -m "chore: update unit data from FAF API

- Refreshed unit stats from spooky-db
- Updated: $(date +%Y-%m-%d)"
```

### Step 4: Update All Environments

```bash
# Update local database
mix ecto.seed

# Deploy to production (includes new seed file)
fly deploy --app faf-cn

# Re-seed production
fly ssh console --app faf-cn --command "/app/bin/faf_cn eval 'FafCn.Release.seed()'"
```

### When to Refresh

| Frequency | Recommendation |
|-----------|----------------|
| **Every release** | No - only if units changed |
| **Monthly** | Good balance |
| **After game patches** | Yes - when FAF updates |
| **When requested** | If players report outdated stats |

---

## File Reference

| File | Purpose | Notes |
|------|---------|-------|
| `priv/repo/units_seed.json` | Local unit data cache | ~3.6MB, git-tracked |
| `priv/repo/seeds.exs` | Legacy seed script | Loads from JSON file |
| `lib/mix/tasks/faf_cn.seed.ex` | Mix task for seeding | Development use |
| `lib/mix/tasks/faf_cn.refresh_units.ex` | Mix task for API fetch | Updates JSON file |
| `lib/faf_cn/release.ex` | Production seed function | `FafCn.Release.seed/0` |
| `lib/faf_cn/units/unit_fetcher.ex` | API client module | Fetches from FAF |

---

## Troubleshooting

### Issue: "Seed file not found"

**Error:**
```
ERROR: Seed file not found: /app/priv/repo/units_seed.json
```

**Causes & Solutions:**

1. **For new developers:**
   ```bash
   # Run this first to generate the seed file
   mix faf_cn.refresh_units
   ```

2. **For production:**
   ```bash
   # Check if file exists in release
   fly ssh console --app faf-cn --command "find /app -name units_seed.json"
   
   # If missing, rebuild and redeploy
   fly deploy --app faf-cn
   ```

### Issue: Seed takes too long

**Expected:**
- Local seed: 2-5 seconds
- API refresh: 10-30 seconds

**If slower:**
- Check internet connection (for API refresh)
- Check database connection
- For large datasets, consider batching

### Issue: Units out of date

**Check last refresh:**
```bash
# View metadata in seed file
head -5 priv/repo/units_seed.json
```

**Output:**
```json
{
  "fetched_at": "2026-02-10T06:39:22Z",
  "source": "FAF spooky-db",
  ...
}
```

**Update if old:**
```bash
mix faf_cn.refresh_units
git add priv/repo/units_seed.json
git commit -m "chore: refresh unit data"
```

### Issue: Database connection errors during seed

**Check:**
1. Database is running: `fly status --app faf-cn-db`
2. App can connect: `fly logs --app faf-cn | grep -i database`
3. Secrets are set: `fly secrets list --app faf-cn`

---

## Commands Quick Reference

### Development

```bash
# Full setup (DB + migrations + seeds)
mix ecto.setup

# Reset database (drop + create + migrate + seed)
mix ecto.reset

# Seed only (after migrations)
mix ecto.seed
# or
mix faf_cn.seed

# Refresh unit data from API
mix faf_cn.refresh_units
```

### Production (Fly.io)

```bash
# Seed production database
fly ssh console --app faf-cn --command "/app/bin/faf_cn eval 'FafCn.Release.seed()'"

# Check unit count
fly ssh console --app faf-cn --command "/app/bin/faf_cn eval 'IO.puts(FafCn.Repo.aggregate(FafCn.Units.Unit, :count, :id))'"

# View logs
fly logs --app faf-cn
```

---

## Data Flow Diagram

### New Developer Setup

```
Clone repo ──► mix deps.get ──► mix ecto.setup
                                      │
                                      ▼
                              ┌───────────────┐
                              │  ecto.create  │
                              └───────┬───────┘
                                      ▼
                              ┌───────────────┐
                              │ ecto.migrate  │
                              └───────┬───────┘
                                      ▼
                              ┌───────────────┐
                              │  ecto.seed    │
                              └───────┬───────┘
                                      ▼
                         ┌────────────────────────┐
                         │ Read units_seed.json   │
                         │ (local file, instant)  │
                         └───────────┬────────────┘
                                     ▼
                         ┌────────────────────────┐
                         │   Insert into DB       │
                         │   (405 units)          │
                         └────────────────────────┘
```

### API Refresh Process

```
mix faf_cn.refresh_units
         │
         ▼
┌────────────────────────┐
│  HTTP GET to FAF API   │
│  (10-30 seconds)       │
└───────────┬────────────┘
            ▼
┌────────────────────────┐
│  Parse JSON response   │
└───────────┬────────────┘
            ▼
┌────────────────────────┐
│  Write units_seed.json │
│  (update local cache)  │
└───────────┬────────────┘
            ▼
┌────────────────────────┐
│  Commit to git         │
│  (version control)     │
└────────────────────────┘
```

---

## Best Practices

1. **Never commit broken seed data**
   - Always verify `mix ecto.seed` works before committing
   - Run `mix test` after seeding changes

2. **Document API refreshes**
   - Include date in commit message
   - Note any major changes in PR description

3. **Backup before major changes**
   ```bash
   # Export current units
   pg_dump faf_cn_dev --table units > units_backup.sql
   ```

4. **Monitor seed file size**
   - Currently ~3.6MB for 405 units
   - If it grows significantly, investigate

5. **Use in CI/CD**
   ```yaml
   # Example GitHub Actions step
   - name: Setup database
     run: |
       mix ecto.create
       mix ecto.migrate
       mix ecto.seed
   ```

---

## Migration from Old System

If you have an existing database with units and want to export to the new seed file:

```bash
# Export current units to JSON
mix run -e '
  alias FafCn.Repo
  alias FafCn.Units.Unit
  
  units = Repo.all(Unit) |> Enum.map(&Map.drop(&1, [:__meta__, :id]))
  data = %{
    "fetched_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
    "source" => "manual_export",
    "units" => units
  }
  
  File.write!("priv/repo/units_seed.json", Jason.encode!(data, pretty: true))
  IO.puts("Exported #{length(units)} units")
'
```

---

**Last Updated**: 2026-02-10  
**Seed File Version**: 405 units  
**Last API Refresh**: 2026-02-10T06:39:22Z
