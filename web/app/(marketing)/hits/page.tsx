import type { Metadata } from "next";
import { HitCard } from "@/components/hit-card";
import { hitsList } from "@/content/hits";

export const metadata: Metadata = {
  title: "The five HITs™",
  description:
    "Bright Eyes · Kiss & Smile · Glow on · Shape up · Profile — the five Holistic Individualised Treatments of the AART-HIT™ methodology.",
};

export default function HitsIndexPage() {
  return (
    <>
      <section className="border-b hairline">
        <div className="container-page py-14 md:py-20">
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            Treatment
          </p>
          <h1 className="mt-4 max-w-3xl font-display text-[2.25rem] tracking-tight sm:text-5xl md:text-6xl">
            Five HITs. One playbook per region.
          </h1>
          <p className="mt-5 max-w-2xl text-[var(--color-ink-dim)]">
            Each Holistic Individualised Treatment combines neuromodulators, HA fillers, Skinboosters, and biostimulators to address a specific facial region — informed by the patient&apos;s FAS profile, anatomy, and goals.
          </p>
        </div>
      </section>

      <section>
        <div className="container-page py-12 md:py-16">
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {hitsList.map((h) => (
              <HitCard key={h.id} hit={h} href={`/hits/${h.id}`} />
            ))}
          </div>
        </div>
      </section>
    </>
  );
}
