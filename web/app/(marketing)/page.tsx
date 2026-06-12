import Link from "next/link";
import { FasRadar } from "@/components/fas-radar";
import { FacetCard } from "@/components/facet-card";
import { HitCard } from "@/components/hit-card";
import { facetsList } from "@/content/fas";
import { hitsList } from "@/content/hits";
import { aart } from "@/content/aart-hit";
import { rList } from "@/content/range";

export default function HomePage() {
  return (
    <>
      <Hero />
      <AartIntro />
      <FasTeaser />
      <HitsTeaser />
      <RangeTeaser />
      <Built />
      <CTA />
    </>
  );
}

function Hero() {
  return (
    <section className="relative overflow-hidden border-b hairline">
      <div className="container-page grid gap-8 py-14 md:gap-10 md:py-20 lg:grid-cols-[minmax(0,1fr)_auto] lg:items-center lg:gap-16 lg:py-28">
        <div>
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            AART-HIT™ · For licensed aesthetic practitioners
          </p>
          <h1 className="mt-5 text-balance font-display text-[2.5rem] leading-[1.05] tracking-tight sm:text-5xl md:text-6xl lg:text-7xl">
            Turn your AART™ into a{" "}
            <span className="italic text-[var(--color-facet-symmetry)]">
              HIT™
            </span>
            .
          </h1>
          <p className="mt-6 max-w-xl text-balance text-lg text-[var(--color-ink-dim)]">
            FaceMap implements Dr Andreas Nikolis&apos;s AART-HIT™ methodology — Assessment, Anatomy, Range, Treatment — combining a complete range of aesthetic injectables into five Holistic Individualised Treatments. The iOS app is the digital companion to the FAS™ diagnostic tool.
          </p>
          <div className="mt-8 flex flex-wrap items-center gap-3">
            <Link
              href="/access"
              className="rounded-[var(--radius-button)] bg-[var(--color-cta-bg)] px-5 py-3 text-sm font-medium text-[var(--color-cta-ink)] transition hover:opacity-90"
            >
              Get the app
            </Link>
            <Link
              href="/decision-aid"
              className="rounded-[var(--radius-button)] border hairline px-5 py-3 text-sm transition hover:border-[var(--color-ink-dim)]"
            >
              Try the decision aid
            </Link>
          </div>
          <p className="mt-6 max-w-md text-xs text-[var(--color-ink-muted)]">
            A planning aid for licensed practitioners. Not a medical device.
            Does not diagnose, prescribe, or recommend treatment.
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

      <div className="border-t hairline">
        <div className="container-page grid grid-cols-2 gap-px bg-[var(--color-hairline)] md:grid-cols-4">
          {[
            { stat: "100%", label: "agreed FAS™ was useful in clinical practice" },
            { stat: "100%", label: "agreed temporal sequencing was adequate" },
            { stat: "85%", label: "agreed AART-HIT™ was adequate for their needs" },
            { stat: "n=28", label: "clinicians surveyed across IMCAS Paris 2023" },
          ].map((s) => (
            <div
              key={s.label}
              className="bg-[var(--color-canvas)] px-4 py-5 md:px-6 md:py-6"
            >
              <p className="num font-display text-2xl tracking-tight text-[var(--color-ink)] md:text-3xl">
                {s.stat}
              </p>
              <p className="mt-1 text-[11px] text-[var(--color-ink-dim)] md:text-xs">
                {s.label}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function AartIntro() {
  return (
    <section className="border-b hairline">
      <div className="container-page py-14 md:py-20">
        <div className="flex flex-col gap-2">
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            The methodology
          </p>
          <h2 className="font-display text-4xl tracking-tight md:text-5xl">
            Four steps. One language. Reproducible outcomes.
          </h2>
          <p className="mt-3 max-w-2xl text-[var(--color-ink-dim)]">
            AART-HIT™ is the systematic methodology Nikolis et al. published in <em>Clinical, Cosmetic and Investigational Dermatology</em> 2024. It walks the practitioner from full-face assessment through layered anatomy, the product range, and finally a Holistic Individualised Treatment.
          </p>
        </div>
        <div className="mt-12 grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          {aart.map((step) => (
            <article
              key={step.letter}
              className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-6"
            >
              <span className="font-display text-5xl tracking-tight text-[var(--color-ink-dim)]">
                {step.glyph}
              </span>
              <h3 className="mt-3 text-2xl">{step.title}</h3>
              <p className="mt-2 text-sm text-[var(--color-ink-dim)]">
                {step.purpose}
              </p>
            </article>
          ))}
        </div>
        <div className="mt-10">
          <Link
            href="/aart-hit"
            className="text-sm text-[var(--color-ink-dim)] transition hover:text-[var(--color-ink)]"
          >
            Read the full AART-HIT methodology →
          </Link>
        </div>
      </div>
    </section>
  );
}

function FasTeaser() {
  return (
    <section className="border-b hairline">
      <div className="container-page py-14 md:py-20">
        <div className="flex flex-col gap-2">
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            Assessment
          </p>
          <h2 className="font-display text-4xl tracking-tight md:text-5xl">
            FAS™ — five facets, graded 0 to 3.
          </h2>
          <p className="mt-3 max-w-2xl text-[var(--color-ink-dim)]">
            The Facial Assessment Scale grades five facets — Skin quality, Facial shape, Proportions, Symmetry, Expression — on a 0–3 severity scale. The results plot as a circular figure that shrinks toward the centre as treatments take effect.
          </p>
        </div>
        <div className="mt-12 grid gap-4 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">
          {facetsList.map((f) => (
            <FacetCard key={f.id} facet={f} />
          ))}
        </div>
        <div className="mt-10">
          <Link
            href="/fas"
            className="text-sm text-[var(--color-ink-dim)] transition hover:text-[var(--color-ink)]"
          >
            Explore the FAS in depth →
          </Link>
        </div>
      </div>
    </section>
  );
}

function HitsTeaser() {
  return (
    <section className="border-b hairline">
      <div className="container-page py-14 md:py-20">
        <div className="flex flex-col gap-2">
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            Treatment
          </p>
          <h2 className="font-display text-4xl tracking-tight md:text-5xl">
            Five HITs™ for five treatment regions.
          </h2>
          <p className="mt-3 max-w-2xl text-[var(--color-ink-dim)]">
            Each HIT is a Holistic Individualised Treatment combining the right products from the range — relaxers, fillers, skinboosters, biostimulators — for a specific region.
          </p>
        </div>
        <div className="mt-12 grid gap-4 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">
          {hitsList.map((h) => (
            <HitCard key={h.id} hit={h} href={`/hits/${h.id}`} />
          ))}
        </div>
        <div className="mt-10">
          <Link
            href="/hits"
            className="text-sm text-[var(--color-ink-dim)] transition hover:text-[var(--color-ink)]"
          >
            See all five HITs →
          </Link>
        </div>
      </div>
    </section>
  );
}

function RangeTeaser() {
  return (
    <section className="border-b hairline">
      <div className="container-page py-14 md:py-20">
        <div className="flex flex-col gap-2">
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            Range
          </p>
          <h2 className="font-display text-4xl tracking-tight md:text-5xl">
            Relax · Refine · Refresh · Renew.
          </h2>
          <p className="mt-3 max-w-2xl text-[var(--color-ink-dim)]">
            The Galderma portfolio organised as four R&apos;s — neuromodulators, HA fillers (NASHA &amp; OBT/XpresHAn), Skinboosters, and biostimulators (PLLA-SCA).
          </p>
        </div>
        <div className="mt-10 grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          {rList.map((r) => (
            <article
              key={r.id}
              className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-6"
              style={{
                backgroundImage: `linear-gradient(180deg, ${r.hue}1A 0%, transparent 60%)`,
              }}
            >
              <span
                className="font-display text-5xl tracking-tight"
                style={{ color: r.hue }}
              >
                R
              </span>
              <h3 className="mt-2 text-2xl">{r.title}</h3>
              <p className="mt-1 text-xs uppercase tracking-wider text-[var(--color-ink-muted)]">
                {r.family}
              </p>
              <p className="mt-3 text-sm text-[var(--color-ink-dim)]">
                {r.description}
              </p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

function Built() {
  return (
    <section className="border-b hairline">
      <div className="container-page grid gap-8 py-14 md:gap-10 md:py-20 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)] lg:items-center">
        <div>
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            Built by clinicians
          </p>
          <h2 className="mt-3 font-display text-4xl tracking-tight md:text-5xl">
            By Dr Andreas Nikolis &amp; team.
          </h2>
          <p className="mt-4 text-[var(--color-ink-dim)]">
            FaceMap implements the AART-HIT™ methodology developed and validated by Dr Andreas Nikolis and his team — published in <em>Clinical, Cosmetic and Investigational Dermatology</em> in 2024. Every facet, every HIT, every product mapping was designed around how clinicians already work.
          </p>
          <Link
            href="/about"
            className="mt-6 inline-block text-sm text-[var(--color-ink-dim)] transition hover:text-[var(--color-ink)]"
          >
            About the team →
          </Link>
        </div>
        <blockquote className="rounded-[var(--radius-sheet)] border hairline bg-[var(--color-surface)] p-8">
          <p className="font-display text-2xl leading-snug text-[var(--color-ink)]">
            &ldquo;A standardised system for facial assessment allows providers to create a holistic, individualised, and reproducible long-term treatment plan.&rdquo;
          </p>
          <footer className="mt-5 text-sm text-[var(--color-ink-dim)]">
            — Nikolis et al., Clin Cosmet Investig Dermatol 2024:17, 2051–2069
          </footer>
        </blockquote>
      </div>
    </section>
  );
}

function CTA() {
  return (
    <section>
      <div className="container-page py-14 md:py-20 text-center">
        <h2 className="mx-auto max-w-2xl font-display text-4xl tracking-tight md:text-5xl">
          Walk the AART. Land the HIT.
        </h2>
        <p className="mx-auto mt-4 max-w-xl text-[var(--color-ink-dim)]">
          FaceMap brings the FAS™ to iPhone — a 3D measurement tool that grades every facet and measures the objective volume change your treatment produced, visit-over-visit. Built for licensed practitioners.
        </p>
        <div className="mt-8 flex justify-center gap-3">
          <Link
            href="/access"
            className="rounded-[var(--radius-button)] bg-[var(--color-cta-bg)] px-5 py-3 text-sm font-medium text-[var(--color-cta-ink)] transition hover:opacity-90"
          >
            Get access
          </Link>
          <Link
            href="/methodology"
            className="rounded-[var(--radius-button)] border hairline px-5 py-3 text-sm transition hover:border-[var(--color-ink-dim)]"
          >
            Read the methodology
          </Link>
        </div>
      </div>
    </section>
  );
}
