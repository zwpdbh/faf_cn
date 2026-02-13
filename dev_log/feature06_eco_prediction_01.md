# Feature06: Eco Prediction Part01 -- UI

Goal-oriented economy simulator that calculates time required to afford target units based on current eco stats.
This is part one -- which focus on settle down the UI part to determine how user should use this page.

**URL**: http://localhost:4000/eco-prediction

---

## Phase 01: ECharts Integration ✅

Basic chart with static demo data.


## Phase 02: Goal-Oriented Design ✅ COMPLETED

### User Flow Implemented

1. **Set Initial Eco** (Left Column, Top Card)
   - Mass income/s, Energy income/s
   - T1/T2/T3 engineer counts
   - Current/Max Mass storage
   - Current/Max Energy storage

2. **Select Unit** (Left Column, Unit Grid)
   - Faction tabs (UEF/CYBRAN/AEON/SERAPHIM)
   - Filter bar (Engineer/Structure/Land/Air/Naval, T1/T2/T3/EXP)
   - Unit grid with faction-colored backgrounds (same as Eco Guides)

3. **Set Goal** (Right Column, Goal Panel)
   - Selected unit display with icon
   - Quantity input
   - Total cost calculation (Mass × Qty, Energy × Qty)
   - **Run Simulation** button

4. **View Results** (Right Column + Full Width)
   - **Timeline Card**: Vertical timeline from start to goal completion
   - **Chart Card**: Toggle between Mass/Energy views
     - Shows accumulated resources over time
     - Goal line (dashed horizontal)
     - Time to completion in header

### UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│                    Faction Tabs (UEF/CYBRAN/AEON/SERAPHIM)  │
├──────────────────────────────┬──────────────────────────────┤
│  1. Set Initial Eco          │  Selected Unit + Goal        │
│  ┌────────────────────────┐  │  ┌────────────────────────┐  │
│  │ Mass | Energy          │  │  │ [Unit Icon]            │  │
│  │ [income] [storage/max] │  │  │ Name: XYZ              │  │
│  └────────────────────────┘  │  │ Cost: 100M / 500E      │  │
│  ┌────────────────────────┐  │  │ Quantity: [___]        │  │
│  │ Engineers T1/T2/T3     │  │  │ Total: 300M / 1500E    │  │
│  └────────────────────────┘  │  │ [Run Simulation]       │  │
│                              │  └────────────────────────┘  │
│  2. Select Units             │                              │
│  ┌────────────────────────┐  │  Timeline (when results)     │
│  │ [Filter Bar]           │  │  ┌────────────────────────┐  │
│  │                        │  │  │ ● 0:00 Start           │  │
│  │ [Unit Grid]            │  │  │ ○ 2:30 Mass storage    │  │
│  │                        │  │  │ ○ 4:15 Energy ready    │  │
│  │                        │  │  │ ● 5:47 Goal Complete   │  │
│  └────────────────────────┘  │  └────────────────────────┘  │
├──────────────────────────────┴──────────────────────────────┤
│  Resource Accumulation Over Time (when results)             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ [Mass] [Energy] Toggle Buttons                        │  │
│  │                                                       │  │
│  │         [ECharts Line Chart]                          │  │
│  │         - Accumulated resource over time              │  │
│  │         - Goal line (dashed)                          │  │
│  │                                                       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Technical Implementation

**Files Created/Modified:**
- `lib/faf_cn_web/live/eco_prediction_live.ex` - Main LiveView
- `assets/js/hooks/eco_chart.js` - ECharts hook with toggle support
- `lib/faf_cn/eco_engine/` - Simulation engine (to be implemented)

**Key Components:**
- `initial_eco_card/1` - Mass/Energy/Engineer inputs
- `unit_selection_card/1` - Faction tabs + filter bar + unit grid
- `goal_panel/1` - Selected unit + quantity + run button
- `timeline_card/1` - Vertical milestone timeline
- `eco_chart_card/1` - Toggleable Mass/Energy charts

**Chart Features:**
- Toggle between Mass and Energy views
- Smooth area fill under curves
- Goal line (dashed horizontal with label)
- Time formatter (M:SS)
- Value formatter (k/M suffixes)

---

### Quick Test

```bash
mix phx.server
open http://localhost:4000/eco-prediction
```

1. Set initial eco (Mass: 10/s, Energy: 100/s, Engineers: 5/0/0)
2. Select a unit from the grid
3. Set quantity (e.g., 1)
4. Click "Run Simulation"
5. Toggle between Mass/Energy chart views
