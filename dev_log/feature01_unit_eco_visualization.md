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