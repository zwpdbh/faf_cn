//! Eco Guide view for FAF CN
//! 
//! This component replicates the Phoenix LiveView eco guide page
//! with unit selection and economy comparison features.

use dioxus::prelude::*;
use fafcn_core::{
    Faction, Filter, Unit,
    all_units, find_unit, faction_engineer_id,
    generate_engineer_comparisons, generate_tiered_cross_comparisons,
    total_mass_cost, total_energy_cost, format_number,
};

/// Eco Guide page component
#[component]
pub fn EcoGuide() -> Element {
    // State
    let mut selected_faction = use_signal(|| Faction::Uef);
    let mut active_filters = use_signal(|| Vec::<String>::new());
    let mut selected_units = use_signal(|| Vec::<Unit>::new());

    // Get base engineer for selected faction
    let base_unit = use_memo(move || {
        let faction = selected_faction.read();
        let engineer_id = faction_engineer_id(*faction);
        find_unit(engineer_id).expect("Engineer unit should exist")
    });

    // Get units for selected faction
    let faction_units = use_memo(move || {
        let faction = *selected_faction.read();
        let all = all_units();
        let mut units: Vec<Unit> = all.into_iter()
            .filter(|u| u.faction == faction)
            .collect();
        units.sort_by(|a, b| a.unit_id.cmp(&b.unit_id));
        units
    });

    // Apply filters
    let filtered_units = use_memo(move || {
        let units = faction_units.read();
        let filters = active_filters.read();
        if filters.is_empty() {
            units.clone()
        } else {
            units.iter()
                .filter(|u| u.matches_filters(&filters))
                .cloned()
                .collect()
        }
    });

    // Event handlers
    let select_faction = move |faction: Faction| {
        selected_faction.set(faction);
        active_filters.set(vec![]);
        selected_units.set(vec![]);
    };

    let toggle_filter = move |filter_key: String| {
        let mut filters = active_filters.read().clone();
        if let Some(pos) = filters.iter().position(|f| f == &filter_key) {
            filters.remove(pos);
        } else {
            // Handle mutually exclusive groups
            let usage_filters = Filter::usage_filters();
            let tech_filters = Filter::tech_filters();
            
            // Remove other filters from the same group
            if usage_filters.contains(&filter_key) {
                filters.retain(|f| !usage_filters.contains(f));
            } else if tech_filters.contains(&filter_key) {
                filters.retain(|f| !tech_filters.contains(f));
            }
            filters.push(filter_key);
        }
        active_filters.set(filters);
    };

    let clear_filters = move || {
        active_filters.set(vec![]);
    };

    let toggle_unit = move |unit: Unit| {
        let mut units = selected_units.read().clone();
        // Don't allow selecting the base unit
        if unit.unit_id == base_unit.read().unit_id {
            return;
        }
        if let Some(pos) = units.iter().position(|u| u.unit_id == unit.unit_id) {
            units.remove(pos);
        } else {
            units.push(unit);
        }
        selected_units.set(units);
    };

    let clear_selections = move || {
        selected_units.set(vec![]);
    };

    rsx! {
        div { class: "eco-guide max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6",
            // Header
            div { class: "mb-6",
                h1 { class: "text-3xl font-bold text-gray-900", "Eco Guides" }
                p { class: "mt-2 text-gray-600",
                    "Select units to compare their economy costs against the faction's T1 Engineer."
                }
            }

            // Faction Tabs
            div { class: "mb-6",
                FactionTabs {
                    selected_faction: *selected_faction.read(),
                    on_select: select_faction,
                }
            }

            div { class: "grid grid-cols-1 lg:grid-cols-12 gap-6",
                // Left Column: Unit Selection (8 columns)
                div { class: "lg:col-span-8 space-y-6",
                    BaseUnitCard { base_unit: base_unit.read().clone() }
                    UnitSelectionGrid {
                        units: filtered_units.read().clone(),
                        base_unit: base_unit.read().clone(),
                        selected_unit_ids: selected_units.read().iter().map(|u| u.unit_id.clone()).collect(),
                        active_filters: active_filters.read().clone(),
                        on_toggle_unit: toggle_unit,
                        on_toggle_filter: toggle_filter,
                        on_clear_filters: clear_filters,
                        on_clear_selections: clear_selections,
                    }
                }

                // Right Column: Eco Comparison (4 columns)
                div { class: "lg:col-span-4 space-y-4",
                    EcoComparison {
                        base_unit: base_unit.read().clone(),
                        selected_units: selected_units.read().clone(),
                    }
                }
            }
        }
    }
}

