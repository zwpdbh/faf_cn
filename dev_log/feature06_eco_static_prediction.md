# Feature06: Static Eco Prediction

## Overview

A real-time economy simulator that visualizes how a player's resources (mass, energy, build power) change throughout a Forged Alliance match.

## Goal

- **New Section**: "Eco Prediction" in the navigation
- **Core Functionality**: 
  - Simulate eco stats a user experiences through a game
  - Visualize resource changes over time with real-time charts
- **Chart Display**:
  - **Horizontal X-axis**: Time (in-game seconds)
  - **Vertical Y-axis**:
    - Current Mass
    - Current Energy
    - Current Build Power

---

## Phase 01: ECharts Integration (Completed)

### What Was Implemented

#### 1. ECharts Library Integration
- **Installed**: ECharts via npm (`npm install echarts`)
- **Created**: `assets/js/hooks/eco_chart.js` - Phoenix LiveView hook
- **Features**:
  - Line chart with 3 series (Mass, Energy, Build Power)
  - Interactive tooltips on hover
  - Gradient area fill for Mass
  - Responsive design (handles window resize)
  - SVG renderer for sharp display

#### 2. Eco Prediction Page
- **Route**: `/eco-prediction`
- **LiveView**: `EcoPredictionLive`
- **Demo Data**: Static simulation showing:
  - 2 T1 Mass Extractors (+4 mass/sec)
  - Starting resources: 650 mass, 2500 energy
  - Build queue: 3 T1 Engineers
  - Duration: 5 minutes (300 seconds)

#### 3. Navigation Updates
- **Header**: Added "Eco Prediction" link with chart icon
- **Home Page**: Added new card with gradient styling
- **Icon**: `hero-chart-line` (Heroicons)

### Files Changed

| File                                                  | Change                        |
| ----------------------------------------------------- | ----------------------------- |
| `assets/js/hooks/eco_chart.js`                        | New - ECharts LiveView hook   |
| `assets/js/app.js`                                    | Register EcoChart hook        |
| `lib/faf_cn_web/live/eco_prediction_live.ex`          | New - LiveView with demo data |
| `lib/faf_cn_web/router.ex`                            | Add `/eco-prediction` route   |
| `lib/faf_cn_web/components/layouts.ex`                | Add nav link                  |
| `lib/faf_cn_web/controllers/page_html/home.html.heex` | Add home card                 |
| `assets/package.json`                                 | Add echarts dependency        |

### Technical Details

**Chart Configuration:**
- Library: ECharts (Apache 2.0)
- Type: Line chart with area fill
- X-axis: Time (0-300 seconds)
- Y-axis: Resource amounts
- Colors: Mass (emerald), Energy (amber), Build Power (blue)

**Data Flow:**
```
LiveView assigns chart data → 
JSON encode in data attributes → 
Phoenix hook initializes ECharts → 
Chart renders with animation
```

---

## Phase 02: Real-Time Eco Simulation (In Progress)

### Architecture Decision

**Location**: `lib/faf_cn/eco_engine/` - Dedicated simulation engine module

```
lib/faf_cn/
├── eco_engine/              # Eco simulation engine
│   ├── simulator.ex         # Main tick-based simulation
│   ├── state.ex             # Simulation state struct
│   ├── config.ex            # Starting conditions config
│   └── income.ex            # Income calculations
└── ...
```

**Module Naming**: `FafCn.EcoEngine.{Simulator, State, Config}`

### Features

#### 1. Start Conditions Card
- **Mass Storage**: Input field (default: 650)
- **Energy Storage**: Input field (default: 2500)
- **Mass Extractors**:
  - T1 Mex count (2 mass/sec each)
  - T2 Mex count (6 mass/sec each)  
  - T3 Mex count (18 mass/sec each)

#### 2. Build Order Card
- Unchanged from Phase 01

#### 3. Simulation Result Card
- **Chart Controls** (right side, multi-select):
  - ☑ Mass (emerald)
  - ☑ Energy (amber)
  - ☑ Build Power (blue)
