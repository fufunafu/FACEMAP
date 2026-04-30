/**
 * The Lip Assessment Scale (LAS) — a site-specific FAS variant for lips and
 * perioral region. From Figure 5 of Nikolis et al., 2024:17.
 *
 * Five categories, each graded 0 (None) → 3 (Severe), used inside the
 * Kiss & Smile HIT™ to drive the lip treatment plan.
 */

export interface LasCategory {
  id: string;
  name: string;
  parameters: string[];
  hue: string;
}

export const lasCategories: LasCategory[] = [
  {
    id: "proportions",
    name: "Proportions",
    parameters: ["Lips ↔ Lower face", "Superior ↔ Inferior lips"],
    hue: "#E9B5E0",
  },
  {
    id: "dynamic",
    name: "Dynamic movement",
    parameters: ["Dynamic evaluation"],
    hue: "#F2C9A1",
  },
  {
    id: "perioral",
    name: "Perioral",
    parameters: ["Lines and wrinkles"],
    hue: "#C9BBEE",
  },
  {
    id: "symmetry",
    name: "Symmetry",
    parameters: ["Asymmetry"],
    hue: "#A6B4DD",
  },
  {
    id: "shape",
    name: "Shape",
    parameters: ["Projection", "Volume", "Contour"],
    hue: "#7A8094",
  },
];

export const LIP_PRIORITIES = [
  {
    title: "Ideal lips",
    body:
      "The starting point — symmetric, proportionate, naturally shaped. Products: HA-KYS or HA-RES for the lip body.",
  },
  {
    title: "Framing lips",
    body:
      "Surrounding support — pyriform aperture, nasolabial folds, marionette lines, labiomental fold, perioral hydration. Products: HA-LYF, HA-REF, HA-DEF, HA-SBV.",
  },
  {
    title: "Confident smile",
    body:
      "Lateral canthal lines (Dysport), perioral support, gummy smile camouflage via depressor anguli oris, orbicularis oris, mentalis. About confidence and animation, not beautification.",
  },
];
