import { SEVERITY_LEVELS } from "@/content/fas";

/**
 * Visual demo of FAS severity (0/1/2/3 → opacity ramp on a hue).
 * Pass a hex hue. Used on the FAS framework, methodology, and HIT pages.
 */
export function SeverityRamp({ hue }: { hue: string }) {
  return (
    <div className="flex items-end gap-3" aria-label="Severity ramp">
      {SEVERITY_LEVELS.map(({ grade, label, opacity }) => {
        const isNone = grade === 0;
        return (
          <div key={grade} className="flex flex-col items-center gap-2">
            <div
              className="size-12 rounded-full border hairline"
              style={{
                backgroundColor: isNone
                  ? "transparent"
                  : `color-mix(in srgb, ${hue} ${opacity * 100}%, transparent)`,
                borderColor: isNone
                  ? "var(--color-hairline)"
                  : "transparent",
              }}
              aria-hidden="true"
            />
            <span className="num text-[11px] text-[var(--color-ink-muted)]">
              {grade}
            </span>
            <span className="text-[10px] uppercase tracking-wider text-[var(--color-ink-muted)]">
              {label}
            </span>
          </div>
        );
      })}
    </div>
  );
}