- **Action Buttons**:
  - **[Run]**: Start real-time animation (disabled when running)
  - **[Pause]**: Pause animation (shown when running)
  - **[Reset]**: Stop, clear chart, unlock start conditions (disabled by default)

### Real-Time Animation Flow

```
User clicks [Run]
       ↓
LiveView creates Simulator with Config
       ↓
Start GenServer tick loop (every 100ms = 1 game sec)
       ↓
Each tick: Calculate state → push_event to JS
       ↓
JS receives data → appends to chart progressively
       ↓
[Pause] pauses stream | [Reset] stops and clears
```

### Simulation Logic

```elixir
# Income calculation
defp calculate_income(config) do
  mass = config.t1_mex * 2 + config.t2_mex * 6 + config.t3_mex * 18
  energy = 0  # Simplified: assume sufficient energy
  %{mass: mass, energy: energy}
end

# Tick processing
def tick(state) do
  income = calculate_income(state.config)
  
  %{
    time: state.time + 1,
    mass_storage: state.mass_storage + income.mass,
    energy_storage: state.energy_storage + income.energy,
    # ... process builds, update build power
  }
end
```

### Implementation Plan

| Step | Task | File(s) |
|------|------|---------|
| 1 | Create `Config` struct | `lib/faf_cn/eco_engine/config.ex` |
| 2 | Create `State` struct | `lib/faf_cn/eco_engine/state.ex` |
| 3 | Implement `Simulator` | `lib/faf_cn/eco_engine/simulator.ex` |
| 4 | Update Start Conditions UI | `eco_prediction_live.ex` |
| 5 | Add animation controls | `eco_prediction_live.ex`, `eco_chart.js` |
| 6 | Wire up Run/Pause/Reset | LiveView event handlers |

### Status

- ✅ Completed 2026-02-11

### Files Created/Changed

| File | Change |
|------|--------|
| `lib/faf_cn/eco_engine/config.ex` | NEW - Simulation configuration |
| `lib/faf_cn/eco_engine/state.ex` | NEW - Simulation state struct |
| `lib/faf_cn/eco_engine/simulator.ex` | NEW - Tick-based simulation engine |
| `lib/faf_cn_web/live/eco_prediction_live.ex` | UPDATED - Real-time animation, Run/Pause/Reset |
| `assets/js/hooks/eco_chart.js` | UPDATED - Series toggles, real-time updates |
| `test/faf_cn/eco_engine/config_test.exs` | NEW - Unit tests for Config |
| `test/faf_cn/eco_engine/state_test.exs` | NEW - Unit tests for State |
| `test/faf_cn/eco_engine/simulator_test.exs` | NEW - Unit tests for Simulator |

### Phase 03: Simulation Engine
- Real-time simulation (tick-based)
- Mex-only income model
- Build time calculations
- Resource overflow/stall handling

### Phase 04: Advanced Features
- T2/T3 mex upgrades
- Energy generator simulation
- Save/load build orders
- Compare multiple build orders

---

## Testing

```bash
# Verify all tests pass
mix test
# Result: 125 tests, 0 failures (22 new eco engine tests)

# Run eco engine tests only
mix test test/faf_cn/eco_engine/
# Result: 22 tests, 0 failures

# Verify page loads
curl http://localhost:4000/eco-prediction
# Result: HTTP 200
```

---

**Status**: ✅ Phase 02 Complete  
**Last Updated**: 2026-02-11  
**URL**: http://localhost:4000/eco-prediction

### Quick Test

```bash
# Start server
mix phx.server

# Visit
open http://localhost:4000/eco-prediction

# Try:
# 1. Change T1/T2/T3 mex counts
# 2. Click "Run Simulation"
# 3. Watch real-time chart animation
# 4. Click "Pause" then "Resume"
# 5. Toggle chart series on/off
# 6. Click "Reset" to start over
```
