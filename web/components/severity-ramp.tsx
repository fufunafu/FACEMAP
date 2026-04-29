import { severityOpacity } from "@/lib/tokens";
import { domains, type DomainId } from "@/content/domains";

const STEPS: Array<{ key: keyof typeof severityOpacity; label: string }> = [
  { key: "normal", label: "Normal" },
  { key: "mild", label: "Mild" },
  { key: "moderate", label: "Moderate" },
  { key: "significant", label: "Significant" },
];

export function SeverityRamp({ domain }: { domain: DomainId }) {
  const hue = domains[domain].hue;
  return (
    <div className="flex items-end gap-3" aria-label="Severity ramp">
      {STEPS.map(({ key, label }) => {
        const opacity = severityOpacity[key];
        const isNormal = key === "normal";
        return (
          <div key={key} className="flex flex-col items-center gap-2">
            <div
              className="size-12 rounded-full border hairline"
              style={{
                backgroundColor: isNormal
                  ? "transparent"
                  : `color-mix(in srgb, ${hue} ${opacity * 100}%, transparent)`,
                borderColor: isNormal
                  ? "rgba(255,255,255,0.24)"
                  : "transparent",
              }}
              aria-hidden="true"
            />
            <span className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
              {label}
            </span>
            <span className="num text-[10px] text-[var(--color-ink-muted)]">
              {Math.round(opacity * 100)}%
            </span>
          </div>
        );
      })}
    </div>
  );
}