/// Faction selection tabs
#[component]
fn FactionTabs(
    selected_faction: Faction,
    on_select: EventHandler<Faction>,
) -> Element {
    let factions = Faction::all();

    rsx! {
        div { class: "border-b border-gray-200",
            nav { class: "-mb-px flex space-x-8", aria_label: "Tabs",
                for faction in factions {
                    FactionTab {
                        faction,
                        is_active: selected_faction == faction,
                        on_click: move |_| on_select.call(faction),
                    }
                }
            }
        }
    }
}

/// Single faction tab
#[component]
fn FactionTab(
    faction: Faction,
    is_active: bool,
    on_click: EventHandler<()>,
) -> Element {
    let (active_classes, inactive_classes) = match faction {
        Faction::Uef => (
            "border-blue-500 text-blue-600",
            "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
        ),
        Faction::Cybran => (
            "border-red-500 text-red-600",
            "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
        ),
        Faction::Aeon => (
            "border-emerald-500 text-emerald-600",
            "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
        ),
        Faction::Seraphim => (
            "border-violet-500 text-violet-600",
            "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
        ),
    };

    let classes = if is_active { active_classes } else { inactive_classes };

    rsx! {
        button {
            class: "whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm capitalize transition-colors {classes}",
            onclick: move |_| on_click.call(()),
            { faction.as_str() }
        }
    }
}

/// Base unit (Engineer) display card
#[component]
fn BaseUnitCard(base_unit: Unit) -> Element {
    rsx! {
        div { class: "bg-white rounded-lg shadow-sm border border-gray-200 p-4",
            div { class: "flex items-center justify-between mb-3",
                h2 { class: "text-lg font-semibold text-gray-900", "Base Unit (Engineer)" }
                span { 
                    class: "px-2 py-1 text-xs font-medium rounded-full {base_unit.faction_badge_class()}",
                    { base_unit.faction.as_str() }
                }
            }
            div { class: "flex items-center space-x-4",
                // Engineer Icon placeholder
                div { 
                    class: "w-16 h-16 rounded-lg flex items-center justify-center shadow-inner {base_unit.faction_bg_class()}",
                    span { class: "text-white text-xs", "ENG" }
                }
                div { class: "flex-1",
                    div { class: "flex items-center space-x-2",
                        span { class: "inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-800",
                            { base_unit.tech_badge() }
                        }
                        h3 { class: "font-semibold text-gray-900", { base_unit.unit_id.clone() } }
                    }
                    p { class: "text-sm text-gray-600", { base_unit.description.clone() } }
                    div { class: "mt-1 flex items-center space-x-4 text-xs text-gray-500",
                        span { "Mass: {format_number(base_unit.build_cost_mass)}" }
                        span { "Energy: {format_number(base_unit.build_cost_energy)}" }
                        span { "BT: {format_number(base_unit.build_time)}" }
                    }
                }
            }
        }
    }
}

