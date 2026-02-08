# Feature03: units display improvement 

Currently all units belong to one race is displayed in the grid. It is not easier to select them at first glance.
We need to add some filter functions.

## Goal01: units display improvement 

- Add a horizontal multiple selection feature between "Select Units to Compare" and "Clear"
- The multiple selection has following buttons, from left to right 
  -  engineer, structure, land, air, naval, tech1, tech2, tech3 and experimental
  -  consider user the butter apearance from `https://faf-unitdb.web.app/faf/list-by-faction`, 
      - engineer image: `<img _ngcontent-vlv-c35="" src="assets/filters/ENGINEER.png" alt="ENGINEER">`
      - structure image: `<img _ngcontent-vlv-c35="" src="assets/filters/STRUCTURE.png" alt="STRUCTURE">`
      - land: `<img _ngcontent-vlv-c35="" src="assets/filters/LAND.png" alt="LAND">`
      - air: `<img _ngcontent-vlv-c35="" src="assets/filters/AIR.png" alt="AIR">`
      - naval: `<img _ngcontent-vlv-c35="" src="assets/filters/NAVAL.png" alt="NAVAL">`
      - t1: `<img _ngcontent-vlv-c35="" src="assets/filters/TECH1.png" alt="TECH1">`
      - t2: `<img _ngcontent-vlv-c35="" src="assets/filters/TECH2.png" alt="TECH2">`
      - t3: `<img _ngcontent-vlv-c35="" src="assets/filters/TECH3.png" alt="TECH3">`
      - exprimental: `<img _ngcontent-vlv-c35="" src="assets/filters/EXPERIMENTAL.png" alt="EXPERIMENTAL">`

## Plan

### Phase 1: Filter Logic & State Management
- [x] Add `active_filters` assign to EcoGuidesLive (list of active filter keys)
- [x] Create `apply_filters/2` function to filter units by category/tech level
- [x] Add `toggle_filter` event handler
- [x] Add `clear_filters` event handler

### Phase 2: UI Components
- [x] Create `<.filter_bar>` component with filter buttons
- [x] Style filter buttons horizontally between title and "Clear" button
- [x] Use text labels for buttons (images to be added later)
- [x] Show active filters with highlighted state (indigo background)
- [x] Show "Clear All" button when filters are active

### Phase 3: Integration
- [x] Update `unit_selection_grid` to accept and apply filters
- [x] Update template to include filter bar
- [x] Ensure filters work with existing selection logic
- [x] Show "No units match" message with clear button when filters result in empty set

### Phase 4: Polish
- [x] Add hover effects to filter buttons
- [x] Add empty state handling


## Progress Log

### 2026-02-08
Implemented filter functionality:

**Changes Made:**
- `lib/faf_cn_web/live/eco_guides_live.ex`:
  - Added `@filters` module attribute with 9 filter definitions (with group: :usage or :tech)
  - Added `@usage_filters` and `@tech_filters` for mutually exclusive groups
  - Added `active_filters` to socket assigns
  - Added `handle_event("toggle_filter", ...)` with mutually exclusive logic:
    - Within usage group (Engineer/Structure/Land/Air/Naval): only one can be selected
    - Within tech group (T1/T2/T3/EXP): only one can be selected
    - But can select one from each group simultaneously (max 2 filters)
  - Added `handle_event("clear_filters", ...)` to clear all filters
  - Clears filters when switching factions

- `lib/faf_cn_web/live/eco_guides_live/components.ex`:
  - Added `apply_filters/2` helper function
  - Added `<.filter_bar>` component with filter buttons
  - Updated `<.unit_selection_grid>` to:
    - Accept `filters` and `active_filters` attributes
    - Display filter bar between title and unit grid
    - Apply filters to displayed units
    - Show "No units match" empty state with clear button

- `lib/faf_cn_web/live/eco_guides_live.html.heex`:
  - Updated to pass `filters` and `active_filters` to `<.unit_selection_grid>`

**Filter Behavior:**
- Usage filters (Engineer/Structure/Land/Air/Naval): mutually exclusive, max 1 active
- Tech filters (T1/T2/T3/EXP): mutually exclusive, max 1 active
- Can combine 1 usage + 1 tech filter (e.g., "Land" + "T2")
- Selecting a new filter in same group replaces the previous one
- Active filters show with indigo background
- Inactive filters show with white background
- "Clear All" button appears when filters are active
- Filters are cleared when switching factions
- Empty state shown when no units match filters

