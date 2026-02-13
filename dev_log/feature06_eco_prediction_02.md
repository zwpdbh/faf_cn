# Feature06: Eco Prediction Part02 -- Algorithm


## Architecture

**Observer-driven tick cycle**: 
Observer advances time → reports to Manager → Manager decides → Builder executes update eco drain to Observer → repeat.

## Agent Responsibilities

### Observer Agent
**Role**: World state keeper. Drives the simulation tick.

**State**: mass_storage, energy_storage, mass_income, energy_income, mass_drain, energy_drain

**Actions**:
- `tick()`: Advance one step, apply income and drain
- `apply_consumption(drain)`: Builder reports consumption
- `get_stats()`: Return current eco snapshot
- Generate warnings: `:mass_overflow`, `:mass_stall`, `:energy_overflow`, `:energy_stall`

### Manager Agent
**Role**: Decision maker. Controls simulation lifecycle.

**State**: goal (unit + qty), expand_directions (mass/energy/bp priorities), current_builds

**Actions**:
- `start(goal, initial_eco)`: Initialize simulation
- `on_tick(eco_stats, warnings)`: Decide next action
- `stop()`: Terminate simulation when goal achieved

**Decision Logic**:
- Goal unit completed? → stop simulation
- Can afford goal? → order Builder to build it
- Mass limited? → order mex/fabber
- Energy limited? → order pgen
- BP limited? → order engineer

### Builder Agent
**Role**: Build executor. Tracks construction progress.

**State**: current_target, build_power, progress_seconds, total_seconds

**Actions**:
- `receive_order({:build, unit})`: Start new build
- `tick()`: Advance progress, report consumption
- `report_consumption()`: Tell Observer upcoming drain
- `report_complete()`: Notify Manager when done

## Message Protocol

| Direction          | Message                           | Purpose              |
| ------------------ | --------------------------------- | -------------------- |
| Observer → Manager | `{:tick_report, stats, warnings}` | Current eco + alerts |
| Manager → Builder  | `{:build, unit}` / `:wait`        | What to do next      |
| Builder → Observer | `{:will_consume, mass, energy}`   | Upcoming drain       |
| Builder → Manager  | `{:build_completed, unit}`        | Build finished       |

## Simulation Lifecycle

```
:start → Manager initializes Observer with eco, Builder idle
   ↓
:run → Observer.tick() drives loop
   ↓
:decide → Manager receives report, sends order
   ↓
:execute → Builder updates, reports consumption
   ↓
:check → Builder completed? → Manager stops if goal achieved
   ↓
:completed → Return {completion_time, milestones, final_eco}
```

## Notes

- **Observer** is objectively passive. Only records and reports. No decisions.
- **Manager** is the only decider. Controls when to stop.
- **Builder** is pure execution. Reports progress and consumption.
- Warnings are just data. Manager decides whether to act on them.
