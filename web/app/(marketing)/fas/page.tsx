import Link from "next/link";
import type { Metadata } from "next";
import { FasRadar } from "@/components/fas-radar";
import { FacetCard } from "@/components/facet-card";
import { SeverityRamp } from "@/components/severity-ramp";
import { facetsList } from "@/content/fas";

export const metadata: Metadata = {
  title: "FAS™ — Facial Assessment Scale",
  description:
    "The Facial Assessment Scale (FAS™) — five facets graded 0 to 3, plotted on a radar chart. Skin quality, Facial shape, Proportions, Symmetry, Expression.",
};

export default function FasPage() {
  return (
    <>
      <section className="border-b hairline">
        <div className="container-page grid gap-10 py-20 lg:grid-cols-[minmax(0,1fr)_auto] lg:items-center">
          <div>
            <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
              Assessment
            </p>
            <h1 className="mt-4 font-display text-5xl tracking-tight md:text-6xl">
              The Facial Assessment Scale.
            </h1>
            <p className="mt-5 max-w-xl text-[var(--color-ink-dim)]">
              Five facets — Skin quality, Facial shape, Proportions, Symmetry, Expression. Each graded 0 (None) → 3 (Severe). The result plots as a circular figure that grows outward with severity. Outliers identify priorities; comparing across visits tracks progress.
            </p>
            <p className="mt-3 max-w-xl text-sm text-[var(--color-ink-muted)]">
              Per Nikolis et al., Clin Cosmet Investig Dermatol 2024:17, 2051–2069.
            </p>
          </div>
          <div className="flex justify-center lg:justify-end">
            <FasRadar
              size={420}
              values={{
                skinQuality: 1,
                facialShape: 2,
                proportions: 1,
                symmetry: 2,
                expression: 1,
              }}
            />
          </div>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-20">
          <h2 className="font-display text-3xl tracking-tight md:text-4xl">
            The five facets.
          </h2>
          <div className="mt-10 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {facetsList.map((f) => (
              <FacetCard key={f.id} facet={f} />
            ))}
          </div>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-20">
          <div className="grid gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
            <div>
              <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
                Severity
              </p>
              <h2 className="mt-3 font-display text-3xl tracking-tight md:text-4xl">
                0 · 1 · 2 · 3 — None to Severe.
              </h2>
              <p className="mt-4 text-[var(--color-ink-dim)]">
                Each facet is graded on the same 4-point scale. As parameters are graded, the FAS figure begins to appear. With each subsequent treatment, the lines of the FAS move closer to point 0 (the centre), indicating milder deficits.
              </p>
              <p className="mt-3 text-sm text-[var(--color-ink-muted)]">
                Severity is encoded as opacity of each facet&apos;s hue — outliers identify priorities at a glance.
              </p>
            </div>
            <div className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-7">
              <div className="space-y-7">
                {facetsList.map((f) => (
                  <div key={f.id}>
                    <p className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
                      {f.name}
                    </p>
                    <div className="mt-3">
                      <SeverityRamp hue={f.hue} />
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      <section>
        <div className="container-page py-16 text-center">
          <h2 className="font-display text-3xl tracking-tight md:text-4xl">
            Grade the radar yourself.
          </h2>
          <p className="mx-auto mt-3 max-w-xl text-[var(--color-ink-dim)]">
            The decision aid lets you grade each facet and see which HIT(s) address the priorities.
          </p>
          <Link
            href="/decision-aid"
            className="mt-6 inline-block rounded-[var(--radius-button)] bg-[var(--color-cta-bg)] px-5 py-3 text-sm font-medium text-[var(--color-cta-ink)] transition hover:opacity-90"
          >
            Open the decision aid
          </Link>
        </div>
      </section>
    </>
  );
}
