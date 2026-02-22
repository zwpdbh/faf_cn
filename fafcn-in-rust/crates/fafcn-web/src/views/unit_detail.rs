//! Unit Detail Page
//! Displays detailed information about a specific unit

use dioxus::prelude::*;
use fafcn_core::models::{find_unit, format_number, Unit};

/// Unit detail page component
#[component]
pub fn UnitDetail(unit_id: String) -> Element {
    // Find the unit by ID
    let unit = find_unit(&unit_id);

    rsx! {
        div { class: "max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-6",
            // Back link
            Link {
                to: "/eco-guide",
                class: "text-indigo-600 hover:text-indigo-800 mb-4 inline-flex items-center",
                svg {
                    class: "w-4 h-4 mr-1",
                    fill: "none",
                    view_box: "0 0 24 24",
                    stroke: "currentColor",
                    stroke_width: "1.5",
                    path {
                        stroke_linecap: "round",
                        stroke_linejoin: "round",
                        d: "M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18"
                    }
                }
                "Back to Eco Guides"
            }

            // Unit Content
            if let Some(unit) = unit {
                UnitContent { unit }
            } else {
                UnitNotFound { unit_id }
            }
        }
    }
}

/// Unit content when found
#[component]
fn UnitContent(unit: Unit) -> Element {
    rsx! {
        // Unit Header
        div { class: "bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6",
            div { class: "flex items-start gap-6",
                // Large Unit Icon
                div { class: "w-24 h-24 rounded-xl flex items-center justify-center shrink-0 {unit.faction_bg_class()}",
                    div { class: "unit-icon-{unit.unit_id} w-20 h-20" }
                }

                // Unit Info
                div { class: "flex-1",
                    div { class: "flex items-center gap-3 mb-2",
                        span { class: "text-sm font-medium text-gray-500", "{unit.unit_id}" }
                        span { class: "px-2 py-0.5 rounded text-xs font-medium {unit.faction_badge_class()}",
                            "{unit.faction.as_str()}"
                        }
                    }
                    h1 { class: "text-2xl font-bold text-gray-900 mb-2",
                        "{unit.display_name()}"
                    }
                    p { class: "text-gray-600",
                        "{unit.description}"
                    }
                }
            }
        }

        // Unit Stats Card
        div { class: "bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6",
            h2 { class: "text-lg font-semibold text-gray-900 mb-4", "Economy Stats" }

            // Stats Display
            div { class: "grid grid-cols-3 gap-4",
                div { class: "text-center p-4 bg-gray-50 rounded-lg",
                    div { class: "text-sm text-gray-500 mb-1", "Mass" }
                    div { class: "text-2xl font-bold text-gray-900",
                        "{format_number(unit.build_cost_mass)}"
                    }
                }
                div { class: "text-center p-4 bg-gray-50 rounded-lg",
                    div { class: "text-sm text-gray-500 mb-1", "Energy" }
                    div { class: "text-2xl font-bold text-gray-900",
                        "{format_number(unit.build_cost_energy)}"
                    }
                }
                div { class: "text-center p-4 bg-gray-50 rounded-lg",
                    div { class: "text-sm text-gray-500 mb-1", "Build Time" }
                    div { class: "text-2xl font-bold text-gray-900",
                        "{format_number(unit.build_time)}"
                    }
                }
            }
        }

        // Categories
        if !unit.categories.is_empty() {
            div { class: "bg-white rounded-lg shadow-sm border border-gray-200 p-6",
                h2 { class: "text-lg font-semibold text-gray-900 mb-4", "Categories" }
                div { class: "flex flex-wrap gap-2",
                    for category in unit.categories.iter().filter(|c| is_display_category(c)) {
                        span { class: "px-3 py-1 bg-gray-100 text-gray-700 rounded-full text-sm",
                            "{category}"
                        }
                    }
                }
            }
        }
    }
}

/// Unit not found state
#[component]
fn UnitNotFound(unit_id: String) -> Element {
    rsx! {
        div { class: "bg-white rounded-lg shadow-sm border border-gray-200 p-8 text-center",
            div { class: "mx-auto h-12 w-12 text-gray-300 mb-4",
                svg {
                    class: "h-12 w-12",
                    fill: "none",
                    view_box: "0 0 24 24",
                    stroke: "currentColor",
                    stroke_width: "1.5",
                    path {
                        stroke_linecap: "round",
                        stroke_linejoin: "round",
                        d: "M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                    }
                }
            }
            h2 { class: "text-xl font-semibold text-gray-900 mb-2", "Unit Not Found" }
            p { class: "text-gray-600 mb-4",
                "The unit \"{unit_id}\" could not be found in the database."
            }
            Link {
                to: "/eco-guide",
                class: "inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700",
                "Go to Eco Guide"
            }
        }
    }
}

/// Filter categories to show only relevant ones
fn is_display_category(category: &str) -> bool {
    matches!(
        category,
        "TECH1" | "TECH2" | "TECH3" | "EXPERIMENTAL" | "ENGINEER" | "LAND" | "AIR" | "NAVAL" | "STRUCTURE"
    )
}
