use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};

/// FAF Unit entity
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Unit {
    pub id: i64,
    pub unit_id: String,
    pub faction: Faction,
    pub name: Option<String>,
    pub description: Option<String>,
    pub build_cost_mass: i32,
    pub build_cost_energy: i32,
    pub build_time: i32,
    pub categories: Vec<String>,
    pub data: serde_json::Value,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash)]
#[serde(rename_all = "UPPERCASE")]
pub enum Faction {
    Uef,
    Cybran,
    Aeon,
    Seraphim,
}

impl std::fmt::Display for Faction {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Faction::Uef => write!(f, "UEF"),
            Faction::Cybran => write!(f, "CYBRAN"),
            Faction::Aeon => write!(f, "AEON"),
            Faction::Seraphim => write!(f, "SERAPHIM"),
        }
    }
}

impl std::str::FromStr for Faction {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_uppercase().as_str() {
            "UEF" => Ok(Faction::Uef),
            "CYBRAN" => Ok(Faction::Cybran),
            "AEON" => Ok(Faction::Aeon),
            "SERAPHIM" => Ok(Faction::Seraphim),
            _ => Err(format!("Unknown faction: {}", s)),
        }
    }
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "UPPERCASE")]
pub enum TechLevel {
    T1,
    T2,
    T3,
    Experimental,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq)]
pub enum UnitCategory {
    Engineer,
    Structure,
    Land,
    Air,
    Naval,
}

impl Unit {
    /// Get tech level from categories
    pub fn tech_level(&self) -> Option<TechLevel> {
        if self.categories.contains(&"TECH1".to_string()) {
            Some(TechLevel::T1)
        } else if self.categories.contains(&"TECH2".to_string()) {
            Some(TechLevel::T2)
        } else if self.categories.contains(&"TECH3".to_string()) {
            Some(TechLevel::T3)
        } else if self.categories.contains(&"EXPERIMENTAL".to_string()) {
            Some(TechLevel::Experimental)
        } else {
            None
        }
    }

    /// Check if unit matches filter criteria
    pub fn matches_filter(&self, filter: &UnitFilter) -> bool {
        if let Some(faction) = &filter.faction {
            if self.faction != *faction {
                return false;
            }
        }

        if let Some(category) = &filter.category {
            if !self.categories.contains(category) {
                return false;
            }
        }

        if let Some(tech) = &filter.tech_level {
            if self.tech_level() != Some(*tech) {
                return false;
            }
        }

        if let Some(search) = &filter.search {
            let search_lower = search.to_lowercase();
            let matches_name = self.name.as_ref()
                .map(|n| n.to_lowercase().contains(&search_lower))
                .unwrap_or(false);
            let matches_desc = self.description.as_ref()
                .map(|d| d.to_lowercase().contains(&search_lower))
                .unwrap_or(false);
            let matches_id = self.unit_id.to_lowercase().contains(&search_lower);
            
            if !matches_name && !matches_desc && !matches_id {
                return false;
            }
        }

        true
    }
}

#[derive(Debug, Clone, Default)]
pub struct UnitFilter {
    pub faction: Option<Faction>,
    pub category: Option<String>,
    pub tech_level: Option<TechLevel>,
    pub search: Option<String>,
}

#[cfg(test)]
mod tests {
    use super::*;

    fn create_test_unit() -> Unit {
        Unit {
            id: 1,
            unit_id: "UEB0101".to_string(),
            faction: Faction::Uef,
            name: Some("Land Factory".to_string()),
            description: Some("T1 Land Factory".to_string()),
            build_cost_mass: 240,
            build_cost_energy: 2100,
            build_time: 300,
            categories: vec!["STRUCTURE".to_string(), "TECH1".to_string(), "FACTORY".to_string()],
            data: serde_json::json!({}),
            created_at: Utc::now(),
            updated_at: Utc::now(),
        }
    }

    #[test]
    fn test_tech_level_detection() {
        let unit = create_test_unit();
        assert_eq!(unit.tech_level(), Some(TechLevel::T1));
    }

    #[test]
    fn test_faction_filter() {
        let unit = create_test_unit();
        
        let matching_filter = UnitFilter {
            faction: Some(Faction::Uef),
            ..Default::default()
        };
        assert!(unit.matches_filter(&matching_filter));

        let non_matching_filter = UnitFilter {
            faction: Some(Faction::Cybran),
            ..Default::default()
        };
        assert!(!unit.matches_filter(&non_matching_filter));
    }

    #[test]
    fn test_search_filter() {
        let unit = create_test_unit();
        
        let filter = UnitFilter {
            search: Some("factory".to_string()),
            ..Default::default()
        };
        assert!(unit.matches_filter(&filter));
    }
}
