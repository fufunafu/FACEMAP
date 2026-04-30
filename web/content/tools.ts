/**
 * Catalogue of decision aid tools available on /tools.
 * Each tool is a small interactive component grounded in the AART-HIT paper.
 */

export interface ToolMeta {
  id: string;
  title: string;
  blurb: string;
  /** What clinical question the tool resolves. */
  resolves: string;
  /** Hex hue used to brand the tool card. */
  hue: string;
  /** Section grouping for the index page. */
  group: "Assess" | "Plan" | "Track";
}

export const tools: ToolMeta[] = [
  {
    id: "scalp-grid",
    title: "SCALP × region grid",
    blurb: "Which product goes at which depth, by region.",
    resolves: "What product fits this layer in this region?",
    hue: "#A6B4DD",
    group: "Plan",
  },
  {
    id: "filler-picker",
    title: "NASHA vs OBT picker",
    blurb: "Three dropdowns route you to the right HA family.",
    resolves: "Lift & precision, or contour & expression?",
    hue: "#E9B5E0",
    group: "Plan",
  },
  {
    id: "pinch-test",
    title: "Pinch & slide laxity test",
    blurb: "Stratify the Shape-Up patient archetype.",
    resolves: "Shape & lift, or firm & lift?",
    hue: "#A6B4DD",
    group: "Assess",
  },
  {
    id: "lip-priorities",
    title: "Lip priorities planner",
    blurb: "Grade the LAS, get the three Kiss & Smile priorities.",
    resolves: "Ideal lips, framing lips, or confident smile?",
    hue: "#E9B5E0",
    group: "Plan",
  },
  {
    id: "age-sequencer",
    title: "Age-era sequencer",
    blurb: "Patient age + dominant facet → ordered HIT shortlist.",
    resolves: "Which HIT first this visit, given the decade?",
    hue: "#C9BBEE",
    group: "Plan",
  },
  {
    id: "eye-area",
    title: "Bright Eyes vs Glow on",
    blurb: "Disambiguate two HITs that overlap around the orbit.",
    resolves: "Which periorbital HIT applies?",
    hue: "#F2C9A1",
    group: "Plan",
  },
  {
    id: "profile-balance",
    title: "Profile balance assessor",
    blurb: "Click three points on a profile to evaluate Ricketts' line.",
    resolves: "Lips over-projected? Chin under-projected?",
    hue: "#7A8094",
    group: "Assess",
  },
  {
    id: "plan-builder",
    title: "Treatment plan builder",
    blurb: "Assemble HITs and products into a session summary.",
    resolves: "What's on the menu this visit?",
    hue: "#C9BBEE",
    group: "Plan",
  },
  {
    id: "visit-log",
    title: "Visit-over-visit log",
    blurb: "Track FAS grades across visits — per patient code.",
    resolves: "Is the radar shrinking toward zero?",
    hue: "#A6B4DD",
    group: "Track",
  },
];
