// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// using a path starting with the package name:
//
//     import "some-package"

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"

// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Import hooks from different features
import EcoChart from "./hooks/eco_chart"
import { EdgeInfoHook, EditButtonHook, QuantityButtonHook } from "./hooks/eco_workflow"
import { LiveFlowHook, FileImportHook, setupDownloadHandler } from "live_flow"

// Configure and initialize LiveSocket
const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: {
    // Feature: Eco Charts
    EcoChart,
    
    // Feature: Eco Workflow (LiveFlow integration)
    // Hook names must match phx-hook attributes in templates
    EdgeInfo: EdgeInfoHook,
    EditButton: EditButtonHook,
    QuantityButton: QuantityButtonHook,
    
    // Package: LiveFlow
    LiveFlow: LiveFlowHook,
    FileImport: FileImportHook
  }
})

// Enable JSON file download for LiveFlow
setupDownloadHandler()

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// Connect if there are any LiveViews on the page
liveSocket.connect()

// Expose liveSocket on window for web console debug
window.liveSocket = liveSocket

// Development features (quality of life for phoenix_live_reload)
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({ detail: reloader }) => {
    // Enable server log streaming to client
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of clicked element
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if (keyDown === "c") {
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if (keyDown === "d") {
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}
