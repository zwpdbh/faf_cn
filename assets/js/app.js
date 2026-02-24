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
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import EcoChart from "./hooks/eco_chart"
import { LiveFlowHook, FileImportHook, setupDownloadHandler } from "live_flow"

// Get the simulation state from the workflow container
const getSimulationState = (element) => {
  const container = element.closest('#eco-workflow-container')
  return container && container.dataset.simulationRun === "true"
}

// Hook to handle hover tooltip and double-click on edges during simulation
const EdgeInfoHook = {
  mounted() {
    // Parse edge tooltips from data attribute
    this.parseEdgeTooltips()
    
    // Create tooltip element
    this.tooltip = document.createElement('div')
    this.tooltip.className = 'edge-hover-tooltip'
    this.tooltip.style.cssText = `
      position: fixed;
      background: hsl(var(--b1));
      border: 1px solid hsl(var(--b3));
      border-radius: 6px;
      padding: 6px 10px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
      font-size: 11px;
      pointer-events: none;
      z-index: 1000;
      display: none;
      white-space: nowrap;
      color: hsl(var(--bc));
    `
    document.body.appendChild(this.tooltip)
    
    // Mouse over - show tooltip (use mouseover for SVG elements)
    this.handleMouseOver = (e) => {
      if (!getSimulationState(this.el)) return
      
      const edgeEl = e.target.closest('.lf-edge-interaction, .lf-edge')
      if (!edgeEl) return
      
      const edgeId = edgeEl.dataset.edgeId
      if (!edgeId) return
      
      // Get tooltip text from parsed data
      const tooltipText = this.edgeTooltips[edgeId]
      if (tooltipText) {
        this.tooltip.textContent = tooltipText
        this.tooltip.style.display = 'block'
        this.updateTooltipPosition(e)
      }
    }
    
    // Mouse move - update position
    this.handleMouseMove = (e) => {
      if (this.tooltip.style.display === 'block') {
        this.updateTooltipPosition(e)
      }
    }
    
    // Mouse out - hide tooltip
    this.handleMouseOut = (e) => {
      // Only hide if leaving the edge entirely
      const relatedTarget = e.relatedTarget
      if (!relatedTarget || !relatedTarget.closest('.lf-edge-group')) {
        this.tooltip.style.display = 'none'
      }
    }
    
    // Double-click - open modal
    this.handleDoubleClick = (e) => {
      if (!getSimulationState(this.el)) return
      
      const edgeEl = e.target.closest('.lf-edge-interaction, .lf-edge')
      if (!edgeEl) return
      
      const edgeId = edgeEl.dataset.edgeId
      if (edgeId) {
        e.preventDefault()
        e.stopPropagation()
        this.pushEvent("show_edge_info", { "edge_id": edgeId })
      }
    }
    
    // Add event listeners - use bubble phase for mouse events, capture for dblclick
    this.el.addEventListener('mouseover', this.handleMouseOver)
    this.el.addEventListener('mousemove', this.handleMouseMove)
    this.el.addEventListener('mouseout', this.handleMouseOut)
    this.el.addEventListener('dblclick', this.handleDoubleClick, true)
  },
  
  updated() {
    // Re-parse tooltips after DOM update
    this.parseEdgeTooltips()
  },
  
  parseEdgeTooltips() {
    try {
      const tooltipsJson = this.el.dataset.edgeTooltips || '{}'
      this.edgeTooltips = JSON.parse(tooltipsJson)
    } catch (e) {
      this.edgeTooltips = {}
    }
  },
  
  updateTooltipPosition(e) {
    const x = e.clientX + 10
    const y = e.clientY - 30
    this.tooltip.style.left = x + 'px'
    this.tooltip.style.top = y + 'px'
  },
  
  destroyed() {
    this.el.removeEventListener('mouseover', this.handleMouseOver)
    this.el.removeEventListener('mousemove', this.handleMouseMove)
    this.el.removeEventListener('mouseout', this.handleMouseOut)
    this.el.removeEventListener('dblclick', this.handleDoubleClick, true)
    if (this.tooltip && this.tooltip.parentNode) {
      this.tooltip.parentNode.removeChild(this.tooltip)
    }
  }
}

// Hook to handle edit button clicks in workflow nodes
const EditButtonHook = {
  mounted() {
    this.handleMouseDown = (e) => {
      // Check if simulation is running - if so, prevent editing
      if (getSimulationState(this.el)) {
        e.preventDefault()
        e.stopPropagation()
        return false
      }
      
      // Prevent default and stop propagation
      e.preventDefault()
      e.stopPropagation()
    }
    
    this.handleClick = (e) => {
      // Check if simulation is running - if so, prevent editing
      if (getSimulationState(this.el)) {
        e.preventDefault()
        e.stopPropagation()
        e.stopImmediatePropagation()
        return false
      }
      
      // Prevent default and stop propagation immediately
      e.preventDefault()
      e.stopPropagation()
      e.stopImmediatePropagation()
      
      const eventName = this.el.getAttribute("data-event")
      const nodeId = this.el.getAttribute("data-node-id")
      
      if (eventName) {
        // Longer delay to ensure the modal backdrop click handler doesn't fire
        setTimeout(() => {
          this.pushEvent(eventName, { "node-id": nodeId })
        }, 100)
      }
      
      return false
    }
    
    // Capture in multiple phases to ensure we catch everything
    this.el.addEventListener("mousedown", this.handleMouseDown, { capture: true })
    this.el.addEventListener("click", this.handleClick, { capture: true })
  },
  
  destroyed() {
    this.el.removeEventListener("mousedown", this.handleMouseDown, { capture: true })
    this.el.removeEventListener("click", this.handleClick, { capture: true })
  }
}

// Hook to handle quantity button clicks (+/-) in workflow nodes
const QuantityButtonHook = {
  mounted() {
    this.handleMouseDown = (e) => {
      // Check if simulation is running - if so, prevent changes
      if (getSimulationState(this.el)) {
        e.preventDefault()
        e.stopPropagation()
        return false
      }
      
      // Prevent default and stop propagation
      e.preventDefault()
      e.stopPropagation()
    }
    
    this.handleClick = (e) => {
      // Check if simulation is running - if so, prevent changes
      if (getSimulationState(this.el)) {
        e.preventDefault()
        e.stopPropagation()
        e.stopImmediatePropagation()
        return false
      }
      
      // Prevent default and stop propagation immediately
      e.preventDefault()
      e.stopPropagation()
      e.stopImmediatePropagation()
      
      const eventName = this.el.getAttribute("data-event")
      const nodeId = this.el.getAttribute("data-node-id")
      
      if (eventName) {
        setTimeout(() => {
          this.pushEvent(eventName, { "node-id": nodeId })
        }, 50)
      }
      
      return false
    }
    
    // Capture in capture phase to intercept before LiveFlow
    this.el.addEventListener("mousedown", this.handleMouseDown, { capture: true })
    this.el.addEventListener("click", this.handleClick, { capture: true })
  },
  
  destroyed() {
    this.el.removeEventListener("mousedown", this.handleMouseDown, { capture: true })
    this.el.removeEventListener("click", this.handleClick, { capture: true })
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: {
    EcoChart,
    LiveFlow: LiveFlowHook,
    FileImport: FileImportHook,
    EditButton: EditButtonHook,
    QuantityButton: QuantityButtonHook,
    EdgeInfo: EdgeInfoHook
  },
})

// Enable JSON file download for LiveFlow
setupDownloadHandler()

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({ detail: reloader }) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
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

