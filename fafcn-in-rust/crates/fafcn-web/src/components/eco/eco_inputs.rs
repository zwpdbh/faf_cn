use dioxus::prelude::*;

use crate::state::use_app_state;

#[component]
pub fn EcoInputs() -> Element {
    let mut state = use_app_state();

    rsx! {
        div { class: "space-y-4",
            // Mass & Energy in 2 columns
            div { class: "grid grid-cols-2 gap-3",
                // Mass Group
                div { class: "bg-blue-50 rounded p-3 border border-blue-100",
                    h3 { class: "text-xs font-semibold text-blue-900 mb-2 flex items-center gap-1",
                        span { "●" }
                        "Mass"
                    }
                    div { class: "space-y-2",
                        div {
                            label { class: "block text-[10px] font-medium text-blue-700 mb-0.5",
                                "Income/s"
                            }
                            input {
                                class: "w-full px-2 py-1 text-sm border border-blue-200 rounded bg-white",
                                r#type: "number",
                                value: {(state.eco)().mass_income.to_string()},
                                oninput: move |e| {
                                    if let Ok(val) = e.value().parse::<f64>() {
                                        let mut new_eco = (state.eco)().clone();
                                        new_eco.mass_income = val;
                                        state.eco.set(new_eco);
                                    }
                                },
                            }
                        }
                        div {
                            label { class: "block text-[10px] font-medium text-blue-700 mb-0.5",
                                "Storage"
                            }
                            div { class: "flex gap-1",
                                input {
                                    class: "flex-1 px-2 py-1 text-sm border border-blue-200 rounded bg-white",
                                    r#type: "number",
                                    value: {(state.eco)().mass_storage.to_string()},
                                    placeholder: "Current",
                                    oninput: move |e| {
                                        if let Ok(val) = e.value().parse::<f64>() {
                                            let mut new_eco = (state.eco)().clone();
                                            new_eco.mass_storage = val;
                                            state.eco.set(new_eco);
                                        }
                                    },
                                }
                                input {
                                    class: "flex-1 px-2 py-1 text-sm border border-blue-200 rounded bg-white",
                                    r#type: "number",
                                    value: {(state.eco)().mass_storage_max.to_string()},
                                    placeholder: "Max",
                                    oninput: move |e| {
                                        if let Ok(val) = e.value().parse::<f64>() {
                                            let mut new_eco = (state.eco)().clone();
                                            new_eco.mass_storage_max = val;
                                            state.eco.set(new_eco);
                                        }
                                    },
                                }
                            }
                        }
                    }
                }

                // Energy Group
                div { class: "bg-yellow-50 rounded p-3 border border-yellow-100",
                    h3 { class: "text-xs font-semibold text-yellow-900 mb-2 flex items-center gap-1",
                        span { "⚡" }
                        "Energy"
                    }
                    div { class: "space-y-2",
                        div {
                            label { class: "block text-[10px] font-medium text-yellow-700 mb-0.5",
                                "Income/s"
                            }
                            input {
                                class: "w-full px-2 py-1 text-sm border border-yellow-200 rounded bg-white",
                                r#type: "number",
                                value: {(state.eco)().energy_income.to_string()},
                                oninput: move |e| {
                                    if let Ok(val) = e.value().parse::<f64>() {
                                        let mut new_eco = (state.eco)().clone();
                                        new_eco.energy_income = val;
                                        state.eco.set(new_eco);
                                    }
                                },
                            }
                        }
                        div {
                            label { class: "block text-[10px] font-medium text-yellow-700 mb-0.5",
                                "Storage"
                            }
                            div { class: "flex gap-1",
                                input {
                                    class: "flex-1 px-2 py-1 text-sm border border-yellow-200 rounded bg-white",
                                    r#type: "number",
                                    value: {(state.eco)().energy_storage.to_string()},
                                    placeholder: "Current",
                                    oninput: move |e| {
                                        if let Ok(val) = e.value().parse::<f64>() {
                                            let mut new_eco = (state.eco)().clone();
                                            new_eco.energy_storage = val;
                                            state.eco.set(new_eco);
                                        }
                                    },
                                }
                                input {
                                    class: "flex-1 px-2 py-1 text-sm border border-yellow-200 rounded bg-white",
                                    r#type: "number",
                                    value: {(state.eco)().energy_storage_max.to_string()},
                                    placeholder: "Max",
                                    oninput: move |e| {
                                        if let Ok(val) = e.value().parse::<f64>() {
                                            let mut new_eco = (state.eco)().clone();
                                            new_eco.energy_storage_max = val;
                                            state.eco.set(new_eco);
                                        }
                                    },
                                }
                            }
                        }
                    }
                }
            }

            // Engineers Group
            div { class: "bg-purple-50 rounded p-3 border border-purple-100",
                h3 { class: "text-xs font-semibold text-purple-900 mb-2", "Build Power (Engineers)" }
                div { class: "grid grid-cols-3 gap-2",
                    div {
                        label { class: "block text-[10px] font-medium text-purple-700 mb-0.5",
                            "T1 Engineers"
                        }
                        input {
                            class: "w-full px-2 py-1 text-sm border border-purple-200 rounded bg-white",
                            r#type: "number",
                            value: {(state.eco)().t1_engineers.to_string()},
                            oninput: move |e| {
                                if let Ok(val) = e.value().parse::<i32>() {
                                    let mut new_eco = (state.eco)().clone();
                                    new_eco.t1_engineers = val;
                                    state.eco.set(new_eco);
                                }
                            },
                        }
                    }
                    div {
                        label { class: "block text-[10px] font-medium text-purple-700 mb-0.5",
                            "T2 Engineers"
                        }
                        input {
                            class: "w-full px-2 py-1 text-sm border border-purple-200 rounded bg-white",
                            r#type: "number",
                            value: {(state.eco)().t2_engineers.to_string()},
                            oninput: move |e| {
                                if let Ok(val) = e.value().parse::<i32>() {
                                    let mut new_eco = (state.eco)().clone();
                                    new_eco.t2_engineers = val;
                                    state.eco.set(new_eco);
                                }
                            },
                        }
                    }
                    div {
                        label { class: "block text-[10px] font-medium text-purple-700 mb-0.5",
                            "T3 Engineers"
                        }
                        input {
                            class: "w-full px-2 py-1 text-sm border border-purple-200 rounded bg-white",
                            r#type: "number",
                            value: {(state.eco)().t3_engineers.to_string()},
                            oninput: move |e| {
                                if let Ok(val) = e.value().parse::<i32>() {
                                    let mut new_eco = (state.eco)().clone();
                                    new_eco.t3_engineers = val;
                                    state.eco.set(new_eco);
                                }
                            },
                        }
                    }
                }
            }
        }
    }
}
