import Link from "next/link";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Get access",
  description:
    "FaceMap is in restricted access for licensed medical practitioners. Apply for access here.",
};

export default function AccessPage() {
  return (
    <>
      <section className="border-b hairline">
        <div className="container-page py-20">
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            Get access
          </p>
          <h1 className="mt-4 max-w-3xl font-display text-5xl tracking-tight md:text-6xl">
            Restricted to licensed medical practitioners.
          </h1>
          <p className="mt-5 max-w-2xl text-[var(--color-ink-dim)]">
            FaceMap is rolling out to a vetted group of practitioners. Apply
            with your licensing details and we&apos;ll be in touch.
          </p>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-20">
          <div className="grid gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
            <div>
              <h2 className="font-display text-3xl tracking-tight md:text-4xl">
                What we&apos;ll need.
              </h2>
              <ul className="mt-6 space-y-3 text-[var(--color-ink-dim)]">
                <li>
                  <span className="text-[var(--color-ink)]">Your name and clinic.</span>
                  {" "}So we know who we&apos;re onboarding.
                </li>
                <li>
                  <span className="text-[var(--color-ink)]">Licensing jurisdiction and number.</span>
                  {" "}We verify before sending an invitation.
                </li>
                <li>
                  <span className="text-[var(--color-ink)]">Your iPhone model.</span>
                  {" "}FaceMap requires a TrueDepth front camera (iPhone X or later).
                </li>
                <li>
                  <span className="text-[var(--color-ink)]">Your work email.</span>
                  {" "}We&apos;ll only use it for the access flow.
                </li>
              </ul>
              <p className="mt-6 text-sm text-[var(--color-ink-muted)]">
                We do not collect patient data. The app stores cases on-device
                under a non-PII patient code chosen by the practitioner.
              </p>
            </div>

            <form
              className="rounded-[var(--radius-sheet)] border hairline bg-[var(--color-surface)] p-7"
              action="mailto:hello@facemap.app"
              method="post"
              encType="text/plain"
            >
              <Field label="Full name" name="name" required />
              <Field label="Clinic" name="clinic" />
              <Field
                label="Licensing jurisdiction"
                name="licensing"
                placeholder="e.g. Quebec, Canada"
                required
              />
              <Field
                label="License number"
                name="license_number"
                required
              />
              <Field
                label="iPhone model"
                name="iphone"
                placeholder="e.g. iPhone 15 Pro"
              />
              <Field label="Work email" name="email" type="email" required />
              <button
                type="submit"
                className="mt-2 w-full rounded-[var(--radius-button)] bg-[var(--color-cta-bg)] px-5 py-3 text-sm font-medium text-[var(--color-cta-ink)] transition hover:opacity-90"
              >
                Apply for access
              </button>
              <p className="mt-3 text-[11px] text-[var(--color-ink-muted)]">
                By submitting you confirm you are a licensed medical
                practitioner and have read the{" "}
                <Link
                  href="/legal/disclaimer"
                  className="underline-offset-4 hover:underline"
                >
                  disclaimer
                </Link>
                .
              </p>
            </form>
          </div>
        </div>
      </section>
    </>
  );
}

function Field({
  label,
  name,
  type = "text",
  placeholder,
  required,
}: {
  label: string;
  name: string;
  type?: string;
  placeholder?: string;
  required?: boolean;
}) {
  return (
    <label className="mb-4 block">
      <span className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
        {label}
        {required ? " *" : null}
      </span>
      <input
        name={name}
        type={type}
        placeholder={placeholder}
        required={required}
        className="mt-1.5 block w-full rounded-[var(--radius-button)] border hairline bg-[var(--color-surface-raised)] px-3 py-2 text-sm text-[var(--color-ink)] outline-none transition placeholder:text-[var(--color-ink-muted)] focus:border-[var(--color-ink-dim)]"
      />
    </label>
  );
}
