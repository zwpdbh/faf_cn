# Feature06: Eco Prediction

Goal-oriented economy simulator that calculates time required to afford target units based on current eco stats.

**URL**: http://localhost:4000/eco-prediction

---

## Phase 01: ECharts Integration ✅

Basic chart with static demo data.

---

## Phase 02: Real-Time Simulation ✅ (Deprecated)

Original design with tick-based simulation - replaced by Phase 03.

---

## Phase 03: Goal-Oriented Redesign ✅ COMPLETED

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

## Phase 04: Real Calculation Engine 🔄 NEXT STEP

### Current State
Using dummy data for UI prototyping:
```elixir
%{
  completion_time: 347,  # seconds
  goal_quantity: 1,
  goal_mass: 1500,
  goal_energy: 65000,
  unit_name: "Broadsword",
  milestones: [
    %{time: 0, label: "Start"},
    %{time: 120, label: "Mass storage full"},
    %{time: 234, label: "Energy threshold reached"},
    %{time: 347, label: "Goal Complete"}
  ]
}
```

### Required Implementation

**1. Calculate Total Build Power**
```
Total BP = (T1_eng × 5) + (T2_eng × 10) + (T3_eng × 15)
```

**2. Calculate Build Time for Goal**
```
Unit Build Time = unit.build_time / Total BP
Total Build Time = Unit Build Time × Quantity
```

**3. Calculate Resource Requirements**
```
Total Mass Needed = unit.build_cost_mass × quantity
Total Energy Needed = unit.build_cost_energy × quantity
```

**4. Calculate Time to Accumulate Resources**

Simple version (no storage limits):
```
Time for Mass = Total Mass Needed / mass_income
Time for Energy = Total Energy Needed / energy_income
completion_time = max(Time for Mass, Time for Energy, Total Build Time)
```

Advanced version (with storage limits):
- Track storage filling/emptying
- Handle overflow when storage is full
- Calculate exact moment when both resources are available

**5. Generate Milestones**
- **Start** (time: 0)
- **Storage Full** (if applicable - when mass or energy hits max storage)
- **Resource Threshold** (when accumulated >= required)
- **Goal Complete** (max of resource time and build time)

**6. Generate Chart Data**
```
For each time point t from 0 to completion_time:
  accumulated_mass[t] = min(mass_storage + mass_income × t, mass_storage_max)
  accumulated_energy[t] = min(energy_storage + energy_income × t, energy_storage_max)
```

### Algorithm Outline

```elixir
def run_simulation(initial_eco, unit, quantity) do
  total_mass = unit.build_cost_mass * quantity
  total_energy = unit.build_cost_energy * quantity
  total_bp = calculate_build_power(initial_eco)
  build_time = unit.build_time / total_bp * quantity
  
  # Calculate resource accumulation time
  mass_time = calculate_resource_time(
    total_mass,
    initial_eco.mass_income,
    initial_eco.mass_storage,
    initial_eco.mass_storage_max
  )
  
  energy_time = calculate_resource_time(
    total_energy,
    initial_eco.energy_income,
    initial_eco.energy_storage,
    initial_eco.energy_storage_max
  )
  
  completion_time = max(mass_time, energy_time, build_time)
  
  # Generate time series data
  chart_data = generate_chart_data(initial_eco, completion_time)
  
  # Generate milestones
  milestones = generate_milestones(
    completion_time,
    mass_time,
    energy_time,
    build_time,
    initial_eco
  )
  
  %{
    completion_time: completion_time,
    goal_mass: total_mass,
    goal_energy: total_energy,
    chart_data: chart_data,
    milestones: milestones
  }
end
```

---

## Phase 05: Advanced Features (Future)

- Multiple sequential goals
- Energy generator simulation (income changes over time)
- Mass extractor upgrades during build
- Save/load scenarios
- Share results via URL

---

**Status**: ✅ Phase 03 Complete, 🔄 Phase 04 Ready to Implement  
**Last Updated**: 2026-02-11

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
