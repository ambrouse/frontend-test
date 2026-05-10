export function formatMemory(mb: number) {
  if (mb >= 1024) {
    return `${(mb / 1024).toFixed(mb % 1024 === 0 ? 0 : 1)} GB`;
  }

  return `${mb} MB`;
}

export function formatPercent(value: number) {
  return `${Math.round(value)}%`;
}

export function formatDuration(seconds: number) {
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;

  if (minutes === 0) {
    return `${remainingSeconds}s`;
  }

  return `${minutes}m ${remainingSeconds.toString().padStart(2, "0")}s`;
}

export function formatProjectType(type: string) {
  const labels: Record<string, string> = {
    llm: "LLM",
    vision: "Vision",
    "spark-llm": "Spark LLM",
    "nvidia-blueprint": "NVIDIA Blueprint",
    embedding: "Embedding",
    speech: "Speech",
    tooling: "Tooling",
  };

  return labels[type] ?? type;
}
