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

- [x] Find source for FAF unit icons from spooky-db CSS sprite sheet
- [x] Download unit sprite sheet (`a9005d59.units.png` - 1472x1472px containing 503 unit icons at 64x64px each)
- [x] Extract CSS background positions for all 503 unit IDs
- [x] Generate CSS file with unit icon classes (`unit_icon-XXXX`)
- [x] Update Eco Guides UI to display actual unit icons from sprite sheet
- [x] Remove unused strategic icons and migration (not needed with sprite sheet approach)

**Status**: ✅ Completed

**Implementation Details**:
- The spooky-db site uses a CSS sprite sheet (`a9005d59.units.png`) where each unit icon is 64x64 pixels
- CSS classes map unit IDs (e.g., `UEL0105`) to background positions in the sprite sheet
- Generated `unit_icons.css` with 503 CSS rules for all units
- Updated `eco_guides_live.html.heex` to use `<div class="unit-icon-{unit_id}">` instead of Heroicons
- Icons are displayed at 48x48px (w-12 h-12) in the unit grid and 56x56px (w-14 h-14) in the base unit display
- Sprite sheet is 1472x1472 pixels total (23x23 grid of 64x64 icons)

**Files Changed**:
- `priv/static/images/units/a9005d59.units.png` - Unit icons sprite sheet
- `assets/css/unit_icons.css` - Generated CSS with background positions for all units
- `assets/css/app.css` - Import unit_icons.css
- `lib/faf_cn_web/live/eco_guides_live.html.heex` - Use unit icon CSS classes
- Removed: `priv/repo/migrations/*_add_unit_icon_path.exs` (not needed with CSS approach)
- Removed: `priv/static/images/units/strategic/` folder (unused)

## Task05 -- improvement icons background

- [x] Fix the background color when displaying units
- [x] Download background image `d2cdefc2.background.jpg` from spooky-db
- [x] Add faction-specific CSS background classes:
  - [x] UEF: `rgba(45, 120, 178, 0.2)` (blue)
  - [x] CYBRAN: `rgba(223, 45, 14, 0.2)` (red)
  - [x] AEON: `rgba(10, 157, 47, 0.2)` (green)
  - [x] SERAPHIM: `rgba(241, 194, 64, 0.2)` (yellow/gold)
- [x] Apply background image + faction color overlay using `background-blend-mode: overlay`
- [x] Update unit icon containers to use faction background classes

**Status**: ✅ Completed

**Implementation Details**:
- Background image is applied via CSS with `background-image: url('/images/units/background.jpg')`
- Each faction has a transparent color overlay that blends with the background image
- The `background-blend-mode: overlay` creates the same effect as spooky-db
- Added `unit_faction_bg_class/1` helper function in `eco_guides_live.ex`
- Updated both base unit display and unit grid to use faction backgrounds
- CSS classes: `.unit-bg-uef`, `.unit-bg-cybran`, `.unit-bg-aeon`, `.unit-bg-seraphim`

**Files Changed**:
- `priv/static/images/units/background.jpg` - Background texture image
- `assets/css/unit_icons.css` - Added faction background classes
- `lib/faf_cn_web/live/eco_guides_live.ex` - Added `unit_faction_bg_class/1` helper
- `lib/faf_cn_web/live/eco_guides_live.html.heex` - Applied faction backgrounds to unit icons

## Task06: Improve unit selection grid background

- [x] Change the "Select Units to Compare" section background from white to the unit background image
- [x] Update section title styling with white text and drop shadow for visibility
- [x] Update "Clear" button to have a solid red background for visibility on the image

**Status**: ✅ Completed

**Implementation Details**:
- Changed the container background from `bg-white` to use the same background image as unit icons
- Added `background-size: cover` and `background-position: center` for proper image display
- Section title now uses white text with drop shadow for readability
- Clear button changed to solid red (`bg-red-600`) with white text and shadow for visibility

**Files Changed**:
- `lib/faf_cn_web/live/eco_guides_live.html.heex` - Updated unit selection grid container styling 

## Task 07: Improve comparison section with unit icons

