// Eco Workflow Hooks
// Custom Phoenix LiveView hooks for the Eco Workflow feature
// These hooks handle interactions with LiveFlow nodes and edges during simulation

// Helper to check if simulation is running
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
    document.body.appendChild(this.tooltip)

    // Mouse over - show tooltip (use mouseover for SVG elements)
    this.handleMouseOver = (e) => {
      if (!getSimulationState(this.el)) return

      const edgeEl = e.target.closest('.lf-edge-interaction, .lf-edge')
      if (!edgeEl) return

      const edgeId = edgeEl.dataset.edgeId
      if (!edgeId) return

      // Get tooltip data from parsed data
      const tooltipData = this.edgeTooltips[edgeId]
      if (tooltipData) {
        this.renderTooltip(tooltipData)
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

  renderTooltip(data) {
    // Format values with 1 decimal place max
    const formatValue = (val) => {
      if (typeof val === 'number') {
        return Number.isInteger(val) ? val.toString() : val.toFixed(1)
      }
      return '0'
    }

    const massValue = formatValue(data.mass)
    const energyValue = formatValue(data.energy)

    this.tooltip.innerHTML = `
      <div class="edge-hover-tooltip-row mass-row">
        <div class="edge-hover-tooltip-label">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-4 h-4" style="color: #06b6d4;">
            <path d="M10.75 10.818v2.614A3.25 3.25 0 0011.262 13.5c.845.014 1.462.153 2.003.477.279.17.47.382.592.613a.75.75 0 101.3-.75c-.133-.248-.37-.52-.73-.766-.74-.502-1.54-.793-2.618-.813a4.002 4.002 0 01-3.51-3.512c-.02-1.078-.311-1.878-.813-2.618-.246-.36-.518-.597-.766-.73a.75.75 0 00-.75 1.3c.231.122.443.313.613.592.324.541.463 1.158.477 2.003.006.342.123.665.318.927a3.25 3.25 0 00-2.461 2.461h-2.614A3.25 3.25 0 004.25 11.25v-.75a.75.75 0 00-1.5 0v.75A4.75 4.75 0 007.5 16h5A4.75 4.75 0 0017.25 11.25v-.75a.75.75 0 00-1.5 0v.75A3.25 3.25 0 0112.75 14h-5a3.25 3.25 0 01-3.25-3.25v-.75h2.614A3.25 3.25 0 0010 8.982V6.338a3.25 3.25 0 00-.928-2.284 3.25 3.25 0 00-2.284-.928H3.75a3.25 3.25 0 00-3.25 3.25v2.614A3.25 3.25 0 002.678 10h2.614c.17 0 .335.013.497.038V6.338a1.75 1.75 0 011.75-1.75h2.614a1.75 1.75 0 011.75 1.75v2.614a1.75 1.75 0 01-1.75 1.75H7.5z" />
          </svg>
          Mass
        </div>
        <div class="edge-hover-tooltip-value mass-value">-${massValue}/s</div>
      </div>
      <div class="edge-hover-tooltip-row energy-row">
        <div class="edge-hover-tooltip-label">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-4 h-4" style="color: #f59e0b;">
            <path fill-rule="evenodd" d="M11.3 1.046A1 1 0 0112 2v5h4a1 1 0 01.82 1.573l-7 10A1 1 0 018 18v-5H4a1 1 0 01-.82-1.573l7-10a1 1 0 011.12-.38z" clip-rule="evenodd" />
          </svg>
          Energy
        </div>
        <div class="edge-hover-tooltip-value energy-value">-${energyValue}/s</div>
      </div>
      <div class="edge-hover-tooltip-hint">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-3 h-3">
          <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a.75.75 0 000 1.5h.253a.25.25 0 01.244.304l-.459 2.066A1.75 1.75 0 0010.747 15H11a.75.75 0 000-1.5h-.253a.25.25 0 01-.244-.304l.459-2.066A1.75 1.75 0 009.253 9H9z" clip-rule="evenodd" />
        </svg>
        Double-click for details
      </div>
    `
  },

  updateTooltipPosition(e) {
    // Position above the cursor with some offset
    const tooltipRect = this.tooltip.getBoundingClientRect()
    let x = e.clientX - tooltipRect.width / 2
    let y = e.clientY - tooltipRect.height - 15

    // Keep within viewport
    const padding = 10
    x = Math.max(padding, Math.min(x, window.innerWidth - tooltipRect.width - padding))
    y = Math.max(padding, y)

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

export { EdgeInfoHook, EditButtonHook, QuantityButtonHook }
