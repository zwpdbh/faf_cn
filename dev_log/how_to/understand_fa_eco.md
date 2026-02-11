# Forged Alliance Economy Mechanics

Understanding how FAF economy actually works for accurate simulation.

## Core Resources

There are only two resources in the game, mass and power.

- Mass is generated per seconds from mex and mass fabricator (ignore relcaim for simplicity).
- Energy is generated per seconds from power generator (ignore other sources for simplicity).
- There are mass and energy storage to store generated mass and energy that are not spent quickly enough.
- Overflow, mass and energy could overflow if the accumulated resource reach the limit of their storage.
- Stall, mass and energy could reach negative if the spending of mass or energy is much higher than their income.

How could you spend more than your income?

This reflect the core aspect of FA eco in which the building is a continuous progress. 
Except mass and energy, there are other two factors: build power and build time.


## Understand Build Power and Build Time

- Build power determine how fast you could accerlate a building progress if you put multiple engineers to build something.
- The absolute value of how fast mass and energy are cost is determined by build power and build time of a unit you are bulding.

For build power let's list each tier, one engineer's BP:

- T1 Engineer, build power is 5
- T2 Engineer, build power is 10
- T3 Engineer, build power is 32.5


## Case 01

Let's study from simple case, we have infinite mass and power income.
A T3 Land Factory has 90 build power. Below shows how much time it takes to build a Brick when assisted by 1, 3, and 10 T3 engineers.

### Build Time: T3 Factory + T3 Engineers Building a Brick

| Setup                  | Build Power | Build Time | Time Saved vs Factory Alone |
| ---------------------- | ----------- | ---------- | --------------------------- |
| T3 Factory alone       | 90          | 53.3s      | —                           |
| T3 Factory + 1 T3 Eng  | 122.5       | 39.2s      | 26% faster                  |
| T3 Factory + 3 T3 Eng  | 187.5       | 25.6s      | 52% faster                  |
| T3 Factory + 10 T3 Eng | 415         | 11.6s      | 78% faster                  |

**Brick Stats**: 1,280M | 14,000E | Base Time: 4,800s

**Formula**: `Build Time = 4,800 / (90 + Assist BP)`

**Key Observations**:
- Diminishing returns: First engineer helps most (26% speedup)
- 10 engineers reduce time by 78% (4.6× faster)
- Factory alone is already quite fast (53s) for such an expensive unit


## Case 02

Now let's study building a Cybran Experimental - the Monkeylord - using 10, 15, and 20 T3 engineers.

### Build Time: T3 Engineers Building a Monkeylord

| T3 Engineers | Build Power | Build Time | Mass Drain/s | Energy Drain/s |
| ------------ | ----------- | ---------- | ------------ | -------------- |
| 10           | 325         | 84.6s      | 236.4/s      | 3,073.3/s      |
| 15           | 487.5       | 56.4s      | 354.6/s      | 4,609.9/s      |
| 20           | 650         | 42.3s      | 472.8/s      | 6,146.6/s      |

**Monkeylord Stats**: 20,000M | 260,000E | Base Time: 27,500s

**Formula**: `Build Time = 27,500 / (T3 Eng Count × 32.5)`

**Resource Reality Check**:
- To sustain 20 engineers: Need ~473M/s and ~6,147E/s income
- 26 T3 mexes → 468M/s (close!)
- 3 T3 pgens → 7,500E/s (covered)

**Key Observations**:
- 20 T3 engineers build Monkeylord in just **42 seconds**!
- That's 10.6× faster than 2 engineers would take
- Mass drain becomes the bottleneck - need serious eco to support 20 engineers


## Case 03 -- Stall on Mass 

Same as Case 02, but now with **limited resources**:
- Mass income: **300/s** (fixed)
- Energy income: **5,000/s** (fixed)

This shows what happens when your eco can't support your build power.

### Build Time: Resource-Limited Monkeylord Production

| T3 Engineers | Theoretical BP | Theoretical Time | Limiting Factor                   | Actual Time | Efficiency |
| ------------ | -------------- | ---------------- | --------------------------------- | ----------- | ---------- |
| 10           | 325            | 84.6s            | None (sufficient eco)             | **84.6s**   | 100%       |
| 15           | 487.5          | 56.4s            | Mass stall (need 355/s, have 300) | **66.7s**   | 85%        |
| 20           | 650            | 42.3s            | Mass stall (need 473/s, have 300) | **66.7s**   | 63%        |

**Resource Analysis**:

**10 Engineers**:
- Drain: 236M/s < 300M/s ✓ | 3,073E/s < 5,000E/s ✓
- Result: No stall, builds at full speed

**15 Engineers**:
- Drain: 355M/s > 300M/s ✗ MASS STALL | 4,610E/s < 5,000E/s ✓
- Result: Mass-limited, builds at 85% efficiency
- Extra BP wasted: You paid for 15 engineers but only get ~12.5 worth

**20 Engineers**:
- Drain: 473M/s > 300M/s ✗ MASS STALL | 6,147E/s > 5,000E/s ✗ ENERGY STALL
- Result: Double stall! Mass is the primary limit
- Wasted: 37% of your build power is idle

### The Stall Formula

When `Drain > Income`:

```
Actual Time = Total Cost / Income (whichever is lower)
Efficiency = Income / Drain
```

**15 Engineers Example**:
- Mass limited: 20,000M / 300M/s = 66.7s
- Efficiency: 300/355 = 85%

**Key Lesson**: 
- More build power without matching eco = **wasted investment**
- 20 engineers with 300M/s income = same result as 12.5 engineers
- Always balance BP with resource income! 

## Case 04: Stall on Energy

- This is actually the dead scenario. Because if you stall on energy, the main mass income from mex will also decrease dramtically.
- Simulat this is too much complex for now.
- Keep simple so ignore this part.



