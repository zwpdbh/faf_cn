# FAF CN Documentation

**Pure Frontend Demo with Dioxus + Rust**

No backend required. Runs entirely in the browser.

## Guides

1. **[Quick Start](./01-quick-start.md)** - Get running in 5 minutes
2. **[Architecture](./02-architecture.md)** - System design
3. **[State Management](./03-state-management.md)** - Signals and persistence
4. **[Components](./04-components.md)** - UI component catalog
5. **[Deployment](./05-deployment.md)** - Ship to production

## Implementation Timeline

| Phase | Duration | Focus |
|-------|----------|-------|
| 1 | Week 1 | fafcn-core: Domain models + Eco engine |
| 2 | Week 2 | fafcn-web: Dioxus setup + basic UI |
| 3 | Week 3 | Features: Drag-drop, charts, simulation |
| 4 | Week 4 | Polish: Optimize, test, deploy |

## What Works

- ✅ Browse all 400+ units
- ✅ Filter by faction/tech/category
- ✅ Real eco simulation (WASM)
- ✅ Drag-drop build queue
- ✅ Interactive charts (zoom/pan)
- ✅ Works offline
- ✅ LocalStorage persistence

## Quick Commands

```bash
# Run dev server
cd crates/fafcn-web && dx serve --hot-reload

# Test core
cargo test -p fafcn-core

# Build production
dx build --release

# Deploy
netlify deploy --prod --dir=dist
```

## Start Here

Go to [Quick Start](./01-quick-start.md)
