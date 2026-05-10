import clsx from "clsx";
import type { CompatibilityLevel } from "@/services/types";

const labels: Record<CompatibilityLevel, string> = {
  green: "Fit",
  yellow: "Warn",
  red: "Block",
};

export function CompatibilityPing({
  level,
  reasons,
}: {
  level: CompatibilityLevel;
  reasons: string[];
}) {
  return (
    <div className={clsx("compatibility-ping", `ping-${level}`)} title={reasons.join("\n")}>
      <span aria-hidden="true" />
      <strong>{labels[level]}</strong>
    </div>
  );
}
