use dioxus::prelude::*;
use fafcn_core::eco::EventType;

use crate::state::use_app_state;

#[component]
pub fn EcoSummary() -> Element {
    let state = use_app_state();
    let simulation_result = (state.simulation_result)();
    let is_simulating = (state.is_simulating)();

    rsx! {
        if is_simulating {
            div { class: "bg-white rounded-lg shadow-sm border border-gray-200 p-4",
                p { class: "text-center text-gray-600", "Running simulation..." }
            }
        } else if let Some(result) = simulation_result {
            div { class: "bg-white rounded-lg shadow-sm border border-gray-200 p-4",
                h3 { class: "text-base font-semibold text-gray-900 mb-3",
                    "Simulation Results"
                }
                
                // Total time
                div { class: "mb-4 p-3 bg-blue-50 rounded border border-blue-100",
                    div { class: "text-xs text-blue-700", "Total Time" }
                    div { class: "text-2xl font-bold text-blue-900",
                        {result.completion_time.map(format_time).unwrap_or_else(|| "--".to_string())}
                    }
                }
                
                // Summary stats
                div { class: "space-y-2 text-sm",
                    div { class: "flex justify-between",
                        span { class: "text-gray-600", "Items Completed:" }
                        span { class: "font-medium", "{result.items_completed.len()}" }
                    }
                    
                    if result.total_stall_time > 0.0 {
                        div { class: "flex justify-between text-yellow-600",
                            span { "Total Stall Time:" }
                            span { class: "font-medium", "{format_duration(result.total_stall_time)}" }
                        }
                    }
                }
                
                // Timeline events
                if !result.timeline.is_empty() {
                    div { class: "mt-4",
                        h4 { class: "text-xs font-semibold text-gray-700 mb-2", "Timeline" }
                        div { class: "space-y-1 max-h-48 overflow-auto text-xs",
                            for event in result.timeline.iter().take(20) {
                                div { class: "flex items-center gap-2",
                                    span { class: "text-gray-500 w-12 shrink-0",
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
                            if result.timeline.len() > 20 {
                                div { class: "text-center text-gray-500 italic",
                                    "... and {result.timeline.len() - 20} more events"
                                }
                            }
                        }
                    }
                }
            }
        } else {
            div {}
        }
    }
}

fn format_time(seconds: f64) -> String {
    let minutes = (seconds / 60.0).floor() as i32;
    let secs = (seconds % 60.0).floor() as i32;
    let tenths = ((seconds % 1.0) * 10.0).floor() as i32;
    
    if minutes > 0 {
        format!("{}:{:02}", minutes, secs)
    } else {
        format!("{}.{:.0}s", secs, tenths)
    }
}

fn format_duration(seconds: f64) -> String {
    if seconds >= 60.0 {
        format!("{:.1}m", seconds / 60.0)
    } else {
        format!("{:.1}s", seconds)
    }
}
