mod app;
mod components;
mod data;
mod hooks;
mod pages;
mod state;

use app::App;
use dioxus::launch;

fn main() {
    wasm_logger::init(wasm_logger::Config::default());
    console_error_panic_hook::set_once();
    
    launch(App);
}
