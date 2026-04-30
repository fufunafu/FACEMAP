import { scalp } from "@/content/scalp";

const HUES: Record<string, string> = {
  S: "#C9BBEE",
  C: "#A6B4DD",
  A: "#7A8094",
  L: "#E9B5E0",
  P: "#F2C9A1",
};

export function ScalpStack() {
  return (
    <div className="overflow-hidden rounded-[var(--radius-card)] border hairline">
      {scalp.map((layer) => (
        <div
          key={layer.letter}
          className="flex items-stretch border-b hairline last:border-b-0"
        >
          <div
            className="flex w-16 shrink-0 items-center justify-center font-display text-3xl"
            style={{
              backgroundColor: `color-mix(in srgb, ${HUES[layer.letter]} 28%, transparent)`,
              color: "var(--color-ink)",
            }}
          >
            {layer.letter}
          </div>
          <div className="flex-1 bg-[var(--color-surface)] px-5 py-4">
            <p className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
              {layer.name}
            </p>
            <p className="mt-1 text-sm text-[var(--color-ink-dim)]">
              {layer.blurb}
            </p>
            <p className="mt-1 text-xs text-[var(--color-ink-muted)]">
              {layer.treatment}
            </p>
          </div>
        </div>
      ))}
    </div>
  );
}
