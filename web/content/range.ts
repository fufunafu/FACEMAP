/**
 * The Galderma Aesthetic Portfolio organised as four R's. Per Nikolis et al.,
 * Clin Cosmet Investig Dermatol 2024:17. NASHA (lifting/precision, higher G')
 * and OBT/XpresHAn (contouring/expression, more crosslinking, lower G') are
 * the two complementary HA technologies; biostimulators and neuromodulators
 * round out the range.
 */

export type RId = "relax" | "refine" | "refresh" | "renew";

export interface RangeR {
  id: RId;
  letter: "R";
  title: string;
  /** Product family. */
  family: string;
  /** Plain-English description. */
  description: string;
  /** Which mechanism / technology. */
  technology: string;
  /** Hex hue used in the brand system. */
  hue: string;
}

export const rs: Record<RId, RangeR> = {
  relax: {
    id: "relax",
    letter: "R",
    title: "Relax",
    family: "Neuromodulators (botulinum toxin type A)",
    description:
      "Relax the facial muscles of expression involved in the formation of dynamic wrinkles. Indicated for glabellar and lateral canthal lines.",
    technology: "Neurotoxin A",
    hue: "#F2C9A1",
  },
  refine: {
    id: "refine",
    letter: "R",
    title: "Refine",
    family: "HA fillers (NASHA & OBT/XpresHAn)",
    description:
      "Refine shape and contour through lifting, volumizing, or filling lines and wrinkles. NASHA is for lifting and precision (higher G'). OBT/XpresHAn is for contouring and natural movement (lower G', more flexible gel).",
    technology: "NASHA & OBT/XpresHAn HA gel",
    hue: "#E9B5E0",
  },
  refresh: {
    id: "refresh",
    letter: "R",
    title: "Refresh",
    family: "Skinboosters (HA-SBs)",
    description:
      "Restore skin hydration balance, improve skin structure and elasticity. Stabilised HA in the gel attracts and binds water — overall results lasting up to 15 months.",
    technology: "Stabilised HA microdroplets",
    hue: "#A6B4DD",
  },
  renew: {
    id: "renew",
    letter: "R",
    title: "Renew",
    family: "Biostimulators (PLLA-SCA / Sculptra)",
    description:
      "Activate fibroblasts to increase the collagen content of the skin, restoring structure and firmness. Indicated for fine lines, contour deficiencies, and lipoatrophy. Results can last up to 25 months.",
    technology: "Poly-L-lactic acid",
    hue: "#C9BBEE",
  },
};

export const rOrder: RId[] = ["relax", "refine", "refresh", "renew"];
export const rList = rOrder.map((id) => rs[id]);
