# Feature06: Eco Prediction Part02 -- Algorithm

## Core Concepts

This section layouts the core concepts the simulation must consider.

### Resource Production Units

| Resource | Valid Production Units | Notes |
|----------|----------------------|-------|
| **Mass** | T1/T2/T3 Mex, T2/T3 Mass Fabricator | Only these contribute to mass income |
| **Energy** | T1/T2/T3 Power Generators | (List to be completed) |

### Build Power Rules

#### Engineer Build Power (Base)

| Engineer Tier | Build Power |
|--------------|-------------|
| T1 Engineer | 5 BP |
| T2 Engineer | 10 BP |
| T3 Engineer | 15 BP |

**Formula**: `Total Engineer BP = (T1 × 5) + (T2 × 10) + (T3 × 15)`

---

#### Factory Build Power (Reference)

| Factory Type | Build Power |
|--------------|-------------|
| T1 Land Factory | ~20 BP |
| T2 Land Factory | ~40 BP |
| T3 Land Factory | ~90 BP |
| T1 Air Factory | ~20 BP |
| T2 Air Factory | ~40 BP |
| T3 Air Factory | ~90 BP |
| T1 Naval Factory | ~20 BP |
| T2 Naval Factory | ~40 BP |
| T3 Naval Factory | ~90 BP |

---

#### Factory Requirement by Target Unit

| Target Category | Factory Required? | Factory Type Needed | BP Calculation |
|-----------------|-------------------|---------------------|----------------|
| **Experimental** | ❌ No | — | Engineers only |
| **Land (non-EXP)** | ✅ Yes | Matching tier Land Factory | Factory BP + assisting engineers |
| **Air** | ✅ Yes | Matching tier Air Factory | Factory BP + assisting engineers |
| **Naval** | ✅ Yes | Matching tier Naval Factory | Factory BP + assisting engineers |
| **Structure** | ❌ No | — | Engineers only |
| **Engineer** | ❌ No | — | Engineers only |

---

#### Build Power Formula by Scenario

**Scenario A: Building Experimental or Structure**
```
Total BP = Sum of all engineers' BP
```

**Scenario B: Building Battle Unit (Land/Air/Naval) with Existing Factory**
```
Total BP = Factory_BP + Sum_of_assisting_engineers_BP
```

**Scenario C: Building Battle Unit + Factory (User selects "include factory")**
```
Phase 1: Build Factory
  - BP = Engineers only

Phase 2: Build Units
  - BP = New_Factory_BP + Assisting_Engineers_BP
```

---

#### Examples

**Example 1: Building Galactic Colossus (Experimental)**
- 5 T3 Engineers
- BP = 5 × 15 = **75 BP**

**Example 2: Building 10 Bricks (T3 Land) with existing factory**
- T3 Land Factory + 5 T3 Engineers assisting
- BP = 90 + (5 × 15) = **165 BP**

**Example 3: Building T3 Land Factory + 10 Bricks**
- Phase 1: Build T3 Land Factory with 5 T3 Engineers
  - Time to build factory = Factory_Cost / (5 × 15) = Factory_Cost / 75
- Phase 2: Build 10 Bricks with factory + 5 T3 Engineers
  - BP = 90 + 75 = **165 BP**

### Resource Flow Characteristics

- **Drain**: Continuous (mass/energy drain steadily during build)
- **Income**: Discrete (only completed structures generate income)
- **Build Power**: Discrete (only completed engineers add BP)
- **Priority**: Avoid energy stall as first priority

### Unit Energy Consumption

Completed structures (Mex, Mass Fab) drain energy continuously and reduce net energy income.

---

## Requirements

Requirements derived from core concepts and design decisions.

### R1: Simulation Scope

**R1.1**: The simulation MUST calculate the optimal build order to achieve user goal in minimum time.

**R1.2**: The simulation MUST consider building income structures (Mex/Fab/Pgens) first if it reduces total completion time.

