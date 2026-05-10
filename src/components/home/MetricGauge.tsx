import clsx from "clsx";
import { formatPercent } from "@/utils/format";

type MetricGaugeProps = {
  label: string;
  value: number;
  detail: string;
  tone?: "cyan" | "amber" | "green" | "red";
};

export function MetricGauge({ label, value, detail, tone = "cyan" }: MetricGaugeProps) {
  const clampedValue = Math.max(0, Math.min(100, value));

  return (
    <article className={clsx("metric-gauge", `tone-${tone}`)}>
      <div
        className="metric-ring"
        style={{
          "--metric-value": `${clampedValue * 3.6}deg`,
        } as React.CSSProperties}
        aria-hidden="true"
      >
        <span>{formatPercent(clampedValue)}</span>
      </div>
      <div>
        <p>{label}</p>
        <strong>{detail}</strong>
      </div>
    </article>
  );
}
