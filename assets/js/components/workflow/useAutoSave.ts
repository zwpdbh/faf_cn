// Auto-save hook for workflow editor

import * as React from 'react';
import { useCallback, useEffect, useRef } from 'react';

interface UseAutoSaveOptions<T> {
  data: T;
  onSave: (data: T) => void;
  interval?: number; // milliseconds
  enabled?: boolean;
}

export function useAutoSave<T>({
  data,
  onSave,
  interval = 30000, // Default 30 seconds
  enabled = true,
}: UseAutoSaveOptions<T>): { isSaving: boolean; lastSaved: Date | null; forceSave: () => void } {
  const dataRef = useRef(data);
  const isSavingRef = useRef(false);
  const lastSavedRef = useRef<Date | null>(null);
  const [, forceUpdate] = React.useReducer((x) => x + 1, 0);

  // Keep ref in sync
  useEffect(() => {
    dataRef.current = data;
  }, [data]);

  // Save function
  const save = useCallback(async () => {
    if (isSavingRef.current || !enabled) return;

    isSavingRef.current = true;
    forceUpdate();

    try {
      await onSave(dataRef.current);
      lastSavedRef.current = new Date();
    } catch (error) {
      console.error('Auto-save failed:', error);
    } finally {
      isSavingRef.current = false;
      forceUpdate();
    }
  }, [onSave, enabled]);

  // Force save
  const forceSave = useCallback(() => {
    save();
  }, [save]);

  // Set up interval
  useEffect(() => {
    if (!enabled) return;

    const timer = setInterval(save, interval);
    return () => clearInterval(timer);
  }, [save, interval, enabled]);

  // Save on page unload
  useEffect(() => {
    if (!enabled) return;

    const handleBeforeUnload = () => {
      if (isSavingRef.current) return;
      // Use synchronous save for unload
      onSave(dataRef.current);
    };

    window.addEventListener('beforeunload', handleBeforeUnload);
    return () => window.removeEventListener('beforeunload', handleBeforeUnload);
  }, [onSave, enabled]);

  return {
    isSaving: isSavingRef.current,
    lastSaved: lastSavedRef.current,
    forceSave,
  };
}
