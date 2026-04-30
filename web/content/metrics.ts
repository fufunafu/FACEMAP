/**
 * Mirrors FaceMap/Analysis/Metrics/*.swift.
 * The five geometric metrics implemented in v0.1 of the iOS app.
 * Each metric supports one of two FAS facets — Proportions or Symmetry.
 */

import type { FacetId } from "./fas";

export interface Metric {
  /** Matches the metric's `id` field in the Swift source. */
  id: string;
  /** Display name as used in the iOS app. */
  name: string;
  /** One-line summary suitable for cards. */
  summary: string;
  /** Plain-English description of what the metric computes. */
  description: string;
  /** Target range expressed as practitioner-readable copy. */
  target: string;
  /** Anatomical regions the metric can flag. */
  flags: string[];
  /** Which FAS facet this metric supports. */
  facet: FacetId;
}

export const metrics: Metric[] = [
  {
    id: "facial.thirds",
    name: "Facial thirds",
    summary: "Vertical balance across forehead, midface, and lower face.",
    description:
      "Measures the three vertical segments — trichion → glabella, glabella → subnasale, subnasale → menton — and reports the worst-case deviation from one-third of total face height.",
    target: "Each third within ±5% of equal.",
    flags: ["Forehead", "Midface", "Upper lip", "Lower lip", "Chin"],
    facet: "proportions",
  },
  {
    id: "facial.fifths",
    name: "Facial fifths",
    summary: "Horizontal balance across the canthal level.",
    description:
      "Divides the face width at canthal level into five segments anchored on zygion, exocanthion, and endocanthion landmarks. Reports the worst deviation from 20% per fifth.",
    target: "Each fifth within ±10% of equal.",
    flags: ["Temples", "Midface"],
    facet: "proportions",
  },
  {
    id: "facial.goldenRatio",
    name: "Golden ratio (selected)",
    summary: "Two well-attested phi ratios.",
    description:
      "Computes mouth width ÷ nose width and lower-third height ÷ nose length, reporting the worst deviation from φ ≈ 1.618.",
    target: "Within ±10% of φ on both ratios.",
    flags: ["Upper lip", "Lower lip", "Perioral", "Chin"],
    facet: "proportions",
  },
  {
    id: "ocular.canthalTilt",
    name: "Canthal tilt",
    summary: "Angle of the eye axis on each side.",
    description:
      "Measures the angle from medial canthus to lateral canthus relative to horizontal, per side. A low or negative tilt flags tear-trough and midface regions.",
    target: "4° to 7° on each side.",
    flags: ["Tear trough (L/R)", "Midface (L/R)"],
    facet: "symmetry",
  },
  {
    id: "facial.asymmetry",
    name: "Facial asymmetry",
    summary: "Bilateral surface symmetry across the midsagittal plane.",
    description:
      "Mirrors each left-side region centroid across the midsagittal plane and measures the distance to its right-side counterpart. Pairs exceeding ~1.5 mm are flagged.",
    target: "Each pair within 1.5 mm of perfect mirror symmetry.",
    flags: [
      "Temples",
      "Brows",
      "Tear trough",
      "Midface",
      "Nasolabial",
      "Marionette",
      "Prejowl",
      "Jawline",
    ],
    facet: "symmetry",
  },
];
