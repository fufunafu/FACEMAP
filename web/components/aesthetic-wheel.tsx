"use client";

import { useId, useState } from "react";
import { domains, domainsList, type DomainId } from "@/content/domains";
import { cn } from "@/lib/cn";

/**
 * The Nikolis Aesthetic Wheel.
 *
 * Four equal quadrants with labels following the published reference image:
 *   top-left: Mechanical (lavender)
 *   top-right: Optical (slate)
 *   bottom-left: Symmetry (magenta-pink)
 *   bottom-right: Structural (periwinkle)
 *
 * Geometry mirrors the iOS AestheticWheel — top-left = -180° → -90°, etc.
 * Use as `<AestheticWheel interactive />` to wire keyboard + click selection;
 * the parent owns the selection state via `value` + `onValueChange`.
 */
export interface AestheticWheelProps {
  /** Currently selected domain (controlled). */
  value?: DomainId | null;
  onValueChange?: (id: DomainId | null) => void;
  /** Visual size in pixels. Aspect is always 1:1. */
  size?: number;
  interactive?: boolean;
  className?: string;
}

const VIEW = 400;
const C = VIEW / 2;
const R_OUTER = 180;
const R_INNER = 30;
const GAP_DEG = 4;

// SVG angle convention: 0deg = 3 o'clock, increasing clockwise.
// Quadrant arcs *before* gaps:
//   optical:    -90 →   0   (top-right)
//   structural:   0 →  90   (bottom-right)
//   symmetry:    90 → 180   (bottom-left)
//   mechanical: 180 → 270   (top-left, == -180 → -90)
const ARCS: Record<DomainId, { start: number; end: number }> = {
  optical: { start: -90, end: 0 },
  structural: { start: 0, end: 90 },
  symmetry: { start: 90, end: 180 },
  mechanical: { start: 180, end: 270 },
};

function polar(radius: number, angleDeg: number) {
  const a = (angleDeg * Math.PI) / 180;
  return [C + radius * Math.cos(a), C + radius * Math.sin(a)] as const;
}

function buildQuadrantPath(start: number, end: number) {
  const s = start + GAP_DEG / 2;
  const e = end - GAP_DEG / 2;
  const [x1o, y1o] = polar(R_OUTER, s);
  const [x2o, y2o] = polar(R_OUTER, e);
  const [x2i, y2i] = polar(R_INNER, e);
  const [x1i, y1i] = polar(R_INNER, s);
  const largeArc = e - s > 180 ? 1 : 0;
  return [
    `M ${x1o} ${y1o}`,
    `A ${R_OUTER} ${R_OUTER} 0 ${largeArc} 1 ${x2o} ${y2o}`,
    `L ${x2i} ${y2i}`,
    `A ${R_INNER} ${R_INNER} 0 ${largeArc} 0 ${x1i} ${y1i}`,
    "Z",
  ].join(" ");
}

function buildLabelPath(start: number, end: number) {
  const labelRadius = R_OUTER + 22;
  const s = start + GAP_DEG / 2;
  const e = end - GAP_DEG / 2;
  // Bottom quadrants: text along the inner arc so it reads upright.
  const isBottom = (start + end) / 2 > 0;
  const [x1, y1] = polar(labelRadius, isBottom ? e : s);
  const [x2, y2] = polar(labelRadius, isBottom ? s : e);
  const sweep = isBottom ? 0 : 1;
  return `M ${x1} ${y1} A ${labelRadius} ${labelRadius} 0 0 ${sweep} ${x2} ${y2}`;
}

const ORDER: DomainId[] = ["mechanical", "optical", "structural", "symmetry"];

