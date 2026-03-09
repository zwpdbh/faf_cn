// Main workflow editor component for FAF Eco Workflow
// 3-panel layout: Left palette, Center canvas, Right properties

import * as React from 'react';
import {
  ReactFlow,
  ReactFlowProvider,
  Background,
  Controls,
  MiniMap,
  useNodesState,
  useEdgesState,
  addEdge,
  type Connection,
  type Edge,
  type Node,
  ConnectionLineType,
  useReactFlow,
  BackgroundVariant,
} from '@xyflow/react';
import '@xyflow/react/dist/style.css';

import type { WorkflowEditorProps, WorkflowNodeData, GraphState } from './types';
import { defaultNodes, defaultEdges } from './defaultData';
import { WorkflowNode } from './WorkflowNode';
import { TopToolbar, BottomToolbar } from './TopToolbar';
import { LeftPanel } from './LeftPanel';
import { RightPanel } from './RightPanel';
import { HistoryManager } from './history';
import { useAutoSave } from './useAutoSave';

// Main exported component with provider
const WorkflowEditor: React.FC<WorkflowEditorProps> = (props) => {
  return (
    <ReactFlowProvider>
      <WorkflowEditorInner {...props} />
    </ReactFlowProvider>
  );
};

// Inner component that uses React Flow hooks
const WorkflowEditorInner: React.FC<WorkflowEditorProps> = ({
  initialNodes = defaultNodes,
  initialEdges = defaultEdges,
  readonly = false,
  autoSave = true,
  workflowId,
  workflowName = 'Untitled Workflow',
  onNodeClick,
  onNodesChange: onNodesChangeCallback,
  onEdgesChange: onEdgesChangeCallback,
  onConnect: onConnectCallback,
  onSave,
  pushEvent,
}) => {
  // React Flow state management
  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState(initialEdges);
  const { fitView } = useReactFlow();

  // Track selected elements
  const [selectedNode, setSelectedNode] = React.useState<Node<WorkflowNodeData> | null>(null);
  const [selectedEdge, setSelectedEdge] = React.useState<Edge | null>(null);

  // History for undo/redo
  const historyRef = React.useRef(
    new HistoryManager<GraphState>({ nodes: initialNodes, edges: initialEdges })
  );
  const [canUndo, setCanUndo] = React.useState(false);
  const [canRedo, setCanRedo] = React.useState(false);

  // Track if there are unsaved changes
  const [hasChanges, setHasChanges] = React.useState(false);
  const [isSaving, setIsSaving] = React.useState(false);
  const [simulationRun, setSimulationRun] = React.useState(false);

  // Sync with initial props when they change
  React.useEffect(() => {
    setNodes(initialNodes);
    historyRef.current.clear({ nodes: initialNodes, edges: initialEdges });
    updateHistoryButtons();
  }, [initialNodes, setNodes]);

  React.useEffect(() => {
    setEdges(initialEdges);
  }, [initialEdges, setEdges]);

  // Update undo/redo button states
  const updateHistoryButtons = React.useCallback(() => {
    setCanUndo(historyRef.current.canUndo());
    setCanRedo(historyRef.current.canRedo());
  }, []);

  // Push state to history
  const pushToHistory = React.useCallback((newNodes: Node<WorkflowNodeData>[], newEdges: Edge[]) => {
    historyRef.current.push({ nodes: newNodes, edges: newEdges });
    updateHistoryButtons();
    setHasChanges(true);
  }, [updateHistoryButtons]);

  // Handle node position changes
  const handleNodesChange = React.useCallback(
    (changes: Parameters<typeof onNodesChange>[0]) => {
      onNodesChange(changes);
      onNodesChangeCallback?.(nodes);

      // Push to history after significant changes (not just selections)
      const hasPositionChange = changes.some(
        (change) => change.type === 'position' && change.position
      );
      if (hasPositionChange) {
        pushToHistory(nodes, edges);
      }
    },
    [onNodesChange, onNodesChangeCallback, nodes, pushToHistory, edges]
  );

  // Handle edge changes
  const handleEdgesChange = React.useCallback(
    (changes: Parameters<typeof onEdgesChange>[0]) => {
      onEdgesChange(changes);
      onEdgesChangeCallback?.(edges);

      // Push to history for add/remove operations
      const hasAddRemove = changes.some(
        (change) => change.type === 'add' || change.type === 'remove'
      );
      if (hasAddRemove) {
        pushToHistory(nodes, edges);
      }
    },
    [onEdgesChange, onEdgesChangeCallback, edges, pushToHistory, nodes]
  );

  // Handle new connections between nodes
  const handleConnect = React.useCallback(
    (connection: Connection) => {
      // Validation: Prevent duplicate edges
      const edgeExists = edges.some(
        (e) => e.source === connection.source && e.target === connection.target
      );
      if (edgeExists) {
        return;
      }

      // Validation: Prevent self-connections
      if (connection.source === connection.target) {
        return;
      }

      const newEdge = addEdge(
        { ...connection, type: ConnectionLineType.SmoothStep, animated: false },
        edges
      );
      setEdges(newEdge);
      pushToHistory(nodes, newEdge);

      if (connection.source && connection.target) {
        onConnectCallback?.({ source: connection.source, target: connection.target });
        pushEvent?.('edge_created', { connection });
      }
    },
    [edges, onConnectCallback, pushEvent, setEdges, pushToHistory, nodes]
  );

  // Handle node click - select and notify LiveView
  const handleNodeClick = React.useCallback(
    (_event: React.MouseEvent, node: Node<WorkflowNodeData>) => {
      setSelectedNode(node);
      setSelectedEdge(null);
      onNodeClick?.(node.id, node.data);
      pushEvent?.('node_clicked', { nodeId: node.id, data: node.data });
    },
    [onNodeClick, pushEvent]
  );

  // Handle edge click
  const handleEdgeClick = React.useCallback(
    (_event: React.MouseEvent, edge: Edge) => {
      setSelectedEdge(edge);
      setSelectedNode(null);
      pushEvent?.('edge_clicked', { edgeId: edge.id, edge });
    },
    [pushEvent]
  );

  // Handle pane click - deselect
  const handlePaneClick = React.useCallback(() => {
    setSelectedNode(null);
    setSelectedEdge(null);
  }, []);

  // Add a new node
  const addNode = React.useCallback(
    (type: WorkflowNodeData['type']) => {
      const id = `node-${Date.now()}`;
      const centerX = 400;
      const centerY = 300;

      let data: WorkflowNodeData = {
        label: 'New Node',
        type,
        status: 'idle',
        description: '',
        config: {},
      };

      // Set default data based on node type
      if (type === 'initial') {
        data = {
          ...data,
          label: 'Initial Eco',
          mass_in_storage: 650,
          energy_in_storage: 5000,
          mass_per_sec: 1.0,
          energy_per_sec: 20.0,
          build_power: 10,
        };
      } else if (type === 'unit') {
        data = {
          ...data,
          label: 'Unit',
          quantity: 1,
        };
      }

      const newNode: Node<WorkflowNodeData> = {
        id,
        type: 'default',
        position: {
          x: centerX + (Math.random() - 0.5) * 100,
          y: centerY + (Math.random() - 0.5) * 100,
        },
        data,
      };

      const newNodes = [...nodes, newNode];
      setNodes(newNodes);
      pushToHistory(newNodes, edges);
      pushEvent?.('node_added', { node: newNode });

      // Auto-select the new node
      setSelectedNode(newNode);
    },
    [pushEvent, setNodes, nodes, edges, pushToHistory]
  );

  // Add a unit node (special case that prompts unit selector)
  const addUnitNode = React.useCallback(() => {
    const id = `unit-${Date.now()}`;
    const centerX = 400;
    const centerY = 300;

    const newNode: Node<WorkflowNodeData> = {
      id,
      type: 'default',
      position: {
        x: centerX + (Math.random() - 0.5) * 100,
        y: centerY + (Math.random() - 0.5) * 100,
      },
      data: {
        label: 'Unit',
        type: 'unit',
        status: 'idle',
        quantity: 1,
      },
    };

    const newNodes = [...nodes, newNode];
    setNodes(newNodes);
    pushToHistory(newNodes, edges);
    pushEvent?.('node_added', { node: newNode });
    pushEvent?.('open_unit_selector', { nodeId: id });

    // Auto-select the new node
    setSelectedNode(newNode);
  }, [pushEvent, setNodes, nodes, edges, pushToHistory]);

  // Delete selected node
  const deleteNode = React.useCallback(
    (nodeId: string) => {
      // Don't allow deleting the initial node
      const node = nodes.find((n) => n.id === nodeId);
      if (node?.data.type === 'initial') {
        return;
      }

      const newNodes = nodes.filter((n) => n.id !== nodeId);
      const newEdges = edges.filter((e) => e.source !== nodeId && e.target !== nodeId);

      setNodes(newNodes);
      setEdges(newEdges);
      pushToHistory(newNodes, newEdges);
      pushEvent?.('node_deleted', { nodeId });
      setSelectedNode(null);
    },
    [pushEvent, setEdges, setNodes, nodes, edges, pushToHistory]
  );

  // Delete selected edge
  const deleteEdge = React.useCallback(
    (edgeId: string) => {
      const newEdges = edges.filter((e) => e.id !== edgeId);

      setEdges(newEdges);
      pushToHistory(nodes, newEdges);
      pushEvent?.('edge_deleted', { edgeId });
      setSelectedEdge(null);
    },
    [pushEvent, setEdges, nodes, edges, pushToHistory]
  );

  // Update node data
  const updateNodeData = React.useCallback(
    (nodeId: string, data: Partial<WorkflowNodeData>) => {
      const newNodes = nodes.map((node) => {
        if (node.id === nodeId) {
          return {
            ...node,
            data: { ...node.data, ...data },
          };
        }
        return node;
      });

      setNodes(newNodes);
      pushToHistory(newNodes, edges);
      pushEvent?.('node_updated', { nodeId, data });

      // Update selected node if it's the one being edited
      if (selectedNode?.id === nodeId) {
        setSelectedNode((prev) => prev ? { ...prev, data: { ...prev.data, ...data } } : null);
      }
    },
    [pushEvent, setNodes, nodes, edges, pushToHistory, selectedNode]
  );

  // Open unit selector for a node
  const openUnitSelector = React.useCallback(
    (nodeId: string) => {
      pushEvent?.('open_unit_selector', { nodeId });
    },
    [pushEvent]
  );

  // Clear all nodes (except initial)
  const clearWorkflow = React.useCallback(() => {
    const initialNode = nodes.find((n) => n.data.type === 'initial');
    const newNodes = initialNode ? [initialNode] : [];
    setNodes(newNodes);
    setEdges([]);
    pushToHistory(newNodes, []);
    pushEvent?.('workflow_cleared', {});
    setSelectedNode(null);
    setSelectedEdge(null);
  }, [pushEvent, setEdges, setNodes, nodes, pushToHistory]);

  // Reset to default workflow
  const resetWorkflow = React.useCallback(() => {
    setNodes(defaultNodes);
    setEdges(defaultEdges);
    pushToHistory(defaultNodes, defaultEdges);
    pushEvent?.('workflow_reset', {});
    fitView();
    setSelectedNode(null);
    setSelectedEdge(null);
    setSimulationRun(false);
  }, [pushEvent, setEdges, setNodes, pushToHistory, fitView]);

  // Run simulation
  const runSimulation = React.useCallback(() => {
    pushEvent?.('run_simulation', { nodes, edges });
    setSimulationRun(true);
  }, [pushEvent, nodes, edges]);

  // Navigate home
  const goHome = React.useCallback(() => {
    window.location.href = '/';
  }, []);

  // Fit view
  const handleFitView = React.useCallback(() => {
    fitView({ padding: 0.1, duration: 200 });
  }, [fitView]);

  // Undo action
  const handleUndo = React.useCallback(() => {
    const state = historyRef.current.undo();
    if (state) {
      setNodes(state.nodes);
      setEdges(state.edges);
      updateHistoryButtons();
      setHasChanges(true);
      pushEvent?.('history_undo', {});
    }
  }, [setNodes, setEdges, updateHistoryButtons, pushEvent]);

  // Redo action
  const handleRedo = React.useCallback(() => {
    const state = historyRef.current.redo();
    if (state) {
      setNodes(state.nodes);
      setEdges(state.edges);
      updateHistoryButtons();
      setHasChanges(true);
      pushEvent?.('history_redo', {});
    }
  }, [setNodes, setEdges, updateHistoryButtons, pushEvent]);

  // Auto-save functionality
  const handleSave = React.useCallback(
    (state: GraphState) => {
      onSave?.(state);
      pushEvent?.('auto_save', { nodes: state.nodes, edges: state.edges });
      setHasChanges(false);
    },
    [onSave, pushEvent]
  );

  const { lastSaved, forceSave } = useAutoSave({
    data: { nodes, edges },
    onSave: handleSave,
    interval: 30000,
    enabled: autoSave && !readonly && !!workflowId,
  });

  // Manual save
  const handleManualSave = React.useCallback(() => {
    setIsSaving(true);
    forceSave();
    pushEvent?.('save_workflow', { nodes, edges });
    setTimeout(() => setIsSaving(false), 500);
  }, [forceSave, pushEvent, nodes, edges]);

  // Handle save as
  const handleSaveAs = React.useCallback(() => {
    pushEvent?.('save_workflow_as', { nodes, edges });
  }, [pushEvent, nodes, edges]);

  // Handle load
  const handleLoad = React.useCallback(() => {
    pushEvent?.('load_workflow', {});
  }, [pushEvent]);

  // Keyboard shortcuts
  React.useEffect(() => {
    if (readonly) return;

    const handleKeyDown = (event: KeyboardEvent) => {
      // Undo: Ctrl+Z or Cmd+Z
      if ((event.ctrlKey || event.metaKey) && event.key === 'z' && !event.shiftKey) {
        event.preventDefault();
        handleUndo();
      }
      // Redo: Ctrl+Shift+Z or Cmd+Shift+Z
      else if ((event.ctrlKey || event.metaKey) && event.shiftKey && event.key === 'z') {
        event.preventDefault();
        handleRedo();
      }
      // Redo: Ctrl+Y or Cmd+Y (alternative)
      else if ((event.ctrlKey || event.metaKey) && event.key === 'y') {
        event.preventDefault();
        handleRedo();
      }
      // Delete: Delete or Backspace when node/edge selected
      else if ((event.key === 'Delete' || event.key === 'Backspace')) {
        if (selectedNode) {
          event.preventDefault();
          deleteNode(selectedNode.id);
        } else if (selectedEdge) {
          event.preventDefault();
          deleteEdge(selectedEdge.id);
        }
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [readonly, handleUndo, handleRedo, deleteNode, deleteEdge, selectedNode, selectedEdge]);

  // Define custom node types
  const nodeTypes = React.useMemo(
    () => ({
      default: (props: { data: WorkflowNodeData; selected?: boolean }) => (
        <WorkflowNode {...props} readonly={readonly} />
      ),
    }),
    [readonly]
  );

  return (
    <div className="flex flex-col h-full bg-gray-50">
      {/* Top Toolbar */}
      <TopToolbar
        title="Eco Workflow"
        workflowName={workflowName}
        readonly={readonly}
        hasChanges={hasChanges}
        isSaving={isSaving}
        simulationRun={simulationRun}
        onSave={handleManualSave}
        onSaveAs={handleSaveAs}
        onLoad={handleLoad}
        onClear={clearWorkflow}
        onReset={resetWorkflow}
        onRun={runSimulation}
        onHome={goHome}
        onFitView={handleFitView}
      />

      {/* Main Content Area */}
      <div className="flex flex-1 overflow-hidden">
        {/* Left Panel - Node Palette */}
        <LeftPanel
          readonly={readonly}
          onAddNode={addNode}
          onAddUnitNode={addUnitNode}
        />

        {/* Center - Canvas */}
        <div className="flex-1 relative">
          <ReactFlow
            nodes={nodes}
            edges={edges}
            onNodesChange={readonly ? undefined : handleNodesChange}
            onEdgesChange={readonly ? undefined : handleEdgesChange}
            onConnect={readonly ? undefined : handleConnect}
            onNodeClick={handleNodeClick}
            onEdgeClick={handleEdgeClick}
            onPaneClick={handlePaneClick}
            nodeTypes={nodeTypes}
            connectionLineType={ConnectionLineType.SmoothStep}
            fitView
            attributionPosition="bottom-right"
            nodesDraggable={!readonly}
            nodesConnectable={!readonly}
            elementsSelectable={!readonly}
            selectNodesOnDrag={!readonly}
            multiSelectionKeyCode={readonly ? null : 'Shift'}
            deleteKeyCode={null} // Handle delete manually
          >
            <Background variant={BackgroundVariant.Dots} gap={16} size={1} />
            <Controls className="bg-white/80 shadow-md rounded-lg border border-gray-200" />
            <MiniMap
              nodeStrokeWidth={3}
              zoomable
              pannable
              className="bg-white/80 rounded-lg shadow-md border border-gray-200"
            />
          </ReactFlow>

          {/* Bottom toolbar with stats and undo/redo */}
          {!readonly && (
            <BottomToolbar
              nodeCount={nodes.length}
              edgeCount={edges.length}
              lastSaved={lastSaved}
              canUndo={canUndo}
              canRedo={canRedo}
              onUndo={handleUndo}
              onRedo={handleRedo}
            />
          )}
          {readonly && (
            <div className="absolute bottom-4 left-4 flex items-center gap-3 px-3 py-2 bg-white/95 backdrop-blur rounded-md border border-gray-200 shadow-sm text-sm">
              <span className="text-gray-600">
                <strong className="text-slate-800">{nodes.length}</strong> nodes
              </span>
              <span className="w-px h-3 bg-gray-300" />
              <span className="text-gray-600">
                <strong className="text-slate-800">{edges.length}</strong> edges
              </span>
            </div>
          )}

          {/* Read-only badge */}
          {readonly && (
            <div className="absolute top-4 right-4 px-3 py-1.5 bg-amber-100 text-amber-800 text-sm font-medium rounded-lg border border-amber-200">
              View Only Mode
            </div>
          )}
        </div>

        {/* Right Panel - Properties */}
        <RightPanel
          selectedNode={selectedNode}
          selectedEdge={selectedEdge}
          readonly={readonly}
          onNodeDataChange={updateNodeData}
          onDeleteNode={deleteNode}
          onDeleteEdge={deleteEdge}
          onOpenUnitSelector={openUnitSelector}
        />
      </div>
    </div>
  );
};

export default WorkflowEditor;
