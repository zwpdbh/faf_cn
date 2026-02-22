use dioxus::prelude::*;
use fafcn_core::{Faction, Unit};

#[derive(Props, Clone, PartialEq)]
pub struct EcoComparisonProps {
    pub base_unit: Unit,
    pub selected_units: Vec<Unit>,
}

/// Helper struct for ratio calculations
#[derive(Clone, Copy, Debug, PartialEq)]
struct UnitRatio {
    mass: f64,
    energy: f64,
    build_time: f64,
}

fn calculate_ratio(base: i32, target: i32) -> f64 {
    if base == 0 {
        0.0
    } else {
        (target as f64 / base as f64 * 10.0).round() / 10.0
    }
}

fn get_faction_bg_class(faction: Faction) -> &'static str {
    match faction {
        Faction::Uef => "unit-bg-uef",
        Faction::Cybran => "unit-bg-cybran",
        Faction::Aeon => "unit-bg-aeon",
        Faction::Seraphim => "unit-bg-seraphim",
    }
}

fn get_ratio_badge_class(ratio: f64) -> &'static str {
    if ratio < 1.0 {
        "bg-emerald-100 text-emerald-700"
    } else if ratio < 5.0 {
        "bg-blue-100 text-blue-700"
    } else if ratio < 20.0 {
        "bg-yellow-100 text-yellow-700"
    } else {
        "bg-red-100 text-red-700"
    }
}

fn get_ratio_color_class(ratio: f64) -> &'static str {
    if ratio < 1.0 {
        "font-semibold text-emerald-600"
    } else if ratio < 5.0 {
        "font-semibold text-blue-600"
    } else if ratio < 20.0 {
        "font-semibold text-yellow-600"
    } else {
        "font-semibold text-red-600"
    }
}

fn format_number(n: i32) -> String {
    if n >= 1000 {
        format!("{:.1}k", n as f64 / 1000.0)
    } else {
        n.to_string()
    }
}

fn format_unit_name(unit: &Unit) -> String {
    unit.description
        .clone()
        .or_else(|| unit.name.clone())
        .unwrap_or_else(|| unit.unit_id.clone())
}

#[component]
pub fn EcoComparison(props: EcoComparisonProps) -> Element {
    let has_selections = !props.selected_units.is_empty();

    rsx! {
        div { class: "bg-white rounded-lg shadow-sm border border-gray-200 p-4 h-fit",
            h2 { class: "text-lg font-semibold text-gray-900 mb-4", "Eco Comparison" }

            if !has_selections {
                EmptyComparisonState {}
            } else {
                div { class: "space-y-4",
                    BaseUnitComparison {
                        base_unit: props.base_unit.clone(),
                        selected_units: props.selected_units.clone(),
                    }
                    CrossUnitComparison {
                        base_unit: props.base_unit.clone(),
                        selected_units: props.selected_units.clone(),
                    }
                    ComparisonSummaryStats {
                        selected_units: props.selected_units.clone(),
                    }
                }
            }
        }
    }
}

#[component]
fn EmptyComparisonState() -> Element {
    rsx! {
        div { class: "text-center py-8 text-gray-500",
            // Calculator icon
            svg {
                class: "mx-auto h-10 w-10 text-gray-300 mb-3",
                fill: "none",
                view_box: "0 0 24 24",
                stroke: "currentColor",
                stroke_width: "1.5",
                path {
                    stroke_linecap: "round",
                    stroke_linejoin: "round",
                    d: "M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z"
                }
            }
            p { class: "text-sm", "Select units to see comparisons against the Engineer." }
        }
    }
}

#[component]
fn BaseUnitComparison(props: BaseUnitComparisonProps) -> Element {
    let faction_bg = get_faction_bg_class(props.base_unit.faction);
    let unit_icon_class = format!("unit-icon-{}", props.base_unit.unit_id);

    rsx! {
        div {
            div { class: "bg-gray-100 rounded-lg p-2 mb-3 border border-gray-200",
                // Base unit header
                div { class: "flex items-center gap-2 mb-2",
                    div { class: "w-8 h-8 rounded shrink-0 overflow-hidden relative {faction_bg}",
                        div {
                            class: "{unit_icon_class} absolute",
                            style: "width: 64px; height: 64px; transform: scale(0.5); transform-origin: top left;"
                        }
                    }
                    div { class: "flex-1 min-w-0",
                        span { class: "text-xs font-semibold text-gray-900 truncate",
                            {format_unit_name(&props.base_unit)}
                        }
                        p { class: "text-[10px] text-gray-500", {props.base_unit.unit_id.clone()} }
                    }
                }

                // Base unit eco values
                div { class: "grid grid-cols-3 gap-1 text-[10px] text-center",
                    div { class: "bg-white rounded p-1",
                        span { class: "block text-gray-400", "Mass" }
                        span { class: "font-semibold text-gray-700",
                            {format_number(props.base_unit.build_cost_mass)}
                        }
                    }
                    div { class: "bg-white rounded p-1",
                        span { class: "block text-gray-400", "Energy" }
                        span { class: "font-semibold text-gray-700",
                            {format_number(props.base_unit.build_cost_energy)}
                        }
                    }
                    div { class: "bg-white rounded p-1",
                        span { class: "block text-gray-400", "BT" }
                        span { class: "font-semibold text-gray-700",
                            {format_number(props.base_unit.build_time)}
                        }
                    }
                }
            }

            // Selected units comparison list
            div { class: "space-y-2",
                for unit in props.selected_units.iter().cloned() {
                    UnitComparisonCard {
                        unit: unit.clone(),
                        base_unit: props.base_unit.clone(),
                    }
                }
            }
        }
    }
}

