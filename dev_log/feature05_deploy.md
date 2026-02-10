# Feature05 -- Deploy to Fly.io

This guide documents how to deploy the `faf_cn` Phoenix application to Fly.io.

**Current Status**: ✅ Successfully deployed at https://faf-cn.fly.dev

---

## Overview

This is a Phoenix 1.8 web application that uses:
- **Phoenix LiveView** for reactive UI
- **PostgreSQL** for data persistence
- **GitHub OAuth** for authentication
- **Tailwind CSS + daisyUI** for styling

---

## Prerequisites

Before you start, ensure you have:

1. **Elixir/OTP installed** (see `.tool-versions` for exact versions)
   ```bash
   # Using asdf (recommended)
   asdf install
   ```

2. **Fly CLI installed**
   ```bash
   curl -L https://fly.io/install.sh | sh
   # Add to your shell profile:
   export FLYCTL_INSTALL="$HOME/.fly"
   export PATH="$FLYCTL_INSTALL/bin:$PATH"
   ```

3. **A Fly.io account**
   - Sign up at https://fly.io
   - Run `fly auth login` to authenticate

4. **A GitHub account**
   - Required for creating OAuth app

---

## Step-by-Step Deployment Guide

### Step 1: Generate Release Configuration

The release configuration enables the app to run in production without Mix:

```bash
mix phx.gen.release
```

This creates:
- `rel/overlays/bin/server` - Start script
- `rel/overlays/bin/migrate` - Database migration script
- `lib/faf_cn/release.ex` - Release utilities

### Step 2: Create GitHub OAuth App

1. Go to https://github.com/settings/developers
2. Click **New OAuth App**
3. Fill in the form:
   - **Application name**: `faf-cn` (or your preference)
   - **Homepage URL**: `https://faf-cn.fly.dev` (or your custom domain)
   - **Authorization callback URL**: `https://faf-cn.fly.dev/auth/github/callback`
4. Click **Register application**
5. Click **Generate a new client secret**
6. **Save these credentials** (you'll need them in Step 5):
   - Client ID
   - Client Secret

### Step 3: Create Fly.io App

Create the app on Fly.io (this also provisions PostgreSQL):

```bash
fly launch --name faf-cn --region sin --no-deploy
```

**Parameters:**
- `--name faf-cn` - Your app name (must be globally unique on Fly.io)
- `--region sin` - Singapore region (closest to China mainland)
- `--no-deploy` - Don't deploy yet (we'll set secrets first)

**What this does:**
- Creates the app on Fly.io
- Provisions a PostgreSQL database
- Attaches the database to your app (sets `DATABASE_URL` secret)
- Creates `fly.toml` if it doesn't exist

### Step 4: Review/Create Deployment Files

Ensure these files exist in your project root:

#### `fly.toml`
```toml
app = 'faf-cn'
primary_region = 'sin'

[build]

[env]
  PHX_HOST = 'faf-cn.fly.dev'
  PORT = '8080'

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = 'stop'
  auto_start_machines = true
  min_machines_running = 0
  processes = ['app']

  [http_service.concurrency]
    type = 'connections'
    hard_limit = 1000
    soft_limit = 1000

[[vm]]
  size = 'shared-cpu-1x'
  memory = '1gb'
```

**Note**: If you change the app name, update `PHX_HOST` accordingly.

#### `Dockerfile`
The project includes a `Dockerfile` optimized for Phoenix 1.8. Key points:
- Uses Elixir 1.17.3 / OTP 27.1 / Debian Bookworm
- Multi-stage build for smaller image size
- Runs as `nobody` user for security

#### `.dockerignore`
```
.git
/deps/
/_build/
/cover/
/doc/
/test/
/tmp/
.elixir_ls/
/installer/_build/
/installer/deps/
/installer/doc/
/assets/node_modules/
/priv/static/assets/
/priv/static/cache_manifest.json
erl_crash.dump
```

### Step 5: Set Environment Secrets

Generate a secret key base and set all required secrets:

