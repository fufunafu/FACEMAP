"use client";

import { useEffect, useId, useRef, useState } from "react";
import { facets, facetsList, facetOrder, type FacetId } from "@/content/fas";
import { cn } from "@/lib/cn";

/**
 * The Facial Assessment Scale (FAS™) radar chart.
 *
 * Five axes — one per facet — with four severity rings (0/1/2/3). Each axis
 * carries a marker at its current severity grade. The chart renders both:
 *  - decoratively, with no input (static), or
 *  - interactively, where each axis is a click target / radio button.
 *
 * In `interactive` mode the parent owns severity values + selected facet.
 */
export interface FasRadarProps {
  /** Severity per facet (0..3). Defaults to 0. */
  values?: Partial<Record<FacetId, number>>;
  /** Currently focused facet (controlled). */
  focused?: FacetId | null;
  onFocusChange?: (id: FacetId | null) => void;
  size?: number;
  interactive?: boolean;
  className?: string;
}

const VIEW = 460;
const C = VIEW / 2;
const R_MAX = 175;
const RINGS = 3; // grades 1, 2, 3 (0 is the centre)
const N = 5;

function angleFor(axis: number) {
  // Axis 0 is at the top (12 o'clock); progress clockwise.
  return (-Math.PI / 2) + (axis * (2 * Math.PI)) / N;
}

function point(axis: number, radius: number) {
  const a = angleFor(axis);
  return [C + radius * Math.cos(a), C + radius * Math.sin(a)] as const;
}

export function FasRadar({
  values = {},
  focused = null,
  onFocusChange,
  size = 480,
  interactive = false,
  className,
}: FasRadarProps) {
  const ids = useId();
  const [hover, setHover] = useState<FacetId | null>(null);
  const [revealed, setRevealed] = useState(false);
  const svgRef = useRef<SVGSVGElement | null>(null);

  useEffect(() => {
    const node = svgRef.current;
    if (!node) return;
    if (typeof IntersectionObserver === "undefined") {
      setRevealed(true);
      return;
    }
    const observer = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (e.isIntersecting) {
            setRevealed(true);
            observer.disconnect();
            break;
          }
        }
      },
      { threshold: 0.25 },
    );
    observer.observe(node);
    return () => observer.disconnect();
  }, []);

  function cycle(direction: 1 | -1) {
    if (!interactive) return;
    const current = focused ?? hover;
    const idx = current ? facetOrder.indexOf(current) : -1;
    const next = facetOrder[(idx + direction + N) % N];
    onFocusChange?.(next);
  }

  const polygon = facetsList
    .map((f, i) => {
      const v = Math.max(0, Math.min(3, values[f.id] ?? 0));
      const r = (v / 3) * R_MAX;
      const [x, y] = point(i, r);
      return `${x},${y}`;
    })
    .join(" ");

  return (
    <svg
      ref={svgRef}
      viewBox={`0 0 ${VIEW} ${VIEW}`}
      width="100%"
      height="auto"
      style={{ maxWidth: size }}
      role={interactive ? "tablist" : "img"}
      aria-label="Facial Assessment Scale (FAS™) radar chart with five facets"
      className={cn("select-none", className)}
      onKeyDown={(e) => {
        if (!interactive) return;
        if (e.key === "ArrowRight" || e.key === "ArrowDown") {
          e.preventDefault();
          cycle(1);
        } else if (e.key === "ArrowLeft" || e.key === "ArrowUp") {
          e.preventDefault();
          cycle(-1);
        } else if (e.key === "Escape") {
          onFocusChange?.(null);
        }
      }}
    >
      {/* Severity rings */}
      {Array.from({ length: RINGS }).map((_, i) => {
        const r = ((i + 1) / RINGS) * R_MAX;
        return (
          <circle
            key={i}
            cx={C}
            cy={C}
            r={r}
            fill="none"
            stroke="var(--color-hairline)"
            strokeWidth={1}
          />
        );
      })}

      {/* Axes */}
      {facetsList.map((f, i) => {
        const [x, y] = point(i, R_MAX);
        return (
          <line
            key={`axis-${f.id}`}
            x1={C}
            y1={C}
            x2={x}
            y2={y}
            stroke="var(--color-hairline)"
            strokeWidth={1}
          />
        );
      })}

      {/* Filled severity polygon */}
      <g
        style={{
          transformOrigin: `${C}px ${C}px`,
          transform: revealed ? "scale(1)" : "scale(0.001)",
          opacity: revealed ? 1 : 0,
          transition:
            "transform 720ms cubic-bezier(0.22, 1, 0.36, 1) 80ms, opacity 320ms ease 80ms",
        }}
      >
        <polygon
          points={polygon}
          fill="rgba(201,187,238,0.2)"
          stroke="var(--color-ink)"
          strokeWidth={1.25}
          style={{ transition: "all 240ms ease" }}
        />
        {facetsList.map((f, i) => {
          const v = Math.max(0, Math.min(3, values[f.id] ?? 0));
          if (v === 0) return null;
          const r = (v / 3) * R_MAX;
          const [x, y] = point(i, r);
          return (
            <circle
              key={`mark-${f.id}`}
              cx={x}
              cy={y}
              r={6}
              fill={f.hue}
              stroke="var(--color-canvas)"
              strokeWidth={2}
            />
          );
        })}
      </g>

      {/* Labels (interactive when in tablist mode) */}
      {facetsList.map((f, i) => {
        const labelR = R_MAX + 32;
        const [x, y] = point(i, labelR);
        const isFocused = focused === f.id;
        const isHover = hover === f.id;
        const dim =
          (focused !== null && !isFocused) || (hover !== null && !isHover);
        return (
          <g key={`lbl-${f.id}`}>
            {interactive ? (
              <circle
                cx={x}
                cy={y}
                r={42}
                fill="transparent"
                role="tab"
                aria-selected={isFocused}
                aria-controls={`${ids}-${f.id}-panel`}
                tabIndex={isFocused || (!focused && i === 0) ? 0 : -1}
                style={{ cursor: "pointer" }}
                onMouseEnter={() => setHover(f.id)}
                onMouseLeave={() => setHover(null)}
                onFocus={() => setHover(f.id)}
                onBlur={() => setHover(null)}
                onClick={() =>
                  onFocusChange?.(focused === f.id ? null : f.id)
                }
              />
            ) : null}
            <text
              x={x}
              y={y}
              fill={isFocused || isHover ? f.hue : "var(--color-ink)"}
              fontSize={13}
              fontFamily="var(--font-display)"
              textAnchor="middle"
              dominantBaseline="middle"
              style={{
                pointerEvents: "none",
                opacity: dim ? 0.45 : 1,
                transition: "opacity 200ms ease, fill 200ms ease",
              }}
            >
              {f.name}
            </text>
          </g>
        );
      })}

      {/* Severity numerals on the top axis (1, 2, 3) */}
      {[1, 2, 3].map((g) => {
        const r = (g / 3) * R_MAX;
        const [x, y] = [C + 8, C - r];
        return (
          <text
            key={`g-${g}`}
            x={x}
            y={y}
            fill="var(--color-ink-muted)"
            fontSize={10}
            fontFamily="var(--font-mono)"
            style={{ pointerEvents: "none" }}
          >
            {g}
          </text>
        );
      })}

      {/* Centre dot */}
      <circle
        cx={C}
        cy={C}
        r={3}
        fill="var(--color-ink)"
        opacity={0.4}
      />
    </svg>
  );
}
