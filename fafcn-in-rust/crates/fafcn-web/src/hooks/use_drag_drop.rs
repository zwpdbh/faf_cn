use dioxus::prelude::*;

#[derive(Clone, Copy)]
pub struct DragDropState {
    pub dragged_index: Signal<Option<usize>>,
    pub drag_over_index: Signal<Option<usize>>,
}

impl DragDropState {
    pub fn new() -> Self {
        Self {
            dragged_index: use_signal(|| None),
            drag_over_index: use_signal(|| None),
        }
    }
}

pub fn use_drag_drop<F>(_on_reorder: F) -> DragDropState
where
    F: Fn(usize, usize) + 'static,
{
    DragDropState::new()
}