export function AestheticWheel({
  value = null,
  onValueChange,
  size = 480,
  interactive = false,
  className,
}: AestheticWheelProps) {
  const [hover, setHover] = useState<DomainId | null>(null);
  const ids = useId();

  function selectNext(direction: 1 | -1) {
    if (!interactive) return;
    const current = value ?? hover;
    const idx = current ? ORDER.indexOf(current) : -1;
    const next = ORDER[(idx + direction + ORDER.length) % ORDER.length];
    onValueChange?.(next);
  }

  return (
    <svg
      viewBox={`0 0 ${VIEW} ${VIEW}`}
      width={size}
      height={size}
      role={interactive ? "tablist" : "img"}
      aria-label="Dr Andreas Nikolis's four-domain Facial Aesthetic framework"
      className={cn("select-none", className)}
      onKeyDown={(e) => {
        if (!interactive) return;
        if (e.key === "ArrowRight" || e.key === "ArrowDown") {
          e.preventDefault();
          selectNext(1);
        } else if (e.key === "ArrowLeft" || e.key === "ArrowUp") {
          e.preventDefault();
          selectNext(-1);
        } else if (e.key === "Escape") {
          onValueChange?.(null);
        }
      }}
    >
      <defs>
        {domainsList.map((d) => (
          <path
            key={d.id}
            id={`${ids}-${d.id}-label`}
            d={buildLabelPath(ARCS[d.id].start, ARCS[d.id].end)}
            fill="none"
          />
        ))}
      </defs>

      {/* Outer canvas border (matches background in both themes) */}
      <circle
        cx={C}
        cy={C}
        r={R_OUTER + 14}
        fill="var(--color-wheel-bg, #000)"
      />

      {/* Quadrants */}
      {domainsList.map((d) => {
        const { start, end } = ARCS[d.id];
        const isActive = value === d.id;
        const isHover = hover === d.id;
        const dim = (value !== null && !isActive) || (hover !== null && !isHover);
        return (
          <g key={d.id}>
            <path
              d={buildQuadrantPath(start, end)}
              fill={d.hue}
              stroke="var(--color-wheel-stroke, #000)"
              strokeWidth={2}
              role={interactive ? "tab" : undefined}
              aria-selected={interactive ? isActive : undefined}
              aria-controls={
                interactive ? `${ids}-${d.id}-panel` : undefined
              }
              tabIndex={interactive ? (isActive || (!value && d.id === "mechanical") ? 0 : -1) : undefined}
              style={{
                cursor: interactive ? "pointer" : undefined,
                opacity: dim ? 0.32 : 1,
                transformOrigin: `${C}px ${C}px`,
                transform: isActive || isHover ? "scale(1.02)" : "scale(1)",
                transition:
                  "opacity 200ms ease, transform 200ms ease, filter 200ms ease",
                filter: isActive
                  ? `drop-shadow(0 0 18px ${d.hue}66)`
                  : undefined,
              }}
              onMouseEnter={() => interactive && setHover(d.id)}
              onMouseLeave={() => interactive && setHover(null)}
              onFocus={() => interactive && setHover(d.id)}
              onBlur={() => interactive && setHover(null)}
              onClick={() => {
                if (!interactive) return;
                onValueChange?.(value === d.id ? null : d.id);
              }}
            />
          </g>
        );
      })}

      {/* Curved labels */}
      {domainsList.map((d) => (
        <text
          key={`${d.id}-label`}
          fill="var(--color-wheel-label, #fff)"
          fontSize={14}
          fontFamily="var(--font-display, ui-serif, Georgia, serif)"
          letterSpacing="0.04em"
          style={{ pointerEvents: "none" }}
        >
          <textPath
            href={`#${ids}-${d.id}-label`}
            startOffset="50%"
            textAnchor="middle"
          >
            {d.name}
          </textPath>
        </text>
      ))}

      {/* Centre hub */}
      <circle
        cx={C}
        cy={C}
        r={R_INNER}
        fill="var(--color-wheel-hub, #000)"
      />
      <circle
        cx={C}
        cy={C}
        r={R_INNER - 1}
        fill="none"
        stroke="var(--color-hairline)"
        strokeWidth={1}
      />
    </svg>
  );
}
