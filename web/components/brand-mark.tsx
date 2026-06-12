import { facetHues } from "@/lib/tokens";

/**
 * Circular five-slice FaceMap mark — one 72° slice per FAS facet, clockwise
 * from 12 o'clock in facet order. Mirrors
 * FaceMap/UI/DesignSystem/Components/LogoMark.swift.
 */

const FACET_ORDER = [
  "skinQuality",
  "facialShape",
  "proportions",
  "symmetry",
  "expression",
] as const;

const C = 16;
const R = 15;

function point(deg: number) {
  const a = (deg * Math.PI) / 180;
  return `${(C + R * Math.cos(a)).toFixed(2)} ${(C + R * Math.sin(a)).toFixed(2)}`;
}

const SLICES = FACET_ORDER.map((id, i) => {
  const start = -90 + i * 72;
  return {
    id,
    d: `M ${C} ${C} L ${point(start)} A ${R} ${R} 0 0 1 ${point(start + 72)} Z`,
  };
});

export function BrandMark({ size = 24 }: { size?: number }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 32 32"
      role="img"
      aria-label="FaceMap"
    >
      <circle cx="16" cy="16" r="15" fill="var(--color-wheel-bg, #000)" stroke="var(--color-hairline)" strokeWidth="1" />
      {SLICES.map((slice) => (
        <path key={slice.id} d={slice.d} fill={facetHues[slice.id]} />
      ))}
      <circle cx="16" cy="16" r="4" fill="var(--color-wheel-hub, #000)" />
    </svg>
  );
}
