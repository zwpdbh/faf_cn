/// FAF Unit entity - simplified for frontend use without DB timestamps
#[derive(Debug, Clone, PartialEq)]
pub struct Unit {
    pub unit_id: String,
    pub faction: Faction,
    pub name: Option<String>,
    pub description: String,
    pub build_cost_mass: i32,
    pub build_cost_energy: i32,
    pub build_time: i32,
    pub categories: Vec<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Faction {
    Uef,
    Cybran,
    Aeon,
    Seraphim,
}

impl Faction {
    pub fn as_str(&self) -> &'static str {
        match self {
            Faction::Uef => "UEF",
            Faction::Cybran => "CYBRAN",
            Faction::Aeon => "AEON",
            Faction::Seraphim => "SERAPHIM",
        }
    }

    pub fn all() -> Vec<Faction> {
        vec![Faction::Uef, Faction::Cybran, Faction::Aeon, Faction::Seraphim]
    }
}

impl std::fmt::Display for Faction {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.as_str())
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

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum TechLevel {
    T1,
    T2,
    T3,
    Experimental,
}

impl TechLevel {
    pub fn as_str(&self) -> &'static str {
        match self {
            TechLevel::T1 => "T1",
            TechLevel::T2 => "T2",
            TechLevel::T3 => "T3",
            TechLevel::Experimental => "EXP",
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum UnitCategory {
    Engineer,
    Structure,
    Land,
    Air,
    Naval,
}

impl UnitCategory {
    pub fn as_str(&self) -> &'static str {
        match self {
            UnitCategory::Engineer => "ENGINEER",
            UnitCategory::Structure => "STRUCTURE",
            UnitCategory::Land => "LAND",
            UnitCategory::Air => "AIR",
            UnitCategory::Naval => "NAVAL",
        }
    }
}

/// Filter definition for UI filters
#[derive(Debug, Clone, PartialEq)]
pub struct Filter {
    pub key: String,
    pub label: String,
    pub category: String,
    pub group: FilterGroup,
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum FilterGroup {
    Usage,
    Tech,
}

impl Filter {
    pub fn all_filters() -> Vec<Filter> {
        vec![
            // Usage filters
            Filter { key: "ENGINEER".to_string(), label: "Engineer".to_string(), category: "ENGINEER".to_string(), group: FilterGroup::Usage },
            Filter { key: "STRUCTURE".to_string(), label: "Structure".to_string(), category: "STRUCTURE".to_string(), group: FilterGroup::Usage },
            Filter { key: "LAND".to_string(), label: "Land".to_string(), category: "LAND".to_string(), group: FilterGroup::Usage },
            Filter { key: "AIR".to_string(), label: "Air".to_string(), category: "AIR".to_string(), group: FilterGroup::Usage },
            Filter { key: "NAVAL".to_string(), label: "Naval".to_string(), category: "NAVAL".to_string(), group: FilterGroup::Usage },
            // Tech filters
            Filter { key: "TECH1".to_string(), label: "T1".to_string(), category: "TECH1".to_string(), group: FilterGroup::Tech },
            Filter { key: "TECH2".to_string(), label: "T2".to_string(), category: "TECH2".to_string(), group: FilterGroup::Tech },
            Filter { key: "TECH3".to_string(), label: "T3".to_string(), category: "TECH3".to_string(), group: FilterGroup::Tech },
            Filter { key: "EXPERIMENTAL".to_string(), label: "EXP".to_string(), category: "EXPERIMENTAL".to_string(), group: FilterGroup::Tech },
        ]
    }

    pub fn usage_filters() -> Vec<String> {
        vec!["ENGINEER".to_string(), "STRUCTURE".to_string(), "LAND".to_string(), "AIR".to_string(), "NAVAL".to_string()]
    }

    pub fn tech_filters() -> Vec<String> {
        vec!["TECH1".to_string(), "TECH2".to_string(), "TECH3".to_string(), "EXPERIMENTAL".to_string()]
    }
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

