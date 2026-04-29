import Link from "next/link";
import type { Metadata } from "next";
import { AestheticWheel } from "@/components/aesthetic-wheel";
import { DomainCard } from "@/components/domain-card";
import { SeverityRamp } from "@/components/severity-ramp";
import { domainsList } from "@/content/domains";

export const metadata: Metadata = {
  title: "The Nikolis four-domain framework",
  description:
    "Mechanical behaviour, Optical properties, Symmetry & proportions, Structural volume — Dr Andreas Nikolis's framework, as implemented in FaceMap.",
};

export default function FrameworkPage() {
  return (
    <>
      <section className="border-b hairline">
        <div className="container-page grid gap-10 py-20 lg:grid-cols-[minmax(0,1fr)_auto] lg:items-center">
          <div>
            <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
              The framework
            </p>
            <h1 className="mt-4 font-display text-5xl tracking-tight md:text-6xl">
              Four domains of the aesthetic face.
            </h1>
            <p className="mt-5 max-w-xl text-[var(--color-ink-dim)]">
              The published wheel divides every observable concern into four
              domains. FaceMap inherits this structure end-to-end — from the
              colour of a flagged region to the way severity is encoded.
            </p>
          </div>
          <div className="flex justify-center lg:justify-end">
            <AestheticWheel size={420} />
          </div>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-20">
          <div className="grid gap-4 md:grid-cols-2">
            {domainsList.map((d) => (
              <DomainCard key={d.id} domain={d} />
            ))}
          </div>
          <p className="mt-8 max-w-2xl text-sm text-[var(--color-ink-dim)]">
            Every metric in v0.1 of the iOS app is in the Symmetry &amp;
            proportions quadrant. The other three quadrants are part of the
            published framework and are on the v0.1 roadmap. The wheel
            visualisation itself works for the full framework.
          </p>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-20">
          <div className="grid gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
            <div>
              <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
                Severity encoding
              </p>
              <h2 className="mt-3 font-display text-3xl tracking-tight md:text-4xl">
                Opacity of the domain hue, not red &middot; amber &middot; green.
              </h2>
              <p className="mt-4 text-[var(--color-ink-dim)]">
                Inside a quadrant, severity is the opacity of that quadrant&apos;s
                hue: 0% for normal, 38% for mild, 64% for moderate, 100% for
                significant. The eye reads severity as <em>more domain</em>,
                not as a separate alarm colour.
              </p>
              <p className="mt-3 text-sm text-[var(--color-ink-muted)]">
                Tokens mirrored from <code className="num">Theme.swift</code>{" "}
                in the iOS app.
              </p>
            </div>
            <div className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-7">
              <div className="space-y-7">
                {domainsList.map((d) => (
                  <div key={d.id}>
                    <p className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
                      {d.name}
                    </p>
                    <div className="mt-3">
                      <SeverityRamp domain={d.id} />
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
            Ready to walk the wheel?
          </h2>
          <p className="mx-auto mt-3 max-w-xl text-[var(--color-ink-dim)]">
            The decision aid lets you click through each quadrant and see what
            FaceMap can flag inside it.
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
