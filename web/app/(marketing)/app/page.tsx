import Link from "next/link";
import type { Metadata } from "next";
import { MetricExplainer } from "@/components/metric-explainer";
import { SeverityRamp } from "@/components/severity-ramp";
import { MeshViewer } from "@/components/mesh-viewer";
import { PhoneFrame } from "@/components/phone-frame";
import { metrics } from "@/content/metrics";
import { facets } from "@/content/fas";

// Toggle to true (and drop a GLB at web/public/sample-face.glb) to activate.
const HAS_SAMPLE_MESH = false;

// Toggle individual screenshot src to a real path under /public/screenshots
// once captures are available; until then the PhoneFrame placeholder renders.
const SCREENSHOTS = [
  { src: "", caption: "Capture — TrueDepth framing guide and on-device mesh build." },
  { src: "", caption: "Analyse — FAS radar with five facets graded after each capture." },
  { src: "", caption: "Plan — flagged regions on the 3D mesh, opacity scaled to severity." },
];

export const metadata: Metadata = {
  title: "The app",
  description:
    "What FaceMap does on iPhone — capture a 3D mesh, run geometric metrics that quantify the Proportions and Symmetry facets of the FAS, and render the radar on-device.",
};

const FEATURES = [
  {
    title: "TrueDepth capture",
    body:
      "Front-facing TrueDepth camera produces a high-fidelity 3D mesh on-device. No cloud upload. The capture screen guides framing and pose.",
  },
  {
    title: "FAS radar on iPhone",
    body:
      "Every capture grades the radar. Proportions and Symmetry are quantified geometrically; Skin quality, Facial shape, and Expression are graded by the practitioner inline.",
  },
  {
    title: "Severity by opacity",
    body:
      "0 None · 1 Mild · 2 Moderate · 3 Severe. Severity is the opacity of the facet hue — outliers are obvious. No separate red·amber·green ramp.",
  },
  {
    title: "Local case storage",
    body:
      "Save cases under non-PII patient codes (e.g. ‘P-014 Visit 2’). Track each FAS visit-over-visit to see the radar shrink toward the centre.",
  },
  {
    title: "HIT-ready output",
    body:
      "Every FAS profile maps to one or more HITs. The app surfaces which Holistic Individualised Treatment(s) the patient&apos;s outliers point to.",
  },
  {
    title: "Practitioner-only gate",
    body:
      "First-launch disclaimer requires the practitioner to confirm licensing and patient consent before any capture is allowed.",
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
            FaceMap is a digital FAS™.
          </h1>
          <p className="mt-5 max-w-2xl text-[var(--color-ink-dim)]">
            FaceMap brings the Facial Assessment Scale to iPhone. Capture a 3D face mesh, grade five facets, plot the radar, and see which Holistic Individualised Treatment(s) address the priorities — all on-device. Built for licensed practitioners.
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
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            On iPhone
          </p>
          <h2 className="mt-3 font-display text-3xl tracking-tight md:text-4xl">
            Three screens, one workflow.
          </h2>
          <p className="mt-3 max-w-2xl text-[var(--color-ink-dim)]">
            Capture, analyse, plan — every step on-device. Real screenshots arriving soon.
          </p>
          <div className="mt-12 flex flex-wrap items-start justify-center gap-8 lg:gap-12">
            {SCREENSHOTS.map((s, i) => (
              <PhoneFrame
                key={i}
                src={s.src || undefined}
                placeholder={!s.src}
                caption={s.caption}
                width={260}
              />
            ))}
          </div>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-20">
          <div className="grid gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)] lg:items-center">
            <div>
              <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
                Sample 3D mesh
              </p>
              <h2 className="mt-3 font-display text-3xl tracking-tight md:text-4xl">
                Spin a captured face.
              </h2>
              <p className="mt-4 text-[var(--color-ink-dim)]">
                The iOS app builds a high-fidelity 3D mesh from the iPhone&apos;s TrueDepth camera. The same mesh format renders inline here — drag to rotate, scroll to zoom.
              </p>
              <p className="mt-3 text-sm text-[var(--color-ink-muted)]">
                {HAS_SAMPLE_MESH
                  ? "Live: drag to rotate, pinch to zoom."
                  : "Sample face landing soon. Until then, a stylised preview."}
              </p>
            </div>
            <MeshViewer hasMesh={HAS_SAMPLE_MESH} />
          </div>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-20">
          <div className="flex flex-col gap-2">
            <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
              v0.1 metrics
            </p>
            <h2 className="font-display text-3xl tracking-tight md:text-4xl">
              Five geometric metrics — quantifying Proportions &amp; Symmetry.
            </h2>
            <p className="mt-2 max-w-2xl text-[var(--color-ink-dim)]">
              Proportions and Symmetry are quantified by geometry directly. The other three FAS facets — Skin quality, Facial shape, Expression — are graded by direct practitioner observation in v0.1.
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
                On the radar
              </p>
              <h2 className="mt-3 font-display text-3xl tracking-tight md:text-4xl">
                Severity reads as more facet.
              </h2>
              <p className="mt-4 text-[var(--color-ink-dim)]">
                Each facet axis carries a marker at its current grade. With each subsequent treatment, the lines of the FAS move closer to point 0 — the centre — indicating milder deficits.
              </p>
            </div>
            <div className="rounded-[var(--radius-sheet)] border hairline bg-[var(--color-surface)] p-7">
              <p className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
                Proportions facet
              </p>
              <div className="mt-4">
                <SeverityRamp hue={facets.proportions.hue} />
              </div>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}
