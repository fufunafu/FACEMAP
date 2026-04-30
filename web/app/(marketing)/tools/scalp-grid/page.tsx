import type { Metadata } from "next";
import { ToolHeader } from "../_tool-shell";
import { tools } from "@/content/tools";

const TOOL = tools.find((t) => t.id === "scalp-grid")!;

export const metadata: Metadata = {
  title: TOOL.title,
  description: TOOL.blurb,
};

const LAYERS = ["S — Skin", "C — Connective tissue", "A — Aponeurosis", "L — Loose connective", "P — Periosteum"];
const REGIONS = ["Forehead / Glabella", "Periorbital", "Midface", "Lips & Perioral", "Lower face / Jawline"];

interface Cell {
  products: string[];
  note?: string;
}

// Indexed by [layer][region] — products per the AART-HIT paper.
const GRID: Cell[][] = [
  // S — Skin
  [
    { products: ["Neurotoxin A", "HA-SBs"], note: "Glabellar / forehead lines" },
    { products: ["Neurotoxin A", "HA-SBs"], note: "Crow's feet, periorbital hydration" },
    { products: ["HA-SBs", "PLLA-SCA"], note: "Texture, radiance" },
    { products: ["HA-SBV"], note: "Perioral hydration (Vital/Lido)" },
    { products: ["PLLA-SCA", "HA-SBs"], note: "Neck, jawline texture" },
  ],
  // C — Connective tissue
  [
    { products: ["HA-REF"], note: "Superficial line filling" },
    { products: ["HA-DEF"], note: "Periorbital — thin skin" },
    { products: ["HA-DEF", "HA-LYF"], note: "Thin / thick skin contour" },
    { products: ["HA-DEF", "HA-REF"], note: "Oral commissures, perioral" },
    { products: ["HA-DEF"], note: "Jowl camouflage" },
  ],
  // A — Aponeurosis (SMAS)
  [
    { products: ["—"], note: "Not directly injected" },
    { products: ["—"], note: "Not directly injected" },
    { products: ["PLLA-SCA"], note: "SMAS attachments — collagen stimulation" },
    { products: ["—"], note: "Not directly injected" },
    { products: ["PLLA-SCA"], note: "Lateral platysma support" },
  ],
  // L — Loose connective tissue
  [
    { products: ["—"], note: "Limited indication" },
    { products: ["HA-LYF"], note: "Temporal fossa volumisation" },
    { products: ["HA-VOL", "HA-LYF"], note: "Medial midface deep volume" },
    { products: ["HA-LYF"], note: "Pyriform aperture support" },
    { products: ["HA-LYF"], note: "Mandibular contour" },
  ],
  // P — Periosteum
  [
    { products: ["—"], note: "Limited indication" },
    { products: ["HA-LYF"], note: "Supraperiosteal anchoring" },
    { products: ["HA-LYF"], note: "Zygoma — bony anchor" },
    { products: ["HA-LYF"], note: "Anterior nasal spine, deep chin" },
    { products: ["HA-LYF"], note: "Mandibular bone, gonial angle" },
  ],
];

export default function ScalpGridPage() {
  return (
    <>
      <ToolHeader title={TOOL.title} resolves={TOOL.resolves} hue={TOOL.hue} />
      <section>
        <div className="container-page py-12">
          <p className="max-w-2xl text-[var(--color-ink-dim)]">
            Cross-reference the SCALP layered anatomy with five treatment regions. Each cell lists the suggested product family per Nikolis et al., 2024.
          </p>
          <div className="mt-10 overflow-x-auto rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)]">
            <table className="w-full min-w-[920px] text-sm">
              <thead>
                <tr className="text-left">
                  <th className="px-4 py-3 text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
                    Layer ↓ / Region →
                  </th>
                  {REGIONS.map((r) => (
                    <th
                      key={r}
                      className="px-4 py-3 text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]"
                    >
                      {r}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {LAYERS.map((layer, i) => (
                  <tr key={layer} className="border-t hairline">
                    <th className="bg-[var(--color-surface-raised)] px-4 py-4 text-left align-top text-[11px] uppercase tracking-wider text-[var(--color-ink)]">
                      {layer}
                    </th>
                    {REGIONS.map((_, j) => {
                      const cell = GRID[i][j];
                      return (
                        <td
                          key={j}
                          className="border-l hairline px-4 py-4 align-top"
                        >
                          <div className="flex flex-wrap gap-1">
                            {cell.products.map((p) => (
                              <span
                                key={p}
                                className="rounded-full border hairline px-2 py-0.5 text-[11px] num"
                              >
                                {p}
                              </span>
                            ))}
                          </div>
                          {cell.note ? (
                            <p className="mt-2 text-[11px] text-[var(--color-ink-dim)]">
                              {cell.note}
                            </p>
                          ) : null}
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <p className="mt-6 max-w-3xl text-xs text-[var(--color-ink-muted)]">
            Adapted from the SCALP anatomy and HIT product mappings in Nikolis et al., Clin Cosmet Investig Dermatol 2024:17. Off-label uses (e.g. neurotoxin A in the neck for Nefertiti lift) are flagged in individual HIT pages.
          </p>
        </div>
      </section>
    </>
  );
}