/// Unit selection grid with filters
#[component]
fn UnitSelectionGrid(
    units: Vec<Unit>,
    base_unit: Unit,
    selected_unit_ids: Vec<String>,
    active_filters: Vec<String>,
    on_toggle_unit: EventHandler<Unit>,
    on_toggle_filter: EventHandler<String>,
    on_clear_filters: EventHandler<()>,
    on_clear_selections: EventHandler<()>,
) -> Element {
    let filters = Filter::all_filters();
    let has_selections = !selected_unit_ids.is_empty();
    let has_filters = !active_filters.is_empty();

    rsx! {
        div { 
            class: "rounded-lg shadow-sm border border-gray-200 p-4",
            style: "background-image: linear-gradient(rgba(0,0,0,0.7), rgba(0,0,0,0.7)), url('/images/units/background.jpg'); background-size: cover; background-position: center;",
            
            div { class: "flex items-center justify-between mb-4",
                h2 { class: "text-lg font-semibold text-white drop-shadow-md", "Select Units to Compare" }
                if has_selections {
                    button {
                        class: "text-sm bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded transition-colors shadow-md",
                        onclick: move |_| on_clear_selections.call(()),
                        "Clear ({selected_unit_ids.len()})"
                    }
                }
            }

            // Filter Bar
            div { class: "flex flex-wrap gap-2 mb-4",
                for filter in filters {
                    FilterButton {
                        filter: filter.clone(),
                        is_active: active_filters.contains(&filter.key),
                        on_toggle: on_toggle_filter,
                    }
                }
                if has_filters {
                    button {
                        class: "px-3 py-1.5 rounded text-sm font-medium bg-gray-500/50 text-white hover:bg-gray-500/70 transition-all",
                        onclick: move |_| on_clear_filters.call(()),
                        "Clear All"
                    }
                }
            }

            // Unit Grid
            div { class: "grid grid-cols-4 sm:grid-cols-6 md:grid-cols-8 gap-3 mt-4",
                for unit in units.clone() {
                    UnitGridItem {
                        unit: unit.clone(),
                        is_engineer: unit.unit_id == base_unit.unit_id,
                        is_selected: selected_unit_ids.contains(&unit.unit_id),
                        on_toggle: move |_| on_toggle_unit.call(unit.clone()),
                    }
                }
            }

            if units.is_empty() {
                div { class: "text-center py-8 text-white/70",
                    p { "No units match the selected filters." }
                    button {
                        class: "mt-2 text-sm underline hover:text-white",
                        onclick: move |_| on_clear_filters.call(()),
                        "Clear filters"
                    }
                }
            }
        }
    }
}

/// Filter button component
#[component]
fn FilterButton(
    filter: Filter,
    is_active: bool,
    on_toggle: EventHandler<String>,
) -> Element {
    let class = if is_active {
        "px-3 py-1.5 rounded text-sm font-medium transition-all bg-indigo-500 text-white shadow-md"
    } else {
        "px-3 py-1.5 rounded text-sm font-medium transition-all bg-white/90 text-gray-700 hover:bg-white hover:shadow"
    };
    let key = filter.key.clone();
    
    rsx! {
        button {
            class: "{class}",
            onclick: move |_| on_toggle.call(key.clone()),
            { filter.label }
        }
    }
}

/// Single unit grid item
#[component]
fn UnitGridItem(
    unit: Unit,
    is_engineer: bool,
    is_selected: bool,
    on_toggle: EventHandler<()>,
) -> Element {
    let border_class = if is_engineer {
        "ring-2 ring-yellow-400 ring-offset-1 cursor-default"
    } else if is_selected {
        "ring-2 ring-indigo-500 ring-offset-1"
    } else {
        "hover:ring-2 hover:ring-gray-300 hover:ring-offset-1 cursor-pointer"
    };

    rsx! {
        button {
            class: "group relative aspect-square rounded-lg p-1 transition-all duration-150 flex flex-col items-center justify-center text-center overflow-hidden {unit.faction_bg_class()} {border_class}",
            onclick: move |_| on_toggle.call(()),
            disabled: is_engineer,
            title: "{unit.display_name()}: {unit.description}",
            
            // Unit icon placeholder
            div { class: "w-10 h-10 shrink-0 flex items-center justify-center text-white text-xs font-bold",
                { unit.unit_id.chars().skip(3).take(4).collect::<String>() }
            }
            
            if is_engineer {
                span { class: "absolute -top-1 -right-1 w-4 h-4 bg-yellow-400 rounded-full flex items-center justify-center z-10",
                    span { class: "text-[8px] font-bold text-yellow-900", "★" }
                }
            }
            if is_selected {
                span { class: "absolute -top-1 -right-1 w-4 h-4 bg-indigo-500 rounded-full flex items-center justify-center z-10",
                    svg {
                        class: "w-3 h-3 text-white",
                        fill: "currentColor",
                        view_box: "0 0 20 20",
                        path {
                            fill_rule: "evenodd",
                            d: "M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z",
                            clip_rule: "evenodd"
                        }
                    }
                }
            }
        }
    }
}