    /// Get tech level badge string
    pub fn tech_badge(&self) -> String {
        match self.tech_level() {
            Some(TechLevel::T1) => "T1".to_string(),
            Some(TechLevel::T2) => "T2".to_string(),
            Some(TechLevel::T3) => "T3".to_string(),
            Some(TechLevel::Experimental) => "EXP".to_string(),
            None => "T1".to_string(),
        }
    }

    /// Check if unit matches filter criteria
    pub fn matches_filters(&self, active_filters: &[String]) -> bool {
        if active_filters.is_empty() {
            return true;
        }
        active_filters.iter().all(|filter| self.categories.contains(filter))
    }

    /// Get display name with tier prefix for multi-tier units
    pub fn display_name(&self) -> String {
        let standardized = ["Mass Extractor", "Mass Fabricator", "Power Generator", 
                          "Energy Generator", "Hydrocarbon Power Plant"];
        
        let multi_tier = ["Mass Extractor", "Mass Fabricator", "Power Generator", 
                         "Energy Storage", "Mass Storage", "Engineer",
                         "Land Factory", "Land Factory HQ", "Air Factory", "Air Factory HQ",
                         "Naval Factory", "Naval Factory HQ", "Point Defense",
                         "Anti-Air Turret", "Anti-Air Defense", "Anti-Air Flak Artillery",
                         "Anti-Air SAM Launcher", "Artillery Installation", "Torpedo Launcher",
                         "Radar System", "Sonar System"];
        
        let base_name = if standardized.contains(&self.description.as_str()) {
            self.description.clone()
        } else {
            self.name.clone().unwrap_or_else(|| self.description.clone())
        };

        // Add tier prefix for multi-tier units
        if multi_tier.contains(&self.description.as_str()) {
            format!("{} {}", self.tech_badge(), base_name)
        } else {
            base_name
        }
    }

    /// Get faction background class for styling
    pub fn faction_bg_class(&self) -> &'static str {
        match self.faction {
            Faction::Uef => "unit-bg-uef",
            Faction::Cybran => "unit-bg-cybran",
            Faction::Aeon => "unit-bg-aeon",
            Faction::Seraphim => "unit-bg-seraphim",
        }
    }

    /// Get faction badge class for styling  
    pub fn faction_badge_class(&self) -> &'static str {
        match self.faction {
            Faction::Uef => "bg-blue-100 text-blue-800",
            Faction::Cybran => "bg-red-100 text-red-800",
            Faction::Aeon => "bg-emerald-100 text-emerald-800",
            Faction::Seraphim => "bg-violet-100 text-violet-800",
        }
    }
}

/// Format number with commas for thousands
pub fn format_number(n: i32) -> String {
    if n < 1000 {
        return n.to_string();
    }
    let s = n.to_string();
    let chars: Vec<char> = s.chars().rev().collect();
    let mut result = String::new();
    for (i, c) in chars.iter().enumerate() {
        if i > 0 && i % 3 == 0 {
            result.push(',');
        }
        result.push(*c);
    }
    result.chars().rev().collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn create_test_unit() -> Unit {
        Unit {
            unit_id: "UEB0101".to_string(),
            faction: Faction::Uef,
            name: Some("Land Factory".to_string()),
            description: "Land Factory".to_string(),
            build_cost_mass: 240,
            build_cost_energy: 2100,
            build_time: 300,
            categories: vec!["STRUCTURE".to_string(), "TECH1".to_string(), "LAND".to_string()],
        }
    }

    #[test]
    fn test_tech_level_detection() {
        let unit = create_test_unit();
        assert_eq!(unit.tech_level(), Some(TechLevel::T1));
    }

    #[test]
    fn test_format_number() {
        assert_eq!(format_number(100), "100");
        assert_eq!(format_number(1000), "1,000");
        assert_eq!(format_number(1000000), "1,000,000");
    }

    #[test]
    fn test_display_name() {
        let unit = create_test_unit();
        assert_eq!(unit.display_name(), "T1 Land Factory");
    }
}
