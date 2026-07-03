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
    "What FaceMap does on iPhone — quality-gated TrueDepth capture, a photo-textured 3D model, all five FAS facets quantified with eight metrics, and objective volume change visit-over-visit. On-device, for licensed practitioners.",
};

const FEATURES = [
  {
    title: "Quality-gated 3D capture",
    body:
      "A coached three-pose capture (frontal + both obliques) builds a 3D mesh from the iPhone's TrueDepth camera — and only auto-fires when the head is level and the expression neutral, coaching the patient line by line. Every capture carries a quality score, so a shaky record is flagged before it misleads.",
  },
  {
    title: "Photo-textured 3D model",
    body:
      "The clinical photo captured with each pose is projected onto the mesh, so you review real skin on real geometry — not a grey shell. Toggle between photo and clay surfaces, with flagged regions overlaid in place.",
  },
  {
    title: "All five FAS facets, quantified",
    body:
      "Eight metrics grade the full radar automatically — Proportions, Symmetry, and Facial shape from mesh geometry, Expression from resting muscle activation, and Skin quality from a photo-based texture indicator.",
  },
  {
    title: "Objective volume tracking",
    body:
      "Re-capture at the next visit and FaceMap measures the millimetre change in projection per region — “midface +0.8 mm since the filler visit.” Objective outcomes a 2D photo tool cannot produce.",
  },
  {
    title: "Treatment-plan PDF",
    body:
      "Export a multi-page report — clinical photos, the FAS radar, per-facet findings, and the visit-over-visit change table — under a non-PII patient code. The artifact the patient record keeps.",
  },
  {
    title: "On-device & private",
    body:
      "Cases live in encrypted-at-rest storage excluded from device backups, behind an optional Face ID lock. Pseudonymous patient codes only — no names, no PII, no telemetry.",
  },
  {
    title: "Practitioner-only gate",
    body:
      "A first-launch disclaimer requires the practitioner to confirm licensing and patient consent before any capture. A standing banner flags results until landmarks are calibrated on the device.",
  },
];

export default function AppPage() {
  return (
    <>
      <section className="border-b hairline">
        <div className="container-page py-14 md:py-20">
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            The app
          </p>
          <h1 className="mt-4 max-w-3xl font-display text-[2.25rem] tracking-tight sm:text-5xl md:text-6xl">
            Measure the face. Prove the result.
          </h1>
          <p className="mt-5 max-w-2xl text-[var(--color-ink-dim)]">
            FaceMap brings the Facial Assessment Scale to iPhone as a measurement tool, not a scoring toy. Capture a 3D TrueDepth mesh, quantify all five FAS facets, plan the HIT — then re-capture and measure the objective volume change your treatment produced. On-device, for licensed practitioners.
          </p>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-14 md:py-20">
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
        <div className="container-page py-14 md:py-20">
          <div className="grid gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)] lg:items-center">
            <div>
              <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
                The difference
              </p>
              <h2 className="mt-3 font-display text-3xl tracking-tight md:text-4xl">
                Objective outcomes, not attractiveness scores.
              </h2>
              <p className="mt-4 text-[var(--color-ink-dim)]">
                Photo-based tools rate a face from a 2D image. FaceMap measures one. Because ARKit&apos;s mesh has fixed topology, the same anatomical point is tracked across visits — so re-capturing after treatment yields the millimetre change in projection per region, after aligning on bony landmarks that filler cannot move.
              </p>
              <p className="mt-3 text-[var(--color-ink-dim)]">
                A 2D photo cannot produce that number. It is the evidence a practitioner shows the patient, and the record that documents the result.
              </p>
              <p className="mt-4 text-xs text-[var(--color-ink-muted)]">
                Changes below the capture-noise floor are reported as no measurable change — an honest null is itself a useful result.
              </p>
            </div>
            <div className="rounded-[var(--radius-sheet)] border hairline bg-[var(--color-surface)] p-7">
              <p className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
                Region projection change · Visit 1 → Visit 2
              </p>
              <ul className="mt-5 flex flex-col gap-px overflow-hidden rounded-[var(--radius-card)] bg-[var(--color-hairline)]">
                {[
                  { region: "Midface (L)", delta: "+0.8 mm", gained: true },
                  { region: "Midface (R)", delta: "+0.7 mm", gained: true },
                  { region: "Tear trough (L)", delta: "+0.4 mm", gained: true },
                  { region: "Chin", delta: "+1.2 mm", gained: true },
                  { region: "Jawline (L)", delta: "—", gained: false },
                ].map((row) => (
                  <li
                    key={row.region}
                    className="flex items-center justify-between gap-4 bg-[var(--color-surface)] px-4 py-3"
                  >
                    <span className="text-sm text-[var(--color-ink)]">
                      {row.region}
                    </span>
                    <span
                      className="num text-sm tracking-tight"
                      style={{
                        color: row.gained
                          ? "var(--color-ink)"
                          : "var(--color-ink-muted)",
                      }}
                    >
                      {row.delta}
                    </span>
                  </li>
                ))}
              </ul>
              <p className="mt-4 text-[11px] text-[var(--color-ink-muted)]">
                Illustrative figures. Magnitudes depend on on-device calibration.
              </p>
            </div>
          </div>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-14 md:py-20">
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
        <div className="container-page py-14 md:py-20">
          <div className="grid gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)] lg:items-center">
            <div>
              <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
                Sample 3D mesh
              </p>
              <h2 className="mt-3 font-display text-3xl tracking-tight md:text-4xl">
                Spin a captured face.
              </h2>
              <p className="mt-4 text-[var(--color-ink-dim)]">
                The iOS app builds a smooth-shaded 3D mesh from the iPhone&apos;s TrueDepth camera and textures it with the patient&apos;s own clinical photo. The same mesh format renders inline here — drag to rotate, scroll to zoom.
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
        <div className="container-page py-14 md:py-20">
          <div className="flex flex-col gap-2">
            <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
              The metrics
            </p>
            <h2 className="font-display text-3xl tracking-tight md:text-4xl">
              Eight metrics across all five facets.
            </h2>
            <p className="mt-2 max-w-2xl text-[var(--color-ink-dim)]">
              Proportions, Symmetry, and Facial shape are measured from the 3D mesh; Expression from resting muscle activation; Skin quality from a provisional photo-based texture indicator. Every facet on the radar now carries an automatic signal.
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
        <div className="container-page py-14 md:py-20">
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
