use fafcn_core::models::{Unit, Faction};

mod units;

pub use units::UNITS;

pub fn get_units() -> Vec<Unit> {
    UNITS.to_vec()
}

pub fn get_all_units() -> Vec<Unit> {
    UNITS.to_vec()
}

pub fn get_units_by_faction(faction: Faction) -> Vec<Unit> {
    UNITS.iter()
        .filter(|u| u.faction == faction)
        .cloned()
        .collect()
}

pub fn get_unit_by_id(unit_id: &str) -> Option<Unit> {
    UNITS.iter()
        .find(|u| u.unit_id == unit_id)
        .cloned()
}

pub fn filter_units(
    faction: Option<Faction>,
    category: Option<&str>,
    tech_level: Option<&str>,
    search: Option<&str>,
) -> Vec<Unit> {
    UNITS.iter()
        .filter(|u| {
            if let Some(f) = faction {
                if u.faction != f { return false; }
            }
            if let Some(cat) = category {
                if !u.categories.contains(&cat.to_string()) { return false; }
            }
            if let Some(tech) = tech_level {
                if !u.categories.contains(&tech.to_string()) { return false; }
            }
            if let Some(s) = search {
                let s_lower = s.to_lowercase();
                let matches_name = u.name.as_ref()
                    .map(|n| n.to_lowercase().contains(&s_lower))
                    .unwrap_or(false);
                let matches_desc = u.description.as_ref()
                    .map(|d| d.to_lowercase().contains(&s_lower))
                    .unwrap_or(false);
                let matches_id = u.unit_id.to_lowercase().contains(&s_lower);
                if !matches_name && !matches_desc && !matches_id { return false; }
            }
            true
        })
        .cloned()
        .collect()
}
