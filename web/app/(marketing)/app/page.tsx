import Link from "next/link";
import type { Metadata } from "next";
import { MetricExplainer } from "@/components/metric-explainer";
import { SeverityRamp } from "@/components/severity-ramp";
import { metrics } from "@/content/metrics";

export const metadata: Metadata = {
  title: "The app",
  description:
    "What FaceMap does on iPhone — capture a 3D mesh, run five geometric metrics, render flagged regions on an interactive 3D model.",
};

const FEATURES = [
  {
    title: "TrueDepth capture",
    body:
      "Front-facing TrueDepth camera produces a high-fidelity 3D mesh on-device. No cloud upload. The capture screen guides framing and pose.",
  },
  {
    title: "Interactive 3D viewer",
    body:
      "Drag to rotate, pinch to zoom. Preset views: front, three-quarter (L/R), profile (L/R), overhead. Flagged regions tint the mesh in their domain hue.",
  },
  {
    title: "Severity by opacity",
    body:
      "No red·amber·green. Each region is shaded in its domain hue at an opacity that scales with severity (0 → 38 → 64 → 100%).",
  },
  {
    title: "Local case storage",
    body:
      "Save cases under non-PII patient codes (e.g. ‘P-014 Visit 2’). Cases stay on device unless the practitioner exports them.",
  },
  {
    title: "Practitioner-only gate",
    body:
      "First-launch disclaimer requires the practitioner to confirm licensing and patient consent before any capture is allowed.",
  },
  {
    title: "Single language for findings",
    body:
      "Every metric tags a domain on the published wheel; every flagged region is shown in its domain hue. Results read the same way every time.",
  },
];

export default function AppPage() {
  return (
    <>
      <section className="border-b hairline">
        <div className="container-page py-20">
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            The app
          </p>
          <h1 className="mt-4 max-w-3xl font-display text-5xl tracking-tight md:text-6xl">
            iPhone, TrueDepth, on-device.
          </h1>
          <p className="mt-5 max-w-2xl text-[var(--color-ink-dim)]">
            FaceMap runs on any iPhone with a TrueDepth front camera. Capture,
            analysis, and rendering all happen on-device — your patient&apos;s
            face never touches the cloud.
          </p>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-20">
          <h2 className="font-display text-3xl tracking-tight md:text-4xl">
            What you get.
          </h2>
          <ul className="mt-10 grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {FEATURES.map((f) => (
              <li
                key={f.title}
                className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-6"
              >
                <h3 className="text-lg">{f.title}</h3>
                <p className="mt-2 text-sm text-[var(--color-ink-dim)]">
                  {f.body}
                </p>
              </li>
            ))}
          </ul>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-20">
          <div className="flex flex-col gap-2">
            <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
              v0.1 metrics
            </p>
            <h2 className="font-display text-3xl tracking-tight md:text-4xl">
              Five geometric measurements.
            </h2>
            <p className="mt-2 max-w-2xl text-[var(--color-ink-dim)]">
              Each metric runs after every capture and contributes to the
              flagged-regions overlay. All five sit in the Symmetry &amp;
              proportions quadrant of the framework.
            </p>
          </div>
          <div className="mt-10 grid gap-4 md:grid-cols-2">
            {metrics.map((m) => (
              <MetricExplainer key={m.id} metric={m} />
            ))}
          </div>
          <p className="mt-6 text-sm">
            <Link
              href="/methodology"
              className="text-[var(--color-ink-dim)] underline-offset-4 transition hover:text-[var(--color-ink)] hover:underline"
            >
              See the full methodology →
            </Link>
          </p>
        </div>
      </section>

      <section>
        <div className="container-page py-20">
          <div className="grid gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)] lg:items-center">
            <div>
              <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
                On the model
              </p>
              <h2 className="mt-3 font-display text-3xl tracking-tight md:text-4xl">
                Severity reads as more domain.
              </h2>
              <p className="mt-4 text-[var(--color-ink-dim)]">
                A flagged region is rendered in its domain hue at an opacity
                that scales with severity. Mild is a whisper. Significant is
                fully saturated. The visual gradient is the framework, not a
                separate alarm scheme.
              </p>
            </div>
            <div className="rounded-[var(--radius-sheet)] border hairline bg-[var(--color-surface)] p-7">
              <p className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
                Symmetry &amp; proportions
              </p>
              <div className="mt-4">
                <SeverityRamp domain="symmetry" />
              </div>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}
