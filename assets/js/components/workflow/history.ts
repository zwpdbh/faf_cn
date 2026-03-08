// Undo/Redo history management for workflow editor

export interface HistoryState<T> {
  past: T[];
  present: T;
  future: T[];
}

export class HistoryManager<T> {
  private state: HistoryState<T>;
  private maxHistory: number;

  constructor(initialState: T, maxHistory: number = 50) {
    this.state = {
      past: [],
      present: initialState,
      future: [],
    };
    this.maxHistory = maxHistory;
  }

  // Push new state to history
  push(newState: T): void {
    const { past, present } = this.state;

    // Don't push if state is identical
    if (JSON.stringify(present) === JSON.stringify(newState)) {
      return;
    }

    this.state = {
      past: [...past.slice(-(this.maxHistory - 1)), present],
      present: newState,
      future: [],
    };
  }

  // Undo - go back to previous state
  undo(): T | null {
    const { past, present, future } = this.state;

    if (past.length === 0) {
      return null;
    }

    const previous = past[past.length - 1];
    const newPast = past.slice(0, -1);

    this.state = {
      past: newPast,
      present: previous,
      future: [present, ...future],
    };

    return previous;
  }

  // Redo - go forward to next state
  redo(): T | null {
    const { past, present, future } = this.state;

    if (future.length === 0) {
      return null;
    }

    const next = future[0];
    const newFuture = future.slice(1);

    this.state = {
      past: [...past, present],
      present: next,
      future: newFuture,
    };

    return next;
  }

  // Get current state
  getState(): T {
    return this.state.present;
  }

  // Check if undo is available
  canUndo(): boolean {
    return this.state.past.length > 0;
  }

  // Check if redo is available
  canRedo(): boolean {
    return this.state.future.length > 0;
  }

  // Clear history
  clear(newState: T): void {
    this.state = {
      past: [],
      present: newState,
      future: [],
    };
  }
}
