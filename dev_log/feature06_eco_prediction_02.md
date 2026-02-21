# Feature06: Eco Prediction Part02 -- Algorithm

## Architecture (Simplified)

Two-part system:

```
┌─────────────────────────────────────────┐
│           GAME (World State)            │
│  - mass_storage, energy_storage         │
│  - mass_produce_per_sec                 │
│  - energy_produce_per_sec               │
│  - mass_drain_per_sec (from Player)     │
│  - energy_drain_per_sec (from Player)   │
└─────────────┬───────────────────────────┘
              │ observes status
┌─────────────▼───────────────────────────┐
│           PLAYER (Decision Maker)       │
│  - target_mass, target_power            │
│  - target_build_time                    │
│  - build_power (BP from engineers)      │
│  - idle (building or not)               │
└─────────────────────────────────────────┘
```

## Core Insight: BP Limited by Resources

The actual build power you can use is limited by whichever resource is the bottleneck:

```
actual_bp = min(available_bp, bp_limited_by_mass, bp_limited_by_energy)

where:
  bp_limited_by_mass = mass_produce / mass_drain_per_bp
  bp_limited_by_energy = energy_produce / energy_drain_per_bp
  
  mass_drain_per_bp = unit_mass_cost / unit_build_time
  energy_drain_per_bp = unit_power_cost / unit_build_time
```

### Example: Fatboy with Limited Resources

**Fatboy Stats:**
- Mass: 28,000
- Energy: 350,000
- Build time: 47,500

**Scenario:** 150 BP available, 40 mass/sec, 1200 energy/sec

```
Step 1: Calculate drain per BP
  mass_drain_per_bp = 28000 / 47500 = 0.589 mass/BP/sec
  energy_drain_per_bp = 350000 / 47500 = 7.368 energy/BP/sec

Step 2: Calculate BP limit from each resource
  bp_limited_by_mass = 40 / 0.589 = 67.86 BP
  bp_limited_by_energy = 1200 / 7.368 = 162.86 BP

Step 3: Take minimum
  actual_bp = min(150, 67.86, 162.86) = 67.86 BP
```

**Result:** Even with 150 BP worth of engineers, you can only use **67.86 BP** because mass is the bottleneck. Adding more engineers doesn't help!

### Key Takeaway

The weakest link determines build speed:
- **Mass-limited**: Common early game (not enough mexes)
- **Energy-limited**: Common when building experimentals (need more pgens)
- **BP-limited**: Rare late game (usually have enough eco)

## Game Module

**Role:** Pure state container. No logic.

**State:**
- `mass_storage`, `energy_storage`: Current resources
- `mass_produce_per_sec`, `energy_produce_per_sec`: Income rates
- `mass_drain_per_sec`, `energy_drain_per_sec`: Consumption rates (set by Player)

**Tick Cycle:**
```
mass_storage += mass_produce_per_sec - mass_drain_per_sec
energy_storage += energy_produce_per_sec - energy_drain_per_sec
```

## Player Module

**Role:** Decision maker. Calculates drain rates.

**State:**
- `target_mass`, `target_power`, `target_build_time`: Unit stats
- `build_power`: Total BP from engineers
- `idle`: Whether currently building

**Drain Calculation:**
```elixir
mass_drain_per_sec = (target_mass / target_build_time) * build_power
energy_drain_per_sec = (target_power / target_build_time) * build_power
```

**Key Methods:**
- `start_build()` → `idle: false` → drain rates become active
- `stop_build()` → `idle: true` → drain rates go to 0

## Infinite vs Limited Resources

### Infinite Resources (Theory)

```
ticks_needed = target_build_time / build_power
```

Fatboy with 150 BP: 47500 / 150 = **316.67 ticks**

### Limited Resources (Reality)

```
actual_bp = min(available_bp, bp_limited_by_mass, bp_limited_by_energy)
ticks_needed = target_build_time / actual_bp
```

Fatboy with 150 BP but 40 mass/sec: actual_bp = 67.86 → **700 ticks**

**More than 2x slower due to mass bottleneck!**

## With Storage Buffer (Two-Phase Build)

When you have initial storage, the build proceeds in two phases:

### Phase 1: Storage Phase
Use full BP until storage depletes:
```
storage_depletion_time = initial_storage / (full_drain - production)
progress_made = full_bp * depletion_time
```

### Phase 2: Income Phase  
Continue at BP limited by income:
```
remaining_progress = target_time - progress_made
ticks_needed = remaining_progress / bp_limited_by_resource
```

### Example: Fatboy with 14k Mass Storage

**Setup:** 150 BP, 40 mass/sec, 14,000 mass storage

```
Phase 1 (Storage):
  mass_depletion_time = 14000 / (88.42 - 40) = 289.1 ticks
  progress = 150 * 289.1 = 43,365 build seconds

Phase 2 (Income-limited):
  remaining = 47,500 - 43,365 = 4,135
  time = 4135 / 67.86 = 60.9 ticks

Total: 289.1 + 60.9 = 350 ticks
(50% faster than 0-storage case: 700 ticks)
```

## BuildPower Module

A dedicated module for pure calculation functions at `lib/faf_cn/eco_engine/build_power.ex`.

### Core Functions

| Function | Description |
|----------|-------------|
| `drain_per_bp/2` | Calculate resource drain per BP per second |
| `bp_limited_by_resource/2` | BP limit given resource production |
| `actual_bp/3` | Actual BP considering all constraints |
| `ticks_needed/2` | Build time given target time and actual BP |
| `storage_depletion_time/3` | How long storage lasts at full BP |
| `two_phase_build_time/6` | Total time with storage buffer |
| `calculate_metrics/4` | Complete metrics map for analysis |

### Example Usage

```elixir
alias FafCn.EcoEngine.BuildPower

# Calculate BP limits
mass_drain = BuildPower.drain_per_bp(28_000, 47_500)
bp_from_mass = BuildPower.bp_limited_by_resource(40, mass_drain)
# => 67.86

# Actual BP with constraints
actual = BuildPower.actual_bp(150, 67.86, 162.86)
# => 67.86 (mass-limited)

# Two-phase build with storage
ticks = BuildPower.two_phase_build_time(
  47_500,  # target build time
  150,     # available BP
  40,      # mass/sec
  1200,    # energy/sec
  14_000,  # mass storage
  175_000  # energy storage
)
# => ~350 ticks
```

## Tests

### BuildPower Module (21 tests)
Located at `test/faf_cn/eco_engine/build_power_test.exs`

Tests for all pure functions with Fatboy as reference unit.

### BuildProgress Integration (8 tests)
Located at `test/faf_cn/eco_engine/build_progress_test.exs`

Scenario-based tests covering:
- Infinite resources (pure BP calculation)
- Limited resources - 0 storage (mass/energy bottlenecks)
- Limited resources - with storage (two-phase builds)

**Test Results:** All 29 tests passing ✓
