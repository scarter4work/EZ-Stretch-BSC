/**
 * File list component for input frame selection
 */

import { Trash2, FolderOpen, X } from 'lucide-react';

interface FileListProps {
  files: string[];
  onAddFiles: (paths: string[]) => void;
  onRemoveFile: (index: number) => void;
  onClearFiles: () => void;
  disabled?: boolean;
}

export function FileList({ files, onAddFiles, onRemoveFile, onClearFiles, disabled }: FileListProps) {
  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    if (disabled) return;

    const paths: string[] = [];
    for (const file of Array.from(e.dataTransfer.files)) {
      if (file.name.toLowerCase().endsWith('.fits') || file.name.toLowerCase().endsWith('.fit')) {
        // In Qt WebEngine, we may get path from webkitRelativePath or just use name
        const filePath = (file as unknown as { path?: string }).path || file.name;
        paths.push(filePath);
      }
    }
    if (paths.length > 0) {
      onAddFiles(paths);
    }
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
  };

  return (
    <div className="bg-gray-800 rounded-lg p-4">
      <div className="flex justify-between items-center mb-3">
        <h2 className="text-lg font-semibold">Input Frames ({files.length})</h2>
        <div className="flex gap-2">
          <button
            onClick={() => {/* TODO: Open file dialog via bridge */}}
            disabled={disabled}
            className="flex items-center gap-1 px-3 py-1 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-600 disabled:cursor-not-allowed rounded text-sm"
          >
            <FolderOpen size={16} />
            Add Files
          </button>
          <button
            onClick={onClearFiles}
            disabled={disabled || files.length === 0}
            className="flex items-center gap-1 px-3 py-1 bg-red-600 hover:bg-red-700 disabled:bg-gray-600 disabled:cursor-not-allowed rounded text-sm"
          >
            <Trash2 size={16} />
            Clear
          </button>
        </div>
      </div>

      <div
        onDrop={handleDrop}
        onDragOver={handleDragOver}
        className={`min-h-[300px] max-h-[500px] overflow-y-auto border-2 border-dashed rounded-lg p-2 ${
          disabled ? 'border-gray-700 bg-gray-900' : 'border-gray-600 hover:border-blue-500'
        }`}
      >
        {files.length === 0 ? (
          <div className="h-full flex items-center justify-center text-gray-500">
            <p>Drag and drop FITS files here, or click "Add Files"</p>
          </div>
        ) : (
          <ul className="space-y-1">
            {files.map((file, index) => (
              <li
                key={index}
                className="flex items-center justify-between bg-gray-700 rounded px-2 py-1 text-sm"
              >
                <span className="truncate flex-1" title={file}>
                  {file.split(/[/\\]/).pop()}
                </span>
                <button
                  onClick={() => onRemoveFile(index)}
                  disabled={disabled}
                  className="ml-2 text-gray-400 hover:text-red-400 disabled:opacity-50"
                >
                  <X size={14} />
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
