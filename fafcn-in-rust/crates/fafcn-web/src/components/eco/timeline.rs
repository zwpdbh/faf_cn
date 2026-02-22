use dioxus::prelude::*;
use fafcn_core::eco::EventType;

use crate::state::use_app_state;

#[component]
pub fn Timeline() -> Element {
    let state = use_app_state();
    let simulation_result = (state.simulation_result)();

    rsx! {
        if let Some(result) = simulation_result {
            div { class: "bg-white rounded-lg shadow-sm border border-gray-200 p-4",
                h3 { class: "text-base font-semibold text-gray-900 mb-3",
                    "Timeline"
                }
                
                // Completion time
                div { class: "mb-4 p-3 bg-blue-50 rounded border border-blue-100",
                    div { class: "text-xs text-blue-700", "Total Time" }
                    div { class: "text-lg font-bold text-blue-900",
                        {result.completion_time.map(format_time).unwrap_or_else(|| "--".to_string())}
                    }
                }
                
                // Event list
                div { class: "space-y-2 max-h-64 overflow-auto",
                    for event in &result.timeline {
                        div { class: "flex items-center gap-2 text-sm",
                            span { class: "text-xs text-gray-500 w-12 shrink-0",
                                {format_time(event.time)}
                            }
                            span { 
                                class: match event.event_type {
                                    EventType::BuildCompleted { .. } => "text-green-600 font-medium",
                                    EventType::BuildStarted { .. } => "text-blue-600",
                                    EventType::ResourceStall { resource } => match resource {
                                        fafcn_core::eco::ResourceType::Mass => "text-red-600",
                                        fafcn_core::eco::ResourceType::Energy => "text-yellow-600",
                                    },
                                    _ => "text-gray-600",
                                },
                                {event.description.clone()}
                            }
                        }
                    }
                }
            }
        } else {
            // Empty state
            div {}
        }
    }
}

fn format_time(seconds: f64) -> String {
    let minutes = (seconds / 60.0).floor() as i32;
    let secs = (seconds % 60.0).floor() as i32;
    
    if minutes > 0 {
        format!("{}:{:02}", minutes, secs)
    } else {
        format!("{}s", secs)
    }
}
