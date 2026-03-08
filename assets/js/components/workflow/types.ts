// Type definitions for Workflow Editor

import type { Node, Edge } from '@xyflow/react';

export type NodeType = 'initial' | 'unit' | 'mass_rate' | 'energy_rate' | 'mass_storage' | 'energy_storage' | 'build_power';
export type NodeStatus = 'idle' | 'running' | 'completed' | 'failed' | 'skipped';

// Unit data from FAF
export interface UnitData {
  unit_id: string;
  name: string;
  faction: string;
  tech_level: number;
  mass_cost: number;
  energy_cost: number;
  build_time: number;
  icon_url?: string;
}

// WorkflowNodeData must satisfy Record<string, unknown> for React Flow
export interface WorkflowNodeData extends Record<string, unknown> {
  label: string;
  type: NodeType;
  status?: NodeStatus;
  description?: string;
  unit?: UnitData;
  quantity?: number;
  // Initial node data
  mass_in_storage?: number;
  energy_in_storage?: number;
  mass_per_sec?: number;
  energy_per_sec?: number;
  build_power?: number;
  // Simulation results
  finished_time?: number | null;
  config?: Record<string, unknown>;
}

export interface GraphState {
  nodes: Array<Node<WorkflowNodeData>>;
  edges: Array<Edge>;
}

export interface WorkflowEditorProps {
  initialNodes?: Array<Node<WorkflowNodeData>>;
  initialEdges?: Array<Edge>;
  readonly?: boolean;
  autoSave?: boolean;
  workflowId?: string | null;
  workflowName?: string;
  onNodeClick?: (nodeId: string, nodeData: WorkflowNodeData) => void;
  onNodesChange?: (nodes: Array<Node<WorkflowNodeData>>) => void;
  onEdgesChange?: (edges: Array<Edge>) => void;
  onConnect?: (connection: { source: string; target: string }) => void;
  onSave?: (state: GraphState) => void;
  pushEvent?: (event: string, payload?: Record<string, unknown>) => void;
}

export interface NodeStyleConfig {
  bg: string;
  border: string;
  color: string;
}

export interface SelectedElements {
  nodes: string[];
  edges: string[];
}
