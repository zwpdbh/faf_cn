# Integrate Tidewave MCP with Phoenix

This guide explains how to use Tidewave as an MCP (Model Context Protocol) server integrated with your Phoenix application, enabling AI agents like Kimi CLI to access runtime intelligence.

## Prerequisites

Before starting, ensure you have the following installed:

### 1. Kimi CLI

Kimi CLI is the AI agent that will connect to Tidewave MCP.

**Installation:**
```bash
curl -L code.kimi.com/install.sh | bash
```

**Verify installation:**
```bash
kimi --version
```

### 2. Phoenix Application with Tidewave

Your Phoenix project should already have Tidewave installed. Check the following files:

**`mix.exs`** - should contain:
```elixir
defp deps do
  [
    {:tidewave, "~> 0.5", only: :dev}
    # ... other deps
  ]
end
```

**`lib/faf_cn_web/endpoint.ex`** - should contain:
```elixir
defmodule FafCnWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :faf_cn

  # ... other plugs

  if Mix.env() == :dev do
    plug Tidewave
  end
end
```

If Tidewave is not installed, add it to your project:

```bash
# Add the dependency
echo '{:tidewave, "~> 0.5", only: :dev}' >> mix.exs

# Add the plug to endpoint (before the router plug)
# Edit lib/faf_cn_web/endpoint.ex and add:
#   if Mix.env() == :dev do
#     plug Tidewave
#   end
```

Then install dependencies:
```bash
mix deps.get
```

## Architecture

Tidewave MCP is **embedded** into your Phoenix application. When you start your Phoenix server, the MCP endpoint is automatically available.

```
┌─────────────────┐      HTTP (SSE)       ┌──────────────────┐
│   Kimi CLI      │ ◄──────────────────► │  Phoenix App     │
│  (with MCP      │    http://localhost  │  (with Tidewave  │
│   client)       │    :4000/tidewave/mcp │   plug)          │
└─────────────────┘                       └──────────────────┘
                                                 │
                                                 ▼
                                          ┌──────────────────┐
                                          │  Runtime Tools:  │
                                          │  - Execute SQL   │
                                          │  - Eval Code     │
                                          │  - Get Logs      │
                                          │  - Find Source   │
                                          └──────────────────┘
```

## Important: Project-Only Configuration

**Problem:** Tidewave MCP is only available when the Phoenix server is running. If you add Tidewave to the global `~/.kimi/mcp.json`, it will cause connection errors when you use Kimi in other projects (e.g., Rust projects) where no Phoenix server is running.

**Solution:** Use a project-local MCP configuration instead of the global one. This ensures Tidewave MCP is only active when working on this Phoenix project.

## Setup Steps

### Step 1: Start Phoenix Server

Start your Phoenix server in development mode:

```bash
cd /home/zw/code/elixir_programming/faf_cn
mix phx.server
```

The MCP endpoint is now available at: `http://localhost:4000/tidewave/mcp`

### Step 2: Configure Kimi CLI (Project-Local)

This project includes a project-local MCP configuration at `.kimi/mcp.json`:

```json
{
  "mcpServers": {
    "tidewave": {
      "url": "http://localhost:4000/tidewave/mcp",
      "transport": "http"
    }
  }
}
```

**To use Kimi with Tidewave in this project only:**

In a **new terminal window** (keep the Phoenix server running), start Kimi with the project-local MCP config:

```bash
# From project root
cd /home/zw/code/elixir_programming/faf_cn
kimi --mcp-config-file .kimi/mcp.json
```

Or create a shell alias for convenience:

```bash
# Add to your ~/.bashrc or ~/.zshrc
alias kimifaf="kimi --mcp-config-file /home/zw/code/elixir_programming/faf_cn/.kimi/mcp.json"
```

Then simply use:

```bash
kimifaf
```

**Note:** We intentionally do NOT add Tidewave to the global `~/.kimi/mcp.json` to avoid connection errors in other projects.

### Step 3: Restart Kimi CLI

**Important:** If Kimi CLI is currently running, you need to **exit and restart it** to load the new MCP configuration.

```bash
# Exit current Kimi session (if running)
# Then start a new session:
kimi
```

### Step 4: Verify the Connection

**Important:** The `--mcp-config-file` flag is designed for loading temporary MCP configs when **starting the main Kimi CLI session**, not for the `mcp` subcommands. The `kimi mcp test` command only looks at the default config location (`~/.kimi/mcp.json`).

To verify Tidewave is working, use one of these methods:

**Method A: Test the MCP endpoint directly**

```bash
curl -X POST http://localhost:4000/tidewave/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
```

Expected response:
```json
{"id":1,"result":{"protocolVersion":"2024-11-05","serverInfo":{...},"capabilities":{...}},"jsonrpc":"2.0"}
```

**Method B: Verify inside Kimi session**

Start Kimi with the project-local config and check MCP tools:

```bash
# From project root
cd /home/zw/code/elixir_programming/faf_cn
kimi --mcp-config-file .kimi/mcp.json
```

