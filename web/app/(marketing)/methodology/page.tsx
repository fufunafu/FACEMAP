import type { Metadata } from "next";
import { MetricExplainer } from "@/components/metric-explainer";
import { metrics } from "@/content/metrics";

export const metadata: Metadata = {
  title: "Methodology",
  description:
    "How FaceMap computes facial thirds, fifths, golden ratio, canthal tilt, and surface asymmetry — with target ranges and severity encoding.",
};

export default function MethodologyPage() {
  return (
    <>
      <section className="border-b hairline">
        <div className="container-page py-20">
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            Methodology
          </p>
          <h1 className="mt-4 max-w-3xl font-display text-5xl tracking-tight md:text-6xl">
            Five geometric metrics, all in the Symmetry &amp; proportions
            quadrant.
          </h1>
          <p className="mt-5 max-w-2xl text-[var(--color-ink-dim)]">
            Each metric runs after every capture, computes a value against a
            target range, and emits a severity grade. Severity is computed from
            how far the value falls outside the target.
          </p>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-16">
          <div className="grid gap-4 md:grid-cols-2">
            {metrics.map((m) => (
              <MetricExplainer key={m.id} metric={m} />
            ))}
          </div>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-16">
          <div className="grid gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
            <div>
              <h2 className="font-display text-3xl tracking-tight md:text-4xl">
                Severity grading.
              </h2>
              <p className="mt-4 text-[var(--color-ink-dim)]">
                For each metric, severity is one of <em>normal</em>,{" "}
                <em>mild</em>, <em>moderate</em>, or <em>significant</em>. It is
                derived from the deviation from the target range: small
                deviations earn <em>mild</em>; large deviations earn{" "}
                <em>significant</em>. Within a domain, severity is encoded as
                opacity of the domain hue.
              </p>
            </div>
            <div className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-7">
              <table className="w-full text-sm">
                <thead>
                  <tr className="text-left text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
                    <th className="pb-3">Severity</th>
                    <th className="pb-3 text-right">Opacity on hue</th>
                  </tr>
                </thead>
                <tbody className="num text-[var(--color-ink-dim)]">
                  <tr className="border-t hairline"><td className="py-2">Normal</td><td className="py-2 text-right">0%</td></tr>
                  <tr className="border-t hairline"><td className="py-2">Mild</td><td className="py-2 text-right">38%</td></tr>
                  <tr className="border-t hairline"><td className="py-2">Moderate</td><td className="py-2 text-right">64%</td></tr>
                  <tr className="border-t hairline"><td className="py-2">Significant</td><td className="py-2 text-right">100%</td></tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </section>

      <section>
        <div className="container-page py-16">
          <h2 className="font-display text-3xl tracking-tight md:text-4xl">
            Limitations.
          </h2>
          <ul className="mt-6 max-w-3xl space-y-3 text-[var(--color-ink-dim)]">
            <li>
              FaceMap analyses geometry only. It does not assess skin quality,
              dynamic motion, or volume directly. Three of the four framework
              quadrants are not yet quantified by the v0.1 app.
            </li>
            <li>
              Asymmetry is computed across regional centroids, so a region with
              translated <em>and</em> rotated asymmetry may report less than
              its true point-cloud asymmetry. Per-vertex asymmetry is on the
              roadmap.
            </li>
            <li>
              Capture pose affects results. Tilted heads produce apparent
              asymmetry. The app&apos;s capture guide nudges toward a neutral
              pose, but practitioners should confirm against direct examination.
            </li>
            <li>
              FaceMap is a planning aid. It is not a medical device, does not
              diagnose any condition, and does not prescribe treatment, dose,
              or specific injection sites.
            </li>
          </ul>
        </div>
      </section>
    </>
  );
}
