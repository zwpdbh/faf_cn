// Node styling configuration

import type { CSSProperties } from 'react';
import type { NodeType, NodeStatus, NodeStyleConfig } from './types';

// Color configuration for each node type
export const typeColors: Record<NodeType, NodeStyleConfig> = {
  initial: { bg: '#dbeafe', border: '#3b82f6', color: '#1e40af' },      // Blue
  unit: { bg: '#dcfce7', border: '#22c55e', color: '#166534' },         // Green
  mass_rate: { bg: '#f3e8ff', border: '#a855f7', color: '#6b21a8' },    // Purple
  energy_rate: { bg: '#fef9c3', border: '#eab308', color: '#854d0e' },  // Yellow
  mass_storage: { bg: '#fce7f3', border: '#ec4899', color: '#9d174d' }, // Pink
  energy_storage: { bg: '#cffafe', border: '#06b6d4', color: '#155e75' }, // Cyan
  build_power: { bg: '#ffedd5', border: '#f97316', color: '#9a3412' },  // Orange
};

// Status-based visual modifications
export const statusStyles: Record<NodeStatus, CSSProperties> = {
  running: {
    boxShadow: '0 0 0 3px rgba(251, 191, 36, 0.5)',
    animation: 'pulse 2s infinite',
  },
  completed: { opacity: 1 },
  failed: {
    borderStyle: 'dashed',
    borderColor: '#ef4444',
    backgroundColor: '#fee2e2',
  },
  skipped: { opacity: 0.5, borderStyle: 'dotted' },
  idle: {},
};

// Base styles applied to all nodes
const baseStyle: CSSProperties = {
  padding: '12px 16px',
  borderRadius: '8px',
  border: '2px solid',
  fontSize: '13px',
  fontWeight: 500,
  minWidth: '120px',
  maxWidth: '180px',
  textAlign: 'center',
  boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
};

// Generate complete node style based on type and status
export function getNodeStyle(
  type: NodeType,
  status: NodeStatus = 'idle',
  selected?: boolean
): CSSProperties {
  const colors = typeColors[type] ?? typeColors.unit;

  return {
    ...baseStyle,
    backgroundColor: colors.bg,
    borderColor: colors.border,
    color: colors.color,
    transform: selected ? 'scale(1.05)' : 'scale(1)',
    transition: 'transform 0.2s',
    ...statusStyles[status],
  };
}

// Handle style configuration
export const handleStyles = {
  input: {
    background: '#94a3b8',
    width: 8,
    height: 8,
  },
  output: {
    background: '#64748b',
    width: 8,
    height: 8,
  },
};
