"use client";

import { useMemo, useState } from "react";
import { lasCategories } from "@/content/las";

type Grades = Record<string, number>;

interface Priority {
  id: "ideal" | "framing" | "smile";
  title: string;
  body: string;
  products: string[];
  hue: string;
  weight: (g: Grades) => number;
}

const PRIORITIES: Priority[] = [
  {
    id: "ideal",
    title: "Ideal lips",
    body: "Symmetric, proportionate, naturally shaped. Lip body work — projection and definition.",
    products: ["HA-KYS · Restylane Kysse", "HA-RES · Restylane"],
    hue: "#E9B5E0",
    // Driven by Shape (volume/projection/contour) and Symmetry low-grade.
    weight: (g) => (g.shape ?? 0) * 1.2 + (g.symmetry ?? 0) * 0.8,
  },
  {
    id: "framing",
    title: "Framing lips",
    body: "Surrounding support — pyriform aperture, NLFs, marionettes, perioral hydration.",
    products: ["HA-LYF · Lyft", "HA-REF · Refyne", "HA-DEF · Defyne", "HA-SBV · Skinboosters Vital"],
    hue: "#A6B4DD",
    // Driven by Perioral lines + Proportions imbalance.
    weight: (g) => (g.perioral ?? 0) * 1.4 + (g.proportions ?? 0) * 1.0,
  },
  {
    id: "smile",
    title: "Confident smile",
    body: "Animation, lateral canthal lines, gummy-smile camouflage. About confidence, not beautification.",
    products: ["Dysport (off-label, perioral)", "HA-DEF · Defyne (perioral)"],
    hue: "#F2C9A1",
    // Driven by Dynamic + Symmetry.
    weight: (g) => (g.dynamic ?? 0) * 1.5 + (g.symmetry ?? 0) * 0.6,
  },
];

export function LipPriorities() {
  const [grades, setGrades] = useState<Grades>({
    proportions: 1,
    dynamic: 1,
    perioral: 1,
    symmetry: 0,
    shape: 1,
  });

  const ranking = useMemo(() => {
    return PRIORITIES.map((p) => ({ ...p, score: p.weight(grades) }))
      .sort((a, b) => b.score - a.score);
  }, [grades]);

  const totalGrade = Object.values(grades).reduce((s, v) => s + v, 0);

  return (
    <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)] lg:items-start">
      <div className="space-y-5">
        <p className="text-sm text-[var(--color-ink-dim)]">
          Grade each Lip Assessment Scale axis 0 (None) to 3 (Severe). Priorities re-rank live.
        </p>
        {lasCategories.map((c) => (
          <div
            key={c.id}
            className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-5"
          >
            <div className="flex items-center justify-between">
              <p className="text-sm font-medium">{c.name}</p>
              <span
                className="size-2 rounded-full"
                style={{ backgroundColor: c.hue }}
                aria-hidden="true"
              />
            </div>
            <p className="mt-1 text-xs text-[var(--color-ink-muted)]">
              {c.parameters.join(" · ")}
            </p>
            <div className="mt-4 grid grid-cols-4 gap-2">
              {[0, 1, 2, 3].map((g) => {
                const active = grades[c.id] === g;
                return (
                  <button
                    key={g}
                    onClick={() => setGrades((p) => ({ ...p, [c.id]: g }))}
                    className="rounded-[var(--radius-button)] border hairline px-2 py-2 text-sm transition"
                    style={{
                      borderColor: active ? c.hue : "var(--color-hairline)",
                      backgroundColor: active
                        ? `color-mix(in srgb, ${c.hue} 18%, transparent)`
                        : "transparent",
                    }}
                  >
                    <span className="num">{g}</span>
                    <span className="ml-2 text-xs">
                      {["None", "Mild", "Mod", "Sev"][g]}
                    </span>
                  </button>
                );
              })}
            </div>
          </div>
        ))}
      </div>

      <aside
        aria-live="polite"
        className="rounded-[var(--radius-sheet)] border hairline bg-[var(--color-surface)] p-7"
      >
        <p className="text-[11px] uppercase tracking-[0.18em] text-[var(--color-ink-muted)]">
          Ranked priorities
        </p>
        {totalGrade === 0 ? (
          <p className="mt-3 text-sm text-[var(--color-ink-muted)]">
            Grade at least one axis to rank the three priorities.
          </p>
        ) : (
          <ol className="mt-4 space-y-3">
            {ranking.map((p, i) => (
              <li
                key={p.id}
                className="rounded-md border hairline bg-[var(--color-surface-raised)] p-4"
                style={{
                  borderColor: i === 0 ? p.hue : "var(--color-hairline)",
                }}
              >
                <div className="flex items-baseline gap-3">
                  <span className="num text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
                    {String(i + 1).padStart(2, "0")}
                  </span>
                  <span
                    className="font-display text-xl"
                    style={{ color: p.hue }}
                  >
                    {p.title}
                  </span>
                  <span className="ml-auto num text-xs text-[var(--color-ink-muted)]">
                    score {p.score.toFixed(1)}
                  </span>
                </div>
                <p className="mt-1 text-sm text-[var(--color-ink-dim)]">
                  {p.body}
                </p>
                <div className="mt-3 flex flex-wrap gap-1">
                  {p.products.map((pr) => (
                    <span
                      key={pr}
                      className="rounded-full border hairline px-2 py-0.5 text-[10px] num"
                    >
                      {pr}
                    </span>
                  ))}
                </div>
              </li>
            ))}
          </ol>
        )}
      </aside>
    </div>
  );
}