```bash
# Generate secret
mix phx.gen.secret
# Copy the output (e.g., "qnsFj6eRuJc1eRRKIWqhgTQ...")

# Set all secrets on Fly.io
fly secrets set \
  SECRET_KEY_BASE="<your_generated_secret>" \
  GITHUB_CLIENT_ID="<your_github_client_id>" \
  GITHUB_CLIENT_SECRET="<your_github_client_secret>" \
  GITHUB_REDIRECT_URI="https://faf-cn.fly.dev/auth/github/callback" \
  PHX_HOST="faf-cn.fly.dev" \
  --app faf-cn
```

**Environment Variables Reference:**

| Variable | Required | Description |
|----------|----------|-------------|
| `SECRET_KEY_BASE` | Yes | Generate with `mix phx.gen.secret` |
| `DATABASE_URL` | Auto | Set by Fly.io when attaching Postgres |
| `PHX_HOST` | Yes | Your domain (e.g., `faf-cn.fly.dev`) |
| `GITHUB_CLIENT_ID` | Yes | From GitHub OAuth app |
| `GITHUB_CLIENT_SECRET` | Yes | From GitHub OAuth app |
| `GITHUB_REDIRECT_URI` | Yes | Must match GitHub OAuth settings |

### Step 6: Deploy

Build and deploy the application:

```bash
fly deploy --app faf-cn
```

This process:
1. Builds the Docker image with all dependencies
2. Compiles assets (Tailwind CSS, ESBuild)
3. Creates an OTP release
4. Pushes the image to Fly.io's registry
5. Deploys to your machines

**First deployment may take 5-10 minutes** (subsequent ones are faster due to caching).

### Step 7: Run Database Migrations

After the app is deployed, run migrations:

```bash
fly ssh console --app faf-cn --command "/app/bin/migrate"
```

Or interactively:
```bash
fly ssh console --app faf-cn
# Then inside the container:
/app/bin/migrate
```

### Step 8: Verify Deployment

Check that everything is working:

```bash
# Check app status
fly status --app faf-cn

# View logs
fly logs --app faf-cn

# Test the homepage
curl https://faf-cn.fly.dev

# Test OAuth endpoint (should return 302 redirect)
curl -I https://faf-cn.fly.dev/auth/github
```

Open https://faf-cn.fly.dev in your browser and test:
- Homepage loads
- GitHub OAuth login works
- Database operations work

---

## Post-Deployment Tasks

### Setting up a Custom Domain (Optional)

```bash
# Add your domain
fly certs create your-domain.com

# Update DNS with the provided verification records
# Then update PHX_HOST secret:
fly secrets set PHX_HOST="your-domain.com" --app faf-cn

# Also update GitHub OAuth callback URL to match
```

### Scale Resources (Optional)

```bash
# Scale to more machines for high availability
fly scale count 2 --app faf-cn

# Upgrade VM size
fly scale vm shared-cpu-2x --app faf-cn

# Increase memory
fly scale memory 2048 --app faf-cn
```

### Backup Strategy

Fly.io PostgreSQL has **daily automated backups**. To restore:

```bash
# List backups
fly postgres backup list --app faf-cn-db

# Restore from backup
fly postgres backup restore <backup-id> --app faf-cn-db
```

---

## Troubleshooting

### Database Connection Issues

**Symptom**: App starts but shows database errors in logs

**Solution**:
1. Ensure migrations ran: `fly ssh console --app faf-cn --command "/app/bin/migrate"`
2. Check database attachment: `fly postgres list`
3. Verify `DATABASE_URL` secret: `fly secrets list --app faf-cn`

### Build Failures

**Symptom**: `fly deploy` fails during build

**Common fixes**:
1. Clear build cache: `fly deploy --app faf-cn --no-cache`
2. Check Elixir/OTP versions in Dockerfile match your project
3. Ensure all dependencies are in `mix.exs`

### OAuth Not Working

**Symptom**: GitHub login fails or redirects incorrectly

**Solution**:
1. Verify `GITHUB_REDIRECT_URI` matches exactly in both Fly secrets AND GitHub OAuth settings
2. Check `PHX_HOST` is set correctly
3. Ensure `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` are correct

