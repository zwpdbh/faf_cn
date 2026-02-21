# Quick Start

Get the FAF CN demo running locally in 5 minutes.

## Prerequisites

- Rust 1.75+ (install from [rustup.rs](https://rustup.rs))
- dioxus-cli: `cargo install dioxus-cli`

## Setup

```bash
# 1. Create workspace structure
mkdir -p fafcn-in-rust/crates
cd fafcn-in-rust

# 2. Create workspace Cargo.toml
cat > Cargo.toml << 'EOF'
[workspace]
members = ["crates/*"]
resolver = "2"

[workspace.package]
version = "0.1.0"
edition = "2021"

[workspace.dependencies]
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
chrono = { version = "0.4", features = ["serde"] }
EOF

# 3. Create fafcn-core crate
cd crates
cargo new --lib fafcn-core

# 4. Create fafcn-web crate
cargo new --bin fafcn-web
cd fafcn-web

# 5. Create Dioxus config
cat > Dioxus.toml << 'EOF'
[application]
name = "fafcn-web"
default_platform = "web"
out_dir = "dist"
asset_dir = "assets"

[web.app]
title = "FAF CN"

[web.watcher]
reload_html = true
watch_path = ["src", "assets"]

[web.resource]
style = ["tailwind.css"]
EOF

# 6. Add index.html template
mkdir -p assets
cat > assets/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>FAF CN</title>
  <link rel="stylesheet" href="/tailwind.css">
</head>
<body>
  <div id="main"></div>
</body>
</html>
EOF
```

## Dependencies

### fafcn-core/Cargo.toml

```toml
[package]
name = "fafcn-core"
version = "0.1.0"
edition = "2021"

[dependencies]
serde = { workspace = true }
chrono = { workspace = true }
```

### fafcn-web/Cargo.toml

```toml
[package]
name = "fafcn-web"
version = "0.1.0"
edition = "2021"

[[bin]]
name = "fafcn-web"
path = "src/main.rs"

[dependencies]
# Core
fafcn-core = { path = "../fafcn-core" }
serde = { workspace = true }
chrono = { workspace = true }

# Frontend
dioxus = { version = "0.5", features = ["web", "router"] }
dioxus-web = "0.5"
dioxus-signals = "0.5"
dioxus-router = { version = "0.5", features = ["web"] }

# WASM
wasm-bindgen = "0.2"
wasm-bindgen-futures = "0.4"
web-sys = "0.3"
js-sys = "0.3"

# Logging
log = "0.4"
wasm-logger = "0.2"
console_error_panic_hook = "0.1"
```

## Basic App Structure

### src/main.rs

```rust
mod app;
mod components;
mod data;
mod hooks;
mod pages;
mod state;

use app::App;

fn main() {
    wasm_logger::init(wasm_logger::Config::default());
    console_error_panic_hook::set_once();
    
    dioxus_web::launch(App);
}
```

### src/app.rs

```rust
use dioxus::prelude::*;
use dioxus_router::prelude::*;

use crate::{state::AppStateProvider, pages::{Home, EcoGuides, EcoPrediction}};

#[derive(Clone, Routable, Debug, PartialEq)]
pub enum Route {
    #[route("/")]
    Home {},
    
    #[route("/eco-guides")]
    EcoGuides {},
    
    #[route("/eco-prediction")]
    EcoPrediction {},
}

#[component]
pub fn App() -> Element {
    rsx! {
        AppStateProvider {
            Router::<Route> {}
        }
    }
}
```

## Run

```bash
# Start dev server
dx serve --hot-reload

# Open browser to http://localhost:8080
```

You should see a blank page. Now let's add content.

## Next Steps

1. [Architecture](./02-architecture.md) - Understand the system design
2. [State Management](./03-state-management.md) - Add global state
3. [Components](./04-components.md) - Build UI components
