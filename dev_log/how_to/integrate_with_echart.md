# How To: Integrate JavaScript Libraries with Phoenix LiveView

This guide uses our ECharts integration as an example, but the pattern applies to any JS library integration (markdown editors, maps, date pickers, etc.).

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        LiveView (Server)                         │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │ Event Handlers│───▶│  push_event  │───▶│  WebSocket   │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ WebSocket
┌─────────────────────────────────────────────────────────────────┐
│                     Browser (Client)                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │  LiveSocket  │───▶│   JS Hook    │───▶│  ECharts/JS  │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│         │                  ▲                                     │
│         └──────────────────┘                                     │
│            handleEvent("event-name")                             │
└─────────────────────────────────────────────────────────────────┘
```

**Key Principle**: Server initiates data updates via `push_event`, client receives via `handleEvent`. Avoid using data attributes for dynamic updates.

## Step-by-Step Implementation

### Step 1: Create the JavaScript Hook

Create `assets/js/hooks/your_library.js`:

```javascript
import * as echarts from 'echarts';  // or your library

export default {
  // Called when element is added to DOM
  mounted() {
    // 1. Initialize your library
    this.chart = echarts.init(this.el, null, { renderer: 'svg' });
    
    // 2. Set up initial configuration
    this.setupChart();
    
    // 3. Listen for server-initiated events
    this.handleEvent('chart-data', (payload) => {
      this.updateChart(payload);
    });
    
    // 4. Handle window resize (optional)
    this.resizeHandler = () => this.chart.resize();
    window.addEventListener('resize', this.resizeHandler);
  },
  
  // Called when element is removed from DOM
  destroyed() {
    // Clean up event listeners
    window.removeEventListener('resize', this.resizeHandler);
    
    // Clean up library instance
    if (this.chart) {
      this.chart.dispose();
    }
  },
  
  // Helper: Initial chart setup
  setupChart() {
    const option = {
      // Your library's initial configuration
      title: { text: 'Chart Title' },
      series: []
    };
    this.chart.setOption(option);
  },
  
  // Helper: Update with data from server
  updateChart(payload) {
    const option = {
      xAxis: { data: payload.time },
      series: [
        { name: 'Series 1', data: payload.data1 },
        { name: 'Series 2', data: payload.data2 }
      ]
    };
    this.chart.setOption(option);
  }
}
```

### Step 2: Register the Hook in app.js

Edit `assets/js/app.js`:

```javascript
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import EcoChart from "./hooks/eco_chart"  // Import your hook

const liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: {
    EcoChart  // Register hook - key must match phx-hook attribute
  }
})
```

### Step 3: Create the HEEx Template

**CRITICAL**: Use `phx-update="ignore"` to prevent LiveView from touching the container:

```elixir
<%# lib/my_app_web/live/my_live.ex %>
<div 
  id="unique-chart-id"           <%# Required: unique DOM ID %>
  phx-hook="EcoChart"            <%# Required: matches hook key in app.js %>
  phx-update="ignore"            <%# CRITICAL: tells LiveView to skip this element %>
  class="w-full h-96"            <%# Styling - ensure dimensions! %>
/>
```

**Why `phx-update="ignore"`?**
- LiveView won't patch/modify this element during updates
- Your JS library has full control over the DOM inside
- Prevents conflicts between LiveView's DOM diffing and library's DOM manipulation

### Step 4: Send Data from LiveView

Use `push_event/3` to send data to the hook:

```elixir
def handle_info(:tick, socket) do
  # ... calculate new data ...
  
  socket =
    socket
    |> assign(:data, new_data)
    |> push_event("chart-data", %{    # Event name matches handleEvent in JS
      time: time_data,
      mass: mass_data,
      energy: energy_data,
      show_mass: socket.assigns.show_mass
    })
  
  {:noreply, socket}
end
```

**Important**: `push_event` sends data immediately via WebSocket - no page reload, no full re-render.

### Step 5: Handle Events from Client to Server (Optional)

If your library needs to send events back to the server:

```javascript
// In your hook's mounted()
this.chart.on('click', (params) => {
  // Send event to server
  this.pushEvent('chart-clicked', { 
    name: params.name,
    value: params.value 
  });
});
```

```elixir
# In LiveView
def handle_event("chart-clicked", %{"name" => name, "value" => value}, socket) do
  # Handle the client-side event
  {:noreply, socket}
end
```

## Complete Working Example

### JavaScript Hook (assets/js/hooks/eco_chart.js)

```javascript
import * as echarts from 'echarts';

