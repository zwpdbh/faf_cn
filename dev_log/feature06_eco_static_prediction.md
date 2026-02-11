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

## Phase 03: Build Order (Planned)

- Build order definition with build times
- Resource stall/overflow detection

---

## Phase 04: Advanced Features (Future)

- Energy generator simulation
- Save/load build orders

---

**Status**: ✅ Phase 02 Complete  
**Last Updated**: 2026-02-11

### Quick Test

```bash
mix phx.server
open http://localhost:4000/eco-prediction
```
