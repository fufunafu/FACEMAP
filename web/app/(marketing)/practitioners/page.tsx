import Link from "next/link";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "For practitioners",
  description:
    "How FaceMap fits into a practitioner workflow — privacy, licensing, consent, and the app's role as a planning aid.",
};

const FAQ = [
  {
    q: "Is FaceMap a medical device?",
    a: "No. FaceMap is a planning aid for licensed medical practitioners. It does not diagnose any condition, and does not prescribe treatment, dose, or specific injection sites. The flagged regions shown by the app are computational outputs based on geometric measurements — not clinical recommendations.",
  },
  {
    q: "Does my patient’s data leave the device?",
    a: "No. Capture, analysis, and rendering happen on-device. Cases are saved locally under a non-PII patient code (e.g. ‘P-014 Visit 2’). Nothing is uploaded unless the practitioner explicitly exports it.",
  },
  {
    q: "Who can use FaceMap?",
    a: "Licensed medical practitioners only. The first-launch disclaimer requires the practitioner to confirm licensing and patient consent before any capture is allowed.",
  },
  {
    q: "What does FaceMap actually measure?",
    a: "v0.1 implements five geometric metrics — facial thirds, fifths, golden ratio, canthal tilt, and surface asymmetry — that quantify the Proportions and Symmetry facets of the FAS™. The other three facets (Skin quality, Facial shape, Expression) are graded by direct practitioner observation.",
  },
  {
    q: "Do you support Android?",
    a: "Not currently. FaceMap relies on the iPhone’s TrueDepth front camera for high-fidelity 3D capture.",
  },
  {
    q: "Will the other facets be quantified?",
    a: "They are on the roadmap. The FAS™ is published in full; v0.1 of the app implements measurement for Proportions and Symmetry. The radar visualisation already reflects all five facets.",
  },
];

const PILLARS = [
  {
    title: "On-device by default",
    body:
      "Capture, analysis, and rendering all run on iPhone. No cloud. No server.",
  },
  {
    title: "Practitioner-gated",
    body:
      "First-launch disclaimer enforces licensed-practitioner attestation and patient-consent confirmation.",
  },
  {
    title: "Plain-English findings",
    body:
      "Every flagged region uses its domain hue. Severity is opacity, not red·amber·green.",
  },
  {
    title: "Pseudonymous cases",
    body:
      "Save cases under a non-PII code. The patient name never enters the app.",
  },
];

export default function PractitionersPage() {
  return (
    <>
      <section className="border-b hairline">
        <div className="container-page py-20">
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            For practitioners
          </p>
          <h1 className="mt-4 max-w-3xl font-display text-5xl tracking-tight md:text-6xl">
            A planning aid that respects the way you work.
          </h1>
          <p className="mt-5 max-w-2xl text-[var(--color-ink-dim)]">
            FaceMap automates geometric measurement so you can put your time
            into judgment, not calipers. The clinical decision is, and stays,
            yours.
          </p>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-20">
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            {PILLARS.map((p) => (
              <article
                key={p.title}
                className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-6"
              >
                <h3 className="text-lg">{p.title}</h3>
                <p className="mt-2 text-sm text-[var(--color-ink-dim)]">
                  {p.body}
                </p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-20">
          <h2 className="font-display text-3xl tracking-tight md:text-4xl">
            Frequently asked.
          </h2>
          <dl className="mt-10 divide-y hairline">
            {FAQ.map((f) => (
              <div key={f.q} className="grid gap-2 py-6 md:grid-cols-[minmax(0,260px)_minmax(0,1fr)] md:gap-10">
                <dt className="text-lg">{f.q}</dt>
                <dd className="text-[var(--color-ink-dim)]">{f.a}</dd>
              </div>
            ))}
          </dl>
        </div>
      </section>

      <section>
        <div className="container-page py-16 text-center">
          <h2 className="font-display text-3xl tracking-tight md:text-4xl">
            Apply for practitioner access.
          </h2>
          <p className="mx-auto mt-3 max-w-xl text-[var(--color-ink-dim)]">
            We verify licensing before granting access.
          </p>
          <Link
            href="/access"
            className="mt-6 inline-block rounded-[var(--radius-button)] bg-[var(--color-cta-bg)] px-5 py-3 text-sm font-medium text-[var(--color-cta-ink)] transition hover:opacity-90"
          >
            Get access
          </Link>
        </div>
      </section>
    </>
  );
}
