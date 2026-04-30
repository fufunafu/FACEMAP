import Link from "next/link";
import type { Metadata } from "next";
import { LasRadar } from "@/components/las-radar";
import { lasCategories, LIP_PRIORITIES } from "@/content/las";

export const metadata: Metadata = {
  title: "Lip Assessment Scale (LAS)",
  description:
    "A site-specific FAS variant for lips and perioral region. Five categories — Proportions, Dynamic movement, Perioral, Symmetry, Shape — driving the Kiss & Smile HIT.",
};

export default function LipAssessmentPage() {
  return (
    <>
      <section className="border-b hairline">
        <div className="container-page grid gap-8 py-14 md:gap-10 md:py-20 lg:grid-cols-[minmax(0,1fr)_auto] lg:items-center">
          <div>
            <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
              Lip Assessment Scale
            </p>
            <h1 className="mt-4 font-display text-[2.25rem] tracking-tight sm:text-5xl md:text-6xl">
              A FAS for lips, specifically.
            </h1>
            <p className="mt-5 max-w-xl text-[var(--color-ink-dim)]">
              The Lip Assessment Scale (LAS) is a site-specific variant of the FAS™ used inside the Kiss &amp; Smile HIT™. Five categories — Proportions, Dynamic movement, Perioral, Symmetry, Shape — graded 0 to 3, plotted on the same radar.
            </p>
            <p className="mt-3 max-w-xl text-sm text-[var(--color-ink-muted)]">
              Adapted from Figure 5 of Nikolis et al., 2024:17.
            </p>
          </div>
          <div className="flex justify-center lg:justify-end">
            <LasRadar size={420} />
          </div>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-14 md:py-20">
          <h2 className="font-display text-3xl tracking-tight md:text-4xl">
            The five categories.
          </h2>
          <div className="mt-10 grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {lasCategories.map((c) => (
              <article
                key={c.id}
                className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-6"
                style={{
                  backgroundImage: `linear-gradient(180deg, ${c.hue}14 0%, transparent 60%)`,
                }}
              >
                <span
                  className="inline-flex items-center gap-2 rounded-full border hairline px-3 py-1 text-[11px] uppercase tracking-wider text-[var(--color-ink-dim)]"
                  style={{ borderColor: `${c.hue}66` }}
                >
                  <span
                    className="size-2 rounded-full"
                    style={{ backgroundColor: c.hue }}
                    aria-hidden="true"
                  />
                  {c.name}
                </span>
                <ul className="mt-4 space-y-1 text-sm text-[var(--color-ink-dim)]">
                  {c.parameters.map((p) => (
                    <li key={p} className="flex items-start gap-2">
                      <span
                        className="mt-1.5 size-1.5 rounded-full"
                        style={{ backgroundColor: c.hue }}
                        aria-hidden="true"
                      />
                      {p}
                    </li>
                  ))}
                </ul>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-14 md:py-20">
          <h2 className="font-display text-3xl tracking-tight md:text-4xl">
            Three lip priorities.
          </h2>
          <p className="mt-3 max-w-2xl text-[var(--color-ink-dim)]">
            The Kiss &amp; Smile HIT™ is divided into three priorities, determined using the LAS.
          </p>
          <div className="mt-10 grid gap-4 md:grid-cols-3">
            {LIP_PRIORITIES.map((p, i) => (
              <article
                key={p.title}
                className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-6"
              >
                <span className="num text-xs uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
                  Priority {i + 1}
                </span>
                <h3 className="mt-2 font-display text-2xl">{p.title}</h3>
                <p className="mt-3 text-sm text-[var(--color-ink-dim)]">
                  {p.body}
                </p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section>
        <div className="container-page py-12 md:py-16 text-center">
          <p className="text-[var(--color-ink-dim)]">
            Used inside the{" "}
            <Link
              href="/hits/kiss-and-smile"
              className="text-[var(--color-ink)] underline-offset-4 hover:underline"
            >
              Kiss &amp; Smile HIT
            </Link>
            .
          </p>
        </div>
      </section>
    </>
  );
}
