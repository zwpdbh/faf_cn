# Feature01: Visualize Eco and Units 

## Background

In FAF, eco is the core. However, player usually waste eco on building units. 
This feature is to build the visualization:

## Task01:

- [x] Fetch unit data from: `https://faforever.github.io/spooky-db/#/`. Only for UEF, Cybran, Aeon and Seraphim.
- [x] Store data in database.

**Status**: ✅ Completed - 405 units fetched and stored (UEF: 105, CYBRAN: 110, AEON: 101, SERAPHIM: 89)

## Task 02:

- [x] Build a simple frontend page called `Eco Guides`.
  - [x] let user select one unit as base unit, say A.
  - [x] let user then select multiple other units, say B, C and D. 
  - [x] display 
    - B = xx of A 
    - C = xx of A 
    - D = xx of A, 
    - B = xx of C, 
    - C = xx of D.

**Status**: ✅ Completed - Accessible at `/eco-guides` 

## Task03:

- [x] Display FAF units as icons in the web page
- [x] Implement tab-based interface:
  - [x] 4 tabs for UEF, CYBRAN, AEON and SERAPHIM with faction-colored styling
  - [x] Clicking a tab shows units belonging to that faction
  - [x] Units are displayed as selectable icons in a responsive grid
- [x] Make T1 engineer the default base unit per faction:
  - [x] UEF: UEL0105
  - [x] CYBRAN: URL0105
  - [x] AEON: UAL0105
  - [x] SERAPHIM: XSL0105
- [x] Auto-display comparisons when units are selected:
  - [x] Each selected unit shows "Xx of Engineer" comparison
  - [x] Cross-comparisons between selected units (A vs B, B vs C, etc.)
- [x] Visual enhancements:
  - [x] Faction-colored icons with tech level indicators
  - [x] Selected state with checkmark badges
  - [x] Engineer marked with star badge
  - [x] Color-coded ratios (green=efficient, orange=moderate, red=expensive)
  - [x] Quick stats summary (total mass/energy of selections)

**Status**: ✅ Completed - Accessible at `/eco-guides`

**Implementation Details**:
- Icons use Heroicons based on unit's `StrategicIconName` (engineer, tank, air, ship, etc.)
- Background colors indicate faction + tech level (lighter=T1, darker=T3/EXP)
- Cross-comparisons automatically update when units are selected/deselected
- Tab switching resets selections and updates base engineer to faction-appropriate unit

Your plan:

1. **Update LiveView Module (`eco_guides_live.ex`)**:
   - Add default T1 engineer as base unit (UEL0105, URL0105, UAL0105, XSL0105 per faction)
   - Add faction tab state management (`:selected_faction`, default to "UEF")
   - Add `handle_event` for faction tab switching
   - Refactor comparison logic: auto-compute relationships when units are selected
   - Group units by faction for display

2. **Create Unit Icon Component**:
   - Create colored placeholder icons for units (using faction colors + unit category colors)
   - UEF: Blue (#2563eb), CYBRAN: Red (#dc2626), AEON: Green (#16a34a), SERAPHIM: Purple (#9333ea)
   - Use strategic icon names from data to categorize (engineer, tank, air, naval, etc.)

3. **Update Template (`eco_guides_live.html.heex`)**:
   - Create 4 faction tabs at the top (UEF, CYBRAN, AEON, SERAPHIM)
   - Left column: Show faction-specific units as clickable icons in a grid
   - Right column: Comparison results showing:
     - Selected unit = xx of Engineer (for each selected unit)
     - Cross-comparisons: A = xx of B, B = xx of C, etc.
   - Remove manual base unit selection (it's always T1 engineer)

4. **Visual Design**:
   - Tab styling with active state indicator
   - Icon grid with hover effects and selection state
   - Comparison cards with eco ratios (mass/energy/build time)
   - Color-coded ratios (green=efficient, red=expensive)

5. **Testing**:
   - Verify all 405 units display correctly
   - Verify default engineer is pre-selected
   - Verify tab switching works
   - Verify comparisons auto-update on selection


## Task 04: Display FAF units icons

- [ ] Find source for FAF unit icons (from spooky-db or FAF game files)
- [ ] Download and convert icons to PNG format
- [ ] Store icons as static assets in `priv/static/images/units/`
- [ ] Add `icon_path` column to units table in database
- [ ] Update unit records with icon paths
- [ ] Update Eco Guides UI to display actual unit icons instead of Heroicons placeholders

**Status**: 🔄 In Progress

Your plan:

1. **Research Icon Source**: Check spooky-db repository for icon assets or find alternative source
2. **Download Icons**: Download icons for all 405 units (UEF, CYBRAN, AEON, SERAPHIM)
3. **Database Update**: 
   - Create migration to add `icon_path` column to units table
   - Update existing units with their icon paths
4. **Static Assets**:
   - Create `priv/static/images/units/` directory
   - Organize icons by faction: `units/uef/`, `units/cybran/`, `units/aeon/`, `units/seraphim/`
5. **UI Update**:
   - Update `eco_guides_live.html.heex` to use `<img>` tags with unit icons
   - Add fallback to Heroicons if icon is missing
6. **Testing**: Verify all units display their correct icons