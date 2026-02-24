# How To: Integrate LiveFlow with Phoenix LiveView

This guide documents the integration of LiveFlow (a visual workflow editor library) with Phoenix LiveView, with special focus on handling interaction conflicts between LiveFlow's drag/selection system and custom UI controls inside nodes.

## Table of Contents

1. [Overview](#overview)
2. [Basic Integration Pattern](#basic-integration-pattern)
3. [The Interaction Problem](#the-interaction-problem)
4. [Solution: Capture-Phase Event Hooks](#solution-capture-phase-event-hooks)
5. [Complete Examples](#complete-examples)
6. [Troubleshooting](#troubleshooting)

---

## Overview

LiveFlow provides a visual node-based editor with drag-and-drop capabilities. When embedding custom interactive elements (buttons, inputs) inside nodes, LiveFlow's event handlers can intercept clicks, causing a frustrating UX where the first click only selects the node instead of triggering the button.

### Common Scenarios Requiring This Fix

- Edit buttons inside workflow nodes
- Quantity +/- buttons inside unit nodes
- Any interactive controls within draggable node content

---

## Basic Integration Pattern

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        LiveView (Server)                         │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │ Event Handlers│◀───│  handle_event │◀───│   WebSocket   │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│         │                                                        │
│         └──────────────────────────────────────────────────┐    │
│                                                            │    │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐ │    │
│  │   Flow State  │───▶│ push_event    │───▶│  LiveFlow API │ │    │
│  └──────────────┘    └──────────────┘    └──────────────┘ │    │
└─────────────────────────────────────────────────────────────┼────┘
                              │                               │
                              │ WebSocket                     │
                              ▼                               │
┌─────────────────────────────────────────────────────────────┼────┐
│                     Browser (Client)                         │    │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │    │
│  │  LiveSocket  │───▶│   JS Hooks   │───▶│   LiveFlow    │  │    │
│  └──────────────┘    └──────────────┘    └──────────────┘  │    │
│         │                          │              │         │    │
│         │                          │              ▼         │    │
│         │                          │       ┌──────────┐    │    │
│         │                          │       │ Node DOM │    │    │
│         │                          │       │ ┌──────┐ │    │    │
│         │                          │       │ │Button│ │────┘    │
│         │                          │       │ └──────┘ │         │
│         │                          │       └──────────┘         │
│         │                          │                             │
│         └──────────────────────────┘  (Capture phase intercept)  │
└─────────────────────────────────────────────────────────────────┘
```

---

## The Interaction Problem

### Problem Description

When users click interactive elements (buttons) inside a workflow node for the **first time**:

1. **Expected**: Button click triggers immediately
2. **Actual**: Click is intercepted by LiveFlow's drag/selection handlers
3. **Result**: Node gets selected instead; button doesn't respond
4. **Second click**: Works because node is already selected

### Root Cause

LiveFlow attaches pointer event handlers to the node container to enable:
- Dragging nodes
- Multi-selection
- Connection creation

These handlers use the **capture phase** and call `stopPropagation()`, preventing your button's `phx-click` from receiving the event.

### Event Flow (Problematic)

```
User clicks + button
    │
    ▼
┌─────────────────────────────────────┐
│  Capture Phase                      │
│    LiveFlow handler (intercepts)   │ ◀── Stops here!
│    stops propagation               │
└─────────────────────────────────────┘
    │
    ▼ (blocked)
┌─────────────────────────────────────┐
│  Bubble Phase                       │
│    Your phx-click handler          │ ◀── Never receives event
│    on the + button                 │
└─────────────────────────────────────┘
```

---

## Solution: Capture-Phase Event Hooks

### Strategy

Intercept the event **before** LiveFlow can capture it, using:
1. **Capture-phase event listeners** (`{ capture: true }`)
2. **Immediate propagation stopping** (`stopPropagation()`, `stopImmediatePropagation()`)
3. **Manual event pushing** via `this.pushEvent()`

### Event Flow (Fixed)

```
User clicks + button
    │
    ▼
┌─────────────────────────────────────┐
│  Capture Phase                      │
│    YOUR hook handler               │ ◀── Intercepts first
│    stops propagation               │
└─────────────────────────────────────┘
    │
    ▼ (propagation stopped)
┌─────────────────────────────────────┐
│  Capture Phase                      │
│    LiveFlow handler                │ ◀── Never receives event
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│  Your code manually pushes event    │
│  via pushEvent()                   │
└─────────────────────────────────────┘
```

### Hook Implementation Pattern

```javascript
// assets/js/app.js

const ButtonInsideNodeHook = {
  mounted() {
    // Prevent LiveFlow's mousedown handler from starting drag
    this.handleMouseDown = (e) => {
      e.preventDefault()
      e.stopPropagation()
    }
    
    // Handle the actual click
    this.handleClick = (e) => {
      // Stop ALL propagation immediately
      e.preventDefault()
      e.stopPropagation()
      e.stopImmediatePropagation()
      
      // Extract event details from data attributes
      const eventName = this.el.getAttribute("data-event")
      const nodeId = this.el.getAttribute("data-node-id")
      
      if (eventName) {
        // Small delay to ensure clean event processing
        setTimeout(() => {
          this.pushEvent(eventName, { "node-id": nodeId })
        }, 50)
      }
      
      return false
    }
    
    // CRITICAL: Use capture phase to intercept before LiveFlow
    this.el.addEventListener("mousedown", this.handleMouseDown, { capture: true })
    this.el.addEventListener("click", this.handleClick, { capture: true })
  },
  
  destroyed() {
    // Clean up to prevent memory leaks
    this.el.removeEventListener("mousedown", this.handleMouseDown, { capture: true })
    this.el.removeEventListener("click", this.handleClick, { capture: true })
  }
}

// Register in LiveSocket
const liveSocket = new LiveSocket("/live", Socket, {
  hooks: {
    ButtonInsideNode: ButtonInsideNodeHook
  }
})
```

### Key Implementation Details

#### 1. Capture Phase is Essential

```javascript
// WRONG - bubble phase, LiveFlow already captured it
this.el.addEventListener("click", this.handleClick)

// CORRECT - capture phase, intercept before LiveFlow
this.el.addEventListener("click", this.handleClick, { capture: true })
```

#### 2. Stop All Propagation

```javascript
this.handleClick = (e) => {
  e.preventDefault()           // Prevent default browser behavior
  e.stopPropagation()          // Stop bubbling up
  e.stopImmediatePropagation() // Stop other handlers on same element
  // ...
}
```

#### 3. Use setTimeout for pushEvent

The small delay ensures:
- Event propagation is fully stopped
- LiveFlow's state settles
- Clean event processing

```javascript
setTimeout(() => {
  this.pushEvent(eventName, { "node-id": nodeId })
}, 50)
```

---

## Complete Examples

### Example 1: Edit Button in Unit Node

**JavaScript Hook:**
```javascript
// assets/js/app.js

const EditButtonHook = {
  mounted() {
    this.handleMouseDown = (e) => {
      e.preventDefault()
      e.stopPropagation()
    }
    
    this.handleClick = (e) => {
      e.preventDefault()
      e.stopPropagation()
      e.stopImmediatePropagation()
      
      const eventName = this.el.getAttribute("data-event")  // "open_unit_selector"
      const nodeId = this.el.getAttribute("data-node-id")
      
      if (eventName) {
        setTimeout(() => {
          this.pushEvent(eventName, { "node-id": nodeId })
        }, 100)  // Longer delay for modals
      }
      
      return false
    }
    
    this.el.addEventListener("mousedown", this.handleMouseDown, { capture: true })
    this.el.addEventListener("click", this.handleClick, { capture: true })
  },
  
  destroyed() {
    this.el.removeEventListener("mousedown", this.handleMouseDown, { capture: true })
    this.el.removeEventListener("click", this.handleClick, { capture: true })
  }
}
```

**LiveComponent Template:**
```elixir
<%# lib/my_app_web/live/workflow/unit_node.ex %>
<button
  type="button"
  class="workflow-node-unit-edit-btn"
  id={"unit-edit-btn-#{@node.id}"}        <%# Unique ID required for hook %>
  phx-hook="EditButton"                    <%# Attach hook %>
  data-event="open_unit_selector"          <%# Event to trigger %>
  data-node-id={@node.id}                  <%# Context data %>
  title="Change unit"
>
  <.icon name="hero-pencil-square" class="w-3 h-3" />
</button>
```

**LiveView Handler:**
```elixir
# lib/my_app_web/live/workflow_live.ex

def handle_event("open_unit_selector", %{"node-id" => node_id}, socket) do
  {:noreply, 
   assign(socket, 
     show_unit_selector: true,
     selected_node_id: node_id
   )}
end
```

### Example 2: Quantity +/- Buttons

**JavaScript Hook:**
```javascript
// assets/js/app.js

const QuantityButtonHook = {
  mounted() {
    this.handleMouseDown = (e) => {
      e.preventDefault()
      e.stopPropagation()
    }
    
    this.handleClick = (e) => {
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
    
    this.el.addEventListener("mousedown", this.handleMouseDown, { capture: true })
    this.el.addEventListener("click", this.handleClick, { capture: true })
  },
  
  destroyed() {
    this.el.removeEventListener("mousedown", this.handleMouseDown, { capture: true })
    this.el.removeEventListener("click", this.handleClick, { capture: true })
  }
}
```

**LiveComponent Template:**
```elixir
<%# lib/my_app_web/live/workflow/unit_node.ex %>
<div class="workflow-node-unit-quantity">
  <%# Decrease button %>
  <button
    type="button"
    class="workflow-node-unit-qty-btn"
    id={"qty-minus-btn-#{@node.id}"}
    phx-hook="QuantityButton"
    data-event="decrease_quantity"
    data-node-id={@node.id}
    disabled={@quantity <= 1}
  >
    <.icon name="hero-minus" class="w-3 h-3" />
  </button>
  
  <span class="workflow-node-unit-qty-value">{@quantity}</span>
  
  <%# Increase button %>
  <button
    type="button"
    class="workflow-node-unit-qty-btn"
    id={"qty-plus-btn-#{@node.id}"}
    phx-hook="QuantityButton"
    data-event="increase_quantity"
    data-node-id={@node.id}
  >
    <.icon name="hero-plus" class="w-3 h-3" />
  </button>
</div>
```

**LiveView Handlers:**
```elixir
def handle_event("increase_quantity", %{"node-id" => node_id}, socket) do
  flow =
    update_node_data(socket.assigns.flow, node_id, fn data ->
      current_qty = data[:quantity] || 1
      %{data | quantity: current_qty + 1}
    end)

  {:noreply, assign(socket, flow: flow, simulation_run: false)}
end

def handle_event("decrease_quantity", %{"node-id" => node_id}, socket) do
  flow =
    update_node_data(socket.assigns.flow, node_id, fn data ->
      current_qty = data[:quantity] || 1
      new_qty = max(1, current_qty - 1)
      %{data | quantity: new_qty}
    end)

  {:noreply, assign(socket, flow: flow, simulation_run: false)}
end
```

---

## Complete Integration File

### assets/js/app.js (Full Example)

```javascript
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import { LiveFlowHook, FileImportHook, setupDownloadHandler } from "live_flow"

// Hook for edit buttons inside workflow nodes
const EditButtonHook = {
  mounted() {
    this.handleMouseDown = (e) => {
      e.preventDefault()
      e.stopPropagation()
    }
    
    this.handleClick = (e) => {
      e.preventDefault()
      e.stopPropagation()
      e.stopImmediatePropagation()
      
      const eventName = this.el.getAttribute("data-event")
      const nodeId = this.el.getAttribute("data-node-id")
      
      if (eventName) {
        setTimeout(() => {
          this.pushEvent(eventName, { "node-id": nodeId })
        }, 100)
      }
      
      return false
    }
    
    this.el.addEventListener("mousedown", this.handleMouseDown, { capture: true })
    this.el.addEventListener("click", this.handleClick, { capture: true })
  },
  
  destroyed() {
    this.el.removeEventListener("mousedown", this.handleMouseDown, { capture: true })
    this.el.removeEventListener("click", this.handleClick, { capture: true })
  }
}

// Hook for quantity +/- buttons inside workflow nodes
const QuantityButtonHook = {
  mounted() {
    this.handleMouseDown = (e) => {
      e.preventDefault()
      e.stopPropagation()
    }
    
    this.handleClick = (e) => {
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
    LiveFlow: LiveFlowHook,
    FileImport: FileImportHook,
    EditButton: EditButtonHook,
    QuantityButton: QuantityButtonHook
  },
})

setupDownloadHandler()
liveSocket.connect()
window.liveSocket = liveSocket
```

---

## Troubleshooting

### Issue: Button still doesn't work on first click

**Checklist:**
1. ✅ Hook is registered in `LiveSocket` configuration
2. ✅ Element has unique `id` attribute
3. ✅ Event listeners use `{ capture: true }`
4. ✅ Calling `stopImmediatePropagation()`
5. ✅ Using `setTimeout` before `pushEvent`

### Issue: Event fires but LiveView handler not called

**Verify param naming:**
```javascript
// JavaScript sends:
this.pushEvent("my_event", { "node-id": node_id })

// Elixir expects:
def handle_event("my_event", %{"node-id" => node_id}, socket) do
  # ...
end
```

### Issue: Multiple events firing

**Cause:** Missing `stopImmediatePropagation()` or not cleaning up listeners.

**Fix:**
```javascript
destroyed() {
  // Must remove capture-phase listeners
  this.el.removeEventListener("click", this.handleClick, { capture: true })
}
```

### Issue: Node still gets selected

**Cause:** `mousedown` event not being stopped.

**Fix:** Ensure you handle `mousedown` in addition to `click`:
```javascript
this.handleMouseDown = (e) => {
  e.preventDefault()
  e.stopPropagation()
}
this.el.addEventListener("mousedown", this.handleMouseDown, { capture: true })
```

---

## Best Practices

### 1. Always Clean Up Event Listeners

```javascript
destroyed() {
  this.el.removeEventListener("mousedown", this.handleMouseDown, { capture: true })
  this.el.removeEventListener("click", this.handleClick, { capture: true })
}
```

### 2. Use Unique IDs

```elixir
<%# Bad - duplicate IDs if multiple nodes %>
id="edit-btn"

<%# Good - unique per node %>
id={"edit-btn-#{@node.id}"}
```

### 3. Use Data Attributes for Configuration

```elixir
<%# Instead of hardcoding in JS %>
phx-hook="MyHook"
data-event="my_event"
data-node-id={@node.id}
data-extra={@some_value}
```

### 4. Adjust Delay Based on Use Case

```javascript
// For simple actions (like incrementing)
setTimeout(() => this.pushEvent(...), 50)

// For modals (longer to ensure backdrop click doesn't immediately close)
setTimeout(() => this.pushEvent(...), 100)
```

### 5. Return false from Click Handler

```javascript
this.handleClick = (e) => {
  // ... handler code ...
  return false  // Extra safety to prevent default
}
```

---

## Summary

| Aspect | Standard phx-click | Hook with Capture Phase |
|--------|-------------------|-------------------------|
| Event timing | Bubble phase | Capture phase |
| Works inside draggable nodes | ❌ No | ✅ Yes |
| Requires custom JS hook | No | Yes |
| Additional setup | None | Hook registration |

---

## Related Documentation

- [Phoenix LiveView JS Interop](https://hexdocs.pm/phoenix_live_view/js-interop.html)
- [LiveFlow Library Documentation](https://github.com/liveshowy/web_components/tree/main/live_flow)
- [MDN: Event Capture and Bubbling](https://developer.mozilla.org/en-US/docs/Learn_web_development/Core/Scripting/Event_bubbling)
