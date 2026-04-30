"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { FasRadar } from "./fas-radar";
import { SeverityRamp } from "./severity-ramp";
import {
  facets,
  facetOrder,
  facetsList,
  type FacetId,
} from "@/content/fas";
import { hits as hitsById, hitsList, type HitId } from "@/content/hits";
import { metrics } from "@/content/metrics";

const PRESET: Record<FacetId, number> = {
  skinQuality: 1,
  facialShape: 2,
  proportions: 1,
  symmetry: 2,
  expression: 1,
};

export function DecisionAidExplorer() {
  const [selected, setSelected] = useState<FacetId | null>("proportions");
  const [values, setValues] = useState<Record<FacetId, number>>(PRESET);

  const ranking = useMemo(() => rankHits(values), [values]);
  const totalGrade = facetOrder.reduce((s, f) => s + (values[f] ?? 0), 0);

  return (
    <div className="grid gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,460px)] lg:items-start">
      <div className="flex flex-col items-center gap-6">
        <FasRadar
          interactive
          focused={selected}
          onFocusChange={setSelected}
          values={values}
          size={520}
        />
        <FacetGrader
          selected={selected}
          values={values}
          setValues={setValues}
        />
        <Recommendation ranking={ranking} totalGrade={totalGrade} />
      </div>

      <aside
        role="tabpanel"
        aria-live="polite"
        className="rounded-[var(--radius-sheet)] border hairline bg-[var(--color-surface)] p-7"
      >
        {selected ? (
          <FacetPanel id={selected} grade={values[selected]} />
        ) : (
          <Placeholder onPick={setSelected} />
        )}

        <div className="mt-8 flex flex-wrap gap-2 border-t hairline pt-5">
          {facetOrder.map((id) => (
            <button
              key={id}
              onClick={() => setSelected(id)}
              className="rounded-full border hairline px-3 py-1 text-xs text-[var(--color-ink-dim)] transition hover:text-[var(--color-ink)]"
              style={{
                borderColor:
                  selected === id ? facets[id].hue : "var(--color-hairline)",
                color: selected === id ? facets[id].hue : undefined,
              }}
            >
              {facets[id].name}
            </button>
          ))}
        </div>
      </aside>
    </div>
  );
}

interface HitRanking {
  id: HitId;
  score: number;
  contributing: Array<{ id: FacetId; grade: number }>;
}

function rankHits(values: Record<FacetId, number>): HitRanking[] {
  const all = hitsList.map((h) => {
    const contributing = h.facets
      .map((f) => ({ id: f, grade: values[f] ?? 0 }))
      .filter((c) => c.grade > 0)
      .sort((a, b) => b.grade - a.grade);
    const score = contributing.reduce((s, c) => s + c.grade, 0);
    return { id: h.id, score, contributing };
  });
  return all.sort((a, b) => b.score - a.score);
}

function Recommendation({
  ranking,
  totalGrade,
}: {
  ranking: HitRanking[];
  totalGrade: number;
}) {
  const top = ranking.filter((r) => r.score > 0);
  return (
    <div className="w-full max-w-[520px] rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-5">
      <p className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
        Suggested HITs (ranked)
      </p>
      {totalGrade === 0 ? (
        <p className="mt-3 text-sm text-[var(--color-ink-muted)]">
          Grade at least one facet above 0 to see a ranked recommendation.
        </p>
      ) : top.length === 0 ? (
        <p className="mt-3 text-sm text-[var(--color-ink-muted)]">
          No high-grade facets currently match a HIT. Adjust the grades to explore.
        </p>
      ) : (
        <ol className="mt-3 space-y-2">
          {top.slice(0, 3).map((r, i) => {
            const hit = hitsById[r.id];
            return (
              <li
                key={r.id}
                className="rounded-md border hairline bg-[var(--color-surface-raised)] p-3"
              >
                <div className="flex items-center justify-between gap-3">
                  <div className="flex items-center gap-3">
                    <span
                      className="num text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]"
                      aria-label={`Rank ${i + 1}`}
                    >
                      {String(i + 1).padStart(2, "0")}
                    </span>
                    <Link
                      href={`/hits/${hit.id}`}
                      className="font-medium underline-offset-4 hover:underline"
                      style={{ color: hit.hue }}
                    >
                      {hit.name}
                    </Link>
                  </div>
                  <span className="num text-xs text-[var(--color-ink-muted)]">
                    score {r.score}
                  </span>
                </div>
                <p className="mt-1 text-xs text-[var(--color-ink-dim)]">
                  Contributing:{" "}
                  {r.contributing
                    .map((c) => `${facets[c.id].name} (${c.grade})`)
                    .join(", ")}
                </p>
              </li>
            );
          })}
        </ol>
      )}
      <p className="mt-3 text-[11px] text-[var(--color-ink-muted)]">
        Educational ranking only. Score = sum of grades on the facets each HIT addresses.
      </p>
    </div>
  );
}