- [x] Add unit icons to engineer comparison cards
- [x] Display unit names/descriptions in comparison cards
- [x] Show engineer icon in the "vs Engineer (Base)" header
- [x] Add unit icons to cross-comparison rows (both from and to units)
- [x] Fix cross-comparison mass ratio to show correct unit costs
- [x] Keep letter labels (A, B, C) alongside icons for reference

**Status**: ✅ Completed

**Implementation Details**:
- Engineer comparison cards now show:
  - Unit icon with faction background (left side)
  - Letter label (A, B, C) and unit ID
  - Unit description/name below
  - Mass/energy/time ratios
- "vs Engineer (Base)" header now shows the engineer unit icon
- Cross-comparisons now show:
  - Both unit icons with faction backgrounds
  - Letter labels for both units
  - Correct mass ratio (to_unit/from_unit instead of to_unit/base_unit)

**Files Changed**:
- `lib/faf_cn_web/live/eco_guides_live.html.heex` - Updated comparison section UI 


## Task 08: Improve comparison section with correct name

- [x] In vs base part:
  - [x] Display unit's full name at the right side of icon
  - [x] Remove letter labels (A, B, C, etc.)
  - [x] Remove unit ID display (like "UEB0203")
- [x] In Cross Comparisons part:
  - [x] Just display icons for both units
  - [x] Remove letter labels (A, B, etc.)

**Status**: ✅ Completed

**Implementation Details**:
- Engineer comparison cards now show:
  - Unit icon with faction background
  - Unit full name (description) only - no more ID or letter labels
  - Mass/energy/time ratios
- Cross-comparisons now show:
  - To unit icon only (no letter label)
  - Ratio value
  - From unit icon only (no letter label)
  - Mass cost comparison

**Files Changed**:
- `lib/faf_cn_web/live/eco_guides_live.html.heex` - Simplified comparison section UI

## Task 09: Improve comparison section with style

- [x] Adjust cross comparison icon sizes to match base comparison (32px)
- [x] Group cross comparisons by the "from" unit (X in "Y = ?x of X")
- [x] Display each group in a visual card matching base comparison style:
  - [x] Card header shows base unit icon and name
  - [x] Each comparison row shows target unit icon, name, and ratio badge
  - [x] Mass/energy/time ratios displayed in grid below each row

**Status**: ✅ Completed

**Implementation Details**:
- Added `group_comparisons_by_base/1` helper function to group comparisons
- Cross comparisons now display as cards grouped by base unit:
  - Card header: `[Icon] Base Unit Name`
  - Comparison rows: `[Icon] Target Unit Name = Ratio`
  - Ratio grid: Mass/Energy/Time breakdown
- Icon sizes standardized to 32px (w-8 h-8) matching base comparison
- Visual style consistent with base comparison cards (bg-gray-50, border, rounded)

**Files Changed**:
- `lib/faf_cn_web/live/eco_guides_live.ex` - Added `group_comparisons_by_base/1` helper
- `lib/faf_cn_web/live/eco_guides_live.html.heex` - Updated cross comparison UI with cards 

## Task 10: Adjust cross comparison

- [x] Sort groups by base unit mass cost (cheapest base unit first)
- [x] Sort comparisons within each group by mass cost (cheapest first)
- [x] Display base unit mass cost in card header

**Status**: ✅ Completed

**Implementation Details**:
- Groups are now sorted by base unit's `build_cost_mass` (ascending)
  - Engineer (52 mass) appears first
  - More expensive base units appear later
- Within each group, comparisons are sorted by target unit's mass cost
- Base unit card header shows:
  - Unit icon
  - Unit full name
  - Mass cost (e.g., "Mass: 52")

**Files Changed**:
- `lib/faf_cn_web/live/eco_guides_live.ex` - Updated sorting logic for groups and comparisons
- `lib/faf_cn_web/live/eco_guides_live.html.heex` - Added mass cost display in header 

## Task 11: Adjust base comparsion section for Eco Comparion 

- Display the full name for base unit. 
- Display mass, energy and build time absolute value for base unit