#[derive(Props, Clone, PartialEq)]
struct BaseUnitComparisonProps {
    base_unit: Unit,
    selected_units: Vec<Unit>,
}

#[component]
fn UnitComparisonCard(props: UnitComparisonCardProps) -> Element {
    let faction_bg = get_faction_bg_class(props.unit.faction);
    let unit_icon_class = format!("unit-icon-{}", props.unit.unit_id);

    let mass_ratio = calculate_ratio(props.base_unit.build_cost_mass, props.unit.build_cost_mass);
    let energy_ratio = calculate_ratio(props.base_unit.build_cost_energy, props.unit.build_cost_energy);
    let time_ratio = calculate_ratio(props.base_unit.build_time, props.unit.build_time);

    let badge_class = get_ratio_badge_class(mass_ratio);

    rsx! {
        div { class: "bg-gray-50 rounded-lg p-2 border border-gray-200",
            // Unit header with icon and ratio badge
            div { class: "flex items-center gap-2 mb-2",
                div { class: "w-8 h-8 rounded shrink-0 overflow-hidden relative {faction_bg}",
                    div {
                        class: "{unit_icon_class} absolute",
                        style: "width: 64px; height: 64px; transform: scale(0.5); transform-origin: top left;"
                    }
                }
                div { class: "flex-1 min-w-0",
                    span { class: "text-xs font-medium text-gray-900 truncate",
                        {format_unit_name(&props.unit)}
                    }
                }
                span { class: "px-1.5 py-0.5 rounded text-[10px] font-medium shrink-0 {badge_class}",
                    "{mass_ratio}x"
                }
            }

            // Ratios grid
            div { class: "grid grid-cols-3 gap-2 text-xs text-center",
                div {
                    span { class: "block text-gray-400", "Mass" }
                    span { class: "{get_ratio_color_class(mass_ratio)}", "{mass_ratio}x" }
                }
                div {
                    span { class: "block text-gray-400", "Energy" }
                    span { class: "{get_ratio_color_class(energy_ratio)}", "{energy_ratio}x" }
                }
                div {
                    span { class: "block text-gray-400", "Time" }
                    span { class: "{get_ratio_color_class(time_ratio)}", "{time_ratio}x" }
                }
            }
        }
    }
}

#[derive(Props, Clone, PartialEq)]
struct UnitComparisonCardProps {
    unit: Unit,
    base_unit: Unit,
}

#[component]
fn CrossUnitComparison(props: CrossUnitComparisonProps) -> Element {
    let has_multiple_selections = props.selected_units.len() >= 2;

    if !has_multiple_selections {
        return rsx! {};
    }

    // Generate cross comparisons - compare each selected unit against others
    let comparisons: Vec<(Unit, Vec<(Unit, UnitRatio)>)> = props
        .selected_units
        .iter()
        .map(|base| {
            let cross_comparisons: Vec<(Unit, UnitRatio)> = props
                .selected_units
                .iter()
                .filter(|u| u.unit_id != base.unit_id)
                .map(|target| {
                    let ratio = UnitRatio {
                        mass: calculate_ratio(base.build_cost_mass, target.build_cost_mass),
                        energy: calculate_ratio(base.build_cost_energy, target.build_cost_energy),
                        build_time: calculate_ratio(base.build_time, target.build_time),
                    };
                    (target.clone(), ratio)
                })
                .collect();
            (base.clone(), cross_comparisons)
        })
        .collect();

    rsx! {
        div { class: "border-t pt-4",
            h3 { class: "text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2",
                "Cross Comparisons"
            }
            div { class: "space-y-3",
                for (base_unit, unit_comparisons) in comparisons {
                    CrossComparisonCard {
                        base_unit: base_unit.clone(),
                        comparisons: unit_comparisons,
                    }
                }
            }
        }
    }
}