function FacetGrader({
  selected,
  values,
  setValues,
}: {
  selected: FacetId | null;
  values: Record<FacetId, number>;
  setValues: React.Dispatch<React.SetStateAction<Record<FacetId, number>>>;
}) {
  if (!selected) return null;
  const f = facets[selected];
  return (
    <div className="w-full max-w-[520px] rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-4">
      <p className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
        Grade <span style={{ color: f.hue }}>{f.name}</span>
      </p>
      <div className="mt-3 grid grid-cols-4 gap-2">
        {[0, 1, 2, 3].map((g) => {
          const active = values[selected] === g;
          return (
            <button
              key={g}
              onClick={() => setValues((v) => ({ ...v, [selected]: g }))}
              className="rounded-[var(--radius-button)] border hairline px-3 py-2 text-sm transition"
              style={{
                borderColor: active ? f.hue : "var(--color-hairline)",
                backgroundColor: active
                  ? `color-mix(in srgb, ${f.hue} 18%, transparent)`
                  : "transparent",
                color: active ? "var(--color-ink)" : "var(--color-ink-dim)",
              }}
            >
              <span className="num text-base">{g}</span>
              <span className="ml-2 text-xs">
                {["None", "Mild", "Moderate", "Severe"][g]}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

function Placeholder({ onPick }: { onPick: (id: FacetId) => void }) {
  return (
    <div>
      <h2 className="text-2xl">Pick a facet</h2>
      <p className="mt-2 text-[var(--color-ink-dim)]">
        Click a facet name on the radar — or any chip below — to see its FAS
        parameters, the HIT(s) that address it, and the severity ramp.
      </p>
      <div className="mt-5 flex flex-wrap gap-2">
        {facetsList.map((f) => (
          <button
            key={f.id}
            onClick={() => onPick(f.id)}
            className="rounded-[var(--radius-button)] border hairline px-3 py-2 text-sm transition hover:border-[var(--color-ink-dim)]"
          >
            {f.name}
          </button>
        ))}
      </div>
    </div>
  );
}

function FacetPanel({ id, grade }: { id: FacetId; grade: number }) {
  const f = facets[id];
  const linked = metrics.filter((m) => m.facet === id);
  const linkedHits = f.hits.map((h) => hitsById[h as keyof typeof hitsById]);
  return (
    <div>
      <span
        className="inline-flex items-center gap-2 rounded-full px-3 py-1 text-[11px] uppercase tracking-wider"
        style={{ backgroundColor: `${f.hue}26`, color: f.hue }}
      >
        <span
          className="size-2 rounded-full"
          style={{ backgroundColor: f.hue }}
          aria-hidden="true"
        />
        FAS facet · grade {grade}
      </span>
      <h2 className="mt-3 text-3xl">{f.name}</h2>
      <p className="mt-2 text-[var(--color-ink-dim)]">{f.blurb}</p>

      <Section label="Graded parameters">
        <ul className="space-y-1.5 text-[var(--color-ink-dim)]">
          {f.parameters.map((p) => (
            <li key={p} className="flex items-start gap-2">
              <span
                className="mt-1.5 size-1.5 rounded-full"
                style={{ backgroundColor: f.hue }}
                aria-hidden="true"
              />
              {p}
            </li>
          ))}
        </ul>
      </Section>

      <Section label="Severity ramp">
        <p className="mb-4 text-sm text-[var(--color-ink-dim)]">
          0 = None, 1 = Mild, 2 = Moderate, 3 = Severe. Severity is the opacity of the facet hue — outliers identify priorities.
        </p>
        <SeverityRamp hue={f.hue} />
      </Section>

      <Section label="HIT(s) that address this facet">
        <ul className="space-y-2">
          {linkedHits.map((h) => (
            <li
              key={h.id}
              className="rounded-md border hairline bg-[var(--color-surface-raised)] p-3"
            >
              <div className="flex items-center justify-between">
                <div className="text-sm font-medium">{h.name}</div>
                <span
                  className="size-2 rounded-full"
                  style={{ backgroundColor: h.hue }}
                  aria-hidden="true"
                />
              </div>
              <div className="mt-1 text-xs text-[var(--color-ink-dim)]">
                {h.region} · {h.blurb}
              </div>
            </li>
          ))}
        </ul>
      </Section>

      <Section label="v0.1 FaceMap metrics that quantify this facet">
        {linked.length === 0 ? (
          <p className="rounded-md border hairline bg-[var(--color-surface-raised)] p-3 text-sm text-[var(--color-ink-muted)]">
            Graded by direct observation. v0.1 of the FaceMap app does not yet
            quantify this facet — it is on the roadmap.
          </p>
        ) : (
          <ul className="space-y-2">
            {linked.map((m) => (
              <li
                key={m.id}
                className="rounded-md border hairline bg-[var(--color-surface-raised)] p-3"
              >
                <div className="text-sm font-medium">{m.name}</div>
                <div className="mt-1 text-xs text-[var(--color-ink-dim)]">
                  {m.summary}
                </div>
              </li>
            ))}
          </ul>
        )}
      </Section>
    </div>
  );
}

function Section({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <section className="mt-6">
      <p className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
        {label}
      </p>
      <div className="mt-2">{children}</div>
    </section>
  );
}
