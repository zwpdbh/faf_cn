use serde::{Deserialize, Serialize};

/// Current economic state at any point in time
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Default)]
pub struct EcoState {
    pub mass_storage: f64,
    pub mass_storage_max: f64,
    pub energy_storage: f64,
    pub energy_storage_max: f64,
    pub mass_income: f64,
    pub energy_income: f64,
    pub build_power: f64,
    // Engineer counts for calculating build power
    pub t1_engineers: i32,
    pub t2_engineers: i32,
    pub t3_engineers: i32,
}

impl EcoState {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_initial_eco(
        mass_income: f64,
        energy_income: f64,
        mass_storage: f64,
        energy_storage: f64,
        build_power: f64,
    ) -> Self {
        Self {
            mass_storage,
            mass_storage_max: mass_storage,
            energy_storage,
            energy_storage_max: energy_storage,
            mass_income,
            energy_income,
            build_power,
            t1_engineers: 1,
            t2_engineers: 0,
            t3_engineers: 0,
        }
    }

    /// Check if we can afford a drain rate for one tick
    pub fn can_afford(&self, mass_drain: f64, energy_drain: f64, dt: f64) -> bool {
        self.mass_storage >= mass_drain * dt && self.energy_storage >= energy_drain * dt
    }

    /// Apply income and drain for one tick
    pub fn tick(&mut self, mass_drain: f64, energy_drain: f64, dt: f64) {
        // Add income
        self.mass_storage += self.mass_income * dt;
        self.energy_storage += self.energy_income * dt;

        // Apply drain (if affordable)
        if self.can_afford(mass_drain, energy_drain, dt) {
            self.mass_storage -= mass_drain * dt;
            self.energy_storage -= energy_drain * dt;
        }

        // Clamp to storage max
        self.mass_storage = self.mass_storage.min(self.mass_storage_max);
        self.energy_storage = self.energy_storage.min(self.energy_storage_max);
        
        // Clamp to zero (can't go negative)
        self.mass_storage = self.mass_storage.max(0.0);
        self.energy_storage = self.energy_storage.max(0.0);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_eco_tick() {
        // Start with room to grow
        let mut state = EcoState {
            mass_storage: 500.0,
            mass_storage_max: 1000.0,
            energy_storage: 5000.0,
            energy_storage_max: 10000.0,
            mass_income: 10.0,
            energy_income: 100.0,
            build_power: 10.0,
            t1_engineers: 1,
            t2_engineers: 0,
            t3_engineers: 0,
        };
        
        // Tick with no drain
        state.tick(0.0, 0.0, 1.0);
        
        assert_eq!(state.mass_storage, 510.0);
        assert_eq!(state.energy_storage, 5100.0);
    }

    #[test]
    fn test_storage_cap() {
        let mut state = EcoState {
            mass_storage: 500.0,
            mass_storage_max: 650.0,
            energy_storage: 5000.0,
            energy_storage_max: 6500.0,
            mass_income: 100.0,
            energy_income: 1000.0,
            build_power: 10.0,
            t1_engineers: 1,
            t2_engineers: 0,
            t3_engineers: 0,
        };
        
        // Tick - should cap at max
        state.tick(0.0, 0.0, 10.0);
        
        // 500 + 100*10 = 1500, capped at 650
        assert_eq!(state.mass_storage, 650.0);
        assert_eq!(state.energy_storage, 6500.0);
    }
}
