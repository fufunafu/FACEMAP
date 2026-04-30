import { facetsList, type FacetId } from "@/content/fas";

const VIEW = 460;
const C = VIEW / 2;
const R_MAX = 175;
const N = 5;

function angleFor(axis: number) {
  return -Math.PI / 2 + (axis * (2 * Math.PI)) / N;
}
function point(axis: number, radius: number) {
  const a = angleFor(axis);
  return [C + radius * Math.cos(a), C + radius * Math.sin(a)] as const;
}

function polygonFor(values: Record<FacetId, number>) {
  return facetsList
    .map((f, i) => {
      const v = Math.max(0, Math.min(3, values[f.id] ?? 0));
      const r = (v / 3) * R_MAX;
      const [x, y] = point(i, r);
      return `${x},${y}`;
    })
    .join(" ");
}

/** A static FAS radar showing a baseline polygon + a follow-up polygon overlaid. */
export function FasComparison({
  baseline,
  followUp,
  size = 460,
}: {
  baseline: Record<FacetId, number>;
  followUp: Record<FacetId, number>;
  size?: number;
}) {
  return (
    <svg
      viewBox={`0 0 ${VIEW} ${VIEW}`}
      width="100%"
      height="auto"
      style={{ maxWidth: size }}
      role="img"
      aria-label="FAS visit-over-visit comparison radar"
      className="select-none"
    >
      {[1, 2, 3].map((i) => (
        <circle
          key={i}
          cx={C}
          cy={C}
          r={(i / 3) * R_MAX}
          fill="none"
          stroke="var(--color-hairline)"
          strokeWidth={1}
        />
      ))}
      {facetsList.map((_, i) => {
        const [x, y] = point(i, R_MAX);
        return (
          <line
            key={i}
            x1={C}
            y1={C}
            x2={x}
            y2={y}
            stroke="var(--color-hairline)"
            strokeWidth={1}
          />
        );
      })}

      {/* Baseline (dashed, dimmer) */}
      <polygon
        points={polygonFor(baseline)}
        fill="rgba(122,128,148,0.18)"
        stroke="var(--color-ink-dim)"
        strokeWidth={1.25}
        strokeDasharray="4 4"
      />

      {/* Follow-up (solid, branded) */}
      <polygon
        points={polygonFor(followUp)}
        fill="rgba(201,187,238,0.28)"
        stroke="var(--color-ink)"
        strokeWidth={1.5}
      />

      {/* Markers */}
      {facetsList.map((f, i) => {
        const v = Math.max(0, Math.min(3, followUp[f.id] ?? 0));
        if (v === 0) return null;
        const r = (v / 3) * R_MAX;
        const [x, y] = point(i, r);
        return (
          <circle
            key={`mark-${f.id}`}
            cx={x}
            cy={y}
            r={5}
            fill={f.hue}
            stroke="var(--color-canvas)"
            strokeWidth={2}
          />
        );
      })}

      {/* Labels */}
      {facetsList.map((f, i) => {
        const labelR = R_MAX + 32;
        const [x, y] = point(i, labelR);
        return (
          <text
            key={`lbl-${f.id}`}
            x={x}
            y={y}
            fill="var(--color-ink)"
            fontSize={13}
            fontFamily="var(--font-display)"
            textAnchor="middle"
            dominantBaseline="middle"
          >
            {f.name}
          </text>
        );
      })}
      <circle cx={C} cy={C} r={3} fill="var(--color-ink)" opacity={0.4} />
    </svg>
  );
}
