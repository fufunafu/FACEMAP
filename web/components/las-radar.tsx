import { lasCategories } from "@/content/las";

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

const SAMPLE = [2, 1, 2, 1, 2];

export function LasRadar({ size = 420 }: { size?: number }) {
  const polygon = SAMPLE.map((g, i) => {
    const r = (g / 3) * R_MAX;
    const [x, y] = point(i, r);
    return `${x},${y}`;
  }).join(" ");

  return (
    <svg
      viewBox={`0 0 ${VIEW} ${VIEW}`}
      width="100%"
      height="auto"
      style={{ maxWidth: size }}
      role="img"
      aria-label="Lip Assessment Scale (LAS) radar with five categories"
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
      {lasCategories.map((_, i) => {
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
      <polygon
        points={polygon}
        fill="rgba(233,181,224,0.22)"
        stroke="var(--color-ink)"
        strokeWidth={1.25}
      />
      {SAMPLE.map((g, i) => {
        const r = (g / 3) * R_MAX;
        const [x, y] = point(i, r);
        return (
          <circle
            key={i}
            cx={x}
            cy={y}
            r={6}
            fill={lasCategories[i].hue}
            stroke="var(--color-canvas)"
            strokeWidth={2}
          />
        );
      })}
      {lasCategories.map((c, i) => {
        const labelR = R_MAX + 32;
        const [x, y] = point(i, labelR);
        return (
          <text
            key={`lbl-${c.id}`}
            x={x}
            y={y}
            fill="var(--color-ink)"
            fontSize={13}
            fontFamily="var(--font-display)"
            textAnchor="middle"
            dominantBaseline="middle"
          >
            {c.name}
          </text>
        );
      })}
      <circle cx={C} cy={C} r={3} fill="var(--color-ink)" opacity={0.4} />
    </svg>
  );
}
