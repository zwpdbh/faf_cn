type t = {
  unit_id: string,
  faction: Faction.t,
  name: option(string),
  description: string,
  build_cost_mass: int,
  build_cost_energy: int,
  build_time: int,
  categories: list(string),
};

let tech_level = unit =>
  if (List.mem("TECH1", unit.categories)) {
    Some(1);
  } else if (List.mem("TECH2", unit.categories)) {
    Some(2);
  } else if (List.mem("TECH3", unit.categories)) {
    Some(3);
  } else if (List.mem("EXPERIMENTAL", unit.categories)) {
    Some(4);
  } else {
    None;
  };

let tech_badge = unit => {
  switch (tech_level(unit)) {
  | Some(1) => "T1"
  | Some(2) => "T2"
  | Some(3) => "T3"
  | Some(4) => "EXP"
  | Some(_) => "T1"
  | None => "T1"
  };
};

let matches_filters = (filters, unit) => {
  filters == [] || List.for_all(f => List.mem(f, unit.categories), filters);
};

let display_name = unit => {
  let standardized = [
    "Mass Extractor",
    "Mass Fabricator",
    "Power Generator",
    "Energy Generator",
    "Hydrocarbon Power Plant",
  ];

  let multi_tier = [
    "Mass Extractor",
    "Mass Fabricator",
    "Power Generator",
    "Energy Storage",
    "Mass Storage",
    "Engineer",
    "Land Factory",
    "Land Factory HQ",
    "Air Factory",
    "Air Factory HQ",
    "Naval Factory",
    "Naval Factory HQ",
    "Point Defense",
    "Anti-Air Turret",
    "Anti-Air Defense",
    "Anti-Air Flak Artillery",
    "Anti-Air SAM Launcher",
    "Artillery Installation",
    "Torpedo Launcher",
    "Radar System",
    "Sonar System",
  ];

  let base_name =
    if (List.mem(unit.description, standardized)) {
      unit.description;
    } else {
      Option.value(unit.name, ~default=unit.description);
    };

  if (List.mem(unit.description, multi_tier)) {
    Printf.sprintf("%s %s", tech_badge(unit), base_name);
  } else {
    base_name;
  };
};

let faction_bg_class = u => Faction.bg_class(u.faction);
let faction_badge_class = u => Faction.badge_class(u.faction);
