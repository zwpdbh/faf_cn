use serde::{Deserialize, Serialize};
use crate::models::Unit;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct BuildItem {
    pub unit: Unit,
    pub quantity: i32,
    #[serde(default)]
    pub progress: f64,
}

impl BuildItem {
    pub fn new(unit: Unit, quantity: i32) -> Self {
        Self {
            unit,
            quantity,
            progress: 0.0,
        }
    }

    /// Total mass cost
    pub fn total_mass(&self) -> i32 {
        self.unit.build_cost_mass * self.quantity
    }

    /// Total energy cost
    pub fn total_energy(&self) -> i32 {
        self.unit.build_cost_energy * self.quantity
    }

    /// Total build time at 1 BP
    pub fn base_build_time(&self) -> f64 {
        self.unit.build_time as f64 * self.quantity as f64
    }

    /// Mass drain per second at given BP
    pub fn mass_drain_per_sec(&self, build_power: f64) -> f64 {
        if self.unit.build_time == 0 {
            return 0.0;
        }
        self.unit.build_cost_mass as f64 * build_power / self.unit.build_time as f64
    }

    /// Energy drain per second at given BP
    pub fn energy_drain_per_sec(&self, build_power: f64) -> f64 {
        if self.unit.build_time == 0 {
            return 0.0;
        }
        self.unit.build_cost_energy as f64 * build_power / self.unit.build_time as f64
    }

    /// Is this item complete?
    pub fn is_complete(&self) -> bool {
        self.progress >= 1.0
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::{Faction};
    use chrono::Utc;

    fn create_test_unit() -> Unit {
        Unit {
            id: 1,
            unit_id: "UEB0101".to_string(),
            faction: Faction::Uef,
            name: Some("Test Unit".to_string()),
            description: None,
            build_cost_mass: 100,
            build_cost_energy: 1000,
            build_time: 100,
            categories: vec![],
            data: serde_json::json!({}),
            created_at: Utc::now(),
            updated_at: Utc::now(),
        }
    }

    #[test]
    fn test_total_costs() {
        let unit = create_test_unit();
        let item = BuildItem::new(unit, 5);
        
        assert_eq!(item.total_mass(), 500);
        assert_eq!(item.total_energy(), 5000);
    }

    #[test]
    fn test_drain_rates() {
        let unit = create_test_unit();
        let item = BuildItem::new(unit, 1);
        
        // At 10 BP
        let mass_drain = item.mass_drain_per_sec(10.0);
        let energy_drain = item.energy_drain_per_sec(10.0);
        
        // (100 mass / 100 time) * 10 BP = 10 mass/s
        assert_eq!(mass_drain, 10.0);
        // (1000 energy / 100 time) * 10 BP = 100 energy/s
        assert_eq!(energy_drain, 100.0);
    }
}
