/**
 * The Facial Assessment Scale (FAS™) — Nikolis et al., Clinical, Cosmetic and
 * Investigational Dermatology 2024:17. The diagnostic tool inside the AART-HIT
 * methodology.
 *
 * Five facets, each graded 0 (None) → 3 (Severe). When all five are graded, the
 * resulting figure is plotted as a circular pie/radar chart that grows outward
 * with severity. Outliers indicate priority areas.
 */

export type FacetId =
  | "skinQuality"
  | "facialShape"
  | "proportions"
  | "symmetry"
  | "expression";

export interface Facet {
  id: FacetId;
  /** Display name as used in the FAS table. */
  name: string;
  /** Sub-parameters graded inside the facet. */
  parameters: string[];
  /** Plain-English description for cards. */
  blurb: string;
  /** Hex hue assigned to this facet — anchors the FAS radar. */
  hue: string;
  /** Position on the radar (0..4 → 0°, 72°, 144°, 216°, 288°). */
  axis: 0 | 1 | 2 | 3 | 4;
  /** Which HIT(s) most directly address this facet. */
  hits: string[];
  /** Whether v0.1 of the FaceMap iOS app currently quantifies this facet. */
  quantifiedInV1: boolean;
}

export const facets: Record<FacetId, Facet> = {
  skinQuality: {
    id: "skinQuality",
    name: "Skin quality",
    parameters: ["Loss of Radiance / Glow", "Loss of firmness"],
    blurb:
      "Texture, radiance, hydration, and firmness — how light reads off the skin's surface.",
    hue: "#C9BBEE", // lavender
    axis: 0,
    hits: ["glow-on"],
    quantifiedInV1: false,
  },
  facialShape: {
    id: "facialShape",
    name: "Facial shape",
    parameters: ["Sagging", "Volume loss"],
    blurb:
      "Shape and contour — bizygomatic and bigonial widths, chin protrusion, sagging, and volume.",
    hue: "#A6B4DD", // periwinkle
    axis: 1,
    hits: ["shape-up", "profile"],
    quantifiedInV1: false,
  },
  proportions: {
    id: "proportions",
    name: "Proportions",
    parameters: ["Imbalance"],
    blurb:
      "Balance between facial thirds, fifths, and the Ogee curve. Whether segments of the face read as equal.",
    hue: "#7A8094", // slate
    axis: 2,
    hits: ["profile", "shape-up"],
    quantifiedInV1: true,
  },
  symmetry: {
    id: "symmetry",
    name: "Symmetry",
    parameters: ["Asymmetry"],
    blurb:
      "Whether the right and left hemispheres of the face appear similar, in context with other attributes.",
    hue: "#E9B5E0", // magenta-pink
    axis: 3,
    hits: ["profile"],
    quantifiedInV1: true,
  },
  expression: {
    id: "expression",
    name: "Expression",
    parameters: ["Static lines", "Dynamic lines"],
    blurb:
      "How the face behaves at rest and in motion — static line effacement and dynamic distortion.",
    hue: "#F2C9A1", // warm peach
    axis: 4,
    hits: ["bright-eyes", "kiss-and-smile"],
    quantifiedInV1: false,
  },
};

export const facetOrder: FacetId[] = [
  "skinQuality",
  "facialShape",
  "proportions",
  "symmetry",
  "expression",
];

export const facetsList = facetOrder.map((id) => facets[id]);

export const SEVERITY_LEVELS = [
  { grade: 0, label: "None", opacity: 0 },
  { grade: 1, label: "Mild", opacity: 0.38 },
  { grade: 2, label: "Moderate", opacity: 0.64 },
  { grade: 3, label: "Severe", opacity: 1 },
] as const;
