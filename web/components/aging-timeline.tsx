/**
 * Aging-by-decade visual. Treatment focus shifts with age, per Nikolis et al.
 *   20s+ — Beautification
 *   30s+ — Volumization
 *   40s+ — Eversion (creating natural lift)
 *   50s+ — Contour definition
 */

import { hits } from "@/content/hits";

interface Era {
  band: string;
  focus: string;
  body: string;
  hits: Array<keyof typeof hits>;
  hue: string;
}

const ERAS: Era[] = [
  {
    band: "20s+",
    focus: "Beautification",
    body: "Refine what's already there. Subtle, natural, focused on the lip body and brow position.",
    hits: ["kiss-and-smile", "glow-on"],
    hue: "#C9BBEE",
  },
  {
    band: "30s+",
    focus: "Volumization",
    body: "First signs of volume loss. Begin medial midface and lip body work; daily skincare matters.",
    hits: ["shape-up", "glow-on"],
    hue: "#A6B4DD",
  },
  {
    band: "40s+",
    focus: "Eversion",
    body: "Restore lip eversion, perioral support, periorbital openness. Layered work.",
    hits: ["bright-eyes", "kiss-and-smile"],
    hue: "#E9B5E0",
  },
  {
    band: "50s+",
    focus: "Contour definition",
    body: "Profile balance, jawline, mandibular line. Skin laxity addressed via biostimulators.",
    hits: ["profile", "shape-up"],
    hue: "#7A8094",
  },
];

export function AgingTimeline() {
  return (
    <ol className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
      {ERAS.map((era) => (
        <li
          key={era.band}
          className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-6"
          style={{
            backgroundImage: `linear-gradient(180deg, ${era.hue}1A 0%, transparent 60%)`,
          }}
        >
          <p
            className="font-display text-4xl tracking-tight"
            style={{ color: era.hue }}
          >
            {era.band}
          </p>
          <h3 className="mt-2 text-lg">{era.focus}</h3>
          <p className="mt-2 text-sm text-[var(--color-ink-dim)]">
            {era.body}
          </p>
          <p className="mt-4 text-[10px] uppercase tracking-wider text-[var(--color-ink-muted)]">
            HITs in play
          </p>
          <div className="mt-2 flex flex-wrap gap-1.5">
            {era.hits.map((id) => {
              const h = hits[id];
              return (
                <span
                  key={id}
                  className="inline-flex items-center gap-1.5 rounded-full border hairline px-2 py-0.5 text-[10px] text-[var(--color-ink-dim)]"
                  style={{ borderColor: `${h.hue}55` }}
                >
                  <span
                    className="size-1.5 rounded-full"
                    style={{ backgroundColor: h.hue }}
                    aria-hidden="true"
                  />
                  {h.name.replace(" HIT™", "")}
                </span>
              );
            })}
          </div>
        </li>
      ))}
    </ol>
  );
}
