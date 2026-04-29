"use client";

import { useState } from "react";
import { AestheticWheel } from "./aesthetic-wheel";
import { SeverityRamp } from "./severity-ramp";
import { domains, wheelOrder, type DomainId } from "@/content/domains";
import { metrics } from "@/content/metrics";

export function DecisionAidExplorer() {
  const [selected, setSelected] = useState<DomainId | null>("symmetry");

  return (
    <div className="grid gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,460px)] lg:items-start">
      <div className="flex justify-center">
        <AestheticWheel
          interactive
          value={selected}
          onValueChange={setSelected}
          size={520}
        />
      </div>

      <div
        role="tabpanel"
        aria-live="polite"
        className="rounded-[var(--radius-sheet)] border hairline bg-[var(--color-surface)] p-7"
      >
        {selected ? (
          <DomainPanel id={selected} />
        ) : (
          <Placeholder onPick={setSelected} />
        )}

        <div className="mt-8 flex flex-wrap gap-2 border-t hairline pt-5">
          {wheelOrder.map((id) => (
            <button
              key={id}
              onClick={() => setSelected(id)}
              className="rounded-full border hairline px-3 py-1 text-xs text-[var(--color-ink-dim)] transition hover:text-[var(--color-ink)]"
              style={{
                borderColor:
                  selected === id ? domains[id].hue : "rgba(255,255,255,0.12)",
                color: selected === id ? domains[id].hue : undefined,
              }}
            >
              {domains[id].name}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

function Placeholder({ onPick }: { onPick: (id: DomainId) => void }) {
  return (
    <div>
      <h2 className="text-2xl">Pick a quadrant</h2>
      <p className="mt-2 text-[var(--color-ink-dim)]">
        Click any quadrant of the wheel — or use the arrow keys — to see what it
        covers, which regions FaceMap can flag in it, and how severity is
        encoded.
      </p>
      <div className="mt-5 flex flex-wrap gap-2">
        {wheelOrder.map((id) => (
          <button
            key={id}
            onClick={() => onPick(id)}
            className="rounded-[var(--radius-button)] border hairline px-3 py-2 text-sm transition hover:border-white/30"
          >
            {domains[id].name}
          </button>
        ))}
      </div>
    </div>
  );
}

function DomainPanel({ id }: { id: DomainId }) {
  const d = domains[id];
  const linked = metrics.filter((m) => m.domain === id);
  return (
    <div>
      <span
        className="inline-flex items-center gap-2 rounded-full px-3 py-1 text-[11px] uppercase tracking-wider"
        style={{ backgroundColor: `${d.hue}22`, color: d.hue }}
      >
        <span
          className="size-2 rounded-full"
          style={{ backgroundColor: d.hue }}
          aria-hidden="true"
        />
        Quadrant {d.quadrant + 1}
      </span>
      <h2 className="mt-3 text-3xl">{d.name}</h2>
      <p className="mt-2 text-[var(--color-ink-dim)]">{d.blurb}</p>

      <Section label="Sub-concerns">
        <ul className="space-y-1.5 text-[var(--color-ink-dim)]">
          {d.subConcerns.map((c) => (
            <li key={c} className="flex items-start gap-2">
              <span
                className="mt-1.5 size-1.5 rounded-full"
                style={{ backgroundColor: d.hue }}
                aria-hidden="true"
              />
              {c}
            </li>
          ))}
        </ul>
      </Section>

      <Section label="Regions the app can flag in this quadrant">
        <p className="text-[var(--color-ink-dim)]">
          {d.exampleRegions.join(" · ")}
        </p>
      </Section>

      <Section label="Severity encoding">
        <p className="mb-4 text-sm text-[var(--color-ink-dim)]">
          Severity is the opacity of the domain hue — no separate red/amber/green ramp.
        </p>
        <SeverityRamp domain={id} />
      </Section>

      <Section label="v0.1 metrics in this quadrant">
        {linked.length === 0 ? (
          <p className="rounded-md border hairline bg-[var(--color-surface-raised)] p-3 text-sm text-[var(--color-ink-muted)]">
            None yet. Quantified metrics for this quadrant are on the v0.1 roadmap. The framework is published in full; v0.1 of the app measures the Symmetry &amp; proportions quadrant.
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
