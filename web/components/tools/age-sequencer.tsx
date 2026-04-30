"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import {
  facets as facetsById,
  facetOrder,
  type FacetId,
} from "@/content/fas";
import { hits as hitsById, hitsList, type HitId } from "@/content/hits";

function eraFor(age: number): "20s+" | "30s+" | "40s+" | "50s+" {
  if (age < 30) return "20s+";
  if (age < 40) return "30s+";
  if (age < 50) return "40s+";
  return "50s+";
}

const ERA_FOCUS: Record<string, { focus: string; hits: HitId[] }> = {
  "20s+": { focus: "Beautification", hits: ["glow-on", "kiss-and-smile"] },
  "30s+": { focus: "Volumization", hits: ["shape-up", "glow-on"] },
  "40s+": { focus: "Eversion", hits: ["bright-eyes", "kiss-and-smile"] },
  "50s+": { focus: "Contour definition", hits: ["profile", "shape-up"] },
};

export function AgeSequencer() {
  const [age, setAge] = useState(38);
  const [facet, setFacet] = useState<FacetId>("facialShape");

  const era = eraFor(age);
  const eraInfo = ERA_FOCUS[era];

  const ordered = useMemo(() => {
    return hitsList
      .map((h) => {
        const eraScore = eraInfo.hits.includes(h.id) ? 2 : 0;
        const facetScore = h.facets.includes(facet) ? 1.5 : 0;
        return { id: h.id, score: eraScore + facetScore };
      })
      .sort((a, b) => b.score - a.score);
  }, [eraInfo, facet]);

  return (
    <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)] lg:items-start">
      <div className="space-y-6">
        <div className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-6">
          <p className="text-[11px] uppercase tracking-[0.18em] text-[var(--color-ink-muted)]">
            Patient age
          </p>
          <div className="mt-3 flex items-baseline gap-3">
            <span className="num font-display text-5xl tracking-tight">{age}</span>
            <span className="num text-sm text-[var(--color-ink-muted)]">{era}</span>
          </div>
          <input
            type="range"
            min={20}
            max={80}
            value={age}
            onChange={(e) => setAge(Number(e.target.value))}
            className="mt-4 w-full accent-[var(--color-facet-symmetry)]"
            aria-label="Patient age"
          />
          <p className="mt-3 text-sm text-[var(--color-ink-dim)]">
            Era focus: <span className="text-[var(--color-ink)]">{eraInfo.focus}</span>
          </p>
        </div>

        <div className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-6">
          <p className="text-[11px] uppercase tracking-[0.18em] text-[var(--color-ink-muted)]">
            Dominant FAS facet
          </p>
          <div className="mt-3 flex flex-wrap gap-2">
            {facetOrder.map((id) => {
              const f = facetsById[id];
              const active = facet === id;
              return (
                <button
                  key={id}
                  onClick={() => setFacet(id)}
                  className="rounded-full border hairline px-3 py-1.5 text-sm transition"
                  style={{
                    borderColor: active ? f.hue : "var(--color-hairline)",
                    color: active ? f.hue : "var(--color-ink-dim)",
                  }}
                >
                  {f.name}
                </button>
              );
            })}
          </div>
        </div>
      </div>

      <aside
        aria-live="polite"
        className="rounded-[var(--radius-sheet)] border hairline bg-[var(--color-surface)] p-7"
      >
        <p className="text-[11px] uppercase tracking-[0.18em] text-[var(--color-ink-muted)]">
          Suggested HITs (this visit)
        </p>
        <ol className="mt-4 space-y-3">
          {ordered.map((r, i) => {
            const h = hitsById[r.id];
            const inEra = eraInfo.hits.includes(r.id);
            const inFacet = h.facets.includes(facet);
            return (
              <li
                key={r.id}
                className="rounded-md border hairline bg-[var(--color-surface-raised)] p-3"
                style={{
                  borderColor:
                    i === 0 && r.score > 0
                      ? h.hue
                      : "var(--color-hairline)",
                  opacity: r.score === 0 ? 0.45 : 1,
                }}
              >
                <div className="flex items-center justify-between gap-3">
                  <Link
                    href={`/hits/${h.id}`}
                    className="font-medium underline-offset-4 hover:underline"
                    style={{ color: h.hue }}
                  >
                    {h.name}
                  </Link>
                  <span className="num text-xs text-[var(--color-ink-muted)]">
                    {r.score.toFixed(1)}
                  </span>
                </div>
                <p className="mt-1 text-xs text-[var(--color-ink-dim)]">
                  {inEra ? `Era fit (${era}). ` : ""}
                  {inFacet ? "Addresses dominant facet." : "Less aligned with this case."}
                </p>
              </li>
            );
          })}
        </ol>
        <p className="mt-4 text-[11px] text-[var(--color-ink-muted)]">
          Score = era alignment (2) + dominant-facet alignment (1.5).
        </p>
      </aside>
    </div>
  );
}