#[derive(Props, Clone, PartialEq)]
struct CrossUnitComparisonProps {
    base_unit: Unit,
    selected_units: Vec<Unit>,
}

#[component]
fn CrossComparisonCard(props: CrossComparisonCardProps) -> Element {
    let faction_bg = get_faction_bg_class(props.base_unit.faction);
    let unit_icon_class = format!("unit-icon-{}", props.base_unit.unit_id);

    rsx! {
        div { class: "bg-gray-50 rounded-lg p-2 border border-gray-200",
            // Base unit header
            div { class: "flex items-center gap-2 mb-2 pb-2 border-b border-gray-200",
                div { class: "w-6 h-6 rounded shrink-0 overflow-hidden relative {faction_bg}",
                    div {
                        class: "{unit_icon_class} absolute",
                        style: "width: 64px; height: 64px; transform: scale(0.375); transform-origin: top left;"
                    }
                }
                div { class: "flex-1 min-w-0",
                    span { class: "text-xs font-medium text-gray-700 truncate block",
                        {format_unit_name(&props.base_unit)}
                    }
                    span { class: "text-[10px] text-gray-500",
                        "Mass: " {format_number(props.base_unit.build_cost_mass)}
                    }
                }
            }

            // Comparisons against this base
            div { class: "space-y-1.5",
                for (target_unit, ratio) in props.comparisons.iter().cloned() {
                    CrossComparisonItem {
                        target_unit: target_unit.clone(),
                        ratio: ratio.clone(),
                    }
                }
            }
        }
    }
}

#[derive(Props, Clone, PartialEq)]
struct CrossComparisonCardProps {
    base_unit: Unit,
    comparisons: Vec<(Unit, UnitRatio)>,
}

#[component]
fn CrossComparisonItem(props: CrossComparisonItemProps) -> Element {
    let faction_bg = get_faction_bg_class(props.target_unit.faction);
    let unit_icon_class = format!("unit-icon-{}", props.target_unit.unit_id);
    let badge_class = get_ratio_badge_class(props.ratio.mass);

    rsx! {
        div {
            div { class: "flex items-center justify-between py-1",
                div { class: "flex items-center gap-2",
                    div { class: "w-8 h-8 rounded shrink-0 overflow-hidden relative {faction_bg}",
                        div {
                            class: "{unit_icon_class} absolute",
                            style: "width: 64px; height: 64px; transform: scale(0.5); transform-origin: top left;"
                        }
                    }
                    span { class: "text-xs text-gray-700 truncate",
                        {format_unit_name(&props.target_unit)}
                    }
                }
                span { class: "px-1.5 py-0.5 rounded text-[10px] font-medium shrink-0 {badge_class}",
                    "{props.ratio.mass}x"
                }
            }

            // Ratios grid
            div { class: "grid grid-cols-3 gap-1 text-[10px] text-center",
                div {
                    span { class: "block text-gray-400", "Mass" }
                    span { class: "{get_ratio_color_class(props.ratio.mass)}", "{props.ratio.mass}x" }
                }
                div {
                    span { class: "block text-gray-400", "Energy" }
                    span { class: "{get_ratio_color_class(props.ratio.energy)}", "{props.ratio.energy}x" }
                }
                div {
                    span { class: "block text-gray-400", "Time" }
                    span { class: "{get_ratio_color_class(props.ratio.build_time)}", "{props.ratio.build_time}x" }
                }
            }
        }
    }
}

#[derive(Props, Clone, PartialEq)]
struct CrossComparisonItemProps {
    target_unit: Unit,
    ratio: UnitRatio,
}

#[component]
fn ComparisonSummaryStats(props: ComparisonSummaryStatsProps) -> Element {
    let total_mass: i32 = props.selected_units.iter().map(|u| u.build_cost_mass).sum();
    let total_energy: i32 = props.selected_units.iter().map(|u| u.build_cost_energy).sum();

    rsx! {
        div { class: "border-t pt-4 mt-4",
            h3 { class: "text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2",
                "Quick Stats"
            }
            div { class: "grid grid-cols-2 gap-2 text-xs",
                div { class: "bg-gray-50 rounded p-2",
                    span { class: "block text-gray-500", "Total Mass" }
                    span { class: "font-semibold text-gray-900", {format_number(total_mass)} }
                }
                div { class: "bg-gray-50 rounded p-2",
                    span { class: "block text-gray-500", "Total Energy" }
                    span { class: "font-semibold text-gray-900", {format_number(total_energy)} }
                }
            }
        }
    }
}

#[derive(Props, Clone, PartialEq)]
struct ComparisonSummaryStatsProps {
    selected_units: Vec<Unit>,
}
