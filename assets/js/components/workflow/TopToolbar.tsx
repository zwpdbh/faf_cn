// Top toolbar component with navigation
// Clean, minimal design matching FAF eco workflow style

import * as React from 'react';

interface TopToolbarProps {
  title: string;
  subtitle?: string;
  workflowName?: string;
  readonly?: boolean;
  hasChanges?: boolean;
  isSaving?: boolean;
  simulationRun?: boolean;
  currentUser?: { id: string; email?: string } | null;
  onSave?: () => void;
  onSaveAs?: () => void;
  onLoad?: () => void;
  onClear?: () => void;
  onReset?: () => void;
  onRun?: () => void;
  onHome?: () => void;
  onFitView?: () => void;
}

export const TopToolbar: React.FC<TopToolbarProps> = ({
  title,
  subtitle = 'Design your economy workflow',
  workflowName,
  readonly,
  hasChanges,
  isSaving,
  simulationRun,
  currentUser,
  onSave,
  onSaveAs,
  onLoad,
  onClear,
  onReset,
  onRun,
  onHome,
  onFitView,
}) => {
  return (
    <div className="flex items-center justify-between px-6 py-4 bg-white border-b border-gray-200">
      {/* Left section - Home link + Title */}
      <div className="flex items-center gap-4">
        {/* Home/Back button */}
        <button
          onClick={onHome}
          className="flex items-center gap-2 px-3 py-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-md transition-colors"
          title="Back to home"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
          </svg>
          <span className="hidden sm:inline text-sm font-medium">Home</span>
        </button>

        <div className="w-px h-6 bg-gray-200" />

        {/* Title section */}
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-lg font-semibold text-slate-800 m-0">{title}</h2>
            {workflowName && (
              <span className="text-sm text-gray-500">
                - {workflowName}
                {hasChanges && <span className="text-amber-500 ml-1">*</span>}
              </span>
            )}
          </div>
          <span className="text-gray-500 text-sm hidden sm:inline">{subtitle}</span>
        </div>
      </div>

      {/* Center section - View controls */}
      <div className="flex items-center gap-2">
        {onFitView && (
          <button
            onClick={onFitView}
            className="px-3 py-2 bg-white text-slate-700 border border-gray-300 rounded-md text-sm font-medium hover:bg-gray-50 hover:border-gray-400 transition-colors"
            title="Fit view to all nodes"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4" />
            </svg>
          </button>
        )}
      </div>

      {/* Right section - Action buttons */}
      <div className="flex items-center gap-2">
        {/* Run Simulation button - primary action */}
        {!readonly && onRun && (
          <button
            onClick={onRun}
            className={`
              px-4 py-2 rounded-md text-sm font-medium transition-colors
              ${simulationRun
                ? 'bg-amber-500 hover:bg-amber-600 text-white'
                : 'bg-green-600 hover:bg-green-700 text-white'
              }
            `}
          >
            {simulationRun ? '↻ Re-run' : '▶ Run Simulation'}
          </button>
        )}

        {/* Workflow management dropdown */}
        {!readonly && currentUser && (
          <div className="relative group">
            <button
              className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md text-sm font-medium transition-colors"
            >
              Workflow ▼
            </button>
            <div className="absolute right-0 top-full mt-1 w-48 bg-white border border-gray-200 rounded-md shadow-lg opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all z-50">
              {onSave && (
                <button
                  onClick={onSave}
                  disabled={isSaving || !hasChanges}
                  className="w-full px-4 py-2 text-left text-sm text-slate-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isSaving ? 'Saving...' : '💾 Save'}
                </button>
              )}
              {onSaveAs && (
                <button
                  onClick={onSaveAs}
                  className="w-full px-4 py-2 text-left text-sm text-slate-700 hover:bg-gray-50"
                >
                  💾 Save As...
                </button>
              )}
              {onLoad && (
                <button
                  onClick={onLoad}
                  className="w-full px-4 py-2 text-left text-sm text-slate-700 hover:bg-gray-50"
                >
                  📂 Load...
                </button>
              )}
              <hr className="my-1 border-gray-200" />
              {onClear && (
                <button
                  onClick={onClear}
                  className="w-full px-4 py-2 text-left text-sm text-red-600 hover:bg-red-50"
                >
                  🗑 Clear All
                </button>
              )}
              {onReset && (
                <button
                  onClick={onReset}
                  className="w-full px-4 py-2 text-left text-sm text-slate-700 hover:bg-gray-50"
                >
                  ↺ Reset to Default
                </button>
              )}
            </div>
          </div>
        )}

        {/* Save button for guests (prompts login) */}
        {!readonly && !currentUser && onSave && (
          <button
            onClick={onSave}
            className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md text-sm font-medium transition-colors"
          >
            💾 Save (Login)
          </button>
        )}

        {/* Read-only indicator */}
        {readonly && (
          <span className="px-3 py-2 bg-amber-50 text-amber-700 border border-amber-200 rounded-md text-sm font-medium">
            👁 View Only
          </span>
        )}
      </div>
    </div>
  );
};

// Bottom toolbar combining stats and undo/redo
interface BottomToolbarProps {
  nodeCount: number;
  edgeCount: number;
  lastSaved?: Date | null;
  canUndo: boolean;
  canRedo: boolean;
  onUndo: () => void;
  onRedo: () => void;
}

export const BottomToolbar: React.FC<BottomToolbarProps> = ({
  nodeCount,
  edgeCount,
  lastSaved,
  canUndo,
  canRedo,
  onUndo,
  onRedo,
}) => {
  return (
    <div className="absolute bottom-4 left-4 flex items-center gap-3">
      {/* Stats bar */}
      <div className="flex items-center gap-3 px-3 py-2 bg-white/95 backdrop-blur rounded-md border border-gray-200 shadow-sm text-sm">
        <span className="text-gray-600">
          <strong className="text-slate-800">{nodeCount}</strong> nodes
        </span>
        <span className="w-px h-3 bg-gray-300" />
        <span className="text-gray-600">
          <strong className="text-slate-800">{edgeCount}</strong> edges
        </span>
        {lastSaved && (
          <>
            <span className="w-px h-3 bg-gray-300" />
            <span className="text-green-600 text-xs">
              Saved {lastSaved.toLocaleTimeString()}
            </span>
          </>
        )}
      </div>

      {/* Undo/Redo controls */}
      <div className="flex items-center bg-white rounded-md border border-gray-200 shadow-sm overflow-hidden">
        <button
          onClick={onUndo}
          disabled={!canUndo}
          className={`
            px-3 py-2 text-sm font-medium transition-colors border-r border-gray-200
            ${canUndo
              ? 'text-slate-700 hover:bg-gray-50'
              : 'text-gray-400 cursor-not-allowed bg-gray-50'
            }
          `}
          title="Undo (Ctrl+Z)"
        >
          ↩ Undo
        </button>
        <button
          onClick={onRedo}
          disabled={!canRedo}
          className={`
            px-3 py-2 text-sm font-medium transition-colors
            ${canRedo
              ? 'text-slate-700 hover:bg-gray-50'
              : 'text-gray-400 cursor-not-allowed bg-gray-50'
            }
          `}
          title="Redo (Ctrl+Shift+Z)"
        >
          Redo ↪
        </button>
      </div>
    </div>
  );
};

export default TopToolbar;
