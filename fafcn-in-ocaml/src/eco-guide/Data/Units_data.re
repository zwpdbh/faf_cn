/* Hardcoded unit data for the eco guide
   These units are embedded in the frontend for static deployment */

open Models;

let uef_units = Units_uef.units;
let cybran_units = Units_cybran.units;
let aeon_units = Units_aeon.units;
let seraphim_units = Units_seraphim.units;

let all_units = () =>
  uef_units() @ cybran_units() @ aeon_units() @ seraphim_units();

let find_unit = unit_id =>
  all_units() |> List.find_opt(u => u.UnitModel.unit_id == unit_id);

let units_by_faction = () => {
  let all = all_units();
  Faction.all
  |> List.map(faction => {
       let units = List.filter(u => u.UnitModel.faction == faction, all);
       (faction, units);
     });
};
