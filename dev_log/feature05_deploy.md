# Feature05 -- Deploy

Currently this project just run locally.
It is time to deploy it to somewhere to let user to give it a try.

## Goal

- Deploy to some cloud provider which could be accessed by China mainland player.
- Ensure GitHub OAuth works in production
- Secure environment for secrets
- Database persistence

---

## Deployment Options Analysis

| Provider      | Pros                                            | Cons                    | China Access           |
| ------------- | ----------------------------------------------- | ----------------------- | ---------------------- |
| **Fly.io** ⭐  | Native Phoenix support, edge in Asia, free tier | Newer platform          | Good (HKG/SIN regions) |
| DigitalOcean  | Simple, affordable                              | Manual SSL setup        | Okay (SIN region)      |
| Alibaba Cloud | Excellent China access                          | Complex, Chinese docs   | Excellent              |
| Render        | Easy to use                                     | No Asia regions         | Poor                   |
| Heroku        | Familiar                                        | Expensive, no free tier | Poor                   |

**Recommendation: Fly.io**
- Built by former Heroku engineers
- First-class Elixir/OTP support
- `fly launch` auto-detects Phoenix apps
- Hong Kong (HKG) and Singapore (SIN) regions
- Free tier: 3 shared-CPU VMs, 3GB persistent volumes

---

## Pre-Deployment Checklist

### Phase 1: Prepare Application for Production

- [ ] **Generate production secret**
  ```bash
  mix phx.gen.secret
  ```
  Save this for `SECRET_KEY_BASE`

- [ ] **Create GitHub OAuth App for production**
  - Go to: https://github.com/settings/developers
  - New OAuth App
  - Homepage URL: `https://your-domain.fly.dev`
  - Authorization callback URL: `https://your-domain.fly.dev/auth/github/callback`
  - Save Client ID and Client Secret

- [ ] **Set up release configuration**
  - Already partially done in `runtime.exs`
  - Verify all production env vars are defined

- [ ] **Database migrations setup**
  - Create `priv/repo/seeds_prod.exs` if needed
  - Ensure `mix ecto.migrate` runs on deploy

### Phase 2: Fly.io Setup

- [ ] **Install Fly CLI**
  ```bash
  curl -L https://fly.io/install.sh | sh
  ```

- [ ] **Sign up / Login**
  ```bash
  fly auth signup  # or fly auth login
  ```

- [ ] **Launch the app**
  ```bash
  fly launch
  # Select:
  # - App name: faf-cn (or similar)
  # - Region: Hong Kong (hkg) or Singapore (sin)
  # - PostgreSQL: Yes (Fly managed)
  # - Redis: No (not needed)
  ```

- [ ] **Set environment variables**
  ```bash
  fly secrets set SECRET_KEY_BASE=your_generated_secret
  fly secrets set GITHUB_CLIENT_ID=your_github_client_id
  fly secrets set GITHUB_CLIENT_SECRET=your_github_client_secret
  fly secrets set GITHUB_REDIRECT_URI=https://your-app.fly.dev/auth/github/callback
  fly secrets set PHX_HOST=your-app.fly.dev
  ```

- [ ] **Deploy**
  ```bash
  fly deploy
  ```

- [ ] **Run database migrations**
  ```bash
  fly ssh console
  /app/bin/faf_cn eval "FafCn.Release.migrate"
  ```

- [ ] **Verify deployment**
  - Check app loads: `https://your-app.fly.dev`
  - Check OAuth works
  - Check admin features work

### Phase 3: Post-Deployment

- [ ] **Set up custom domain (optional)**
  ```bash
  fly certs create your-domain.com
  ```

- [ ] **Configure CDN (optional)**
  - CloudFlare for global access
  - Or use Fly's built-in CDN

- [ ] **Set up monitoring**
  - Fly dashboard shows logs/metrics
  - Configure alerts for crashes

- [ ] **Backup strategy**
  - Fly PostgreSQL has daily backups
  - Document restore process

---

## Environment Variables Reference

| Variable               | Required | Description                          |
| ---------------------- | -------- | ------------------------------------ |
| `SECRET_KEY_BASE`      | Yes      | Generated with `mix phx.gen.secret`  |
| `DATABASE_URL`         | Auto     | Set by Fly PostgreSQL                |
| `PHX_HOST`             | Yes      | Your domain (e.g., `faf-cn.fly.dev`) |
| `GITHUB_CLIENT_ID`     | Yes      | From GitHub OAuth app                |
| `GITHUB_CLIENT_SECRET` | Yes      | From GitHub OAuth app                |
| `GITHUB_REDIRECT_URI`  | Yes      | Must match GitHub OAuth settings     |
| `POOL_SIZE`            | No       | Database connections (default: 10)   |

---

## China Accessibility Considerations

1. **Domain**: Use a `.com` or `.dev` domain (not blocked)
2. **CDN**: Consider CloudFlare or Alibaba CDN for static assets
3. **GitHub OAuth**: May be slow in China, consider backup auth method later
4. **Region Selection**: Hong Kong (HKG) is closest to mainland China

---

## Rollback Plan

```bash
# If deployment fails, rollback to previous version
fly deploy --image flyio/faf-cn:previous-tag

# Or scale to zero and debug
fly scale count 0
fly logs  # Check errors
```

---

## Cost Estimation (Fly.io)

| Resource   | Free Tier    | Paid (if needed)  |
| ---------- | ------------ | ----------------- |
| App VMs    | 3 shared-CPU | ~$5/month per VM  |
| PostgreSQL | 3GB storage  | ~$5/month         |
| Bandwidth  | 160GB/month  | $0.02/GB after    |
| **Total**  | **$0**       | **~$15-30/month** |

---

## Task Breakdown

### Ready to Start
1. Generate secrets and set up GitHub OAuth
2. Install Fly CLI and sign up
3. Run `fly launch`
4. Configure secrets
5. Deploy

### Estimated Time
- First-time setup: 1-2 hours
- Troubleshooting: 1-2 hours (if issues arise)

---

## Questions to Decide

1. **What's your preferred domain name?**
   - `faf-cn.fly.dev` (free)
   - Custom domain (need to configure DNS)
A: free one is good for now. 

2. **Do you have a GitHub account for the OAuth app?**
   - Needed for production OAuth credentials

3. **Do you want a custom domain?**
   - Requires DNS configuration
   - SSL certificate (free via Fly)

4. **Any specific data that needs to be preserved from local dev?**
   - If yes, need to export/import database