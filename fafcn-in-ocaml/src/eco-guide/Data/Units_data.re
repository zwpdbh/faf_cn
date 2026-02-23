/* Hardcoded unit data for the eco guide
   These units are embedded in the frontend for static deployment */

open Models;

let uef_units = () => [
  // T1 Engineer - Base unit
  {
    UnitModel.unit_id: "UEL0105",
    faction: Faction.Uef,
    name: None,
    description: "Engineer",
    build_cost_mass: 52,
    build_cost_energy: 260,
    build_time: 260,
    categories: ["ENGINEER", "TECH1", "LAND"],
  },
  // T2 Engineer
  {
    unit_id: "UEL0208",
    faction: Uef,
    name: None,
    description: "Engineer",
    build_cost_mass: 130,
    build_cost_energy: 650,
    build_time: 650,
    categories: ["ENGINEER", "TECH2", "LAND"],
  },
  // T3 Engineer
  {
    unit_id: "UEL0309",
    faction: Uef,
    name: None,
    description: "Engineer",
    build_cost_mass: 312,
    build_cost_energy: 1560,
    build_time: 1560,
    categories: ["ENGINEER", "TECH3", "LAND"],
  },
  // T1 Land Units
  {
    unit_id: "UEL0101",
    faction: Uef,
    name: Some("Snoop"),
    description: "Land Scout",
    build_cost_mass: 12,
    build_cost_energy: 80,
    build_time: 60,
    categories: ["LAND", "TECH1"],
  },
  {
    unit_id: "UEL0106",
    faction: Uef,
    name: Some("Mech Marine"),
    description: "Light Assault Bot",
    build_cost_mass: 30,
    build_cost_energy: 120,
    build_time: 120,
    categories: ["LAND", "TECH1"],
  },
  {
    unit_id: "UEL0201",
    faction: Uef,
    name: Some("MA12 Striker"),
    description: "Medium Tank",
    build_cost_mass: 56,
    build_cost_energy: 266,
    build_time: 300,
    categories: ["LAND", "TECH1"],
  },
  // T2 Land Units
  {
    unit_id: "UEL0202",
    faction: Uef,
    name: Some("Pillar"),
    description: "Heavy Tank",
    build_cost_mass: 198,
    build_cost_energy: 990,
    build_time: 880,
    categories: ["LAND", "TECH2"],
  },
  // T3 Land Units
  {
    unit_id: "UEL0303",
    faction: Uef,
    name: Some("Titan"),
    description: "Heavy Assault Bot",
    build_cost_mass: 480,
    build_cost_energy: 5250,
    build_time: 2400,
    categories: ["LAND", "TECH3"],
  },
  // T1 Economy
  {
    unit_id: "UEB1101",
    faction: Uef,
    name: None,
    description: "Power Generator",
    build_cost_mass: 75,
    build_cost_energy: 750,
    build_time: 125,
    categories: ["STRUCTURE", "TECH1"],
  },
  {
    unit_id: "UEB1103",
    faction: Uef,
    name: None,
    description: "Mass Extractor",
    build_cost_mass: 36,
    build_cost_energy: 360,
    build_time: 60,
    categories: ["STRUCTURE", "TECH1"],
  },
  // T2 Economy
  {
    unit_id: "UEB1201",
    faction: Uef,
    name: None,
    description: "Power Generator",
    build_cost_mass: 1200,
    build_cost_energy: 12000,
    build_time: 2198,
    categories: ["STRUCTURE", "TECH2"],
  },
  // T1 Factory
  {
    unit_id: "UEB0101",
    faction: Uef,
    name: None,
    description: "Land Factory",
    build_cost_mass: 240,
    build_cost_energy: 2100,
    build_time: 300,
    categories: ["STRUCTURE", "TECH1", "LAND"],
  },
];

let cybran_units = () => [
  {
    UnitModel.unit_id: "URL0105",
    faction: Faction.Cybran,
    name: None,
    description: "Engineer",
    build_cost_mass: 52,
    build_cost_energy: 260,
    build_time: 260,
    categories: ["ENGINEER", "TECH1", "LAND"],
  },
  {
    unit_id: "URL0101",
    faction: Cybran,
    name: Some("Mole"),
    description: "Land Scout",
    build_cost_mass: 12,
    build_cost_energy: 80,
    build_time: 60,
    categories: ["LAND", "TECH1"],
  },
  {
    unit_id: "URL0107",
    faction: Cybran,
    name: Some("Mantis"),
    description: "Light Assault Bot",
    build_cost_mass: 52,
    build_cost_energy: 260,
    build_time: 260,
    categories: ["LAND", "TECH1"],
  },
  {
    unit_id: "URB1103",
    faction: Cybran,
    name: None,
    description: "Mass Extractor",
    build_cost_mass: 36,
    build_cost_energy: 360,
    build_time: 60,
    categories: ["STRUCTURE", "TECH1"],
  },
];

let aeon_units = () => [
  {
    UnitModel.unit_id: "UAL0105",
    faction: Faction.Aeon,
    name: None,
    description: "Engineer",
    build_cost_mass: 52,
    build_cost_energy: 260,
    build_time: 260,
    categories: ["ENGINEER", "TECH1", "LAND"],
  },
  {
    unit_id: "UAL0101",
    faction: Aeon,
    name: Some("Spirit"),
    description: "Land Scout",
    build_cost_mass: 12,
    build_cost_energy: 80,
    build_time: 60,
    categories: ["LAND", "TECH1"],
  },
  {
    unit_id: "UAB1103",
    faction: Aeon,
    name: None,
    description: "Mass Extractor",
    build_cost_mass: 36,
    build_cost_energy: 360,
    build_time: 60,
    categories: ["STRUCTURE", "TECH1"],
  },
];

let seraphim_units = () => [
  {
    UnitModel.unit_id: "XSL0105",
    faction: Faction.Seraphim,
    name: None,
    description: "Engineer",
    build_cost_mass: 52,
    build_cost_energy: 260,
    build_time: 260,
    categories: ["ENGINEER", "TECH1", "LAND"],
  },
  {
    unit_id: "XSL0101",
    faction: Seraphim,
    name: Some("Selen"),
    description: "Land Scout",
    build_cost_mass: 12,
    build_cost_energy: 80,
    build_time: 60,
    categories: ["LAND", "TECH1"],
  },
  {
    unit_id: "XSB1103",
    faction: Seraphim,
    name: None,
    description: "Mass Extractor",
    build_cost_mass: 36,
    build_cost_energy: 360,
    build_time: 60,
    categories: ["STRUCTURE", "TECH1"],
  },
];

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
