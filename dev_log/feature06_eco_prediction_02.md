# Feature06: Eco Prediction Part02 -- Algorithm (Agent-Based)

## Architecture: Two-Agent System

This document describes the agent-based approach to eco simulation.

### Agent Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    TWO-AGENT SYSTEM                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────┐        ┌─────────────────────┐    │
│  │    PLANNER AGENT    │◄──────►│    BUILDER AGENT    │    │
│  │     (The Brain)     │        │    (The Hands)      │    │
│  └─────────────────────┘        └─────────────────────┘    │
│                                                              │
│  Observes:                        Observes:                  │
│  - Current resources              - Build progress           │
│  - Income rates                   - BP availability          │
│  - Goal requirements              - Resource drain           │
│  - Optimization ops                                          │
│                                                              │
│  Decides:                         Executes:                  │
│  "What to build next?"            "Building X... done!"      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Agent Responsibilities

#### PlannerAgent

**State:**
- `goal`: Target unit and quantity
- `current_eco`: Mass/energy storage and income
- `engineers`: Available build power
- `state`: `:idle | :planning | :waiting | :complete`
- `completed_builds`: List of finished builds

**Key Functions:**
- `plan/2`: Analyze and decide what to build
- `receive/2`: Handle messages from Builder
- `analyze_risks/2`: Detect overflow/stall before they happen

#### BuilderAgent

**State:**
- `engineers`: Build power source
- `state`: `:idle | :building | :stalled | :complete`
- `current_build`: What we're building now
- `progress`: How far along (seconds)
- `total_bp`: Available build power

**Key Functions:**
- `receive_order/2`: Accept build commands
- `progress/2`: Advance build by N seconds
- `check_resources/2`: Detect energy/mass stalls

### Message Protocol

#### Message Format

```elixir
%{
  type: :build_completed,
  from: :builder_agent,
  to: :planner_agent,
  payload: %{unit: _, quantity: _},
  timestamp: 0
}
```

#### Message Types

| Category | Message | Direction | Meaning |
|----------|---------|-----------|---------|
| **Command** | `{:build, unit, qty}` | Planner → Builder | Start building |
| **Command** | `{:cancel, unit}` | Planner → Builder | Cancel build |
| **Status** | `{:build_started, unit, limit: _}` | Builder → Planner | Build begun |
| **Status** | `{:build_completed, unit, qty}` | Builder → Planner | Build done |
| **Warning** | `{:stall_warning, resource, _}` | Builder → Planner | Resource stall |
| **Event** | `{:income_boost, resource, amount}` | System → Planner | Mex/Pgen finished |
| **System** | `{:goal_achieved, _}` | Planner → System | All done |

### Message Flow Scenarios

#### Scenario 1: Simple Build

```
T=0:  Planner → Builder: {:build, "UEL0105", qty: 1}
      Builder → Planner: {:build_started, "UEL0105", limit: :build_power}

T=6:  Builder → Planner: {:build_completed, "UEL0105", qty: 1}
      Planner → System: {:goal_achieved, completed: [...]}
```

#### Scenario 2: Resource Limited (Mex First)

```
T=0:  Planner detects: mass income (2/s) too low for GC
      Planner → Builder: {:build, "UAB1103", qty: 1}  # Build Mex first
      
T=65: Builder → Planner: {:build_completed, "UAB1103", qty: 1}
      MexAgent → Planner: {:income_boost, :mass, +2}
      Planner: Updates mass_income: 2 → 4
      
T=65: Planner → Builder: {:build, "UAL0401", qty: 1}  # Now build GC
```

#### Scenario 3: Energy Stall

```
T=0:  Planner → Builder: {:build, "UEL0401", qty: 1}  # Fatboy

T=10: Builder detects: energy drain (700/s) > income (50/s)
      Builder → Planner: {:stall_warning, :energy, drain: 700, income: 50}

T=10: Planner → Builder: {:build, "t1_pgen", qty: 1}  # Build power first

T=35: Builder → Planner: {:build_completed, "t1_pgen", ...}
      PgenAgent → Planner: {:income_boost, :energy, +20}
      Planner: Updates energy_income: 50 → 70

T=35: Planner → Builder: {:resume, "UEL0401"}  # Continue Fatboy
```

### State Machines

#### PlannerAgent States

```
:idle → :planning → :waiting ─┐
  ▲                           │
  └───────────────────────────┘
                              ↓
                         :complete
```

Transitions:
- `:idle` → `:planning`: `plan/2` called
- `:planning` → `:waiting`: Orders sent to builder
- `:waiting` → `:planning`: Received completion, need next plan
- `:waiting` → `:complete`: Goal achieved

#### BuilderAgent States

```
:idle → :building ──→ :complete
          │
          ↓ (stall detected)
       :stalled ──→ :building (resume)
```

Transitions:
- `:idle` → `:building`: Received build order
- `:building` → `:stalled`: Resource stall detected
- `:stalled` → `:building`: Received resume order
- `:building` → `:complete`: Build finished

## Test Philosophy

Tests validate **message sequences**, not numerical values:

```elixir
# Old way (brittle)
assert result.completion_time == 84

# New way (clear intent)
assert messages == [
  {:planner, :builder, {:build, "UAL0401", qty: 1}},
  {:builder, :planner, {:build_started, "UAL0401", limit: :build_power}},
  {:builder, :planner, {:build_completed, "UAL0401", qty: 1}},
  {:planner, :system, {:goal_achieved, _}}
]
```

### Test Scenarios

1. **Simple Build**: Planner orders → Builder completes
2. **Resource Limited**: Planner detects → Orders Mex → Income boost → Orders goal
3. **Energy Stall**: Builder reports → Planner orders Pgen → Resume
4. **Overflow Risk**: Planner predicts → Orders engineers → Avoid waste
5. **Complex**: Multiple constraints, multiple optimizations

## Implementation Status

| Component | Status |
|-----------|--------|
| Message protocol | ✅ Defined |
| PlannerAgent skeleton | ✅ Created |
| BuilderAgent skeleton | ✅ Created |
| Scenario tests | ✅ Created |
| Simple build logic | ✅ Tests pass |
| Resource optimization | ✅ Tests pass (stubs) |
| Energy stall handling | ✅ Tests pass (stubs) |
| Overflow prevention | ⏳ Pending |

## Test Status

All 6 agent tests passing:
- ✅ Scenario 1: Simple build with sufficient resources
- ✅ Scenario 2: Resource limited build (Mex first optimization)
- ✅ Scenario 3: Energy stall during build
- ✅ Scenario 4: Mass overflow risk (engineer orders)
- ✅ Agent state transitions: Planner
- ✅ Agent state transitions: Builder

## Next Steps

1. Implement actual unit lookup (replace `:t1_mex`/`:t1_pgen` stubs with DB queries)
2. Implement income boost updates when structures complete
3. Add overflow prevention logic
4. Integration with EcoEngine main module

Run tests:
```bash
mix test test/faf_cn/eco_engine/agents/planner_builder_test.exs
```
