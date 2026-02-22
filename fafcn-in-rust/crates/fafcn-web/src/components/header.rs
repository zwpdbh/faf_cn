use dioxus::prelude::*;

use crate::app::Route;

#[component]
pub fn Header() -> Element {
    let current_route = use_route::<Route>();
    
    rsx! {
        header { class: "px-4 sm:px-6 lg:px-8 border-b border-gray-200 bg-white",
            div { class: "flex justify-between items-center h-16",
                // Logo section (left)
                div { class: "flex items-center",
                    Link {
                        to: Route::Home {},
                        class: "flex items-center gap-2",
                        // Globe icon
                        svg {
                            class: "w-8 h-8 text-indigo-600",
                            view_box: "0 0 24 24",
                            fill: "none",
                            stroke: "currentColor",
                            stroke_width: "1.5",
                            path {
                                stroke_linecap: "round",
                                stroke_linejoin: "round",
                                d: "M12 21a9.004 9.004 0 008.716-6.747M12 21a9.004 9.004 0 01-8.716-6.747M12 21c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m0 0a8.997 8.997 0 017.843 4.582M12 3a8.997 8.997 0 00-7.843 4.582m15.686 0A11.953 11.953 0 0112 10.5c-2.998 0-5.74-1.1-7.843-2.918m15.686 0A8.959 8.959 0 0121 12c0 .778-.099 1.533-.284 2.253m0 0A17.919 17.919 0 0112 16.5c-3.162 0-6.133-.815-8.716-2.247m0 0A9.015 9.015 0 013 12c0-1.605.42-3.113 1.157-4.418"
                            }
                        }
                        span { class: "text-xl font-bold text-gray-900", "FAF CN" }
                    }
                }
                
                // Navigation links (right)
                nav { class: "flex items-center space-x-4",
                    // Eco Guide Link
                    Link {
                        to: Route::EcoGuides {},
                        class: if matches!(current_route, Route::EcoGuides {}) {
                            "flex items-center px-3 py-2 rounded-md text-sm font-medium text-indigo-600 bg-indigo-50"
                        } else {
                            "flex items-center px-3 py-2 rounded-md text-sm font-medium text-gray-700 hover:text-indigo-600 hover:bg-gray-50"
                        },
                        // Calculator icon
                        svg {
                            class: "w-5 h-5 mr-1",
                            view_box: "0 0 24 24",
                            fill: "none",
                            stroke: "currentColor",
                            stroke_width: "1.5",
                            path {
                                stroke_linecap: "round",
                                stroke_linejoin: "round",
                                d: "M15.75 15.75V12m0 0V8.25m0 3.75h3.75m-3.75 0h-3.75M9.75 15.75V12m0 0V8.25m0 3.75H6m3.75 0h3.75M9.75 4.5h4.5M12 4.5v12m-7.5 0h15"
                            }
                        }
                        "Eco Guide"
                    }
                    
                    // Eco Prediction Link
                    Link {
                        to: Route::EcoPrediction {},
                        class: if matches!(current_route, Route::EcoPrediction {}) {
                            "flex items-center px-3 py-2 rounded-md text-sm font-medium text-emerald-600 bg-emerald-50"
                        } else {
                            "flex items-center px-3 py-2 rounded-md text-sm font-medium text-gray-700 hover:text-emerald-600 hover:bg-gray-50"
                        },
                        // Chart line icon
                        svg {
                            class: "w-5 h-5 mr-1",
                            view_box: "0 0 24 24",
                            fill: "none",
                            stroke: "currentColor",
                            stroke_width: "1.5",
                            path {
                                stroke_linecap: "round",
                                stroke_linejoin: "round",
                                d: "M3.75 3v11.25A2.25 2.25 0 006 16.5h2.25M3.75 3h-1.5m1.5 0h16.5m0 0h1.5m-1.5 0v11.25A2.25 2.25 0 0118 16.5h-2.25m-7.5 0h7.5m-7.5 0l-1 3m8.5-3l1 3m0 0l.5 1.5m-.5-1.5h-9.5m0 0l-.5 1.5m.75-9l3-3 2.148 2.148A12.061 12.061 0 0116.5 7.605"
                            }
                        }
                        "Eco Prediction"
                    }
                }
            }
        }
    }
}
