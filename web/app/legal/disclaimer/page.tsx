import type { Metadata } from "next";
import { disclaimer } from "@/content/disclaimer";

export const metadata: Metadata = {
  title: "Disclaimer",
  description: "FaceMap is a planning aid for licensed medical practitioners.",
};

export default function DisclaimerPage() {
  return (
    <article className="container-narrow py-20">
      <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
        Legal
      </p>
      <h1 className="mt-4 font-display text-5xl tracking-tight md:text-6xl">
        {disclaimer.firstLaunchTitle}.
      </h1>
      <div className="mt-10 space-y-6 text-[var(--color-ink-dim)]">
        {disclaimer.firstLaunchBody.split("\n\n").map((p, i) => (
          <p key={i}>{p}</p>
        ))}
      </div>
      <p className="mt-12 rounded-md border hairline bg-[var(--color-surface-raised)] p-4 text-sm text-[var(--color-ink-muted)]">
        {disclaimer.analysisFooter}
      </p>
    </article>
  );
}
