import type { Metadata } from "next";
import { MetricExplainer } from "@/components/metric-explainer";
import { metrics } from "@/content/metrics";

export const metadata: Metadata = {
  title: "Methodology",
  description:
    "How FaceMap computes facial thirds, fifths, golden ratio, canthal tilt, and surface asymmetry — and how each metric supports a FAS facet.",
};

export default function MethodologyPage() {
  return (
    <>
      <section className="border-b hairline">
        <div className="container-page py-14 md:py-20">
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            Methodology
          </p>
          <h1 className="mt-4 max-w-3xl font-display text-[2.25rem] tracking-tight sm:text-5xl md:text-6xl">
            Geometry that supports the FAS.
          </h1>
          <p className="mt-5 max-w-2xl text-[var(--color-ink-dim)]">
            Each metric runs after every capture, computes a value against a target range, and emits a severity grade aligned with the FAS 0–3 scale. Eight metrics span all five facets — three for Proportions, two for Symmetry, one each for Facial shape, Expression, and Skin quality.
          </p>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-12 md:py-16">
          <div className="grid gap-4 md:grid-cols-2">
            {metrics.map((m) => (
              <MetricExplainer key={m.id} metric={m} />
            ))}
          </div>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-12 md:py-16">
          <div className="grid gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
            <div>
              <h2 className="font-display text-3xl tracking-tight md:text-4xl">
                Severity grading.
              </h2>
              <p className="mt-4 text-[var(--color-ink-dim)]">
                For each metric, severity is one of <em>0 None</em>,{" "}
                <em>1 Mild</em>, <em>2 Moderate</em>, or <em>3 Severe</em> — the
                same scale as the FAS. It is derived from how far the value
                falls outside the target range.
              </p>
            </div>
            <div className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-7">
              <table className="w-full text-sm">
                <thead>
                  <tr className="text-left text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
                    <th className="pb-3">Grade</th>
                    <th className="pb-3">FAS label</th>
                    <th className="pb-3 text-right">Opacity on hue</th>
                  </tr>
                </thead>
                <tbody className="num text-[var(--color-ink-dim)]">
                  <tr className="border-t hairline"><td className="py-2">0</td><td className="py-2">None</td><td className="py-2 text-right">0%</td></tr>
                  <tr className="border-t hairline"><td className="py-2">1</td><td className="py-2">Mild</td><td className="py-2 text-right">38%</td></tr>
                  <tr className="border-t hairline"><td className="py-2">2</td><td className="py-2">Moderate</td><td className="py-2 text-right">64%</td></tr>
                  <tr className="border-t hairline"><td className="py-2">3</td><td className="py-2">Severe</td><td className="py-2 text-right">100%</td></tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-12 md:py-16">
          <h2 className="font-display text-3xl tracking-tight md:text-4xl">
            Further reading.
          </h2>
          <p className="mt-3 max-w-2xl text-[var(--color-ink-dim)]">
            The site is built around the AART-HIT™ paper, with related foundations on facial anatomy and proportion.
          </p>
          <ol className="mt-8 space-y-4 text-sm text-[var(--color-ink-dim)]">
            <li className="rounded-md border hairline bg-[var(--color-surface)] p-4">
              <p>
                <span className="text-[var(--color-ink)]">Nikolis A, Avelar LET, Haddad A, et al.</span>{" "}
                Turn Your AART™ into a HIT™ Using a Complete Range of Aesthetic Injectables: Methodology for Combining Products to Maximise Patient Outcomes.
              </p>
              <p className="mt-1 text-xs text-[var(--color-ink-muted)]">
                <em>Clinical, Cosmetic and Investigational Dermatology</em> 2024:17, 2051–2069. doi:10.2147/CCID.S465155
              </p>
            </li>
            <li className="rounded-md border hairline bg-[var(--color-surface)] p-4">
              <p>
                <span className="text-[var(--color-ink)]">Mendelson B, Wong CH.</span>{" "}
                Changes in the facial skeleton with aging: implications and clinical applications in facial rejuvenation.
              </p>
              <p className="mt-1 text-xs text-[var(--color-ink-muted)]">
                <em>Aesthetic Plastic Surgery</em> 2012;36(4):753–760.
              </p>
            </li>
            <li className="rounded-md border hairline bg-[var(--color-surface)] p-4">
              <p>
                <span className="text-[var(--color-ink)]">Rohrich RJ, Pessa JE.</span>{" "}
                The fat compartments of the face: anatomy and clinical implications for cosmetic surgery.
              </p>
              <p className="mt-1 text-xs text-[var(--color-ink-muted)]">
                <em>Plastic and Reconstructive Surgery</em> 2007;119(7):2219–2227.
              </p>
            </li>
            <li className="rounded-md border hairline bg-[var(--color-surface)] p-4">
              <p>
                <span className="text-[var(--color-ink)]">Pessa JE, Rohrich RJ.</span>{" "}
                Facial Topography: Clinical Anatomy of the Face. CRC Press, 2012.
              </p>
            </li>
            <li className="rounded-md border hairline bg-[var(--color-surface)] p-4">
              <p>
                <span className="text-[var(--color-ink)]">Farkas LG, Hreczko TA, Kolar JC, Munro IR.</span>{" "}
                Vertical and horizontal proportions of the face in young adult North American Caucasians: revision of neoclassical canons.
              </p>
              <p className="mt-1 text-xs text-[var(--color-ink-muted)]">
                <em>Plastic and Reconstructive Surgery</em> 1985;75(3):328–338.
              </p>
            </li>
          </ol>
          <p className="mt-6 text-[11px] text-[var(--color-ink-muted)]">
            Citations are provided as a reading guide, not as endorsement. Practitioners should consult primary sources directly.
          </p>
        </div>
      </section>

      <section>
        <div className="container-page py-12 md:py-16">
          <h2 className="font-display text-3xl tracking-tight md:text-4xl">
            Limitations.
          </h2>
          <ul className="mt-6 max-w-3xl space-y-3 text-[var(--color-ink-dim)]">
            <li>
              Quantification depth varies by facet. Proportions, Symmetry, and Facial shape are measured directly on the mesh; Expression is inferred from resting blendshape activation; Skin quality is a <em>provisional</em> photo-based texture indicator best read longitudinally, not as an absolute score.
            </li>
            <li>
              Every geometric output depends on landmark calibration. The shipped vertex indices are reference seeds that must be calibrated against a real captured mesh on each device before clinical use; the app shows a standing warning until then.
            </li>
            <li>
              Asymmetry is computed across regional centroids, so a region with translated <em>and</em> rotated asymmetry may report less than its true point-cloud asymmetry. Per-vertex asymmetry is on the roadmap.
            </li>
            <li>
              Capture pose affects results. Tilted heads produce apparent asymmetry. The app&apos;s capture guide nudges toward a neutral pose, but practitioners should confirm against direct examination.
            </li>
            <li>
              FaceMap is a planning aid. It is not a medical device, does not diagnose any condition, and does not prescribe treatment, dose, or specific injection sites.
            </li>
          </ul>
        </div>
      </section>
    </>
  );
}
