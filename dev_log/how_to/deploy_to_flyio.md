# Deploy FAF-CN Phoenix App to Fly.io

A step-by-step guide to deploy the `faf_cn` Phoenix application to Fly.io, with special focus on database integration.

---

## Prerequisites

1. **Elixir/OTP** installed (check `.tool-versions` for versions)
2. **Fly CLI** installed:
   ```bash
   curl -L https://fly.io/install.sh | sh
   export FLYCTL_INSTALL="$HOME/.fly"
   export PATH="$FLYCTL_INSTALL/bin:$PATH"
   ```
3. **Fly.io account** - Sign up at https://fly.io and run `fly auth login`
4. **GitHub account** - For OAuth authentication

---

## Deployment Steps

### Step 1: Generate Release Configuration

The release configuration enables the app to run as a compiled OTP release (without Mix):

```bash
mix phx.gen.release
```

This creates:
- `rel/overlays/bin/server` - Start script for production
- `rel/overlays/bin/migrate` - Database migration script
- `lib/faf_cn/release.ex` - Release utilities (migrations, seeds)

### Step 2: Create GitHub OAuth App

1. Go to https://github.com/settings/developers → **New OAuth App**
2. Fill in:
   - **Application name**: Your app name (e.g., `faf-cn`)
   - **Homepage URL**: `https://<your-app-name>.fly.dev`
   - **Authorization callback URL**: `https://<your-app-name>.fly.dev/auth/github/callback`
3. Click **Register application**
4. **Generate a new client secret** and save both:
   - Client ID
   - Client Secret

### Step 3: Create Fly.io App and Database

Create the app (this provisions both the app and PostgreSQL database):

```bash
fly launch --name <your-app-name> --region sin --no-deploy
```

**Parameters:**
- `--name <your-app-name>` - Must be globally unique on Fly.io
- `--region sin` - Singapore region (closest to China)
- `--no-deploy` - Don't deploy yet (we need to set secrets first)

**What this does:**
- Creates the app on Fly.io
- Provisions a **PostgreSQL database** (separate app: `<your-app-name>-db`)
- **Automatically attaches** the database to your app (sets `DATABASE_URL` secret)
- Creates `fly.toml` configuration file

**Verify database attachment:**
```bash
fly secrets list --app <your-app-name>
# You should see DATABASE_URL is already set
```

### Step 4: Configure fly.toml

The `fly.toml` should look like this (update the app name):

```toml
app = '<your-app-name>'
primary_region = 'sin'

[build]

[deploy]
  release_command = '/app/bin/migrate_and_seed'

[env]
  PHX_HOST = '<your-app-name>.fly.dev'
  PORT = '8080'

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 1
  processes = ['app']

  [http_service.concurrency]
    type = 'connections'
    hard_limit = 1000
    soft_limit = 1000

  # Health check configuration - must return HTTP 200 on /health
  [[http_service.checks]]
    interval = "15s"
    timeout = "5s"
    grace_period = "30s"
    method = "GET"
    path = "/health"

[[vm]]
  size = 'shared-cpu-1x'
  memory = '1gb'
```

