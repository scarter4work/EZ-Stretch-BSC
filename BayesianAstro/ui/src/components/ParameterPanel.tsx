/**
 * Parameter panel for configuring the stacking algorithm
 */

interface ParameterPanelProps {
  fusionStrategy: number;
  outlierSigma: number;
  confidenceThreshold: number;
  useGPU: boolean;
  generateConfidenceMap: boolean;
  onFusionStrategyChange: (value: number) => void;
  onOutlierSigmaChange: (value: number) => void;
  onConfidenceThresholdChange: (value: number) => void;
  onUseGPUChange: (value: boolean) => void;
  onGenerateConfidenceMapChange: (value: boolean) => void;
  disabled?: boolean;
}

const FUSION_STRATEGIES = [
  { value: 0, label: 'MLE', description: 'Maximum Likelihood Estimation' },
  { value: 1, label: 'Confidence Weighted', description: 'Weight by inverse variance' },
  { value: 2, label: 'Lucky Imaging', description: 'Per-pixel best frame selection' },
  { value: 3, label: 'Multi-Scale', description: 'Different strategies per frequency' },
];

export function ParameterPanel({
  fusionStrategy,
  outlierSigma,
  confidenceThreshold,
  useGPU,
  generateConfidenceMap,
  onFusionStrategyChange,
  onOutlierSigmaChange,
  onConfidenceThresholdChange,
  onUseGPUChange,
  onGenerateConfidenceMapChange,
  disabled,
}: ParameterPanelProps) {
  return (
    <div className="bg-gray-800 rounded-lg p-4">
      <h2 className="text-lg font-semibold mb-4">Parameters</h2>

      <div className="space-y-4">
        {/* Fusion Strategy */}
        <div>
          <label className="block text-sm font-medium mb-1">Fusion Strategy</label>
          <select
            value={fusionStrategy}
            onChange={(e) => onFusionStrategyChange(Number(e.target.value))}
            disabled={disabled}
            className="w-full bg-gray-700 border border-gray-600 rounded px-3 py-2 text-sm disabled:opacity-50"
          >
            {FUSION_STRATEGIES.map((s) => (
              <option key={s.value} value={s.value}>
                {s.label}
              </option>
            ))}
          </select>
          <p className="text-xs text-gray-400 mt-1">
            {FUSION_STRATEGIES.find((s) => s.value === fusionStrategy)?.description}
          </p>
        </div>

        {/* Outlier Sigma */}
        <div>
          <label className="block text-sm font-medium mb-1">
            Outlier Rejection (sigma): {outlierSigma.toFixed(1)}
          </label>
          <input
            type="range"
            min="0.5"
            max="10"
            step="0.1"
            value={outlierSigma}
            onChange={(e) => onOutlierSigmaChange(Number(e.target.value))}
            disabled={disabled}
            className="w-full"
          />
        </div>

        {/* Confidence Threshold */}
        <div>
          <label className="block text-sm font-medium mb-1">
            Confidence Threshold: {confidenceThreshold.toFixed(2)}
          </label>
          <input
            type="range"
            min="0"
            max="1"
            step="0.01"
            value={confidenceThreshold}
            onChange={(e) => onConfidenceThresholdChange(Number(e.target.value))}
            disabled={disabled}
            className="w-full"
          />
        </div>

        {/* Checkboxes */}
        <div className="space-y-2">
          <label className="flex items-center gap-2 cursor-pointer">
            <input
              type="checkbox"
              checked={useGPU}
              onChange={(e) => onUseGPUChange(e.target.checked)}
              disabled={disabled}
              className="rounded bg-gray-700 border-gray-600"
            />
            <span className="text-sm">Use GPU Acceleration (CUDA)</span>
          </label>

          <label className="flex items-center gap-2 cursor-pointer">
            <input
              type="checkbox"
              checked={generateConfidenceMap}
              onChange={(e) => onGenerateConfidenceMapChange(e.target.checked)}
              disabled={disabled}
              className="rounded bg-gray-700 border-gray-600"
            />
            <span className="text-sm">Generate Confidence Map</span>
          </label>
        </div>
      </div>
    </div>
  );
}
