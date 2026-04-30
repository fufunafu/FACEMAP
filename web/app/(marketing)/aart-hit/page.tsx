import Link from "next/link";
import type { Metadata } from "next";
import { aart } from "@/content/aart-hit";

export const metadata: Metadata = {
  title: "AART-HIT™ methodology",
  description:
    "Assessment, Anatomy, Range, Treatment — the four steps of the AART-HIT™ methodology by Nikolis et al.",
};

export default function AartHitPage() {
  return (
    <>
      <section className="border-b hairline">
        <div className="container-page py-20">
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            Methodology
          </p>
          <h1 className="mt-4 max-w-3xl font-display text-5xl tracking-tight md:text-6xl">
            AART-HIT™ — assess, understand, choose, treat.
          </h1>
          <p className="mt-5 max-w-2xl text-[var(--color-ink-dim)]">
            A systematic, validated methodology for combining injectables to maximise patient outcomes. Published by Nikolis et al. in <em>Clin Cosmet Investig Dermatol</em> 2024:17, 2051–2069.
          </p>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-20">
          <ol className="space-y-12">
            {aart.map((step, i) => (
              <li
                key={step.letter}
                className="grid gap-6 lg:grid-cols-[120px_minmax(0,1fr)] lg:gap-12"
              >
                <div>
                  <span className="font-display text-7xl leading-none text-[var(--color-ink-dim)]">
                    {step.glyph}
                  </span>
                  <p className="mt-2 text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
                    Step {i + 1}
                  </p>
                </div>
                <div className="border-t hairline pt-6 lg:border-l lg:border-t-0 lg:pl-12 lg:pt-0">
                  <h2 className="font-display text-3xl tracking-tight md:text-4xl">
                    {step.title}
                  </h2>
                  <p className="mt-2 text-lg text-[var(--color-ink-dim)]">
                    {step.purpose}
                  </p>
                  <p className="mt-4 text-[var(--color-ink-dim)]">
                    {step.description}
                  </p>
                  <div className="mt-6 flex flex-wrap gap-3 text-sm">
                    {step.title === "Assessment" ? (
                      <Link href="/fas" className="text-[var(--color-ink-dim)] underline-offset-4 hover:text-[var(--color-ink)] hover:underline">
                        Open the FAS →
                      </Link>
                    ) : null}
                    {step.title === "Anatomy" ? (
                      <Link href="/anatomy" className="text-[var(--color-ink-dim)] underline-offset-4 hover:text-[var(--color-ink)] hover:underline">
                        SCALP layered anatomy →
                      </Link>
                    ) : null}
                    {step.title === "Range" ? (
                      <Link href="/range" className="text-[var(--color-ink-dim)] underline-offset-4 hover:text-[var(--color-ink)] hover:underline">
                        The four R&apos;s →
                      </Link>
                    ) : null}
                    {step.title === "Treatment" ? (
                      <Link href="/hits" className="text-[var(--color-ink-dim)] underline-offset-4 hover:text-[var(--color-ink)] hover:underline">
                        The five HITs →
                      </Link>
                    ) : null}
                  </div>
                </div>
              </li>
            ))}
          </ol>
        </div>
      </section>

      <section>
        <div className="container-page py-16 text-center">
          <h2 className="font-display text-3xl tracking-tight md:text-4xl">
            Validated in clinical practice.
          </h2>
          <p className="mx-auto mt-3 max-w-2xl text-[var(--color-ink-dim)]">
            Of 28 surveyed clinicians, over 85% agreed AART-HIT™ was adequate for their needs and 100% agreed the FAS was useful in clinical practice.
          </p>
        </div>
      </section>
    </>
  );
}
