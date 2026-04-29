import { domainHues } from "@/lib/tokens";

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
      <path d="M 16 1 A 15 15 0 0 1 31 16 L 16 16 Z" fill={domainHues.optical} />
      <path d="M 31 16 A 15 15 0 0 1 16 31 L 16 16 Z" fill={domainHues.structural} />
      <path d="M 16 31 A 15 15 0 0 1 1 16 L 16 16 Z" fill={domainHues.symmetry} />
      <path d="M 1 16 A 15 15 0 0 1 16 1 L 16 16 Z" fill={domainHues.mechanical} />
      <circle cx="16" cy="16" r="4" fill="var(--color-wheel-hub, #000)" />
    </svg>
  );
}
