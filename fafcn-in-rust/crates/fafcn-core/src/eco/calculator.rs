//! Eco comparison calculator
//! 
//! This module provides pure functions for calculating economy ratios
//! and comparisons between units.

use crate::models::Unit;

/// Eco ratio between two units
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct EcoRatio {
    pub mass: f64,
    pub energy: f64,
    pub build_time: f64,
}

impl EcoRatio {
    /// Format mass ratio with 2 decimal places
    pub fn mass_formatted(&self) -> String {
        format!("{:.2}x", self.mass)
    }

    /// Format energy ratio with 2 decimal places
    pub fn energy_formatted(&self) -> String {
        format!("{:.2}x", self.energy)
    }

    /// Format build time ratio with 2 decimal places
    pub fn build_time_formatted(&self) -> String {
        format!("{:.2}x", self.build_time)
    }

    /// Get color class for mass ratio
    pub fn mass_color_class(&self) -> &'static str {
        ratio_color_class(self.mass)
    }

    /// Get color class for energy ratio
    pub fn energy_color_class(&self) -> &'static str {
        ratio_color_class(self.energy)
    }

    /// Get color class for build time ratio
    pub fn build_time_color_class(&self) -> &'static str {
        ratio_color_class(self.build_time)
    }

    /// Get badge color class based on mass ratio
    pub fn badge_class(&self) -> &'static str {
        ratio_badge_class(self.mass)
    }
}

/// Calculate eco ratio between base unit and compare unit
pub fn calculate_eco_ratio(base: &Unit, compare: &Unit) -> EcoRatio {
    let base_mass = base.build_cost_mass.max(1) as f64;
    let base_energy = base.build_cost_energy.max(1) as f64;
    let base_time = base.build_time.max(1) as f64;

    let compare_mass = compare.build_cost_mass.max(1) as f64;
    let compare_energy = compare.build_cost_energy.max(1) as f64;
    let compare_time = compare.build_time.max(1) as f64;

    EcoRatio {
        mass: (compare_mass / base_mass * 100.0).round() / 100.0,
        energy: (compare_energy / base_energy * 100.0).round() / 100.0,
        build_time: (compare_time / base_time * 100.0).round() / 100.0,
    }
}

/// Generate comparisons against the base engineer unit
pub fn generate_engineer_comparisons(base_unit: &Unit, selected_units: &[Unit]) -> Vec<(Unit, usize, EcoRatio)> {
    selected_units
        .iter()
        .enumerate()
        .map(|(idx, unit)| {
            let ratio = calculate_eco_ratio(base_unit, unit);
            (unit.clone(), idx, ratio)
        })
        .collect()
}

/// Cross comparison entry
#[derive(Debug, Clone, PartialEq)]
pub struct CrossComparison {
    pub base_unit: Unit,
    pub comparisons: Vec<(Unit, EcoRatio)>,
}

/// Generate tiered cross-comparisons between selected units
/// 
/// This creates a structure where each unit is compared against
/// units that are more expensive than it, sorted by mass cost.
pub fn generate_tiered_cross_comparisons(base_unit: &Unit, selected_units: &[Unit]) -> Vec<CrossComparison> {
    // Combine all units and sort by mass (cheapest first)
    let mut all_units: Vec<Unit> = std::iter::once(base_unit.clone())
        .chain(selected_units.iter().cloned())
        .collect();
    
    all_units.sort_by_key(|u| u.build_cost_mass);

    // Generate tiered comparisons - skip last unit (nothing to compare against)
    all_units
        .iter()
        .enumerate()
        .filter(|(idx, _)| *idx < all_units.len() - 1)
        .map(|(idx, base)| {
            let remaining: Vec<Unit> = all_units.iter().skip(idx + 1).cloned().collect();
            let comparisons: Vec<(Unit, EcoRatio)> = remaining
                .into_iter()
                .map(|target| {
                    let ratio = calculate_eco_ratio(base, &target);
                    (target, ratio)
                })
                .collect();
            
            CrossComparison {
                base_unit: base.clone(),
                comparisons,
            }
        })
        .collect()
}

/// Get color class based on ratio value
/// 
/// - < 0.8: Green (efficient)
/// - > 5.0: Red (very expensive)
/// - > 1.5: Orange (expensive)
/// - Default: Yellow
pub fn ratio_color_class(ratio: f64) -> &'static str {
    if ratio < 0.8 {
        "text-green-600 font-semibold"
    } else if ratio > 5.0 {
        "text-red-600 font-semibold"
    } else if ratio > 1.5 {
        "text-orange-500 font-semibold"
    } else {
        "text-yellow-600 font-medium"
    }
}

/// Get badge color class based on ratio value
pub fn ratio_badge_class(ratio: f64) -> &'static str {
    if ratio < 0.8 {
        "bg-green-100 text-green-800"
    } else if ratio > 5.0 {
        "bg-red-100 text-red-800"
    } else if ratio > 1.5 {
        "bg-orange-100 text-orange-800"
    } else {
        "bg-yellow-100 text-yellow-800"
    }
}

/// Calculate total mass cost of selected units
pub fn total_mass_cost(units: &[Unit]) -> i32 {
    units.iter().map(|u| u.build_cost_mass).sum()
}

/// Calculate total energy cost of selected units
pub fn total_energy_cost(units: &[Unit]) -> i32 {
    units.iter().map(|u| u.build_cost_energy).sum()
}

/// Calculate total build time of selected units
pub fn total_build_time(units: &[Unit]) -> i32 {
    units.iter().map(|u| u.build_time).sum()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::{Faction, Unit};

    fn create_test_unit(unit_id: &str, mass: i32, energy: i32, build_time: i32) -> Unit {
        Unit {
            unit_id: unit_id.to_string(),
            faction: Faction::Uef,
            name: Some("Test Unit".to_string()),
            description: "Test Description".to_string(),
            build_cost_mass: mass,
            build_cost_energy: energy,
            build_time,
            categories: vec!["LAND".to_string(), "TECH1".to_string()],
        }
    }

    #[test]
    fn test_calculate_eco_ratio() {
        let base = create_test_unit("BASE001", 100, 1000, 100);
        let compare = create_test_unit("COMP001", 200, 2000, 150);

        let ratio = calculate_eco_ratio(&base, &compare);

        assert_eq!(ratio.mass, 2.0);
        assert_eq!(ratio.energy, 2.0);
        assert_eq!(ratio.build_time, 1.5);
    }

    #[test]
    fn test_ratio_color_class() {
        assert!(ratio_color_class(0.5).contains("green"));
        assert!(ratio_color_class(6.0).contains("red"));
        assert!(ratio_color_class(2.0).contains("orange"));
        assert!(ratio_color_class(1.0).contains("yellow"));
    }

    #[test]
    fn test_total_costs() {
        let units = vec![
            create_test_unit("U1", 100, 1000, 100),
            create_test_unit("U2", 200, 2000, 200),
            create_test_unit("U3", 300, 3000, 300),
        ];

        assert_eq!(total_mass_cost(&units), 600);
        assert_eq!(total_energy_cost(&units), 6000);
        assert_eq!(total_build_time(&units), 600);
    }
}