**Important:** The health check endpoint (`/health`) must be excluded from SSL redirection in your `config/prod.exs`. See the [Troubleshooting section](#issue-health-check-failing-with-connection-refused--ssl-redirect-loop) for details.

### Step 5: Set Environment Secrets

Generate and set all required secrets:

```bash
# Generate SECRET_KEY_BASE
mix phx.gen.secret
# Copy the output

# Set all secrets on Fly.io
fly secrets set \
  SECRET_KEY_BASE="<generated_secret>" \
  GITHUB_CLIENT_ID="<your_github_client_id>" \
  GITHUB_CLIENT_SECRET="<your_github_client_secret>" \
  GITHUB_REDIRECT_URI="https://<your-app-name>.fly.dev/auth/github/callback" \
  PHX_HOST="<your-app-name>.fly.dev" \
  --app <your-app-name>
```

**Secrets Reference:**

| Variable               | Required | How to Set                                  |
| ---------------------- | -------- | ------------------------------------------- |
| `DATABASE_URL`         | Yes      | Auto-set by Fly.io when attaching Postgres  |
| `SECRET_KEY_BASE`      | Yes      | Generate with `mix phx.gen.secret`          |
| `PHX_HOST`             | Yes      | Your Fly.io domain                          |
| `GITHUB_CLIENT_ID`     | Yes      | From GitHub OAuth app                       |
| `GITHUB_CLIENT_SECRET` | Yes      | From GitHub OAuth app                       |
| `GITHUB_REDIRECT_URI`  | Yes      | Must match GitHub OAuth settings            |
| `POOL_SIZE`            | Optional | Database connection pool size (default: 10) |
| `ECTO_IPV6`            | Optional | Set to `true` if using IPv6                 |

### Step 6: Deploy the Application

```bash
fly deploy --app <your-app-name>
```

First deployment takes 5-10 minutes. Subsequent deployments are faster.

### Step 7: Run Database Migrations

**⚠️ Critical Step**: After the first deployment, you must run migrations:

```bash
fly ssh console --app <your-app-name> --command "/app/bin/migrate"
```

**What this does:**
- Connects to your running app via SSH
- Executes Ecto migrations against the attached PostgreSQL database
- Creates all required tables

### Step 8: Seed Database (Optional)

If your app requires seed data:

```bash
fly ssh console --app <your-app-name> --command "/app/bin/faf_cn eval 'FafCn.Release.seed()'"
```

**Note**: This project includes unit data seeding from `priv/repo/units_seed.json`.

### Step 9: Verify Deployment

```bash
# Check app status
fly status --app <your-app-name>

# View logs
fly logs --app <your-app-name>

# Test endpoints
curl https://<your-app-name>.fly.dev
curl -I https://<your-app-name>.fly.dev/auth/github
```

---

## Database Operations Guide

### Database Architecture on Fly.io

```
┌─────────────────┐         ┌──────────────────┐
│  Your App       │◄───────►│  PostgreSQL DB   │
│  (faf-cn)       │  VPC    │  (faf-cn-db)     │
└─────────────────┘         └──────────────────┘
       │                              │
       │ Auto-stops when idle         │ Always running
       │ Auto-starts on request       │ (for data persistence)
       └──────────────────────────────┘
```

### Common Database Commands

```bash
# Check database status
fly status --app <your-app-name>-db

# View database logs
fly logs --app <your-app-name>-db

# Connect to database console
fly postgres connect --app <your-app-name>-db

# List databases
fly postgres connect --app <your-app-name>-db --command "\l"

# Connect to your app's database
fly postgres connect --app <your-app-name>-db --database <your-app-name>

# View database secrets (including connection URL)
fly secrets list --app <your-app-name>-db
```

### Running Migrations on Deploy

**Option 1: Manual (after deploy)**
```bash
fly ssh console --app <your-app-name> --command "/app/bin/migrate"
```

**Option 2: Release command (automatic)**

Add to `fly.toml` to run migrations automatically on each deploy:

```toml
[deploy]
  release_command = "/app/bin/migrate"
```

**Note**: With release commands, the app waits for migrations to complete before starting.

### Database Backup and Restore

```bash
# List backups
fly postgres backup list --app <your-app-name>-db

# Create manual backup
fly postgres backup create --app <your-app-name>-db

# Restore from backup
fly postgres backup restore <backup-id> --app <your-app-name>-db
```

---

## Troubleshooting Database Issues

### Issue: "Database connection not available"

**Symptoms:**
- App returns 500 errors
- Logs show: `(DBConnection.ConnectionError) connection not available`

**Diagnosis:**
```bash
# Check if database is running
fly status --app <your-app-name>-db

# Check database logs
fly logs --app <your-app-name>-db
```

**Solutions:**

1. **Database is down** - Restart it:
   ```bash
   fly machine restart <machine-id> --app <your-app-name>-db
   ```

2. **Migrations not run** - Run migrations:
   ```bash
   fly ssh console --app <your-app-name> --command "/app/bin/migrate"
   ```

3. **Secrets incorrect** - Verify DATABASE_URL:
   ```bash
   fly secrets list --app <your-app-name>
   ```

### Issue: "Postgrex.Protocol failed to connect"

**Symptoms:**
- Connection errors in logs
- `tcp recv (idle): closed`

**Cause:** Database machine may have crashed or network issue.

**Solution:**
```bash
# Get the database machine ID
fly status --app <your-app-name>-db

# Restart the database machine
fly machine restart <machine-id> --app <your-app-name>-db

# Wait for it to start, then restart your app
fly apps restart <your-app-name>
```

### Issue: SSL Connection Errors

If you see SSL-related connection errors, Fly.io Postgres uses SSL by default. The app configuration in `config/runtime.exs` handles this automatically:

```elixir
# The commented ssl: true is intentional - Fly.io handles SSL at the network level
config :faf_cn, FafCn.Repo,
  # ssl: true,  # Uncomment if needed for external connections
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  socket_options: maybe_ipv6
```

### Issue: Pool Size Exhausted

**Symptoms:**
- `pool_timeout` errors
- Intermittent connection failures

**Solution:**
Increase the pool size:
```bash
fly secrets set POOL_SIZE=20 --app <your-app-name>
```

### Issue: Health Check Failing with "connection refused" / SSL Redirect Loop

**Symptoms:**
- `fly status` shows: `1 total, 1 critical`
- Health check output: `connect: connection refused`
- Logs show repeated: `Plug.SSL is redirecting GET /health to https://... with status 301`
- Application appears to be running but Fly.io reports it as unhealthy

**Root Cause:**
The `exclude` option for `force_ssl` was incorrectly placed **outside** the `force_ssl` configuration in `config/prod.exs`. This caused the health check endpoint (`/health`) to be redirected to HTTPS, which fails because Fly.io's internal health checks use HTTP on port 8080.

**Incorrect Configuration (Broken):**
```elixir
# config/prod.exs - WRONG!
config :faf_cn, FafCnWeb.Endpoint,
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  exclude: [
    # This exclude is at the wrong level!
    paths: ["/health"],
    hosts: ["localhost", "127.0.0.1"]
  ]
```

**Correct Configuration (Fixed):**
```elixir
# config/prod.exs - CORRECT!
config :faf_cn, FafCnWeb.Endpoint,
  force_ssl: [
    rewrite_on: [:x_forwarded_proto],
    exclude: [
      # Health check must be excluded from SSL redirect for Fly.io health checks
      paths: ["/health"],
      hosts: ["localhost", "127.0.0.1"]
    ]
  ]
```

**Why This Matters:**
1. Fly.io's internal health checks connect via HTTP on port 8080 (inside the private network)
2. If `Plug.SSL` redirects these requests to HTTPS, the health check gets a 301 instead of 200
3. The health check must be excluded from SSL redirection to respond properly
4. The `exclude` option must be **nested inside** `force_ssl`, not a sibling key

**Solution Steps:**
1. Fix the configuration in `config/prod.exs` as shown above
2. Ensure the `HealthCheck` plug is placed **first** in the endpoint (before any SSL handling)
3. Deploy the fix:
   ```bash
   fly deploy --app <your-app-name>
   ```
4. Verify the health check passes:
   ```bash
   fly status --app <your-app-name>
   # Should show: 1 total, 1 passing
   ```

**Prevention:**
- Always place `exclude` inside `force_ssl` configuration
- Keep the `HealthCheck` plug at the top of your endpoint pipeline
- Test health check behavior after any SSL-related configuration changes

---

## GitHub Actions Auto-Deployment

The repository includes a workflow for automatic deployment.

### Setup

1. **Generate Fly API Token:**
   ```bash
   fly tokens create deploy -x 999999h --app <your-app-name>
   ```

2. **Add to GitHub Secrets:**
   - Go to: `https://github.com/<username>/<repo>/settings/secrets/actions`
   - Add secret: `FLY_API_TOKEN` = (token from step 1)

### How It Works

- Push to `master` → Triggers CI (tests, lint, format check)
- If CI passes → Auto-deploys to Fly.io
- Database migrations must be run manually after first deploy

---

## Complete Deployment Checklist

### Before First Deploy
- [ ] `mix phx.gen.release` has been run
- [ ] GitHub OAuth app created with correct callback URL
- [ ] `fly.toml` has correct `app`, `PHX_HOST`, and `PORT` settings
- [ ] `Dockerfile` is present and correct
- [ ] `.dockerignore` is configured

### Secrets Setup
- [ ] `SECRET_KEY_BASE` generated and set
- [ ] `GITHUB_CLIENT_ID` set
- [ ] `GITHUB_CLIENT_SECRET` set
- [ ] `GITHUB_REDIRECT_URI` matches GitHub OAuth settings
- [ ] `PHX_HOST` matches Fly.io domain
- [ ] `DATABASE_URL` auto-set by Fly.io (verify with `fly secrets list`)

### After First Deploy
- [ ] Run migrations: `fly ssh console --app <app> --command "/app/bin/migrate"`
- [ ] Run seeds (if needed): `fly ssh console --app <app> --command "/app/bin/faf_cn eval 'FafCn.Release.seed()'"`
- [ ] Test homepage loads
- [ ] Test GitHub OAuth login works
- [ ] Test database operations (CRUD)

### For Auto-Deployment (Optional)
- [ ] `FLY_API_TOKEN` added to GitHub Secrets
- [ ] Workflow file at `.github/workflows/fly-deploy.yml`
- [ ] Test push to verify auto-deployment

---

## Quick Reference Commands

```bash
# Deploy
fly deploy --app <your-app-name>

# View logs
fly logs --app <your-app-name>

# SSH into app
fly ssh console --app <your-app-name>

# Run migrations
fly ssh console --app <your-app-name> --command "/app/bin/migrate"

# Run seeds
fly ssh console --app <your-app-name> --command "/app/bin/faf_cn eval 'FafCn.Release.seed()'"

# View secrets
fly secrets list --app <your-app-name>

# Set a secret
fly secrets set KEY=value --app <your-app-name>

# Database status
fly status --app <your-app-name>-db

# Database console
fly postgres connect --app <your-app-name>-db

# Restart app
fly apps restart <your-app-name>

# Restart database
fly machine restart <machine-id> --app <your-app-name>-db

# Scale app
fly scale count 2 --app <your-app-name>

# Destroy (careful!)
fly apps destroy <your-app-name>
```

---

## Cost Estimation

| Resource          | Free Tier             | Paid (if exceeded) |
| ----------------- | --------------------- | ------------------ |
| App VMs           | 3 shared-CPU machines | ~$5/month per VM   |
| PostgreSQL        | 3GB storage           | ~$5/month          |
| Bandwidth         | 160GB/month           | $0.02/GB after     |
| **Typical total** | **$0**                | **~$10-20/month**  |

---

## Additional Resources

- [Fly.io Postgres Docs](https://fly.io/docs/postgres/)
- [Phoenix Deployment Guides](https://hexdocs.pm/phoenix/deployment.html)
- [Fly.io Phoenix Guide](https://fly.io/docs/elixir/getting-started/)
