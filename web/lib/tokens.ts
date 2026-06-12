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

/**
 * FAS facet hues — the 5 hues used across the site, the logo mark, and the
 * iOS Aesthetic Wheel. SOURCE OF TRUTH for facet colour.
 * Keep in sync with the `domain*` hues in FaceMap/UI/DesignSystem/Theme.swift.
 */
export const facetHues = {
  skinQuality: "#C9BBEE",
  facialShape: "#A6B4DD",
  proportions: "#7A8094",
  symmetry: "#E9B5E0",
  expression: "#F2C9A1",
} as const;

/** Darker slate used when Proportions' hue is a fill background (Theme.domainProportionsFill). */
export const proportionsFill = "#3F4456";

/** Severity → opacity ramp on the facet hue. Mirrors `MetricResult.Severity.ringOpacity` in Theme.swift. */
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
