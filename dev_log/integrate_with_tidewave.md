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

## Setup Steps

### Step 1: Start Phoenix Server

Start your Phoenix server in development mode:

```bash
cd /home/zw/code/elixir_programming/faf_cn
mix phx.server
```

The MCP endpoint is now available at: `http://localhost:4000/tidewave/mcp`

### Step 2: Configure Kimi CLI

In a **new terminal window** (keep the Phoenix server running), add Tidewave as an MCP server:

```bash
kimi mcp add --transport http tidewave http://localhost:4000/tidewave/mcp
```

This creates the MCP configuration at `~/.kimi/mcp.json`.

### Step 3: Restart Kimi CLI

**Important:** If Kimi CLI is currently running, you need to **exit and restart it** to load the new MCP configuration.

```bash
# Exit current Kimi session (if running)
# Then start a new session:
kimi
```

### Step 4: Verify the Connection

Test that Kimi can connect to Tidewave:

```bash
kimi mcp test tidewave
```

Expected output:
```
Testing connection to 'tidewave'...
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

```bash
kimi
```

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

| Issue                    | Solution                                                                        |
| ------------------------ | ------------------------------------------------------------------------------- |
| `Connection refused`     | Ensure Phoenix server is running with `mix phx.server`                          |
| `404 Not Found`          | Check that `plug Tidewave` is in your endpoint and you're in `:dev` environment |
| `MCP tools not showing`  | **Restart Kimi CLI** - MCP servers load at startup, not dynamically              |
| `kimi command not found` | Install Kimi CLI first (see Prerequisites)                                      |

### View MCP configuration

```bash
# List configured MCP servers
kimi mcp list

# View config file
cat ~/.kimi/mcp.json
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

If you need to reconfigure:

```bash
# Remove Tidewave MCP server
kimi mcp remove tidewave

# Re-add it
kimi mcp add --transport http tidewave http://localhost:4000/tidewave/mcp
```

## References

- [Tidewave Phoenix Integration](https://github.com/tidewave-ai/tidewave_phoenix)
- [Tidewave MCP Documentation](https://hexdocs.pm/tidewave/mcp.html)
