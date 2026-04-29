/**
 * Design tokens mirrored from FaceMap/UI/DesignSystem/Theme.swift.
 * Keep in sync — these are the single source of truth for colour and severity
 * encoding, both in the iOS app and on this site.
 */

export const surfaces = {
  canvas: "#000000",
  surface: "#0E0E12",
  surfaceRaised: "#16161C",
  hairline: "rgba(255,255,255,0.12)",
} as const;

export const ink = {
  base: "#FFFFFF",
  dim: "rgba(255,255,255,0.64)",
  muted: "rgba(255,255,255,0.38)",
} as const;

/** Domain hues — one per quadrant of Dr Nikolis's Aesthetic Wheel. */
export const domainHues = {
  mechanical: "#C9BBEE",
  optical: "#7A8094",
  opticalFill: "#3F4456",
  symmetry: "#E9B5E0",
  structural: "#A6B4DD",
} as const;

/** Severity → opacity ramp on the domain hue. Mirrors Theme.swift:62-86. */
export const severityOpacity = {
  normal: 0,
  mild: 0.38,
  moderate: 0.64,
  significant: 1.0,
} as const;

export const radius = {
  card: 16,
  sheet: 24,
  button: 12,
} as const;

export type Severity = keyof typeof severityOpacity;