export default {
  mounted() {
    // Initialize
    this.chart = echarts.init(this.el, null, { renderer: 'svg' });
    
    // Setup
    this.setupChart();
    
    // Listen for server events
    this.handleEvent('chart-data', (payload) => {
      this.updateChart(payload);
    });
    
    // Window resize
    this.resizeHandler = () => this.chart.resize();
    window.addEventListener('resize', this.resizeHandler);
  },
  
  destroyed() {
    window.removeEventListener('resize', this.resizeHandler);
    if (this.chart) this.chart.dispose();
  },
  
  setupChart() {
    this.chart.setOption({
      title: { text: 'Eco Over Time', left: 'center' },
      xAxis: { type: 'category', data: [] },
      yAxis: { type: 'value' },
      series: [
        { name: 'Mass', type: 'line', data: [] },
        { name: 'Energy', type: 'line', data: [] }
      ]
    });
  },
  
  updateChart(payload) {
    // If no data, show sample
    if (!payload.time || payload.time.length === 0) {
      this.chart.setOption({
        xAxis: { data: [1, 2, 3, 4, 5] },
        series: [
          { name: 'Mass', data: [100, 150, 200, 250, 300] },
          { name: 'Energy', data: [1000, 1100, 1200, 1300, 1400] }
        ]
      });
      return;
    }
    
    // Update with real data
    this.chart.setOption({
      xAxis: { data: payload.time },
      series: [
        { name: 'Mass', data: payload.show_mass ? payload.mass : [] },
        { name: 'Energy', data: payload.show_energy ? payload.energy : [] }
      ]
    });
  }
}
```

### LiveView (lib/my_app_web/live/simulation_live.ex)

```elixir
defmodule MyAppWeb.SimulationLive do
  use MyAppWeb, :live_view
  
  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, 
      chart_data: %{time: [], mass: [], energy: []},
      show_mass: true,
      show_energy: true
    )}
  end
  
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div 
        id="eco-chart"
        phx-hook="EcoChart"
        phx-update="ignore"
        class="w-full h-96"
      />
      
      <button phx-click="run_simulation">Run</button>
      <button phx-click="reset">Reset</button>
      
      <label>
        <input type="checkbox" phx-click="toggle_mass" checked={@show_mass} />
        Show Mass
      </label>
    </div>
    """
  end
  
  @impl true
  def handle_event("run_simulation", _params, socket) do
    # Start simulation logic...
    # Send initial data
    socket = push_event(socket, "chart-data", %{
      time: [1, 2, 3],
      mass: [100, 150, 200],
      energy: [1000, 1100, 1200],
      show_mass: socket.assigns.show_mass,
      show_energy: socket.assigns.show_energy
    })
    
    {:noreply, socket}
  end
  
  @impl true
  def handle_event("toggle_mass", _params, socket) do
    new_val = !socket.assigns.show_mass
    
    socket =
      socket
      |> assign(:show_mass, new_val)
      |> push_event("chart-data", %{    # Push updated visibility
        time: socket.assigns.chart_data.time,
        mass: socket.assigns.chart_data.mass,
        energy: socket.assigns.chart_data.energy,
        show_mass: new_val,
        show_energy: socket.assigns.show_energy
      })
    
    {:noreply, socket}
  end
  
  @impl true
  def handle_event("reset", _params, socket) do
    socket =
      socket
      |> assign(:chart_data, %{time: [], mass: [], energy: []})
      |> push_event("chart-data", %{    # Send empty to reset chart
        time: [], mass: [], energy: [],
        show_mass: true, show_energy: true
      })
    
    {:noreply, socket}
  end
end
```

## Best Practices

### 1. Always Use `phx-update="ignore"`

```elixir
<%# Good %>
<div phx-hook="MyChart" phx-update="ignore" />

<%# Bad - LiveView will patch and break your chart %>
<div phx-hook="MyChart" />
```

### 2. Always Use `push_event` for Dynamic Data

```elixir
<%# Good - server pushes via WebSocket %>
|> push_event("chart-data", %{time: data})

<%# Bad - data attributes trigger updated() callback conflicts %>
data-time={Jason.encode!(@data)}
```

### 3. Always Clean Up in `destroyed()`

```javascript
destroyed() {
  // Remove event listeners
  window.removeEventListener('resize', this.handler);
  
  // Dispose library instances
  if (this.chart) this.chart.dispose();
  
  // Clear any intervals/timeouts
  clearInterval(this.interval);
}
```

### 4. Ensure Container Has Dimensions

```css
/* CSS - ensure the container has size */
.chart-container {
  width: 100%;
  height: 400px;  /* Fixed height required! */
}
```

```javascript
// Or check in mounted()
mounted() {
  if (this.el.clientWidth === 0 || this.el.clientHeight === 0) {
    console.error('Chart container has no dimensions!');
  }
}
```

### 5. Handle Visibility Toggles Properly

When toggling visibility, send the current data plus the new toggle state:

```elixir
def handle_event("toggle", _, socket) do
  new_visible = !socket.assigns.visible
  
  socket
  |> assign(:visible, new_visible)
  |> push_event("chart-data", %{
    # Send current data + new visibility
    data: socket.assigns.data,
    visible: new_visible
  })
end
```

## Common Pitfalls

### ❌ Using `updated()` Callback

```javascript
// DON'T DO THIS
export default {
  updated() {
    // Conflicts with LiveView's DOM patching
    this.chart.setOption(newData);
  }
}
```

### ❌ Forgetting `phx-update="ignore"`

Without this, LiveView will patch your chart element and break the library.

### ❌ Not Converting Booleans in Data Attributes

```elixir
<%# Renders as data-active="" (empty string) %>
data-active={@active}

<%# Renders correctly as data-active="true" %>
data-active={to_string(@active)}
```

### ❌ Missing Unique ID

```elixir
<%# Bad - no ID %>
<div phx-hook="Chart" phx-update="ignore" />

<%# Good - unique ID required %>
<div id="chart-<%= @id %>" phx-hook="Chart" phx-update="ignore" />
```

## Quick Reference

| Pattern | When to Use |
|---------|-------------|
| `push_event` + `handleEvent` | Dynamic data updates from server |
| `phx-update="ignore"` | When JS library manages the DOM |
| `phx-hook` | To attach JS behavior to an element |
| `mounted()` / `destroyed()` | Initialize and cleanup JS library |
| `this.pushEvent()` (JS) | Send events from client to server |
| `handle_event()` (Elixir) | Receive events from client |

## Related Documentation

- [Phoenix LiveView JS Interop](https://hexdocs.pm/phoenix_live_view/js-interop.html)
- [ECharts Documentation](https://echarts.apache.org/en/option.html)
- [Troubleshooting: ECharts Integration](../troubleshooting/integration_with_echart.md)
