use dioxus::prelude::*;

use crate::state::use_app_state;

#[component]
pub fn BuildQueue() -> Element {
    let state = use_app_state();
    let build_queue = (state.build_queue)();

    let queue_len = build_queue.len();

    rsx! {
        div { class: "bg-white rounded-lg shadow-sm border border-gray-200 p-4",
            h3 { class: "text-base font-semibold text-gray-900 mb-3", "Build Queue" }

            if queue_len == 0 {
                p { class: "text-sm text-gray-600",
                    "Select units from the grid to add to your build queue."
                }

                div { class: "mt-4 p-4 bg-gray-50 rounded border border-gray-200",
                    p { class: "text-sm text-gray-500 text-center", "No units selected yet" }
                }
            } else {
                div { class: "space-y-2 max-h-64 overflow-auto",
                    for (idx , item) in build_queue.iter().enumerate() {
                        div { class: "flex items-center justify-between p-2 bg-gray-50 rounded",
                            div { class: "flex items-center gap-2",
                                span { class: "text-xs text-gray-500 w-6", "{idx + 1}." }
                                div { class: "flex-1",
                                    div { class: "text-sm font-medium text-gray-900",
                                        {item.unit.name.clone().unwrap_or_else(|| item.unit.unit_id.clone())}
                                    }
                                    div { class: "text-xs text-gray-500", "Qty: {item.quantity}" }
                                }
                            }
                            button {
                                class: "text-red-600 hover:text-red-800 text-xs",
                                onclick: move |_| {
                                    crate::state::remove_from_queue(state, idx);
                                },
                                "Remove"
                            }
                        }
                    }
                }

                div { class: "mt-4 flex gap-2",
                    button {
                        class: "flex-1 px-3 py-2 bg-gray-100 text-gray-700 rounded text-sm hover:bg-gray-200",
                        onclick: move |_| {
                            crate::state::clear_queue(state);
                        },
                        "Clear All"
                    }
                    button {
                        class: "flex-1 px-3 py-2 bg-indigo-600 text-white rounded text-sm hover:bg-indigo-700",
                        onclick: move |_| {
                            crate::state::run_simulation(state);
                        },
                        "Run Simulation"
                    }
                }
            }
        }
    }
}
