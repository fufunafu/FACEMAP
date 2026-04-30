import Link from "next/link";
import type { Metadata } from "next";
import { tools } from "@/content/tools";

export const metadata: Metadata = {
  title: "Decision aid tools",
  description:
    "Nine interactive decision aids grounded in the AART-HIT paper — assessment, planning, and tracking helpers for licensed practitioners.",
};

const GROUPS: Array<{ id: string; label: string; body: string }> = [
  { id: "Assess", label: "Assess", body: "Resolve a single observation into a graded answer." },
  { id: "Plan", label: "Plan", body: "Move from FAS findings to a concrete product or HIT choice." },
  { id: "Track", label: "Track", body: "Persist findings and watch the radar shrink over time." },
];

export default function ToolsIndexPage() {
  return (
    <>
      <section className="border-b hairline">
        <div className="container-page py-20">
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            Decision aids
          </p>
          <h1 className="mt-4 max-w-3xl font-display text-5xl tracking-tight md:text-6xl">
            Nine tools for the AART-HIT workflow.
          </h1>
          <p className="mt-5 max-w-2xl text-[var(--color-ink-dim)]">
            Each tool resolves a single clinical question from the Nikolis et al. 2024 methodology — from grading a facet to picking a product to tracking a patient over time.
          </p>
          <p className="mt-3 max-w-2xl text-sm text-[var(--color-ink-muted)]">
            Educational only. No tool produces a clinical recommendation. The practitioner is the sole decision-maker.
          </p>
        </div>
      </section>

      {GROUPS.map((g) => {
        const list = tools.filter((t) => t.group === g.id);
        return (
          <section key={g.id} className="border-b hairline">
            <div className="container-page py-16">
              <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
                {g.label}
              </p>
              <h2 className="mt-3 font-display text-3xl tracking-tight md:text-4xl">
                {g.body}
              </h2>
              <ul className="mt-10 grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                {list.map((t) => (
                  <li key={t.id}>
                    <Link
                      href={`/tools/${t.id}`}
                      className="group block h-full rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-6 transition hover:border-[var(--color-ink-dim)]"
                      style={{
                        backgroundImage: `linear-gradient(180deg, ${t.hue}14 0%, transparent 65%)`,
                      }}
                    >
                      <div className="flex items-center justify-between">
                        <span
                          className="text-[11px] uppercase tracking-[0.18em]"
                          style={{ color: t.hue }}
                        >
                          {t.group}
                        </span>
                        <span
                          className="size-2 rounded-full"
                          style={{ backgroundColor: t.hue }}
                          aria-hidden="true"
                        />
                      </div>
                      <h3 className="mt-3 font-display text-xl tracking-tight">
                        {t.title}
                      </h3>
                      <p className="mt-2 text-sm text-[var(--color-ink-dim)]">
                        {t.blurb}
                      </p>
                      <p className="mt-4 text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
                        Resolves
                      </p>
                      <p className="mt-1 text-sm">{t.resolves}</p>
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          </section>
        );
      })}

      <section>
        <div className="container-page py-16">
          <p className="text-[var(--color-ink-dim)]">
            The original{" "}
            <Link
              href="/decision-aid"
              className="text-[var(--color-ink)] underline-offset-4 hover:underline"
            >
              FAS facet decision aid
            </Link>{" "}
            is still here — pick a facet, grade it, get a ranked HIT recommendation.
          </p>
        </div>
      </section>
    </>
  );
}
