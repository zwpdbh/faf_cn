use dioxus::prelude::*;
use fafcn_core::{TechLevel, UnitCategory};

#[derive(Props, Clone, PartialEq)]
pub struct FilterBarProps {
    pub tech_levels: Vec<TechLevel>,
    pub selected_tech_level: Option<TechLevel>,
    pub on_select_tech: EventHandler<Option<TechLevel>>,
    
    pub categories: Vec<UnitCategory>,
    pub selected_category: Option<UnitCategory>,
    pub on_select_category: EventHandler<Option<UnitCategory>>,
    
    pub search_query: String,
    pub on_search: EventHandler<String>,
    
    #[props(default = Callback::new(|_| ()))]
    pub on_clear_filters: EventHandler<()>,
}

#[component]
pub fn FilterBar(props: FilterBarProps) -> Element {
    // Check if any filters are active
    let has_active_filters = props.selected_tech_level.is_some() 
        || props.selected_category.is_some() 
        || !props.search_query.is_empty();

    rsx! {
        div { class: "space-y-3",
            // First row: Tech level filters and clear button
            div { class: "flex flex-wrap items-center gap-2",
                // Tech level filter buttons
                {
                    let tech_options: Vec<(Option<TechLevel>, &str)> = vec![
                        (None, "All Tech"),
                        (Some(TechLevel::T1), "T1"),
                        (Some(TechLevel::T2), "T2"),
                        (Some(TechLevel::T3), "T3"),
                        (Some(TechLevel::Experimental), "EXP"),
                    ];
                    
                    tech_options.into_iter().map(|(tech, label)| {
                        let is_active = props.selected_tech_level == tech;
                        let btn_class = if is_active {
                            "px-3 py-1.5 rounded-lg text-sm font-medium transition-all bg-indigo-500 text-white shadow-md hover:bg-indigo-600"
                        } else {
                            "px-3 py-1.5 rounded-lg text-sm font-medium transition-all bg-white/90 text-gray-700 hover:bg-white hover:shadow"
                        };
                        
                        rsx! {
                            button {
                                class: btn_class,
                                onclick: move |_| props.on_select_tech.call(tech),
                                {label}
                            }
                        }
                    })
                }
                
                // Clear all button
                if has_active_filters {
                    button {
                        class: "px-3 py-1.5 rounded-lg text-sm font-medium bg-gray-500/80 text-white hover:bg-gray-500 transition-all",
                        onclick: move |_| props.on_clear_filters.call(()),
                        "Clear All"
                    }
                }
            }
            
            // Second row: Category filters
            div { class: "flex flex-wrap gap-2",
                {
                    let cat_options: Vec<(Option<UnitCategory>, &str)> = vec![
                        (None, "All"),
                        (Some(UnitCategory::Engineer), "Engineer"),
                        (Some(UnitCategory::Structure), "Structure"),
                        (Some(UnitCategory::Land), "Land"),
                        (Some(UnitCategory::Air), "Air"),
                        (Some(UnitCategory::Naval), "Naval"),
                    ];
                    
                    cat_options.into_iter().map(|(cat, label)| {
                        let is_active = props.selected_category == cat;
                        let btn_class = if is_active {
                            "px-3 py-1.5 rounded-lg text-sm font-medium transition-all bg-indigo-500 text-white shadow-md hover:bg-indigo-600"
                        } else {
                            "px-3 py-1.5 rounded-lg text-sm font-medium transition-all bg-white/90 text-gray-700 hover:bg-white hover:shadow"
                        };
                        
                        rsx! {
                            button {
                                class: btn_class,
                                onclick: move |_| props.on_select_category.call(cat),
                                {label}
                            }
                        }
                    })
                }
            }
            
            // Search input
            div { class: "relative",
                // Search icon
                div { class: "absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none",
                    svg {
                        class: "h-4 w-4 text-gray-400",
                        fill: "none",
                        view_box: "0 0 24 24",
                        stroke: "currentColor",
                        path {
                            stroke_linecap: "round",
                            stroke_linejoin: "round",
                            stroke_width: "2",
                            d: "M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                        }
                    }
                }
                input {
                    class: "w-full pl-10 pr-3 py-2 text-sm border border-gray-200 rounded-lg shadow-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 bg-white",
                    placeholder: "Search units by name or unit ID...",
                    value: props.search_query.clone(),
                    oninput: move |e| props.on_search.call(e.value().clone()),
                }
            }
        }
    }
}
