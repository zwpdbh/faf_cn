use dioxus::prelude::*;

use crate::state::AppStateProvider;
use crate::pages::{Home, EcoGuides, EcoPrediction};

#[derive(Clone, Routable, Debug, PartialEq)]
pub enum Route {
    #[route("/")]
    Home {},
    
    #[route("/eco-guides")]
    EcoGuides {},
    
    #[route("/eco-prediction")]
    EcoPrediction {},
}

// Inject CSS into document head
fn inject_styles() {
    let window = web_sys::window().expect("no window");
    let document = window.document().expect("no document");
    let head = document.head().expect("no head");
    
    // Create style element
    let style = document.create_element("style").expect("cannot create style");
    style.set_text_content(Some(include_str!("../assets/tailwind.css")));
    
    // Append to head
    head.append_child(&style).expect("cannot append style");
}

#[component]
pub fn App() -> Element {
    // Inject styles on mount
    use_effect(|| {
        inject_styles();
    });
    
    rsx! {
        AppStateProvider {
            Router::<Route> {}
        }
    }
}
