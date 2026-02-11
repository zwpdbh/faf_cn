# Troubleshooting: ECharts Integration with Phoenix LiveView

## Problem Statement

The ECharts simulation chart was not rendering when dynamic data was pushed during the simulation, even though:
- The chart rendered correctly with static/fixed data on page load
- The time counter was updating correctly
- Server logs showed data was being generated and sent
- Browser console showed the data arrays were populated

## Symptoms

1. **Initial page load**: Fixed sample data rendered correctly (5 data points)
2. **Click "Run Simulation"**: Time counter updated, but chart remained showing static data
3. **Browser console**: Showed data arrays with correct values (e.g., `[1,2,3...128]` for time)
4. **Visibility toggles**: All showed `false` despite being set to `true` in assigns

## Root Causes

### 1. HEEx Boolean Rendering Issue

**Problem**: In HEEx templates, boolean values in data attributes render as empty strings:

```elixir
<%# BAD - renders as data-show-mass="" %>
data-show-mass={@show_mass}

<%# GOOD - renders as data-show-mass="true" %>
data-show-mass={to_string(@show_mass)}
```

**Impact**: JavaScript received empty strings for visibility toggles, causing `dataset.showMass === 'true'` to return `false`, which hid all chart lines.

### 2. LiveView Update Cycle Conflict

**Problem**: Calling `echarts.setOption()` during LiveView's `updated()` callback causes conflicts:

```javascript
// BAD - causes "setOption should not be called during main process" error
updated() {
  this.chart.setOption(newData);
}
```

**Why**: LiveView's DOM patching and echarts' internal rendering happen in the same frame, causing race conditions and null pointer errors.

### 3. Data Attribute Size Limitations

**Problem**: Large data arrays in data attributes can cause issues:
- String serialization/deserialization overhead
- DOM attribute size limits (though not hit here)
- Difficulty debugging complex nested data

## Solution

### Architecture Change: Server-Initiated Events

Instead of using data attributes that trigger `updated()` callback, use LiveView's `push_event`:

**Before (Broken)**:
```elixir
# template.heex
<div phx-hook="EcoChart"
     data-time={Jason.encode!(@chart_data.time)}
     data-mass={Jason.encode!(@chart_data.mass)}
     ...
/>
```

```javascript
// hook.js
export default {
  updated() {
    // This conflicts with LiveView's DOM updates
    const data = JSON.parse(this.el.dataset.time);
    this.chart.setOption({...});
  }
}
```

**After (Working)**:
```elixir
# live_view.ex
# In tick handler or event handlers:
socket 
|> push_event("chart-data", %{
  time: chart_data.time,
  mass: chart_data.mass,
  energy: chart_data.energy,
  build_power: chart_data.build_power,
  show_mass: show_mass,
  show_energy: show_energy,
  show_build_power: show_build_power
})
```

```elixir
# template.heex - note phx-update="ignore"
<div id="eco-chart"
     phx-hook="EcoChart"
     phx-update="ignore"
/>
```

```javascript
// hook.js
export default {
  mounted() {
    this.chart = echarts.init(this.el, null, { renderer: 'svg' });
    this.setupChart();
    
    // Listen for server-initiated events
    this.handleEvent('chart-data', (payload) => {
      this.updateChart(payload);
    });
  },
  
  // No updated() callback needed!
}
```

## Key Implementation Details

### 1. Use `phx-update="ignore"`

This prevents LiveView from touching the chart container, avoiding DOM conflicts:

```elixir
<div id="eco-chart" phx-hook="EcoChart" phx-update="ignore" />
```

### 2. State Machine for Simulation Control

Use pattern matching to prevent race conditions:

```elixir
# Only handle tick when in running state with valid state
def handle_info(:tick, %{assigns: %{simulation_state: :running, simulator_state: %State{} = state}} = socket) do
  # ... process tick
end

# Ignore ticks in other states
def handle_info(:tick, socket), do: {:noreply, socket}
```

### 3. Always Convert Booleans to Strings in HEEx

```elixir
# For data attributes
data-show-mass={to_string(@show_mass)}

# For regular boolean props (not in data attrs), inspect works too
:checked={@show_mass}  # This works for input checkbox
```

## Lessons Learned

1. **Avoid `updated()` for chart libraries**: Use `push_event` + `handleEvent` instead
2. **Use `phx-update="ignore"`**: When JS manages the DOM, tell LiveView to stay away
3. **Check data attribute rendering**: HEEx renders booleans as empty strings - always use `to_string/1`
4. **Debug visibility issues**: Check both raw dataset values AND parsed values
5. **Defer to requestAnimationFrame**: If you must update in callbacks, defer to next frame

## Related Files

- `lib/faf_cn_web/live/eco_prediction_live.ex` - Simulation logic and event pushing
- `assets/js/hooks/eco_chart.js` - ECharts hook implementation
- `lib/faf_cn/eco_engine/` - Simulation engine modules