**R1.3**: The simulation MUST NOT consider partially built structures - all build power focuses on one target at a time (sequential building).

### R2: Goal Definition

**R2.1**: User goal consists of:
- Target unit type
- Quantity to build
- Whether to include prerequisite factory (for battle units)

**R2.2**: For experimental units, factory is NEVER required.

**R2.3**: For battle units (land/air/naval), the corresponding factory MUST be built first IF user selects "include factory" option.

### R3: Build Power Calculation

**R3.1**: Base build power formula:
```
Total BP = (T1_eng × 5) + (T2_eng × 10) + (T3_eng × 15)
```

**R3.2**: When building battle units with factory:
```
Total BP = Factory_BP + Assisting_Engineers_BP
```

**R3.3**: If user inputs 0 engineers, simulation MUST consider building at least 1 engineer first.

### R4: Resource Accumulation

**R4.1**: Simulation MUST handle storage limits:
- Cannot spend mass/energy beyond current storage
- Excess income when storage is full is wasted (overflow)

**R4.2**: Simulation SHOULD minimize mass overflow (keep storage near 0 for efficient players).

**R4.3**: Energy storage limits MAY prevent starting builds if unit cost > storage capacity.

### R5: Energy Stall Prevention

**R5.1**: Energy stall is the PRIMARY constraint to avoid.

**R5.2**: If build drain > available energy income, build progress slows proportionally:
```
Effective_BP = BP × (Actual_Energy_Income / Required_Energy_Drain)
```

**R5.3**: If energy stall would occur, simulation SHOULD schedule building power generators first.

### R6: Income Structure Building

**R6.1**: Building income structures (Mex/Fab/Pgens) during simulation is REQUIRED (not optional).

**R6.2**: Each completed income structure MUST be reflected as a milestone.

**R6.3**: Income structures' energy drain after completion MUST reduce net energy income.

### R7: Factory Handling

**R7.1**: For battle units WITHOUT "include factory":
- Assume factory exists
- Include factory BP in calculation
- Do NOT include factory cost/time

**R7.2**: For battle units WITH "include factory":
- Build factory first
- Then build units with factory assistance

### R8: Milestone Generation

**R8.1**: Milestones MUST include:
- Start (time: 0)
- Each income structure completion
- Factory completion (if applicable)
- Resource threshold reached (mass/energy sufficient for goal)
- Goal completion

**R8.2**: Milestones SHOULD include storage full/overflow warnings.

### R9: Output Data

**R9.1**: Simulation MUST return:
- Total completion time
- Complete build order with timestamps
- Time-series data for chart (accumulated mass/energy at each time point)
- List of milestones

---

## Formulas & Data Structures

(To be completed in next iteration)

### Input Structure

```elixir
%{
  initial_eco: %{
    mass_income: float,
    energy_income: float,
    mass_storage: float,
    mass_storage_max: float,
    energy_storage: float,
    energy_storage_max: float,
    engineers: %{
      t1: integer,
      t2: integer,
      t3: integer
    }
  },
  goal: %{
    unit: UnitSchema,
    quantity: integer,
    include_factory: boolean  # for battle units only
  }
}
```

### Output Structure

```elixir
%{
  completion_time: integer,  # seconds
  build_order: [%{unit: string, start_time: integer, end_time: integer}],
  chart_data: %{
    time: [integer],
    mass: [float],
    energy: [float]
  },
  milestones: [%{time: integer, label: string, type: atom}]
}
```

### Key Formulas

(To be derived from requirements)

---

## Implementation & Unit Tests

(To be completed)

### Module Structure

```
lib/faf_cn/eco_engine/
├── simulation.ex      # Main entry point
├── calculator.ex      # Time/cost calculations
├── scheduler.ex       # Build order optimization
└── validator.ex       # Input validation
```

### Test Cases

(To be defined based on formulas)
