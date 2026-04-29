import type { Metadata } from "next";
import { DecisionAidExplorer } from "@/components/decision-aid-explorer";

export const metadata: Metadata = {
  title: "Decision tool aid",
  description:
    "Walk the four-domain Nikolis framework. Click each quadrant of the wheel to see its sub-concerns, the regions FaceMap can flag, and how severity is encoded.",
};

export default function DecisionAidPage() {
  return (
    <>
      <section className="border-b hairline">
        <div className="container-page py-16">
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            Decision tool aid
          </p>
          <h1 className="mt-4 max-w-3xl font-display text-5xl tracking-tight md:text-6xl">
            Walk the wheel.
          </h1>
          <p className="mt-5 max-w-2xl text-[var(--color-ink-dim)]">
            Click any quadrant — or use arrow keys — to see what it covers,
            which anatomical regions FaceMap can flag inside it, and the
            severity ramp the iOS app uses to render them.
          </p>
          <p className="mt-3 max-w-2xl text-sm text-[var(--color-ink-muted)]">
            This is an educational tool. It does not look at any patient and
            does not produce clinical recommendations.
          </p>
        </div>
      </section>

      <section>
        <div className="container-page py-16">
          <DecisionAidExplorer />
        </div>
      </section>
    </>
  );
}
