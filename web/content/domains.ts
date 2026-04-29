/**
 * Mirrors FaceMap/Analysis/FaceDomain.swift.
 * The four domains of Dr Andreas Nikolis's Facial Aesthetic framework.
 */

import { domainHues } from "@/lib/tokens";

export type DomainId = "mechanical" | "optical" | "symmetry" | "structural";

export interface Domain {
  id: DomainId;
  /** Display name as used in the iOS app. */
  name: string;
  /** One-line plain-English description for tooltips. */
  blurb: string;
  /** Sub-concerns shown on the published wheel image. */
  subConcerns: string[];
  /** Anatomical regions this domain typically addresses. */
  exampleRegions: string[];
  /** Hex hue used in the iOS app's Theme.swift. */
  hue: string;
  /** Position on the wheel — mirrors FaceDomain.wheelQuadrant. */
  quadrant: 0 | 1 | 2 | 3;
  /** Whether v0.1 of the iOS app currently quantifies this domain. */
  quantifiedInV1: boolean;
}

export const domains: Record<DomainId, Domain> = {
  mechanical: {
    id: "mechanical",
    name: "Mechanical behaviour",
    blurb:
      "How the face behaves at rest and in motion — line effacement and dynamic distortion.",
    subConcerns: ["Static line effacement", "Dynamic distortion"],
    exampleRegions: [
      "Forehead",
      "Glabella",
      "Perioral",
      "Marionette",
      "Nasolabial folds",
    ],
    hue: domainHues.mechanical,
    quadrant: 0,
    quantifiedInV1: false,
  },
  optical: {
    id: "optical",
    name: "Optical properties",
    blurb:
      "How light behaves on the skin's surface — surface abnormality and loss of shadows.",
    subConcerns: ["Surface abnormality", "Loss of shadows"],
    exampleRegions: [
      "Tear trough",
      "Midface",
      "Jawline",
      "Forehead",
    ],
    hue: domainHues.optical,
    quadrant: 1,
    quantifiedInV1: false,
  },
  symmetry: {
    id: "symmetry",
    name: "Symmetry & proportions",
    blurb:
      "Geometric balance — facial thirds, fifths, golden ratios, canthal tilt, and bilateral symmetry.",
    subConcerns: ["Proportions", "Asymmetry", "Canthal tilt"],
    exampleRegions: [
      "Forehead",
      "Temples",
      "Midface",
      "Lips",
      "Chin",
      "Tear trough",
    ],
    hue: domainHues.symmetry,
    quadrant: 2,
    quantifiedInV1: true,
  },
  structural: {
    id: "structural",
    name: "Structural volume",
    blurb:
      "Volumetric balance across the upper, mid, and lower face.",
    subConcerns: [
      "Periorbital fullness",
      "Midface volume excess",
      "Lower face / profile imbalance",
    ],
    exampleRegions: [
      "Periorbital",
      "Midface",
      "Lower face",
      "Chin",
      "Prejowl",
    ],
    hue: domainHues.structural,
    quadrant: 3,
    quantifiedInV1: false,
  },
};

/** Wheel order: top-left, top-right, bottom-left, bottom-right. */
export const wheelOrder: DomainId[] = [
  "mechanical",
  "optical",
  "symmetry",
  "structural",
];

export const domainsList = wheelOrder.map((id) => domains[id]);
