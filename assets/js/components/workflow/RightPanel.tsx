// Right panel with properties
// Clean, minimal design for FAF eco workflow

import * as React from 'react';
import type { Node, Edge } from '@xyflow/react';
import type { WorkflowNodeData } from './types';
import { nodeTypeLabels, nodeTypeColors } from './defaultData';

interface RightPanelProps {
  selectedNode: Node<WorkflowNodeData> | null;
  selectedEdge: Edge | null;
  readonly?: boolean;
  onNodeDataChange?: (nodeId: string, data: Partial<WorkflowNodeData>) => void;
  onDeleteNode?: (nodeId: string) => void;
  onDeleteEdge?: (edgeId: string) => void;
  onOpenUnitSelector?: (nodeId: string) => void;
}

export const RightPanel: React.FC<RightPanelProps> = ({
  selectedNode,
  selectedEdge,
  readonly,
  onNodeDataChange,
  onDeleteNode,
  onDeleteEdge,
  onOpenUnitSelector,
}) => {
  const hasSelection = selectedNode !== null || selectedEdge !== null;

  return (
    <div className="w-64 bg-white border-l border-gray-200 flex flex-col h-full">
      {/* Header */}
      <div className="p-4 border-b border-gray-100">
        <h3 className="text-sm font-semibold text-slate-800">Properties</h3>
        <p className="text-xs text-gray-500 mt-1">
          {selectedNode && 'Edit selected node'}
          {selectedEdge && 'Connection details'}
          {!hasSelection && 'Select an element'}
        </p>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        {selectedNode && (
          <NodeProperties
            node={selectedNode}
            readonly={readonly}
            onDataChange={onNodeDataChange}
            onDelete={onDeleteNode}
            onOpenUnitSelector={onOpenUnitSelector}
          />
        )}
        {selectedEdge && (
          <EdgeProperties
            edge={selectedEdge}
            readonly={readonly}
            onDelete={onDeleteEdge}
          />
        )}
        {!hasSelection && <EmptyState />}
      </div>
    </div>
  );
};

// Node properties component
interface NodePropertiesProps {
  node: Node<WorkflowNodeData>;
  readonly?: boolean;
  onDataChange?: (nodeId: string, data: Partial<WorkflowNodeData>) => void;
  onDelete?: (nodeId: string) => void;
  onOpenUnitSelector?: (nodeId: string) => void;
}

