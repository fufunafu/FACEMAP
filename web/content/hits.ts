/**
 * The five Holistic Individualised Treatments (HITs™) defined in Nikolis et
 * al., Clin Cosmet Investig Dermatol 2024:17. Each HIT addresses one or more
 * FAS facets and is anchored to a region of the face.
 */

import type { FacetId } from "./fas";

export type HitId =
  | "bright-eyes"
  | "kiss-and-smile"
  | "glow-on"
  | "shape-up"
  | "profile";

export interface ProductSuggestion {
  /** Generic name as listed in the paper's acronym table. */
  name: string;
  /** Brand label (e.g. "Restylane Lyft"). */
  brand?: string;
  /** Where in this HIT the product is suggested. */
  use: string;
}

export interface Hit {
  id: HitId;
  /** Display name (e.g. "Bright Eyes HIT™"). */
  name: string;
  /** Anatomical region that anchors the HIT. */
  region: string;
  /** Which FAS facets this HIT primarily addresses. */
  facets: FacetId[];
  /** One-line description for cards. */
  blurb: string;
  /** Long-form description for the HIT detail page. */
  description: string;
  /** Anatomical sub-areas treated under this HIT. */
  areas: string[];
  /** Which of the 4 R's apply (relax / refine / refresh / renew). */
  rs: Array<"relax" | "refine" | "refresh" | "renew">;
  /** Suggested products from the Galderma portfolio per the paper. */
  products: ProductSuggestion[];
  /** Hex hue used to brand the HIT. */
  hue: string;
}

