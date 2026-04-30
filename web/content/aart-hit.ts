/**
 * AART-HIT™ methodology — the meta-framework of the Nikolis paper.
 *   A — Assessment (via FAS)
 *   A — Anatomy (SCALP layers, aging, ligaments)
 *   R — Range (NASHA, OBT/XpresHAn, neuromodulators, biostimulators)
 *   T — Treatment (combined as one of 5 HITs)
 */

export interface AartStep {
  letter: "A1" | "A2" | "R" | "T";
  glyph: "A" | "R" | "T";
  title: string;
  /** One-sentence purpose. */
  purpose: string;
  /** Long-form blurb for the methodology page. */
  description: string;
}

export const aart: AartStep[] = [
  {
    letter: "A1",
    glyph: "A",
    title: "Assessment",
    purpose:
      "Evaluate the entire face systematically using the Facial Assessment Scale (FAS™).",
    description:
      "A holistic assessment that goes beyond an isolated correction. The FAS grades five facets — Skin quality, Facial shape, Proportions, Symmetry, Expression — on a 0–3 severity scale and plots them as a circular figure. Outliers identify priorities; comparing the figure across visits tracks progress.",
  },
  {
    letter: "A2",
    glyph: "A",
    title: "Anatomy",
    purpose:
      "Understand the SCALP layered anatomy and how each layer ages.",
    description:
      "The SCALP model — Skin, Connective tissue, Aponeurosis, Loose connective tissue, Periosteum — frames where each injection goes. With aging, bones resorb, fat pads descend, ligaments persist as anchors, and skin loses elasticity. Knowing how layers behave is the difference between safe and reproducible treatment and a one-size-fits-all approach.",
  },
  {
    letter: "R",
    glyph: "R",
    title: "Range",
    purpose:
      "Understand the properties and ideal uses of every product in the portfolio.",
    description:
      "Two complementary HA technologies (NASHA and OBT/XpresHAn) plus neuromodulators and biostimulators. The portfolio is organised as four R's — Relax, Refine, Refresh, Renew — so the right product matches the right tissue need.",
  },
  {
    letter: "T",
    glyph: "T",
    title: "Treatment",
    purpose:
      "Combine products into a Holistic Individualised Treatment (HIT™).",
    description:
      "Five HITs cover the major treatment regions: Bright Eyes (periorbital), Kiss & Smile (lips and perioral), Glow on (skin quality), Shape up (midface), Profile (nose/lips/chin). Each HIT is individualised to the patient's FAS profile, anatomy, and goals.",
  },
];