const NodeProperties: React.FC<NodePropertiesProps> = ({
  node,
  readonly,
  onDataChange,
  onDelete,
  onOpenUnitSelector,
}) => {
  const [label, setLabel] = React.useState(node.data.label);
  const [quantity, setQuantity] = React.useState(node.data.quantity || 1);
  const type = node.data.type;
  const unit = node.data.unit;

  React.useEffect(() => {
    setLabel(node.data.label);
    setQuantity(node.data.quantity || 1);
  }, [node.data.label, node.data.quantity]);

  const handleLabelChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newLabel = e.target.value;
    setLabel(newLabel);
    onDataChange?.(node.id, { label: newLabel });
  };

  const handleQuantityChange = (delta: number) => {
    const newQuantity = Math.max(1, (quantity || 1) + delta);
    setQuantity(newQuantity);
    onDataChange?.(node.id, { quantity: newQuantity });
  };

  const isInitialNode = type === 'initial';
  const isUnitNode = type === 'unit';

  return (
    <div className="p-4 space-y-4">
      {/* Node type badge */}
      <div>
        <span
          className="inline-flex items-center px-2.5 py-1 rounded-md text-xs font-medium text-white"
          style={{ backgroundColor: nodeTypeColors[type] }}
        >
          {nodeTypeLabels[type]}
        </span>
      </div>

      {/* Node ID */}
      <div>
        <label className="block text-xs font-medium text-gray-400 uppercase tracking-wide mb-1">
          Node ID
        </label>
        <code className="block px-2.5 py-1.5 bg-slate-100 rounded text-xs font-mono text-slate-600">
          {node.id}
        </code>
      </div>

      {/* Label input */}
      <div>
        <label className="block text-xs font-medium text-gray-400 uppercase tracking-wide mb-1">
          Label
        </label>
        <input
          type="text"
          value={label}
          onChange={handleLabelChange}
          disabled={readonly}
          className="w-full px-3 py-2 bg-white border border-gray-200 rounded-md text-sm text-slate-700 focus:outline-none focus:border-blue-400 focus:ring-1 focus:ring-blue-400 disabled:bg-slate-50 disabled:text-gray-400 transition-colors"
          placeholder="Enter label..."
        />
      </div>

      {/* Quantity for unit nodes */}
      {isUnitNode && (
        <div>
          <label className="block text-xs font-medium text-gray-400 uppercase tracking-wide mb-1">
            Quantity
          </label>
          <div className="flex items-center gap-2">
            <button
              onClick={() => handleQuantityChange(-1)}
              disabled={readonly || quantity <= 1}
              className="px-3 py-2 bg-gray-100 hover:bg-gray-200 disabled:opacity-50 rounded-md text-sm font-medium transition-colors"
            >
              -
            </button>
            <span className="px-4 py-2 bg-slate-100 rounded-md text-sm font-mono text-slate-700 min-w-[3rem] text-center">
              {quantity}
            </span>
            <button
              onClick={() => handleQuantityChange(1)}
              disabled={readonly}
              className="px-3 py-2 bg-gray-100 hover:bg-gray-200 disabled:opacity-50 rounded-md text-sm font-medium transition-colors"
            >
              +
            </button>
          </div>
        </div>
      )}

      {/* Unit selector button for unit nodes */}
      {isUnitNode && onOpenUnitSelector && (
        <div>
          <label className="block text-xs font-medium text-gray-400 uppercase tracking-wide mb-1">
            Unit
          </label>
          <button
            onClick={() => onOpenUnitSelector(node.id)}
            disabled={readonly}
            className="w-full px-3 py-2 bg-blue-50 hover:bg-blue-100 text-blue-700 border border-blue-200 rounded-md text-sm font-medium transition-colors text-left"
          >
            {unit ? `${unit.name} (${unit.unit_id})` : 'Select Unit...'}
          </button>
          {unit && (
            <div className="mt-2 text-xs space-y-1">
              <div className="flex justify-between">
                <span className="text-gray-500">Mass Cost:</span>
                <span className="text-amber-600 font-medium">{unit.mass_cost}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Energy Cost:</span>
                <span className="text-yellow-600 font-medium">{unit.energy_cost}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Build Time:</span>
                <span className="text-slate-600 font-medium">{unit.build_time}s</span>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Position */}
      <div>
        <label className="block text-xs font-medium text-gray-400 uppercase tracking-wide mb-1">
          Position
        </label>
        <div className="flex gap-2">
          <div className="flex-1 px-2.5 py-1.5 bg-slate-100 rounded text-xs font-mono text-slate-600">
            X: {Math.round(node.position.x)}
          </div>
          <div className="flex-1 px-2.5 py-1.5 bg-slate-100 rounded text-xs font-mono text-slate-600">
            Y: {Math.round(node.position.y)}
          </div>
        </div>
      </div>

      {/* Status */}
      <div>
        <label className="block text-xs font-medium text-gray-400 uppercase tracking-wide mb-1">
          Status
        </label>
        <StatusBadge status={node.data.status || 'idle'} />
      </div>

      {/* Initial node eco settings */}
      {isInitialNode && (
        <div className="space-y-3 pt-2 border-t border-gray-100">
          <p className="text-xs font-medium text-gray-400 uppercase tracking-wide">Economy Settings</p>
          <div className="grid grid-cols-2 gap-2">
            <div>
              <label className="block text-xs text-gray-500 mb-1">Mass Storage</label>
              <input
                type="number"
                value={node.data.mass_in_storage || 0}
                onChange={(e) => onDataChange?.(node.id, { mass_in_storage: parseFloat(e.target.value) || 0 })}
                disabled={readonly}
                className="w-full px-2 py-1.5 bg-white border border-gray-200 rounded text-sm disabled:bg-slate-50"
              />
            </div>
            <div>
              <label className="block text-xs text-gray-500 mb-1">Energy Storage</label>
              <input
                type="number"
                value={node.data.energy_in_storage || 0}
                onChange={(e) => onDataChange?.(node.id, { energy_in_storage: parseFloat(e.target.value) || 0 })}
                disabled={readonly}
                className="w-full px-2 py-1.5 bg-white border border-gray-200 rounded text-sm disabled:bg-slate-50"
              />
            </div>
            <div>
              <label className="block text-xs text-gray-500 mb-1">Mass Income</label>
              <input
                type="number"
                step="0.1"
                value={node.data.mass_per_sec || 0}
                onChange={(e) => onDataChange?.(node.id, { mass_per_sec: parseFloat(e.target.value) || 0 })}
                disabled={readonly}
                className="w-full px-2 py-1.5 bg-white border border-gray-200 rounded text-sm disabled:bg-slate-50"
              />
            </div>
            <div>
              <label className="block text-xs text-gray-500 mb-1">Energy Income</label>
              <input
                type="number"
                step="0.1"
                value={node.data.energy_per_sec || 0}
                onChange={(e) => onDataChange?.(node.id, { energy_per_sec: parseFloat(e.target.value) || 0 })}
                disabled={readonly}
                className="w-full px-2 py-1.5 bg-white border border-gray-200 rounded text-sm disabled:bg-slate-50"
              />
            </div>
          </div>
        </div>
      )}

      {/* Delete button */}
      {!readonly && !isInitialNode && onDelete && (
        <div className="pt-3 border-t border-gray-100">
          <button
            onClick={() => onDelete(node.id)}
            className="w-full px-4 py-2 bg-red-50 hover:bg-red-100 text-red-600 border border-red-200 rounded-md text-sm font-medium transition-colors"
          >
            Delete Node
          </button>
        </div>
      )}
    </div>
  );
};

// Edge properties component
interface EdgePropertiesProps {
  edge: Edge;
  readonly?: boolean;
  onDelete?: (edgeId: string) => void;
}

const EdgeProperties: React.FC<EdgePropertiesProps> = ({
  edge,
  readonly,
  onDelete,
}) => {
  return (
    <div className="p-4 space-y-4">
      {/* Edge type badge */}
      <div>
        <span className="inline-flex items-center px-2.5 py-1 rounded-md text-xs font-medium bg-slate-600 text-white">
          Connection
        </span>
      </div>

      {/* Edge ID */}
      <div>
        <label className="block text-xs font-medium text-gray-400 uppercase tracking-wide mb-1">
          Edge ID
        </label>
        <code className="block px-2.5 py-1.5 bg-slate-100 rounded text-xs font-mono text-slate-600">
          {edge.id}
        </code>
      </div>

      {/* From / Source */}
      <div>
        <label className="block text-xs font-medium text-gray-400 uppercase tracking-wide mb-1">
          From
        </label>
        <div className="flex items-center gap-2 px-2.5 py-1.5 bg-slate-100 rounded">
          <svg className="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 10l7-7m0 0l7 7m-7-7v18" />
          </svg>
          <code className="text-xs font-mono text-slate-600">{edge.source}</code>
        </div>
      </div>

      {/* To / Target */}
      <div>
        <label className="block text-xs font-medium text-gray-400 uppercase tracking-wide mb-1">
          To
        </label>
        <div className="flex items-center gap-2 px-2.5 py-1.5 bg-slate-100 rounded">
          <svg className="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 14l-7 7m0 0l-7-7m7 7V3" />
          </svg>
          <code className="text-xs font-mono text-slate-600">{edge.target}</code>
        </div>
      </div>

      {/* Label (if any) */}
      {edge.label && (
        <div>
          <label className="block text-xs font-medium text-gray-400 uppercase tracking-wide mb-1">
            Label
          </label>
          <div className="px-2.5 py-1.5 bg-slate-100 rounded text-sm text-slate-700">
            {edge.label}
          </div>
        </div>
      )}

      {/* Animated indicator */}
      <div>
        <label className="block text-xs font-medium text-gray-400 uppercase tracking-wide mb-1">
          Animation
        </label>
        <div className="flex items-center gap-2 px-2.5 py-1.5 bg-slate-100 rounded">
          <span className={`w-2 h-2 rounded-full ${edge.animated ? 'bg-green-500 animate-pulse' : 'bg-gray-300'}`} />
          <span className="text-sm text-slate-600">
            {edge.animated ? 'Animated' : 'Static'}
          </span>
        </div>
      </div>

      {/* Delete button */}
      {!readonly && onDelete && (
        <div className="pt-3 border-t border-gray-100">
          <button
            onClick={() => onDelete(edge.id)}
            className="w-full px-4 py-2 bg-red-50 hover:bg-red-100 text-red-600 border border-red-200 rounded-md text-sm font-medium transition-colors"
          >
            Delete Connection
          </button>
        </div>
      )}
    </div>
  );
};

// Empty state when nothing is selected
const EmptyState: React.FC = () => (
  <div className="p-8 text-center">
    <div className="w-16 h-16 mx-auto mb-4 bg-slate-100 rounded-full flex items-center justify-center">
      <svg className="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 15l-2 5L9 9l11 4-5 2zm0 0l5 5M7.188 2.239l.777 2.897M5.136 7.965l-2.898-.777M13.95 4.05l-2.122 2.122m-5.657 5.656l-2.12 2.122" />
      </svg>
    </div>
    <p className="text-sm text-gray-500">
      Click on a node or connection to view and edit its properties
    </p>
  </div>
);

// Status badge component
const StatusBadge: React.FC<{ status: string }> = ({ status }) => {
  const styles: Record<string, { bg: string; text: string; dot?: string }> = {
    idle: { bg: 'bg-gray-100', text: 'text-gray-600' },
    running: { bg: 'bg-amber-100', text: 'text-amber-700', dot: 'bg-amber-500' },
    completed: { bg: 'bg-green-100', text: 'text-green-700' },
    failed: { bg: 'bg-red-100', text: 'text-red-700' },
    skipped: { bg: 'bg-gray-100', text: 'text-gray-500' },
  };

  const style = styles[status] || styles.idle;

  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium ${style.bg} ${style.text}`}>
      {style.dot && <span className={`w-1.5 h-1.5 rounded-full ${style.dot} animate-pulse`} />}
      {status.charAt(0).toUpperCase() + status.slice(1)}
    </span>
  );
};

export default RightPanel;
