import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Privacy",
  description: "How FaceMap handles practitioner and patient data.",
};

export default function PrivacyPage() {
  return (
    <article className="container-narrow py-20">
      <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
        Legal
      </p>
      <h1 className="mt-4 font-display text-5xl tracking-tight md:text-6xl">
        Privacy.
      </h1>
      <div className="mt-10 space-y-6 text-[var(--color-ink-dim)]">
        <p>
          FaceMap is designed so that patient data does not leave the
          practitioner&apos;s device. Capture, analysis, and rendering all run
          locally on iPhone. Cases are stored on-device under a non-PII
          patient code chosen by the practitioner.
        </p>
        <p>
          The website at this domain collects only the information necessary
          to process practitioner access applications: the fields submitted on
          the access form. We use that information solely to verify licensing
          and to grant or decline access. We do not sell or share access-form
          data with third parties.
        </p>
        <p>
          FaceMap does not collect patient personally-identifiable information.
          The app does not require, and does not provide a field for,
          patient names or contact details. Practitioners are instructed to use
          a pseudonymous case code (e.g. ‘P-014 Visit 2’).
        </p>
        <p>
          For questions about privacy, contact the team via the access page.
          This document is a placeholder; consult your jurisdiction&apos;s
          counsel before relying on it.
        </p>
      </div>
    </article>
  );
}
