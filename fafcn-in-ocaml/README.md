# FAF CN - OCaml/Melange Implementation

FAF CN eco guide implemented in OCaml with Melange (compiles to JavaScript).

## Quick Start

```bash
# Install OCaml/Melange and npm dependencies (first time only)
npm run install:npm-opam

# Watch mode for development (rebuilds on file changes)
npm run watch

# In another terminal, serve the application
npm run serve
# Opens http://localhost:5173/src/eco-guide/
```

## Development Workflow

```bash
# Terminal 1: Build in watch mode
npm run watch

# Terminal 2: Serve with Vite (hot reload)
npm run serve

# Open browser to http://localhost:5173/src/eco-guide/
```

## Available Scripts

| Script | Description |
|--------|-------------|
| `npm run install:npm-opam` | Install npm packages + OCaml/Melange dependencies |
| `npm run build` | Build the frontend |
| `npm run watch` | Watch files and rebuild on changes |
| `npm run serve` | Serve with Vite dev server |
| `npm run bundle` | Build for production |
| `npm run clean` | Clean build artifacts |
| `npm run fmt` | Format code with ocamlformat |

## Project Structure

```
fafcn-in-ocaml/
├── package.json           # npm scripts and dependencies
├── vite.config.mjs        # Vite dev server config
├── index.html             # Root index page
├── dune-project           # Dune project metadata
├── dune                   # Root dune config
├── src/
│   └── eco-guide/         # Main Eco Guide app
│       ├── dune           # App build config (melange.emit)
│       ├── index.html     # App entry HTML (loads React manually)
│       ├── App.re         # Main app component with routing
│       ├── Home.re        # Home page component
│       ├── Models.re      # Module wrappers
│       ├── Models/        # Domain types (Faction, Unit, Filter)
│       ├── Eco.re         # Module wrappers
│       ├── Eco/           # Economy calculations
│       ├── Data.re        # Module wrappers
│       ├── Data/          # Unit data
│       ├── Components.re  # Module wrappers
│       └── Components/    # React components
├── backend/               # (Future) OCaml backend
└── public/                # Static assets (styles.css)
```

## How It Works

This follows the official [Melange for React Developers](https://github.com/melange-re/melange-for-react-devs) pattern:

1. **Each app has its own `dune` file** with `melange.emit` stanza
2. **Vite** serves the project and handles hot reload
3. **npm scripts** wrap both opam and dune commands
4. **Build output** goes to `_build/default/src/<app>/output/`

## Key Differences from Rust/Dioxus

| Feature | Rust/Dioxus | OCaml/Melange |
|---------|-------------|---------------|
| Output | WASM | JavaScript |
| React | Dioxus VDOM | Native React |
| Bundle Size | ~2MB | ~200KB |
| Pattern Matching | Excellent | Superior |
| Type Inference | Good | Excellent |
| Dev Server | Built-in | Vite |

## License

MIT