/// Eco comparison panel
#[component]
fn EcoComparison(
    base_unit: Unit,
    selected_units: Vec<Unit>,
) -> Element {
    rsx! {
        div { class: "bg-white rounded-lg shadow-sm border border-gray-200 p-4",
            h2 { class: "text-lg font-semibold text-gray-900 mb-4", "Eco Comparison" }

            if selected_units.is_empty() {
                EmptyComparisonState {}
            } else {
                div { class: "space-y-4",
                    BaseUnitComparison {
                        base_unit: base_unit.clone(),
                        selected_units: selected_units.clone(),
                    }
                    if selected_units.len() >= 2 {
                        CrossUnitComparison {
                            base_unit: base_unit.clone(),
                            selected_units: selected_units.clone(),
                        }
                    }
                    ComparisonSummaryStats { selected_units: selected_units.clone() }
                }
            }
        }
    }
}

/// Empty state when no units selected
#[component]
fn EmptyComparisonState() -> Element {
    rsx! {
        div { class: "text-center py-8 text-gray-500",
            svg {
                class: "mx-auto h-10 w-10 text-gray-300 mb-3",
                fill: "none",
                view_box: "0 0 24 24",
                stroke: "currentColor",
                path {
                    stroke_linecap: "round",
                    stroke_linejoin: "round",
                    stroke_width: "2",
                    d: "M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z"
                }
            }
            p { class: "text-sm", "Select units to see comparisons against the Engineer." }
        }
    }
}

/// Base unit comparison section
#[component]
fn BaseUnitComparison(
    base_unit: Unit,
    selected_units: Vec<Unit>,
) -> Element {
    let comparisons = generate_engineer_comparisons(&base_unit, &selected_units);

    rsx! {
        div {
            // Base unit info
            div { class: "bg-gray-100 rounded-lg p-2 mb-3 border border-gray-200",
                div { class: "flex items-center gap-2 mb-2",
                    div { class: "w-8 h-8 rounded shrink-0 overflow-hidden relative {base_unit.faction_bg_class()}",
                        div { class: "absolute text-white text-[8px] flex items-center justify-center w-full h-full",
                            { base_unit.unit_id.chars().skip(3).take(4).collect::<String>() }
                        }
                    }
                    div { class: "flex-1 min-w-0",
                        span { class: "text-xs font-semibold text-gray-900 truncate",
                            { base_unit.description.clone() }
                        }
                        p { class: "text-[10px] text-gray-500", { base_unit.unit_id.clone() } }
                    }
                }
                // Base Unit Absolute Eco Values
                div { class: "grid grid-cols-3 gap-1 text-[10px] text-center",
                    div { class: "bg-white rounded p-1",
                        span { class: "block text-gray-400", "Mass" }
                        span { class: "font-semibold text-gray-700", { format_number(base_unit.build_cost_mass) } }
                    }
                    div { class: "bg-white rounded p-1",
                        span { class: "block text-gray-400", "Energy" }
                        span { class: "font-semibold text-gray-700", { format_number(base_unit.build_cost_energy) } }
                    }
                    div { class: "bg-white rounded p-1",
                        span { class: "block text-gray-400", "BT" }
                        span { class: "font-semibold text-gray-700", { format_number(base_unit.build_time) } }
                    }
                }
            }

            // Comparison list
            div { class: "space-y-2",
                for (unit, _idx, ratio) in comparisons {
                    ComparisonCard { unit, ratio }
                }
            }
        }
    }
}

/// Single comparison card
#[component]
fn ComparisonCard(unit: Unit, ratio: fafcn_core::EcoRatio) -> Element {
    rsx! {
        div { class: "bg-gray-50 rounded-lg p-2 border border-gray-200",
            div { class: "flex items-center gap-2 mb-2",
                // Unit Icon
                div { class: "w-8 h-8 rounded shrink-0 overflow-hidden relative {unit.faction_bg_class()}",
                    div { class: "absolute text-white text-[7px] flex items-center justify-center w-full h-full",
                        { unit.unit_id.chars().skip(3).take(4).collect::<String>() }
                    }
                }
                div { class: "flex-1 min-w-0",
                    span { class: "text-xs font-medium text-gray-900 truncate",
                        { unit.display_name() }
                    }
                }
                span { class: "px-1.5 py-0.5 rounded text-[10px] font-medium shrink-0 {ratio.badge_class()}",
                    { ratio.mass_formatted() }
                }
            }
            div { class: "grid grid-cols-3 gap-2 text-xs",
                div { class: "text-center",
                    span { class: "block text-gray-400", "Mass" }
                    span { class: "{ratio.mass_color_class()}", { ratio.mass_formatted() } }
                }
                div { class: "text-center",
                    span { class: "block text-gray-400", "Energy" }
                    span { class: "{ratio.energy_color_class()}", { ratio.energy_formatted() } }
                }
                div { class: "text-center",
                    span { class: "block text-gray-400", "Time" }
                    span { class: "{ratio.build_time_color_class()}", { ratio.build_time_formatted() } }
                }
            }
        }
    }
}

