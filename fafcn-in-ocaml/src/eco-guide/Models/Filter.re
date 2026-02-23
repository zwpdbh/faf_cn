type group =
  | Usage
  | Tech;

type t = {
  key: string,
  label: string,
  category: string,
  group,
};

let all_filters = () => [
  {key: "ENGINEER", label: "Engineer", category: "ENGINEER", group: Usage},
  {key: "STRUCTURE", label: "Structure", category: "STRUCTURE", group: Usage},
  {key: "LAND", label: "Land", category: "LAND", group: Usage},
  {key: "AIR", label: "Air", category: "AIR", group: Usage},
  {key: "NAVAL", label: "Naval", category: "NAVAL", group: Usage},
  {key: "TECH1", label: "T1", category: "TECH1", group: Tech},
  {key: "TECH2", label: "T2", category: "TECH2", group: Tech},
  {key: "TECH3", label: "T3", category: "TECH3", group: Tech},
  {key: "EXPERIMENTAL", label: "EXP", category: "EXPERIMENTAL", group: Tech},
];

let usage_filters = ["ENGINEER", "STRUCTURE", "LAND", "AIR", "NAVAL"];
let tech_filters = ["TECH1", "TECH2", "TECH3", "EXPERIMENTAL"];

let is_usage_filter = key => List.mem(key, usage_filters);
let is_tech_filter = key => List.mem(key, tech_filters);
