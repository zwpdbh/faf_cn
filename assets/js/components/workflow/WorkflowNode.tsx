// Custom workflow node component with handles and status indicators

import * as React from 'react';
import { Handle, Position } from '@xyflow/react';
import type { WorkflowNodeData } from './types';
import { getNodeStyle, handleStyles } from './nodeStyles';

interface WorkflowNodeProps {
  data: WorkflowNodeData;
  selected?: boolean;
  readonly?: boolean;
}

export const WorkflowNode: React.FC<WorkflowNodeProps> = ({
  data,
  selected,
  readonly,
}) => {
  const type = data.type ?? 'unit';
  const status = data.status ?? 'idle';
  const quantity = data.quantity ?? 1;
  const unit = data.unit;

  return (
    <div
      style={{
        ...getNodeStyle(type, status, selected),
        cursor: readonly ? 'pointer' : 'grab',
      }}
    >
      {/* Input handles - where connections can connect to */}
      <Handle
        type="target"
        position={Position.Top}
        id="top"
        style={handleStyles.input}
      />
      <Handle
        type="target"
        position={Position.Left}
        id="left"
        style={handleStyles.input}
      />

      {/* Node content */}
      <div className="flex flex-col items-center gap-1">
        <div className="flex items-center gap-2 justify-center">
          <StatusIcon status={data.status} />
          <span className="font-semibold">{data.label}</span>
          {type === 'unit' && quantity > 1 && (
            <span className="bg-white/50 px-1.5 py-0.5 rounded text-xs">
              x{quantity}
            </span>
          )}
        </div>

        {/* Unit cost info */}
        {unit && (
          <div className="text-xs opacity-70 mt-1 space-y-0.5">
            <div className="flex items-center gap-2">
              <span className="text-amber-600">M: {unit.mass_cost}</span>
              <span className="text-yellow-600">E: {unit.energy_cost}</span>
            </div>
            <div className="text-gray-500">BT: {unit.build_time}s</div>
          </div>
        )}

        {/* Initial node eco stats */}
        {type === 'initial' && (
          <div className="text-xs opacity-70 mt-1 space-y-0.5">
            <div className="flex items-center gap-2">
              <span className="text-amber-600">M: {data.mass_in_storage}</span>
              <span className="text-yellow-600">E: {data.energy_in_storage}</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-amber-600">M/s: {data.mass_per_sec}</span>
              <span className="text-yellow-600">E/s: {data.energy_per_sec}</span>
            </div>
          </div>
        )}

        {/* Finished time from simulation */}
        {data.finished_time !== undefined && data.finished_time !== null && (
          <div className="text-xs text-green-600 mt-1 font-medium">
            Done: {data.finished_time.toFixed(1)}s
          </div>
        )}
      </div>

      {/* Output handles - where connections can originate from */}
      <Handle
        type="source"
        position={Position.Right}
        id="right"
        style={handleStyles.output}
      />
      <Handle
        type="source"
        position={Position.Bottom}
        id="bottom"
        style={handleStyles.output}
      />
    </div>
  );
};

// Status indicator icons
interface StatusIconProps {
  status?: string;
}

const StatusIcon: React.FC<StatusIconProps> = ({ status }) => {
  switch (status) {
    case 'running':
      return (
        <span className="animate-spin inline-block w-4 h-4 border-2 border-current border-t-transparent rounded-full" />
      );
    case 'completed':
      return <span className="text-green-600">✓</span>;
    case 'failed':
      return <span className="text-red-500">✗</span>;
    default:
      return null;
  }
};

export default WorkflowNode;
