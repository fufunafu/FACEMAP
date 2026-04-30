"use client";

import { useEffect, useMemo, useState } from "react";
import { hits as hitsById, hitOrder, type HitId } from "@/content/hits";
import { facets as facetsById } from "@/content/fas";

const STORAGE_KEY = "facemap-plan-builder";

interface Plan {
  patientCode: string;
  selectedHits: HitId[];
  notes: string;
}

const EMPTY: Plan = { patientCode: "", selectedHits: [], notes: "" };

export function PlanBuilder() {
  const [plan, setPlan] = useState<Plan>(EMPTY);
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) setPlan(JSON.parse(raw) as Plan);
    } catch {
      /* ignore */
    }
    setHydrated(true);
  }, []);

  useEffect(() => {
    if (!hydrated) return;
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(plan));
    } catch {
      /* ignore */
    }
  }, [plan, hydrated]);

  function toggleHit(id: HitId) {
    setPlan((p) => ({
      ...p,
      selectedHits: p.selectedHits.includes(id)
        ? p.selectedHits.filter((h) => h !== id)
        : [...p.selectedHits, id],
    }));
  }

  function clearAll() {
    setPlan(EMPTY);
  }

  // Aggregate facets, products, and detect overlaps.
  const aggregate = useMemo(() => {
    const selected = plan.selectedHits.map((id) => hitsById[id]);
    const facetCount: Record<string, number> = {};
    const productCount: Record<string, number> = {};
    selected.forEach((h) => {
      h.facets.forEach((f) => (facetCount[f] = (facetCount[f] ?? 0) + 1));
      h.products.forEach((p) => (productCount[p.name] = (productCount[p.name] ?? 0) + 1));
    });
    const sharedFacets = Object.entries(facetCount).filter(([, n]) => n > 1).map(([f]) => f);
    const sharedProducts = Object.entries(productCount).filter(([, n]) => n > 1).map(([p]) => p);
    return { selected, sharedFacets, sharedProducts };
  }, [plan.selectedHits]);

  return (
    <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)] lg:items-start">
      <div className="space-y-6">
        <div className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-5">
          <label className="block">
            <span className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
              Patient code (no PII)
            </span>
            <input
              value={plan.patientCode}
              onChange={(e) => setPlan((p) => ({ ...p, patientCode: e.target.value }))}
              placeholder="e.g. P-014 Visit 2"
              className="mt-2 block w-full rounded-[var(--radius-button)] border hairline bg-[var(--color-surface-raised)] px-3 py-2 text-sm outline-none focus:border-[var(--color-ink-dim)]"
            />
          </label>
        </div>

        <div className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-5">
          <p className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
            Add HITs to the plan
          </p>
          <ul className="mt-3 grid gap-2">
            {hitOrder.map((id) => {
              const h = hitsById[id];
              const active = plan.selectedHits.includes(id);
              return (
                <li key={id}>
                  <button
                    onClick={() => toggleHit(id)}
                    aria-pressed={active}
                    className="flex w-full items-center justify-between gap-3 rounded-md border hairline bg-[var(--color-surface-raised)] p-3 text-left transition"
                    style={{
                      borderColor: active ? h.hue : "var(--color-hairline)",
                    }}
                  >
                    <span>
                      <span className="text-sm font-medium" style={{ color: active ? h.hue : "var(--color-ink)" }}>
                        {h.name}
                      </span>
                      <span className="ml-2 text-xs text-[var(--color-ink-dim)]">
                        · {h.region}
                      </span>
                    </span>
                    <span
                      className="num text-xs"
                      style={{ color: active ? h.hue : "var(--color-ink-muted)" }}
                    >
                      {active ? "in plan" : "add"}
                    </span>
                  </button>
                </li>
              );
            })}
          </ul>
        </div>

        <div className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-5">
          <label className="block">
            <span className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
              Visit notes
            </span>
            <textarea
              value={plan.notes}
              onChange={(e) => setPlan((p) => ({ ...p, notes: e.target.value }))}
              rows={4}
              placeholder="Goals, anatomical observations, patient priorities…"
              className="mt-2 block w-full rounded-[var(--radius-button)] border hairline bg-[var(--color-surface-raised)] px-3 py-2 text-sm outline-none focus:border-[var(--color-ink-dim)]"
            />
          </label>
        </div>

        <div className="flex gap-3">
          <button
            onClick={clearAll}
            className="rounded-[var(--radius-button)] border hairline px-4 py-2 text-sm text-[var(--color-ink-dim)] transition hover:text-[var(--color-ink)]"
          >
            Clear plan
          </button>
          <button
            onClick={() => window.print()}
            className="rounded-[var(--radius-button)] bg-[var(--color-cta-bg)] px-4 py-2 text-sm font-medium text-[var(--color-cta-ink)] transition hover:opacity-90"
          >
            Print summary
          </button>
        </div>
      </div>

      <aside
        aria-live="polite"
        className="rounded-[var(--radius-sheet)] border hairline bg-[var(--color-surface)] p-7"
      >
        <p className="text-[11px] uppercase tracking-[0.18em] text-[var(--color-ink-muted)]">
          Plan summary
        </p>
        <p className="num mt-2 text-sm">
          {plan.patientCode || "—"}
        </p>

        {aggregate.selected.length === 0 ? (
          <p className="mt-4 text-sm text-[var(--color-ink-muted)]">
            No HITs added yet. Tick HITs on the left to compose the plan.
          </p>
        ) : (
          <>
            <p className="mt-4 text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
              HITs in this plan
            </p>
            <ul className="mt-2 space-y-1.5 text-sm">
              {aggregate.selected.map((h) => (
                <li key={h.id} className="flex items-center gap-2">
                  <span
                    className="size-1.5 rounded-full"
                    style={{ backgroundColor: h.hue }}
                    aria-hidden="true"
                  />
                  {h.name}
                </li>
              ))}
            </ul>

            <p className="mt-5 text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
              Aggregate product list
            </p>
            <ul className="mt-2 flex flex-wrap gap-1.5">
              {Array.from(
                new Set(aggregate.selected.flatMap((h) => h.products.map((p) => p.name))),
              ).map((p) => (
                <li
                  key={p}
                  className="rounded-full border hairline px-2 py-0.5 text-[11px] num"
                >
                  {p}
                </li>
              ))}
            </ul>

            {aggregate.sharedFacets.length > 0 ? (
              <div
                className="mt-5 rounded-md border p-3 text-xs"
                style={{
                  borderColor: "rgba(242,201,161,0.5)",
                  backgroundColor: "rgba(242,201,161,0.08)",
                }}
              >
                <p className="font-medium text-[var(--color-ink)]">
                  ⚠ Overlapping facets
                </p>
                <p className="mt-1 text-[var(--color-ink-dim)]">
                  Multiple HITs target:{" "}
                  {aggregate.sharedFacets
                    .map((f) => facetsById[f as keyof typeof facetsById].name)
                    .join(", ")}
                  . Coordinate sequencing to avoid double-treating.
                </p>
              </div>
            ) : null}

            {aggregate.sharedProducts.length > 0 ? (
              <div
                className="mt-3 rounded-md border p-3 text-xs"
                style={{
                  borderColor: "rgba(166,180,221,0.5)",
                  backgroundColor: "rgba(166,180,221,0.08)",
                }}
              >
                <p className="font-medium text-[var(--color-ink)]">
                  ℹ Repeated products
                </p>
                <p className="mt-1 text-[var(--color-ink-dim)]">
                  Same product used in multiple HITs:{" "}
                  {aggregate.sharedProducts.join(", ")}. Plan total volume in advance.
                </p>
              </div>
            ) : null}
          </>
        )}

        {plan.notes ? (
          <>
            <p className="mt-5 text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
              Notes
            </p>
            <p className="mt-2 whitespace-pre-wrap text-sm text-[var(--color-ink-dim)]">
              {plan.notes}
            </p>
          </>
        ) : null}

        <p className="mt-6 text-[11px] text-[var(--color-ink-muted)]">
          Saved locally to your browser. Nothing is uploaded.
        </p>
      </aside>
    </div>
  );
}
