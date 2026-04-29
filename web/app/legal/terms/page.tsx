import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Terms",
  description: "Terms of use for the FaceMap iOS app and this website.",
};

export default function TermsPage() {
  return (
    <article className="container-narrow py-20">
      <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
        Legal
      </p>
      <h1 className="mt-4 font-display text-5xl tracking-tight md:text-6xl">
        Terms.
      </h1>
      <div className="mt-10 space-y-6 text-[var(--color-ink-dim)]">
        <p>
          Use of the FaceMap iOS app is restricted to licensed medical
          practitioners and is conditioned on acceptance of the in-app
          disclaimer. The app is a planning aid; it is not a medical device,
          does not diagnose any condition, and does not prescribe treatment,
          dose, or specific injection sites. The practitioner is the sole
          clinical decision-maker for any aesthetic treatment.
        </p>
        <p>
          The website at this domain is provided for informational purposes.
          Nothing on the site constitutes medical advice. Visitors should
          confirm clinical decisions against direct examination of the patient.
        </p>
        <p>
          All content — including the four-domain framework, the wheel
          imagery, and the metric definitions — is published by Dr Andreas
          Nikolis and team. Reuse outside the FaceMap product requires written
          permission.
        </p>
        <p>
          This document is a placeholder; consult your jurisdiction&apos;s
          counsel before relying on it.
        </p>
      </div>
    </article>
  );
}
