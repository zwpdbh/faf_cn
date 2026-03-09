# Integrating Live React with React Flow

This guide documents how to integrate React components (specifically React Flow) with Phoenix LiveView using `live_react`.

## Overview

We use `@mrdotb/live-react` to embed React components inside LiveView. This allows us to:
- Build complex interactive UIs with React
- Maintain server-side state with LiveView
- Bidirectional communication between React and LiveView

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   LiveView      │────▶│   live_react     │────▶│  React Component│
│  (Elixir)       │◀────│   (JS Hook)      │◀────│  (React Flow)   │
└─────────────────┘     └──────────────────┘     └─────────────────┘
       │                                                      │
       │         pushEvent ─────────────────▶                 │
       │◀────────────────────  handle_event                   │
```

## Installation

### 1. Add Dependency

```elixir
# mix.exs
defp deps do
  [
    {:live_react, "~> 0.1"},
    # ... other deps
  ]
end
```

### 2. Configure esbuild for JSX/TypeScript

```elixir
# config/config.exs
config :esbuild,
  version: "0.25.4",
  faf_cn: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js 
         --external:/fonts/* --external:/images/* 
         --alias:@=. --loader:.js=jsx --loader:.ts=tsx 
         --resolve-extensions=.tsx,.ts,.jsx,.js),
    cd: Path.expand("../assets", __DIR__),
    env: %{
      "NODE_PATH" => [
        Path.expand("../deps", __DIR__),
        Path.expand("../assets/node_modules", __DIR__)
      ]
    }
  ]
```

### 3. Add npm Dependencies

```json
// assets/package.json
{
  "dependencies": {
    "@mrdotb/live-react": "^0.1.0",
    "@xyflow/react": "^12.0.0",
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  }
}
```

### 4. Configure JavaScript Entry Point

```javascript
// assets/js/app.js
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import { getHooks } from "@mrdotb/live-react"

// Import React components
import * as Components from "./components"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

const hooks = {
  ...getHooks(Components),
}

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: hooks
})

liveSocket.connect()
window.liveSocket = liveSocket
```

### 5. Export React Components

```typescript
// assets/js/components/index.ts
export { WorkflowEditor } from './workflow';
export type { WorkflowEditorProps, WorkflowNodeData } from './workflow';
```

### 6. Enable in Elixir

```elixir
# lib/faf_cn_web.ex
defp html_helpers do
  quote do
    # ... other imports
    import LiveReact
  end
end
```

## Creating a React Component

### React Component Structure

```typescript
// assets/js/components/workflow/WorkflowEditor.tsx
import * as React from 'react';
import {
  ReactFlow,
  ReactFlowProvider,
  useNodesState,
  useEdgesState,
  type Node,
  type Edge,
} from '@xyflow/react';
import '@xyflow/react/dist/style.css';

export interface WorkflowEditorProps {
  initialNodes?: Array<Node>;
  initialEdges?: Array<Edge>;
  readonly?: boolean;
  pushEvent?: (event: string, payload?: Record<string, unknown>) => void;
}

const WorkflowEditorInner: React.FC<WorkflowEditorProps> = ({
  initialNodes = [],
  initialEdges = [],
  readonly = false,
  pushEvent,
}) => {
  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState(initialEdges);

  // Handle node click - send to LiveView
  const handleNodeClick = React.useCallback(
    (_event: React.MouseEvent, node: Node) => {
      pushEvent?.('node_clicked', { nodeId: node.id, data: node.data });
    },
    [pushEvent]
  );

  return (
    <div className="h-full w-full">
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={readonly ? undefined : onNodesChange}
        onEdgesChange={readonly ? undefined : onEdgesChange}
        onNodeClick={handleNodeClick}
        fitView
      />
    </div>
  );
};

const WorkflowEditor: React.FC<WorkflowEditorProps> = (props) => {
  return (
    <ReactFlowProvider>
      <WorkflowEditorInner {...props} />
    </ReactFlowProvider>
  );
};

export default WorkflowEditor;
```

## LiveView Integration

### Basic Usage

```elixir
# lib/faf_cn_web/live/eco_workflow_editor_live.ex
defmodule FafCnWeb.EcoWorkflowEditorLive do
  use FafCnWeb, :live_view
  import LiveReact

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:nodes, default_nodes())
     |> assign(:edges, default_edges())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.fullscreen flash={@flash}>
      <.react
        name="WorkflowEditor"
        initialNodes={@nodes}
        initialEdges={@edges}
        readonly={@readonly}
        class="w-full h-full"
      />
    </Layouts.fullscreen>
    """
  end

  # Handle events from React
  @impl true
  def handle_event("node_clicked", %{"nodeId" => node_id, "data" => data}, socket) do
    {:noreply,
     socket
     |> assign(:selected_node_id, node_id)
     |> assign(:selected_node_data, data)}
  end
end
```

## Communication Patterns

### React → LiveView (pushEvent)

From React component:

```typescript
// React side
const handleNodeClick = (node) => {
  pushEvent?.('node_clicked', { 
    nodeId: node.id, 
    data: node.data 
  });
};
```

Handled in LiveView:

```elixir
# LiveView side
@impl true
def handle_event("node_clicked", %{"nodeId" => id, "data" => data}, socket) do
  {:noreply, assign(socket, selected_node: id)}
end
```

### LiveView → React (Props)

Update assigns in LiveView:

```elixir
{:noreply, 
 socket 
 |> assign(:nodes, new_nodes)
 |> assign(:edges, new_edges)}
```

React receives updates via props:

```typescript
React.useEffect(() => {
  setNodes(initialNodes);
}, [initialNodes]);
```

## Asset Pipeline

### Static Asset Configuration

```elixir
# lib/faf_cn_web.ex
def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)
```

### Copying Vendor Assets

```elixir
# mix.exs
"assets.copy_vendor": fn _ ->
  File.mkdir_p!("priv/static/assets/js")
  File.mkdir_p!("priv/static/assets/css")
  File.cp!("assets/vendor/topbar.js", "priv/static/assets/js/topbar.js")
  File.cp!("assets/vendor/react-flow.css", "priv/static/assets/css/react-flow.css")
  :ok
end
```

### Root Layout

```html
<!-- lib/faf_cn_web/components/layouts/root.html.heex -->
<link phx-track-static rel="stylesheet" href={~p"/assets/css/app.css"} />
<link phx-track-static rel="stylesheet" href={~p"/assets/css/react-flow.css"} />
<script defer phx-track-static type="text/javascript" src={~p"/assets/js/topbar.js"}></script>
<script defer phx-track-static type="text/javascript" src={~p"/assets/js/app.js"}></script>
```

## Key Files Summary

| File | Purpose |
|------|---------|
| `assets/js/app.js` | Entry point, configures LiveSocket with live_react hooks |
| `assets/js/components/index.ts` | Exports React components for live_react |
| `assets/js/components/workflow/` | React Flow components |
| `assets/vendor/react-flow.css` | React Flow base styles |
| `assets/package.json` | npm dependencies (react, @xyflow/react, @mrdotb/live-react) |
| `lib/faf_cn_web.ex` | Imports LiveReact in html_helpers |
| `lib/faf_cn_web/live/*_live.ex` | LiveViews using `<.react>` component |
| `config/config.exs` | esbuild configuration for JSX/TS |

## Troubleshooting

### WebSocket Connection Issues

If you see "We can't find the internet" error:
- Check asset paths in `root.html.heex`
- Verify static file serving in endpoint
- Ensure `check_origin` is configured correctly

### React Component Not Rendering

- Check component is exported in `components/index.ts`
- Verify component name matches `name` attribute in `<.react>`
- Check browser console for JS errors

### Styling Issues

- React Flow styles must be loaded via separate CSS file
- Vendor CSS should be copied to `priv/static/assets/css/`
- Tailwind v4 uses different class names than v3

## References

- [live_react on Hex](https://hex.pm/packages/live_react)
- [React Flow Documentation](https://reactflow.dev/)
- [Phoenix LiveView JS Interop](https://hexdocs.pm/phoenix_live_view/js-interop.html)
