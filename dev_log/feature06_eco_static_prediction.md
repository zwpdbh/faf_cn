# Feature06: Eco Prediction

Real-time economy simulator visualizing resource changes (mass, energy, build power) throughout a Forged Alliance match.

**URL**: http://localhost:4000/eco-prediction

---

## Phase 01: ECharts Integration ✅

Basic chart with static demo data.

---

## Phase 02: Real-Time Simulation ✅

### New Features

**Start Conditions** (editable when simulation is idle):
- T1/T2/T3 Mass Extractor count inputs
- Mass/Energy storage starting values
- Max duration input (default: 20 min, min: 1 min, max: 60 min)

**Simulation Controls**:
- **Run** button - start simulation
- **Pause/Resume** buttons - pause and continue
- **Reset** button - stop and clear

**Chart Controls**:
- Checkboxes to toggle Mass/Energy/Build Power visibility

**Real-time Display**:
- Live time counter: "Time: {current}s / {max}s"
- Status indicator: (Running), (Paused), or idle
- Progressive line chart animation

### Technical Implementation

- **Simulation Engine**: `lib/faf_cn/eco_engine/` - tick-based simulator (100ms = 1 game second)
- **State Machine**: `:idle` → `:running` ↔ `:paused`
- **Chart Integration**: Server pushes data via `push_event`, client renders via ECharts

See:
- Implementation guide: [`how_to/integrate_with_echart.md`](./how_to/integrate_with_echart.md)
- Troubleshooting: [`troubleshooting/integration_with_echart.md`](./troubleshooting/integration_with_echart.md)

---

## Phase 03: Goal-Oriented Redesign (Current Focus)

Based on user feedback, pivoting to a goal-oriented design:

### User Flow
1. **Select Goal Unit** - Pick unit from FAF database (reuse Eco Guide selector)
2. **Set Quantity** - How many units to build
3. **Set Current Eco** - Mass/s, Energy/s, engineer count, storage levels
4. **Run Simulation** → **Instant Result** (no real-time animation)

### Key Design Change: No Real-Time Simulation
- ❌ Remove: Tick-by-tick simulation with live updates
- ❌ Remove: Run/Pause/Reset state machine
- ❌ Remove: Timer intervals and progressive chart animation
- ✅ **Single calculation** - Engine runs to completion instantly
- ✅ **One UI update** - All chart data pushed at once
- ✅ **Simpler UX** - Click run, see complete result immediately

### Outputs
- Line chart: mass/s, energy/s, build power, accumulated totals over time
- **Vertical Timeline** - Milestones from start to goal completion

### Technical Changes
- Remove: T1/T2/T3 mex count inputs (calculate from engineers)
- Remove: `handle_info(:tick, ...)` and interval-based updates
- Add: Unit cost lookup from database
- Add: Build time calculation using available BP
- Add: Single `run_simulation/1` function returning complete dataset

---

## Phase 04: Advanced Features (Future)

- Energy generator simulation
- Multiple goals in sequence
- Save/load scenarios

---

**Status**: 🔄 Phase 03 In Progress (Redesign)  
**Last Updated**: 2026-02-12

### Quick Test

```bash
mix phx.server
open http://localhost:4000/eco-prediction
```


## Eco static prediction refactor

Review currently implemented
- Good: echart integration is good.
- Bad: Usage is not clear. Current design could not guide user to achieve a useful result.

Let's design how user should use this "Eco Prediction". 
- User select a unit from FAF unit, user also fill how many of it it need to built.
  - The UI selection should be same as the one in "Select Units to Compare" displayed in "Eco Guide" page.
  - This is the goal of user what to achieve.
- Use set current eco stats
  - mass/s
  - energy/s
  - how many t1, t2, and t3 engineers
  - current power storage:  m power within n storage 
  - current mass storage: m mass within n storage
- User click run simulation
  - UI show the char which following stats over time
    - mass per second
    - enery per second
    - build power 
    - accumulated generated mass (totoal mass)
    - accumulated generated energy (total energy)
  - Let user select to disply which one.
- Build order card now display a timeline
  - timeline displayed vertically
  - Top is the moment of start
  - Down is the moment of user's goal is achieved
  - We could draw the unit or important mile stone achieved on the timeline write.


## UI desgin 

- Almost same with Eco Guides with comparing differences
- The Card which shows the Base unit become the card to show the inital eco seting with title: 1. set inital eco 
- The Card "Select Units to Compare" should show unit as it is. Card title from "Select Units to Compare" change to "2. Select Units"
- The right column Eco Comparison part shows the selected unit and let use to specify a quanlity for it.
  - The "Quick Stats" part could become "run simulation"
  - Draw time line by extending the card.