### App Won't Start

**Symptom**: `fly status` shows machines as `failed` or `stopped`

**Solution**:
1. Check logs: `fly logs --app faf-cn`
2. Verify all required secrets are set: `fly secrets list --app faf-cn`
3. Check internal port matches `fly.toml` (8080)

---

## Rollback

If deployment fails, rollback to the previous version:

```bash
# View previous releases
fly releases list --app faf-cn

# Rollback to a specific version
fly deploy --app faf-cn --image flyio/faf-cn:<previous-image-tag>

# Or scale down and debug
fly scale count 0 --app faf-cn
fly logs --app faf-cn
# Fix issues, then scale back up
fly scale count 1 --app faf-cn
```

---

## Development vs Production Notes

### Key Differences

| Aspect | Development | Production |
|--------|-------------|------------|
| Server | `mix phx.server` | OTP release via `/app/bin/server` |
| Database | Local Docker | Fly.io managed Postgres |
| Assets | Compiled on demand | Compiled at build time |
| Secrets | `.env` file or env vars | Fly secrets |
| OAuth | `localhost:4000` callback | `your-domain.fly.dev` callback |

### Local Testing with Production Config

To test production build locally:

```bash
# Build release locally
MIX_ENV=prod mix release

# Run with production config (requires local Postgres)
DATABASE_URL="postgres://..." \
SECRET_KEY_BASE="..." \
PHX_HOST="localhost" \
PORT=4000 \
_build/prod/rel/faf_cn/bin/server
```

---

## Cost Estimation (Fly.io)

| Resource | Free Tier | Paid (if needed) |
|----------|-----------|------------------|
| App VMs | 3 shared-CPU | ~$5/month per VM |
| PostgreSQL | 3GB storage | ~$5/month |
| Bandwidth | 160GB/month | $0.02/GB after |
| **Total** | **$0** | **~$15-30/month** |

---

## Related Files

| File | Purpose |
|------|---------|
| `fly.toml` | Fly.io app configuration |
| `Dockerfile` | Container build instructions |
| `.dockerignore` | Files to exclude from Docker context |
| `rel/overlays/bin/server` | Production server start script |
| `rel/overlays/bin/migrate` | Database migration script |
| `lib/faf_cn/release.ex` | Release utilities (migrations, etc.) |
| `config/runtime.exs` | Runtime configuration (reads env vars) |

---

## China Accessibility Considerations

1. **Region**: Singapore (`sin`) was chosen as the closest to mainland China
2. **Domain**: `.fly.dev` domains are generally accessible in China
3. **GitHub OAuth**: May be slow/unreliable in China; consider adding a backup auth method
4. **CDN**: For static assets, consider CloudFlare if global access is needed

---

## Quick Reference Commands

```bash
# Deploy
fly deploy --app faf-cn

# View logs
fly logs --app faf-cn

# SSH into running container
fly ssh console --app faf-cn

# Run migrations
fly ssh console --app faf-cn --command "/app/bin/migrate"

# View secrets
fly secrets list --app faf-cn

# Set a secret
fly secrets set KEY=value --app faf-cn

# Scale machines
fly scale count 2 --app faf-cn

# Restart app
fly apps restart faf-cn

# Destroy app (careful!)
fly apps destroy faf-cn
```

---

## Deployment Checklist

Before deploying, verify:

- [ ] `mix phx.gen.release` has been run
- [ ] GitHub OAuth app created with correct callback URL
- [ ] `fly.toml` has correct `PHX_HOST` and `PORT` settings
- [ ] `Dockerfile` has correct Elixir/OTP versions
- [ ] All secrets set (`SECRET_KEY_BASE`, `GITHUB_CLIENT_ID`, etc.)
- [ ] Database migrations run successfully
- [ ] App responds with HTTP 200
- [ ] OAuth login flow works end-to-end

---

**Last Updated**: 2026-02-10  
**Deployed Version**: faf-cn@0.1.0  
**Status**: ✅ Production Ready