export const hits: Record<HitId, Hit> = {
  "bright-eyes": {
    id: "bright-eyes",
    name: "Bright Eyes HIT™",
    region: "Periorbital",
    facets: ["expression", "facialShape"],
    blurb:
      "Periorbital and superior-anterior midface — open the eye area without distorting expression.",
    description:
      "The Bright Eyes HIT™ addresses glabellar lines and lateral canthal lines with botulinum toxin type A, treats the periorbital and temporal fossa regions with fillers, and volumizes the superior-anterior midface. Volumising the anterior malar region produces a compensatory improvement of the tear-trough region by superior movement of the fat pads.",
    areas: [
      "Glabella",
      "Lateral canthal lines",
      "Periorbital",
      "Temporal fossa",
      "Superior-anterior midface",
    ],
    rs: ["relax", "refine"],
    products: [
      { name: "Neurotoxin A", brand: "Dysport", use: "Glabellar lines and lateral canthal lines" },
      { name: "HA-DEF", brand: "Restylane Defyne", use: "Periorbital and temporal fossa (thin skin)" },
      { name: "HA-LYF", brand: "Restylane Lyft", use: "Temporal fossa volumisation (thick skin)" },
      { name: "HA-VOL", brand: "Restylane Volyme", use: "Superior-anterior midface volumisation" },
    ],
    hue: "#F2C9A1",
  },
  "kiss-and-smile": {
    id: "kiss-and-smile",
    name: "Kiss and Smile HIT™",
    region: "Lips and perioral",
    facets: ["expression", "proportions", "symmetry"],
    blurb:
      "Lips and perioral — three priorities: ideal lips, framing lips, confident smile.",
    description:
      "The Kiss and Smile HIT™ is divided into three priorities, determined using the Lip Assessment Tool (a site-specific FAS variant): the ideal lips, framing lips, and confident smile. Treatment needs change with age — beautification (20s+), volumization (30s+), eversion (40s+), and contour (50s+). Product selection depends on whether higher G' (NASHA) or higher xStrain (OBT) is required.",
    areas: [
      "Lips (vermilion, philtrum, Cupid's bow)",
      "Perioral lines",
      "Nasolabial folds",
      "Marionette lines",
      "Labiomental fold",
      "Oral commissures",
    ],
    rs: ["refine", "relax"],
    products: [
      { name: "HA-KYS", brand: "Restylane Kysse", use: "Lip body — projection and definition (OBT)" },
      { name: "HA-RES", brand: "Restylane", use: "Lip body alternative (NASHA, more projection)" },
      { name: "HA-LYF", brand: "Restylane Lyft", use: "Pyriform aperture, deep nasolabial folds" },
      { name: "HA-REF", brand: "Restylane Refyne", use: "Marionette lines, perioral" },
      { name: "HA-DEF", brand: "Restylane Defyne", use: "Labiomental fold, oral commissures" },
      { name: "HA-SBV", brand: "Skinboosters Vital/Lido", use: "Perioral hydration" },
      { name: "Neurotoxin A", brand: "Dysport", use: "Lateral canthal lines (gummy smile, off-label)" },
    ],
    hue: "#E9B5E0",
  },
  "glow-on": {
    id: "glow-on",
    name: "Glow on HIT™",
    region: "Skin quality",
    facets: ["skinQuality"],
    blurb:
      "Skin radiance, texture, and hydration — for patients seeking a natural, rested look.",
    description:
      "The Glow on HIT™ encompasses prevention of further lines and aging through botulinum toxin type A, PLLA-SCA, and Skinboosters. It is the treatment of choice for patients who desire a natural, rested, relaxed look with some residual animation — without appearing angry when they are not. Daily skincare (cleanse, treat, moisturize, protect from UV) sits inside this HIT.",
    areas: [
      "Full face — skin texture and radiance",
      "Forehead",
      "Periorbital",
      "Periauricular",
      "Neck",
    ],
    rs: ["refresh", "renew", "relax"],
    products: [
      { name: "Neurotoxin A", brand: "Dysport", use: "Prevent further lines; smooth skin appearance" },
      { name: "PLLA-SCA", brand: "Sculptra", use: "Collagen biostimulation; firmness and elasticity" },
      { name: "HA-SBs", brand: "Skinboosters (Vital Lido, Vital Light Lido)", use: "Hydration, structure, elasticity" },
    ],
    hue: "#C9BBEE",
  },
  "shape-up": {
    id: "shape-up",
    name: "Shape up HIT™",
    region: "Midface",
    facets: ["facialShape", "proportions"],
    blurb:
      "Midface — shaping and lifting, or firming and lifting, depending on patient skin envelope.",
    description:
      "The Shape up HIT™ has two patient archetypes: those needing shaping and lifting (sufficient skin firmness, but volume loss) and those needing firming and lifting (skin laxity is the dominant issue). Deep layers (3, 4, 5) are addressed with HA fillers (Lyft, Defyne, Volyme); superficial layers (1, 2) with Defyne, Lyft, or PLLA-SCA. The pinch-and-slide test helps stratify firmness.",
    areas: [
      "Medial midface / malar",
      "Zygoma / cheek bone",
      "Pyriform aperture",
      "Mandibular bone",
      "Posterior temple",
      "Jawline",
    ],
    rs: ["refine", "renew"],
    products: [
      { name: "HA-VOL", brand: "Restylane Volyme", use: "Medial midface / malar (deep layer)" },
      { name: "HA-LYF", brand: "Restylane Lyft", use: "Zygoma (thick skin); pyriform aperture" },
      { name: "HA-DEF", brand: "Restylane Defyne", use: "Zygoma (thin skin); superficial layers" },
      { name: "PLLA-SCA", brand: "Sculptra", use: "Skin laxity / firming over months" },
    ],
    hue: "#A6B4DD",
  },
  profile: {
    id: "profile",
    name: "Profile HIT™",
    region: "Profile",
    facets: ["proportions", "facialShape", "symmetry"],
    blurb:
      "Balance between nose, lips, and chin — Ricketts' line, gonial angle, mentocervical angle.",
    description:
      "The Profile HIT™ ensures balance between the tip of the nose, lips, and chin. Pyriform aperture projection is assessed first; then Ricketts' aesthetic line evaluates whether lips are over-projected or chin is under-projected. The gonial angle (130° ideal), mentocervical angle, and nasofrontal angle are also assessed.",
    areas: [
      "Nasal bridge",
      "Pyriform aperture",
      "Chin (mentum)",
      "Gonial angle",
      "Jawline",
    ],
    rs: ["refine"],
    products: [
      { name: "HA-LYF", brand: "Restylane Lyft", use: "Pyriform aperture, chin projection" },
      { name: "HA-DEF", brand: "Restylane Defyne", use: "Nasal bridge, jawline definition" },
      { name: "HA-REF", brand: "Restylane Refyne", use: "Subtle profile refinement" },
      { name: "Neurotoxin A", brand: "Dysport", use: "Nefertiti lift (off-label, neck)" },
    ],
    hue: "#7A8094",
  },
};

export const hitOrder: HitId[] = [
  "bright-eyes",
  "kiss-and-smile",
  "glow-on",
  "shape-up",
  "profile",
];

export const hitsList = hitOrder.map((id) => hits[id]);
