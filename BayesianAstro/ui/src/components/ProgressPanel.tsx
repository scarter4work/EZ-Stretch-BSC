/**
 * Progress panel showing execution status and run button
 */

import { Play, Loader2 } from 'lucide-react';

interface ProgressPanelProps {
  isProcessing: boolean;
  progress: number;
  status: string;
  onExecute: () => void;
  canExecute: boolean;
}

export function ProgressPanel({
  isProcessing,
  progress,
  status,
  onExecute,
  canExecute,
}: ProgressPanelProps) {
  return (
    <div className="bg-gray-800 rounded-lg p-4">
      <h2 className="text-lg font-semibold mb-4">Execution</h2>

      {/* Progress bar */}
      <div className="mb-4">
        <div className="flex justify-between text-sm mb-1">
          <span>{status}</span>
          <span>{progress}%</span>
        </div>
        <div className="w-full bg-gray-700 rounded-full h-2">
          <div
            className="bg-blue-500 h-2 rounded-full transition-all duration-300"
            style={{ width: `${progress}%` }}
          />
        </div>
      </div>

      {/* Execute button */}
      <button
        onClick={onExecute}
        disabled={!canExecute}
        className={`w-full flex items-center justify-center gap-2 py-3 rounded-lg font-semibold transition-colors ${
          canExecute
            ? 'bg-green-600 hover:bg-green-700 text-white'
            : 'bg-gray-600 text-gray-400 cursor-not-allowed'
        }`}
      >
        {isProcessing ? (
          <>
            <Loader2 size={20} className="animate-spin" />
            Processing...
          </>
        ) : (
          <>
            <Play size={20} />
            Execute
          </>
        )}
      </button>

      {!canExecute && !isProcessing && (
        <p className="text-xs text-gray-400 mt-2 text-center">
          Add input files to enable execution
        </p>
      )}
    </div>
  );
}
