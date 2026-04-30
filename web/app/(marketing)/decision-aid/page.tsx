import type { Metadata } from "next";
import { DecisionAidExplorer } from "@/components/decision-aid-explorer";

export const metadata: Metadata = {
  title: "Decision tool aid",
  description:
    "Grade each FAS facet 0–3 and see which Holistic Individualised Treatment (HIT™) addresses the priorities. An interactive walkthrough of the AART-HIT™ methodology.",
};

export default function DecisionAidPage() {
  return (
    <>
      <section className="border-b hairline">
        <div className="container-page py-12 md:py-16">
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            Decision tool aid
          </p>
          <h1 className="mt-4 max-w-3xl font-display text-[2.25rem] tracking-tight sm:text-5xl md:text-6xl">
            Grade the radar. Land the HIT.
          </h1>
          <p className="mt-5 max-w-2xl text-[var(--color-ink-dim)]">
            Click any facet on the FAS radar — or tab between them with arrow keys — to see its parameters, the HIT(s) that address it, and the severity ramp. Adjust the grade to watch the radar shift.
          </p>
          <p className="mt-3 max-w-2xl text-sm text-[var(--color-ink-muted)]">
            This is an educational tool. It does not look at any patient and does not produce clinical recommendations.
          </p>
        </div>
      </section>

      <section>
        <div className="container-page py-12 md:py-16">
          <DecisionAidExplorer />
        </div>
      </section>
    </>
  );
}
