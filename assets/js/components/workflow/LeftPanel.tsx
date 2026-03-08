// Left panel with node palette
// Clean, minimal sidebar for FAF eco workflow

import * as React from 'react';
import type { NodeType } from './types';
import { nodeTypeLabels, nodeTypeDescriptions, nodeTypeColors } from './defaultData';

interface LeftPanelProps {
  readonly?: boolean;
  onAddNode: (type: NodeType) => void;
  onAddUnitNode: () => void;
}

export const LeftPanel: React.FC<LeftPanelProps> = ({
  readonly,
  onAddNode,
  onAddUnitNode,
}) => {
  const [isCollapsed, setIsCollapsed] = React.useState(false);

  if (readonly) {
    return null;
  }

  if (isCollapsed) {
    return (
      <button
        onClick={() => setIsCollapsed(false)}
        className="absolute left-0 top-20 z-10 p-2 bg-white border border-l-0 border-gray-200 rounded-r-lg shadow-sm hover:bg-gray-50 transition-colors"
        title="Expand palette"
      >
        <svg className="w-5 h-5 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
        </svg>
      </button>
    );
  }

  return (
    <div className="w-64 bg-white border-r border-gray-200 flex flex-col h-full">
      {/* Header */}
      <div className="p-4 border-b border-gray-100">
        <h3 className="text-sm font-semibold text-slate-800">Node Palette</h3>
        <p className="text-xs text-gray-500 mt-1">Click to add nodes</p>
      </div>

      {/* Node categories */}
      <div className="flex-1 overflow-y-auto p-4 space-y-5">
        {/* Initial Section */}
        <section>
          <h4 className="text-xs font-medium text-gray-400 uppercase tracking-wide mb-2">
            Start
          </h4>
          <AddNodeButton
            type="initial"
            color="#3b82f6"
            label="Initial Eco"
            description="Starting economy"
            onClick={() => onAddNode('initial')}
          />
        </section>

        {/* Units Section */}
        <section>
          <h4 className="text-xs font-medium text-gray-400 uppercase tracking-wide mb-2">
            Units
          </h4>
          <button
            onClick={onAddUnitNode}
            className="w-full flex items-center gap-3 px-3 py-2.5 bg-white border border-gray-200 rounded-lg hover:border-gray-300 hover:shadow-sm transition-all group text-left"
          >
            {/* Color indicator */}
            <span
              className="w-3 h-3 rounded-full flex-shrink-0"
              style={{ backgroundColor: '#22c55e' }}
            />

            {/* Text content */}
            <div className="flex-1 min-w-0">
              <div className="text-sm font-medium text-slate-700">Unit</div>
              <div className="text-xs text-gray-400 truncate">Build any unit</div>
            </div>

            {/* Plus icon on hover */}
            <svg
              className="w-4 h-4 text-gray-300 group-hover:text-gray-500 transition-colors flex-shrink-0"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </svg>
          </button>
        </section>

        {/* Economy Modifiers Section */}
        <section>
          <h4 className="text-xs font-medium text-gray-400 uppercase tracking-wide mb-2">
            Economy
          </h4>
          <div className="space-y-2">
            <AddNodeButton
              type="mass_rate"
              color="#a855f7"
              onClick={() => onAddNode('mass_rate')}
            />
            <AddNodeButton
              type="energy_rate"
              color="#eab308"
              onClick={() => onAddNode('energy_rate')}
            />
            <AddNodeButton
              type="mass_storage"
              color="#ec4899"
              onClick={() => onAddNode('mass_storage')}
            />
            <AddNodeButton
              type="energy_storage"
              color="#06b6d4"
              onClick={() => onAddNode('energy_storage')}
            />
          </div>
        </section>
      </div>

      {/* Tips section */}
      <div className="p-3 bg-slate-50 border-t border-gray-100">
        <p className="text-xs text-gray-500 leading-relaxed">
          <span className="text-amber-500">💡</span> Drag from handles to connect nodes
        </p>
      </div>

      {/* Collapse button */}
      <button
        onClick={() => setIsCollapsed(true)}
        className="w-full p-3 bg-gray-50 border-t border-gray-200 text-gray-500 text-xs font-medium hover:bg-gray-100 hover:text-gray-700 transition-colors flex items-center justify-center gap-1"
      >
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
        </svg>
        Collapse
      </button>
    </div>
  );
};

// Individual add node button
interface AddNodeButtonProps {
  type: NodeType;
  color: string;
  label?: string;
  description?: string;
  onClick: () => void;
}

const AddNodeButton: React.FC<AddNodeButtonProps> = ({ type, color, label, description, onClick }) => {
  return (
    <button
      onClick={onClick}
      className="w-full flex items-center gap-3 px-3 py-2.5 bg-white border border-gray-200 rounded-lg hover:border-gray-300 hover:shadow-sm transition-all group text-left"
    >
      {/* Color indicator */}
      <span
        className="w-3 h-3 rounded-full flex-shrink-0"
        style={{ backgroundColor: color }}
      />

      {/* Text content */}
      <div className="flex-1 min-w-0">
        <div className="text-sm font-medium text-slate-700">{label || nodeTypeLabels[type]}</div>
        <div className="text-xs text-gray-400 truncate">{description || nodeTypeDescriptions[type]}</div>
      </div>

      {/* Plus icon on hover */}
      <svg
        className="w-4 h-4 text-gray-300 group-hover:text-gray-500 transition-colors flex-shrink-0"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
      </svg>
    </button>
  );
};

export default LeftPanel;
