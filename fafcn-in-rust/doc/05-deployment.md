# Deployment

Deploy the FAF CN demo to various platforms.

## Build Commands

```bash
# Development
dx serve --hot-reload

# Production build
dx build --release

# With optimizations
wasm-opt -O3 dist/*.wasm -o dist/app.wasm
```

## Platform Options

### GitHub Pages (Free)

Best for: Open source projects, simple hosting

```bash
# 1. Enable GitHub Pages in repo settings
# Set source to "deploy from branch" -> "gh-pages"

# 2. Build
cd crates/fafcn-web
dx build --release --public-url /fafcn-in-rust/

# 3. Deploy to gh-pages branch
cd dist
git init
git add .
git commit -m "Deploy"
git push -f git@github.com:yourusername/fafcn-in-rust.git main:gh-pages

# 4. Access at https://yourusername.github.io/fafcn-in-rust/
```

### Netlify (Free Tier)

Best for: Automatic deploys, branch previews

```bash
# 1. Install Netlify CLI
npm install -g netlify-cli

# 2. Build
cd crates/fafcn-web
dx build --release

# 3. Deploy
netlify deploy --prod --dir=dist

# Or with netlify.toml
cat > netlify.toml << 'EOF'
[build]
  command = "cd crates/fafcn-web && dx build --release"
  publish = "crates/fafcn-web/dist"

[build.environment]
  RUST_VERSION = "1.75"
EOF
```

### Vercel (Free Tier)

Best for: Serverless, edge network

```bash
# 1. Install Vercel CLI
npm i -g vercel

# 2. Create vercel.json
cat > vercel.json << 'EOF'
{
  "builds": [
    {
      "src": "crates/fafcn-web/dist/**",
      "use": "@vercel/static"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/$1"
    }
  ]
}
EOF

# 3. Build locally first
cd crates/fafcn-web
dx build --release

# 4. Deploy
vercel --prod
```

### Cloudflare Pages (Free)

Best for: Global CDN, edge functions (future)

```bash
# 1. Build
cd crates/fafcn-web
dx build --release

# 2. Deploy via Wrangler
npx wrangler pages deploy dist --project-name=fafcn
```

## Build Configuration

### Optimized Cargo.toml

```toml
[profile.release]
# Smaller binary size
opt-level = "z"      # Optimize for size
lto = true           # Link-time optimization
codegen-units = 1    # Single codegen unit
panic = "abort"      # Smaller panic handling
strip = true         # Strip symbols
```

### WASM Optimization

```bash
# Install wasm-opt
cargo install wasm-opt

# Optimize the WASM binary
cd crates/fafcn-web/dist
wasm-opt -Oz -o app.opt.wasm *.wasm
mv app.opt.wasm app.wasm
```

### Compression

```bash
# Gzip (most servers do this automatically)
gzip -k dist/*.wasm
gzip -k dist/*.js

# Brotli (better compression)
brotli dist/*.wasm
brotli dist/*.js
```

## Performance Checklist

Before deploying:

- [ ] `opt-level = "z"` in Cargo.toml
- [ ] wasm-opt applied
- [ ] Assets gzipped
- [ ] Images optimized
- [ ] Unused code removed

## Expected Bundle Sizes

| Asset | Raw | Gzipped |
|-------|-----|---------|
| app.wasm | 800KB | 250KB |
| app.js | 50KB | 15KB |
| tailwind.css | 20KB | 5KB |
| unit data | 100KB | 30KB |
| **Total** | **970KB** | **300KB** |

First load: ~300KB
Subsequent loads: Cached

## CDN Configuration

### Cache Headers

```nginx
# nginx.conf
location ~* \.(wasm|js|css)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### CORS (if needed)

```nginx
location / {
    add_header Access-Control-Allow-Origin *;
    add_header Access-Control-Allow-Methods "GET, OPTIONS";
}
```

## Custom Domain

### GitHub Pages + Custom Domain

1. Add `CNAME` file to `dist/` folder:
```
fafcn.yourdomain.com
```

2. Configure DNS:
```
CNAME fafcn.yourdomain.com -> yourusername.github.io
```

### Netlify Custom Domain

1. Add domain in Netlify dashboard
2. Configure DNS:
```
CNAME fafcn.yourdomain.com -> your-site.netlify.app
```

## Monitoring

### Basic Analytics

Add to `index.html`:
```html
<!-- Google Analytics 4 -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_ID');
</script>

<!-- Or privacy-focused Plausible -->
<script defer data-domain="fafcn.yourdomain.com" src="https://plausible.io/js/script.js"></script>
```

### Error Tracking

```rust
// In main.rs
#[cfg(not(debug_assertions))]
{
    // Initialize Sentry for production
    let _guard = sentry::init(("SENTRY_DSN", sentry::ClientOptions {
        release: Some(env!("CARGO_PKG_VERSION").into()),
        ..Default::default()
    }));
}
```

## Checklist

- [ ] Build with `--release`
- [ ] Run wasm-opt
- [ ] Test locally: `python3 -m http.server 8080`
- [ ] Check all routes work
- [ ] Verify LocalStorage persistence
- [ ] Add analytics (optional)
- [ ] Deploy to chosen platform
- [ ] Configure custom domain (optional)
- [ ] Test on mobile
- [ ] Share URL!

## Ready to Ship! 🚀

Your FAF CN demo is now ready to share. Just:

```bash
cd crates/fafcn-web
dx build --release
# Upload dist/ folder to your chosen platform
```

Users can immediately:
- Browse all units
- Run eco simulations
- Save build orders (LocalStorage)
- Use offline

No backend required!