/// Cross-unit comparison section
#[component]
fn CrossUnitComparison(
    base_unit: Unit,
    selected_units: Vec<Unit>,
) -> Element {
    let comparisons = generate_tiered_cross_comparisons(&base_unit, &selected_units);

    rsx! {
        div { class: "border-t pt-4",
            h3 { class: "text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2",
                "Cross Comparisons"
            }
            div { class: "space-y-3",
                for comparison in comparisons {
                    CrossComparisonCard { comparison }
                }
            }
        }
    }
}

/// Cross comparison card
#[component]
fn CrossComparisonCard(comparison: fafcn_core::CrossComparison) -> Element {
    rsx! {
        div { class: "bg-gray-50 rounded-lg p-2 border border-gray-200",
            // Base unit header
            div { class: "flex items-center gap-2 mb-2 pb-2 border-b border-gray-200",
                div { class: "w-6 h-6 rounded shrink-0 overflow-hidden relative {comparison.base_unit.faction_bg_class()}",
                    div { class: "absolute text-white text-[6px] flex items-center justify-center w-full h-full",
                        { comparison.base_unit.unit_id.chars().skip(3).take(4).collect::<String>() }
                    }
                }
                div { class: "flex-1 min-w-0",
                    span { class: "text-xs font-medium text-gray-700 truncate block",
                        { comparison.base_unit.display_name() }
                    }
                    span { class: "text-[10px] text-gray-500",
                        "Mass: {format_number(comparison.base_unit.build_cost_mass)}"
                    }
                }
            }
            // Comparisons against this base
            div { class: "space-y-1.5",
                for (target_unit, ratio) in comparison.comparisons {
                    div { class: "flex items-center justify-between py-1",
                        div { class: "flex items-center gap-2",
                            // To Unit
                            div { class: "w-8 h-8 rounded shrink-0 overflow-hidden relative {target_unit.faction_bg_class()}",
                                div { class: "absolute text-white text-[7px] flex items-center justify-center w-full h-full",
                                    { target_unit.unit_id.chars().skip(3).take(4).collect::<String>() }
                                }
                            }
                            span { class: "text-xs text-gray-700 truncate",
                                { target_unit.display_name() }
                            }
                        }
                        span { class: "px-1.5 py-0.5 rounded text-[10px] font-medium shrink-0 {ratio.badge_class()}",
                            { ratio.mass_formatted() }
                        }
                    }
                    div { class: "grid grid-cols-3 gap-1 text-[10px] text-center",
                        div {
                            span { class: "block text-gray-400", "Mass" }
                            span { class: "{ratio.mass_color_class()}", { ratio.mass_formatted() } }
                        }
                        div {
                            span { class: "block text-gray-400", "Energy" }
                            span { class: "{ratio.energy_color_class()}", { ratio.energy_formatted() } }
                        }
                        div {
                            span { class: "block text-gray-400", "Time" }
                            span { class: "{ratio.build_time_color_class()}", { ratio.build_time_formatted() } }
                        }
                    }
                }
            }
        }
    }
}

/// Comparison summary statistics
#[component]
fn ComparisonSummaryStats(selected_units: Vec<Unit>) -> Element {
    let total_mass = total_mass_cost(&selected_units);
    let total_energy = total_energy_cost(&selected_units);

    rsx! {
        div { class: "border-t pt-4 mt-4",
            h3 { class: "text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2",
                "Quick Stats"
            }
            div { class: "grid grid-cols-2 gap-2 text-xs",
                div { class: "bg-gray-50 rounded p-2",
                    span { class: "block text-gray-500", "Total Mass" }
                    span { class: "font-semibold text-gray-900", { format_number(total_mass) } }
                }
                div { class: "bg-gray-50 rounded p-2",
                    span { class: "block text-gray-500", "Total Energy" }
                    span { class: "font-semibold text-gray-900", { format_number(total_energy) } }
                }
            }
        }
    }
}