Inside the Kimi session, type `/mcp` to view connected servers and loaded tools, or ask:

> "List the MCP tools you have access to"

Expected output:
```
✓ Connected to 'tidewave'
  Available tools: 7
  Tools:
    - get_logs
    - get_source_location
    - get_docs
    - project_eval
    - execute_sql_query
    - get_ecto_schemas
    - search_package_docs
```

### Step 5: Use Kimi with Tidewave

Now when you run Kimi in your project directory, it has access to Tidewave's runtime tools.

**To verify MCP is loaded in your session:**

When you start Kimi, you should see the MCP tools loaded in the startup message, or you can check by asking Kimi to list available tools.

You can verify by asking Kimi something like:
> "List the MCP tools you have access to"


You can ask Kimi to:
- Query your database
- Execute code in your running app
- Find source locations
- Check logs

## Available MCP Tools

| Tool                  | Description                            | Example                          |
| --------------------- | -------------------------------------- | -------------------------------- |
| `execute_sql_query`   | Run SQL queries against your database  | "Count units by faction"         |
| `project_eval`        | Execute Elixir code in the running app | "Test the eco ratio calculation" |
| `get_logs`            | View application logs                  | "Show recent errors"             |
| `get_source_location` | Find where code is defined             | "Find FafCn.Units module"        |
| `get_docs`            | Read documentation                     | "Check Units.list_units docs"    |
| `get_ecto_schemas`    | List all Ecto schemas                  | "Show all database models"       |
| `search_package_docs` | Search Hex documentation               | "Look up Phoenix docs"           |

## Troubleshooting

### Test the MCP endpoint directly

```bash
curl -v http://localhost:4000/tidewave/mcp \
  --header 'Content-Type: application/json' \
  --header "Accept: application/json, text/event-stream" \
  --data '{"jsonrpc":"2.0","id":1,"method":"ping"}'
```

Expected response:
```json
{"id":1,"result":{},"jsonrpc":"2.0"}
```

### Common Issues

| Issue                                     | Solution                                                                                                |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `MCP server 'tidewave' not found`         | `kimi mcp test` doesn't support `--mcp-config-file`. Use curl or check inside Kimi session (see Step 4) |
| `Connection refused`                      | Ensure Phoenix server is running with `mix phx.server`                                                  |
| `404 Not Found`                           | Check that `plug Tidewave` is in your endpoint and you're in `:dev` environment                         |
| `MCP tools not showing`                   | **Restart Kimi CLI** - MCP servers load at startup, not dynamically                                     |
| `kimi command not found`                  | Install Kimi CLI first (see Prerequisites)                                                              |
| `MCP connection errors in other projects` | This happens if Tidewave is in `~/.kimi/mcp.json`. Use project-local config (see Step 2)                |

### View MCP configuration

```bash
# List globally configured MCP servers
kimi mcp list

# View global config file
cat ~/.kimi/mcp.json

# View this project's local MCP config (from project root)
cat .kimi/mcp.json
```

### MCP tools not available in current session

**Problem:** You added the MCP server but Kimi doesn't seem to have access to the tools in your current session.

**Solution:** Exit Kimi and start a new session. MCP servers are loaded when Kimi starts, not dynamically during a session:

```bash
# Exit current session
exit

# Start new session (MCP will be loaded)
kimi
```

### Reset MCP configuration

Since we use project-local MCP configuration (not global), there's no need to remove/add via `kimi mcp` commands. The configuration is stored in `.kimi/mcp.json` within this project.

If you previously added Tidewave to the global config and want to clean it up:

```bash
# Remove Tidewave from global MCP config (if you had added it before)
kimi mcp remove tidewave
```

Then use the project-local config as described in Step 2 above.

## Quick Reference

### Essential Commands

**Start Phoenix server (Terminal 1):**
```bash
cd /home/zw/code/elixir_programming/faf_cn
mix phx.server
```

**Start Kimi with Tidewave (Terminal 2):**
```bash
cd /home/zw/code/elixir_programming/faf_cn
kimi --mcp-config-file .kimi/mcp.json
```

**Verify Tidewave is running (Terminal 2):**
```bash
curl -X POST http://localhost:4000/tidewave/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
```

**Inside Kimi session:**
- Type `/mcp` to view connected MCP servers and tools
- Ask: "List the MCP tools you have access to"

### Project Structure

```
faf_cn/
├── .kimi/
│   └── mcp.json          # Project-local MCP configuration
├── lib/
│   └── faf_cn_web/
│       └── endpoint.ex   # Contains: if Mix.env() == :dev do plug Tidewave end
├── mix.exs               # Contains: {:tidewave, "~> 0.5", only: :dev}
└── dev_log/
    └── integrate_with_tidewave.md  # This guide
```

## References

- [Tidewave Phoenix Integration](https://github.com/tidewave-ai/tidewave_phoenix)
- [Tidewave MCP Documentation](https://hexdocs.pm/tidewave/mcp.html)
