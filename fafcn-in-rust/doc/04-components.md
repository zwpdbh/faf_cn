# Components

Component catalog for the FAF CN web app.

## Component Categories

- [Common Components](#common-components)
- [Unit Components](#unit-components)
- [Eco Components](#eco-components)

---

## Common Components

### Button

```rust
// src/components/common/button.rs

use dioxus::prelude::*;

#[derive(Props, PartialEq, Clone)]
pub struct ButtonProps {
    #[props(default = "primary")]
    pub variant: String,
    #[props(default = false)]
    pub disabled: bool,
    pub onclick: Option<EventHandler<MouseEvent>>,
    pub children: Element,
}

#[component]
pub fn Button(props: ButtonProps) -> Element {
    let base_classes = "px-4 py-2 rounded font-medium transition-colors";
    
    let variant_classes = match props.variant.as_str() {
        "primary" => "bg-blue-600 text-white hover:bg-blue-700 disabled:bg-blue-300",
        "secondary" => "bg-gray-200 text-gray-800 hover:bg-gray-300 disabled:bg-gray-100",
        "danger" => "bg-red-600 text-white hover:bg-red-700",
        _ => "bg-blue-600 text-white",
    };
    
    rsx! {
        button {
            class: "{base_classes} {variant_classes}",
            disabled: props.disabled,
            onclick: move |e| {
                if let Some(handler) = &props.onclick {
                    handler.call(e);
                }
            },
            {props.children}
        }
    }
}

// Usage
rsx! {
    Button {
        variant: "primary",
        onclick: move |_| handle_click(),
        "Click Me"
    }
}
```

### Card

```rust
// src/components/common/card.rs

#[derive(Props, PartialEq, Clone)]
pub struct CardProps {
    #[props(default = "")]
    pub class: String,
    pub children: Element,
}

#[component]
pub fn Card(props: CardProps) -> Element {
    rsx! {
        div {
            class: "bg-white rounded-lg shadow-sm border border-gray-200 p-4 {props.class}",
            {props.children}
        }
    }
}
```

---

## Unit Components

### UnitCard

```rust
// src/components/unit/card.rs

use dioxus::prelude::*;
use fafcn_core::models::{Unit, Faction};

#[derive(Props, PartialEq, Clone)]
pub struct UnitCardProps {
    pub unit: Unit,
    pub is_selected: bool,
    pub onclick: EventHandler<()>,
}

#[component]
pub fn UnitCard(props: UnitCardProps) -> Element {
    let faction_bg = match props.unit.faction {
        Faction::Uef => "bg-blue-100 border-blue-300",
        Faction::Cybran => "bg-red-100 border-red-300",
        Faction::Aeon => "bg-emerald-100 border-emerald-300",
        Faction::Seraphim => "bg-violet-100 border-violet-300",
    };
    
    let selected_class = if props.is_selected {
        "ring-2 ring-indigo-500"
    } else {
        "hover:ring-2 hover:ring-gray-300"
    };
    
    rsx! {
        button {
            class: "relative aspect-square rounded-lg p-2 border {faction_bg} {selected_class} transition-all",
            onclick: move |_| props.onclick.call(()),
            
            // Icon placeholder
            div {
                class: "w-full h-full flex items-center justify-center text-2xl font-bold text-gray-600",
                // Use unit_id for now, replace with actual icon
                "{props.unit.unit_id.chars().take(2).collect::<String>()}"
            }
            
            // Name overlay
            div {
                class: "absolute bottom-0 left-0 right-0 bg-black/50 text-white text-xs p-1 rounded-b-lg",
                "{props.unit.name.as_deref().unwrap_or(&props.unit.unit_id)}"
            }
            
            // Selected indicator
            if props.is_selected {
                div {
                    class: "absolute -top-1 -right-1 w-5 h-5 bg-indigo-500 rounded-full flex items-center justify-center",
                    span { class: "text-white text-xs", "✓" }
                }
            }
        }
    }
}
```

### UnitGrid

```rust
// src/components/unit/grid.rs

use dioxus::prelude::*;
use fafcn_core::models::Unit;
use crate::{components::unit::UnitCard, state::use_app_state};

#[derive(Props, Clone, PartialEq)]
pub struct UnitGridProps {
    pub units: Vec<Unit>,
    pub selected_unit: Option<Unit>,
    pub on_select: EventHandler<Unit>,
}

#[component]
pub fn UnitGrid(props: UnitGridProps) -> Element {
    rsx! {
        div {
            class: "grid grid-cols-4 sm:grid-cols-6 md:grid-cols-8 gap-3",
            
            for unit in props.units.clone() {
                UnitCard {
                    key: "{unit.unit_id}",
                    unit: unit.clone(),
                    is_selected: props.selected_unit.as_ref() == Some(&unit),
                    onclick: move |_| props.on_select.call(unit.clone()),
                }
            }
        }
    }
}
```

---

## Eco Components

### EcoInputs

```rust
// src/components/eco/inputs.rs

use dioxus::prelude::*;
use fafcn_core::eco::EcoState;

#[derive(Props, Clone, PartialEq)]
pub struct EcoInputsProps {
    pub state: EcoState,
    pub on_change: EventHandler<EcoState>,
}

#[component]
pub fn EcoInputs(props: EcoInputsProps) -> Element {
    let mut local_state = use_signal(|| props.state.clone());
    
    // Sync with parent when prop changes
    use_effect({
        let local = local_state.clone();
        move || {
            local.set(props.state.clone());
        }
    });
    
    let update = {
        let on_change = props.on_change.clone();
        let local = local_state.clone();
        move || {
            on_change.call(local());
        }
    };
    
    rsx! {
        div { class: "grid grid-cols-2 gap-4",
            // Mass section
            div { class: "bg-blue-50 p-4 rounded-lg",
                h3 { class: "text-blue-900 font-semibold mb-3", "Mass" }
                
                div { class: "space-y-2",
                    div {
                        label { class: "text-sm text-blue-700", "Income/s" }
                        input {
                            class: "w-full px-2 py-1 border rounded",
                            r#type: "number",
                            value: "{local_state().mass_income}",
                            oninput: move |e| {
                                local_state.write().mass_income = e.value().parse().unwrap_or(0.0);
                            },
                            onchange: move |_| update(),
                        }
                    }
                    
                    div {
                        label { class: "text-sm text-blue-700", "Storage" }
                        input {
                            class: "w-full px-2 py-1 border rounded",
                            r#type: "number",
                            value: "{local_state().mass_storage_max}",
                            oninput: move |e| {
                                let val = e.value().parse().unwrap_or(0.0);
                                local_state.write().mass_storage_max = val;
                                local_state.write().mass_storage = val; // Start full
                            },
                            onchange: move |_| update(),
                        }
                    }
                }
            }
            
            // Energy section
            div { class: "bg-yellow-50 p-4 rounded-lg",
                h3 { class: "text-yellow-900 font-semibold mb-3", "Energy" }
                
                div { class: "space-y-2",
                    div {
                        label { class: "text-sm text-yellow-700", "Income/s" }
                        input {
                            class: "w-full px-2 py-1 border rounded",
                            r#type: "number",
                            value: "{local_state().energy_income}",
                            oninput: move |e| {
                                local_state.write().energy_income = e.value().parse().unwrap_or(0.0);
                            },
                            onchange: move |_| update(),
                        }
                    }
                    
                    div {
                        label { class: "text-sm text-yellow-700", "Storage" }
                        input {
                            class: "w-full px-2 py-1 border rounded",
                            r#type: "number",
                            value: "{local_state().energy_storage_max}",
                            oninput: move |e| {
                                let val = e.value().parse().unwrap_or(0.0);
                                local_state.write().energy_storage_max = val;
                                local_state.write().energy_storage = val;
                            },
                            onchange: move |_| update(),
                        }
                    }
                }
            }
        }
        
        // Build Power
        div { class: "mt-4 bg-purple-50 p-4 rounded-lg",
            h3 { class: "text-purple-900 font-semibold mb-3", "Build Power" }
            
            input {
                class: "w-full px-2 py-1 border rounded",
                r#type: "number",
                value: "{local_state().build_power}",
                oninput: move |e| {
                    local_state.write().build_power = e.value().parse().unwrap_or(0.0);
                },
                onchange: move |_| update(),
            }
        }
    }
}
```

### BuildQueue (with Drag-Drop)

```rust
// src/components/eco/build_queue.rs

use dioxus::prelude::*;
use fafcn_core::eco::BuildItem;
use crate::{hooks::use_drag_drop, state::use_app_state};

#[component]
pub fn BuildQueue() -> Element {
    let state = use_app_state();
    let queue = state.build_queue;
    
    let drag_drop = use_drag_drop({
        let state = state.clone();
        move |from, to| {
            state.move_queue_item(from, to);
        }
    });
    
    let total_cost = use_memo({
        let queue = queue.clone();
        move || {
            queue.read().iter().fold((0, 0), |acc, item| {
                (acc.0 + item.total_mass(), acc.1 + item.total_energy())
            })
        }
    });
    
    rsx! {
        div { class: "bg-white rounded-lg shadow-sm border p-4",
            h3 { class: "text-lg font-semibold mb-4", "Build Queue" }
            
            // Queue items
            div { class: "space-y-2",
                for (index, item) in queue.read().iter().enumerate() {
                    QueueItem {
                        key: "{item.unit.unit_id}-{index}",
                        item: item.clone(),
                        index,
                        is_dragging: drag_drop.dragged_index() == Some(index),
                        is_drag_over: drag_drop.drag_over_index() == Some(index),
                        drag_drop: drag_drop.clone(),
                        on_remove: move |_| state.remove_from_queue(index),
                    }
                }
            }
            
            if queue.read().is_empty() {
                div { class: "text-center py-8 text-gray-400",
                    "Click units to add to queue"
                }
            }
            
            // Total
            div { class: "mt-4 pt-4 border-t flex justify-between",
                span { class: "text-gray-600", "Total:" }
                div { class: "font-semibold",
                    span { class: "text-blue-600 mr-3", "{total_cost().0}M" }
                    span { class: "text-yellow-600", "{total_cost().1}E" }
                }
            }
        }
    }
}

#[derive(Props, Clone, PartialEq)]
struct QueueItemProps {
    item: BuildItem,
    index: usize,
    is_dragging: bool,
    is_drag_over: bool,
    drag_drop: DragDropState,
    on_remove: EventHandler<()>,
}

#[component]
fn QueueItem(props: QueueItemProps) -> Element {
    let opacity = if props.is_dragging { "opacity-50" } else { "" };
    let border = if props.is_drag_over { "border-t-2 border-indigo-500" } else { "" };
    
    rsx! {
        div {
            class: "flex items-center gap-3 p-3 bg-gray-50 rounded-lg cursor-move {opacity} {border}",
            
            draggable: "true",
            ondragstart: props.drag_drop.handle_drag_start(props.index),
            ondragover: props.drag_drop.handle_drag_over(props.index),
            ondrop: props.drag_drop.handle_drop(),
            ondragend: props.drag_drop.handle_drag_end(),
            
            // Drag handle
            div { class: "text-gray-400 select-none", "⋮⋮" }
            
            // Unit info
            div { class: "flex-1",
                div { class: "font-medium text-sm",
                    {props.item.unit.name.clone().unwrap_or_default()}
                }
                div { class: "text-xs text-gray-500",
                    "×{props.item.quantity}"
                }
            }
            
            // Cost
            div { class: "text-xs text-right",
                div { class: "text-blue-600", "{props.item.total_mass()}M" }
                div { class: "text-yellow-600", "{props.item.total_energy()}E" }
            }
            
            // Remove
            button {
                class: "text-red-500 hover:text-red-700 px-2",
                onclick: move |_| props.on_remove.call(()),
                "×"
            }
        }
    }
}
```

### EcoChart (Canvas)

```rust
// src/components/eco/chart.rs

use dioxus::prelude::*;
use fafcn_core::eco::ResourceSnapshot;
use wasm_bindgen::JsCast;
use web_sys::{HtmlCanvasElement, CanvasRenderingContext2d};

#[derive(Props, Clone, PartialEq)]
pub struct EcoChartProps {
    pub data: Vec<ResourceSnapshot>,
    pub highlight_time: Signal<Option<f64>>,
}

#[component]
pub fn EcoChart(props: EcoChartProps) -> Element {
    let canvas_ref = use_signal(|| None::<HtmlCanvasElement>);
    let viewport = use_signal(|| Viewport::default());
    
    // Draw on changes
    use_effect({
        let data = props.data.clone();
        move || {
            let Some(canvas) = canvas_ref() else { return };
            let Ok(ctx) = canvas.get_context("2d")
                .ok()
                .flatten()
                .unwrap()
                .dyn_into::<CanvasRenderingContext2d>()
            else { return };
            
            draw_chart(&ctx, &canvas, &data, &viewport(), props.highlight_time());
        }
    });
    
    rsx! {
        div { class: "relative",
            canvas {
                class: "w-full h-80 bg-gray-50 rounded-lg border",
                onmounted: move |cx| {
                    if let Ok(el) = cx.as_web_event().dyn_into::<HtmlCanvasElement>() {
                        el.set_width(800);
                        el.set_height(400);
                        canvas_ref.set(Some(el));
                    }
                },
            }
        }
    }
}
```

## Component Checklist

### Common
- [x] Button
- [x] Card
- [ ] Input (text, number)
- [ ] Select
- [ ] Modal
- [ ] Tooltip

### Unit
- [x] UnitCard
- [x] UnitGrid
- [ ] UnitDetail
- [ ] FactionTabs
- [ ] FilterBar

### Eco
- [x] EcoInputs
- [x] BuildQueue
- [x] EcoChart
- [ ] Timeline
- [ ] RunButton

## Next

[Deployment](./05-deployment.md)
