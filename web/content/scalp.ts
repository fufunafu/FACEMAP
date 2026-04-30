/**
 * SCALP — Skin · Connective tissue · Aponeurosis · Loose connective tissue ·
 * Periosteum. The five anatomical layers used by Nikolis et al. as the
 * canonical model of facial layered anatomy.
 *
 * With aging, each layer behaves differently — bones remodel and resorb, fat
 * pads descend and deflate, ligaments anchor structure, and the SCALP
 * layering frames where each treatment goes.
 */

export interface ScalpLayer {
  letter: "S" | "C" | "A" | "L" | "P";
  name: string;
  blurb: string;
  /** Treatment-relevance for the practitioner. */
  treatment: string;
}

export const scalp: ScalpLayer[] = [
  {
    letter: "S",
    name: "Skin",
    blurb: "The visible surface — texture, hydration, radiance, elasticity.",
    treatment:
      "Skin quality is addressed by skinboosters, biostimulators, and topical/medical skincare.",
  },
  {
    letter: "C",
    name: "Connective tissue",
    blurb: "Subcutaneous fat compartments and connective tissue framework.",
    treatment:
      "Superficial fillers (HA-DEF, HA-LYF) and PLLA-SCA target this layer for firming.",
  },
  {
    letter: "A",
    name: "Aponeurosis",
    blurb: "Superficial musculoaponeurotic system (SMAS) and platysma muscle.",
    treatment:
      "Manipulating the SMAS can affect positioning of other soft tissues — a foundational lever for lift.",
  },
  {
    letter: "L",
    name: "Loose connective tissue",
    blurb: "Glide plane between SMAS and periosteum, hosting deep fat pads.",
    treatment:
      "Volumization techniques navigate this layer — important for midface support.",
  },
  {
    letter: "P",
    name: "Periosteum / deep fascia",
    blurb: "Bony foundation. Bones remodel and resorb with age.",
    treatment:
      "Bony landmarks like the zygoma stay stable and serve as anchors. Deep volumization via HA-LYF or HA-VOL replaces lost bony support.",
  },
];
