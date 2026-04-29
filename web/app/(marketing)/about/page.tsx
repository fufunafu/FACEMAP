import Link from "next/link";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "About",
  description:
    "FaceMap is developed by Dr Andreas Nikolis and team. The four-domain framework was authored by the team and is implemented end-to-end inside the app.",
};

export default function AboutPage() {
  return (
    <>
      <section className="border-b hairline">
        <div className="container-page py-20">
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            About
          </p>
          <h1 className="mt-4 max-w-3xl font-display text-5xl tracking-tight md:text-6xl">
            Built by the team that authored the framework.
          </h1>
          <p className="mt-5 max-w-2xl text-[var(--color-ink-dim)]">
            FaceMap is developed by Dr Andreas Nikolis and team. The
            four-domain Facial Aesthetic framework was published by the team and
            is implemented end-to-end inside the app — from the colour of every
            quadrant to the severity ramp on every region.
          </p>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-20">
          <div className="grid gap-10 lg:grid-cols-[minmax(0,260px)_minmax(0,1fr)] lg:gap-16">
            <div className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-6">
              <div
                className="mb-5 aspect-[4/5] w-full rounded-md"
                style={{
                  background:
                    "linear-gradient(180deg, #16161C 0%, #0E0E12 100%)",
                  border: "1px dashed rgba(255,255,255,0.12)",
                }}
                role="img"
                aria-label="Headshot placeholder"
              />
              <p className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
                Founder
              </p>
              <h3 className="mt-2 font-display text-2xl">
                Dr Andreas Nikolis
              </h3>
              <p className="mt-1 text-sm text-[var(--color-ink-muted)]">
                Bio coming soon.
              </p>
            </div>
            <div>
              <h2 className="font-display text-3xl tracking-tight md:text-4xl">
                The thesis.
              </h2>
              <p className="mt-4 text-[var(--color-ink-dim)]">
                Aesthetic assessment has long needed a shared vocabulary.
                Practitioners observe the same things — proportions,
                asymmetry, line behaviour, surface optics, volume — but
                describe them in their own terms. The four-domain framework is
                an attempt to give every observation a single home, so that
                conversations between practitioners (and between practitioner
                and patient) start from the same map.
              </p>
              <p className="mt-4 text-[var(--color-ink-dim)]">
                FaceMap implements that map directly. The wheel you see in the
                literature is the wheel you see in the app — and on this site.
                Severity is encoded as opacity of the domain hue, so the eye
                reads severity as <em>more domain</em>, not as a separate alarm
                signal.
              </p>
              <p className="mt-4 text-[var(--color-ink-dim)]">
                The app is a planning aid. The clinical decision is, and stays,
                the practitioner&apos;s.
              </p>
            </div>
          </div>
        </div>
      </section>

      <section>
        <div className="container-page py-16 text-center">
          <h2 className="font-display text-3xl tracking-tight md:text-4xl">
            Want to work with the team?
          </h2>
          <p className="mx-auto mt-3 max-w-xl text-[var(--color-ink-dim)]">
            Reach out via the access page.
          </p>
          <Link
            href="/access"
            className="mt-6 inline-block rounded-[var(--radius-button)] border hairline px-5 py-3 text-sm transition hover:border-white/40"
          >
            Contact
          </Link>
        </div>
      </section>
    </>
  );
}
