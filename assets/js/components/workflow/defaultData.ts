// Default demo data for workflow editor

import type { Node, Edge } from '@xyflow/react';
import type { WorkflowNodeData, NodeType, UnitData } from './types';

// Default unit data (placeholder)
const defaultT3Engineer: UnitData = {
  unit_id: 'UEL0309',
  name: 'T3 Engineer',
  faction: 'UEF',
  tech_level: 3,
  mass_cost: 520,
  energy_cost: 10400,
  build_time: 2600,
};

const defaultT3Pgen: UnitData = {
  unit_id: 'UEB1301',
  name: 'T3 Power Generator',
  faction: 'UEF',
  tech_level: 3,
  mass_cost: 2160,
  energy_cost: 37800,
  build_time: 3240,
};

const defaultT3Mex: UnitData = {
  unit_id: 'UEB1302',
  name: 'T3 Mass Extractor',
  faction: 'UEF',
  tech_level: 3,
  mass_cost: 1800,
  energy_cost: 10800,
  build_time: 1800,
};

const defaultFatboy: UnitData = {
  unit_id: 'UEL0401',
  name: 'Fatboy',
  faction: 'UEF',
  tech_level: 4,
  mass_cost: 28000,
  energy_cost: 350000,
  build_time: 14000,
};

// Demo workflow: Initial -> 3x T3 Engineer -> T3 PGen -> T3 Mex -> Fatboy
export const defaultNodes: Array<Node<WorkflowNodeData>> = [
  {
    id: 'initial',
    type: 'default',
    position: { x: 50, y: 200 },
    data: {
      label: 'Initial Eco',
      type: 'initial',
      status: 'idle',
      mass_in_storage: 650,
      energy_in_storage: 5000,
      mass_per_sec: 1.0,
      energy_per_sec: 20.0,
      build_power: 10,
    },
  },
  {
    id: 'unit-t3-eng-1',
    type: 'default',
    position: { x: 250, y: 100 },
    data: {
      label: 'T3 Engineer',
      type: 'unit',
      status: 'idle',
      unit: defaultT3Engineer,
      quantity: 1,
    },
  },
  {
    id: 'unit-t3-eng-2',
    type: 'default',
    position: { x: 400, y: 200 },
    data: {
      label: 'T3 Engineer',
      type: 'unit',
      status: 'idle',
      unit: defaultT3Engineer,
      quantity: 1,
    },
  },
  {
    id: 'unit-t3-eng-3',
    type: 'default',
    position: { x: 550, y: 300 },
    data: {
      label: 'T3 Engineer',
      type: 'unit',
      status: 'idle',
      unit: defaultT3Engineer,
      quantity: 1,
    },
  },
  {
    id: 'unit-t3-pgen',
    type: 'default',
    position: { x: 700, y: 200 },
    data: {
      label: 'T3 Power Generator',
      type: 'unit',
      status: 'idle',
      unit: defaultT3Pgen,
      quantity: 1,
    },
  },
  {
    id: 'unit-t3-mex',
    type: 'default',
    position: { x: 850, y: 200 },
    data: {
      label: 'T3 Mass Extractor',
      type: 'unit',
      status: 'idle',
      unit: defaultT3Mex,
      quantity: 1,
    },
  },
  {
    id: 'unit-fatboy',
    type: 'default',
    position: { x: 1000, y: 200 },
    data: {
      label: 'Fatboy',
      type: 'unit',
      status: 'idle',
      unit: defaultFatboy,
      quantity: 1,
    },
  },
];

// Connections between nodes
export const defaultEdges: Array<Edge> = [
  {
    id: 'e-initial',
    source: 'initial',
    target: 'unit-t3-eng-1',
    sourceHandle: 'right',
    targetHandle: 'left',
    animated: false,
  },
  {
    id: 'e-eng-1',
    source: 'unit-t3-eng-1',
    target: 'unit-t3-eng-2',
    sourceHandle: 'right',
    targetHandle: 'left',
    animated: false,
  },
  {
    id: 'e-eng-2',
    source: 'unit-t3-eng-2',
    target: 'unit-t3-eng-3',
    sourceHandle: 'right',
    targetHandle: 'left',
    animated: false,
  },
  {
    id: 'e-eng-3',
    source: 'unit-t3-eng-3',
    target: 'unit-t3-pgen',
    sourceHandle: 'right',
    targetHandle: 'left',
    animated: false,
  },
  {
    id: 'e-pgen',
    source: 'unit-t3-pgen',
    target: 'unit-t3-mex',
    sourceHandle: 'right',
    targetHandle: 'left',
    animated: false,
  },
  {
    id: 'e-mex',
    source: 'unit-t3-mex',
    target: 'unit-fatboy',
    sourceHandle: 'right',
    targetHandle: 'left',
    animated: false,
  },
];

// Node type labels for toolbar
export const nodeTypeLabels: Record<NodeType, string> = {
  initial: 'Initial Eco',
  unit: 'Unit',
  mass_rate: 'Mass Income',
  energy_rate: 'Energy Income',
  mass_storage: 'Mass Storage',
  energy_storage: 'Energy Storage',
  build_power: 'Build Power',
};

// Node type button colors for toolbar
export const nodeTypeButtonColors: Record<NodeType, string> = {
  initial: 'bg-blue-100 hover:bg-blue-200 text-blue-700',
  unit: 'bg-green-100 hover:bg-green-200 text-green-700',
  mass_rate: 'bg-purple-100 hover:bg-purple-200 text-purple-700',
  energy_rate: 'bg-yellow-100 hover:bg-yellow-200 text-yellow-700',
  mass_storage: 'bg-pink-100 hover:bg-pink-200 text-pink-700',
  energy_storage: 'bg-cyan-100 hover:bg-cyan-200 text-cyan-700',
  build_power: 'bg-orange-100 hover:bg-orange-200 text-orange-700',
};

// Node type descriptions for the palette
export const nodeTypeDescriptions: Record<NodeType, string> = {
  initial: 'Starting economy state',
  unit: 'Build a unit',
  mass_rate: 'Mass income rate',
  energy_rate: 'Energy income rate',
  mass_storage: 'Mass storage capacity',
  energy_storage: 'Energy storage capacity',
  build_power: 'Build power modifier',
};

// Node type colors (hex for badges)
export const nodeTypeColors: Record<NodeType, string> = {
  initial: '#3b82f6',      // blue-500
  unit: '#22c55e',         // green-500
  mass_rate: '#a855f7',    // purple-500
  energy_rate: '#eab308',  // yellow-500
  mass_storage: '#ec4899', // pink-500
  energy_storage: '#06b6d4', // cyan-500
  build_power: '#f97316',  // orange-500
};
