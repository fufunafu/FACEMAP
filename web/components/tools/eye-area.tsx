"use client";

import Link from "next/link";
import { useState } from "react";

type Concern = "lines" | "hollow" | "lustre";
type Expression = "hyperdynamic" | "static";
type SkinTone = "lax" | "firm";

function decide(c: Concern, e: Expression, s: SkinTone) {
  // Bright Eyes wins when concern is structural / volumetric.
  // Glow on wins when concern is surface (lustre, fine lines on firm skin) and expression hyperdynamic.
  if (c === "hollow") return "bright-eyes";
  if (c === "lines" && e === "hyperdynamic") return "bright-eyes";
  if (c === "lustre") return "glow-on";
  if (c === "lines" && s === "firm") return "glow-on";
  if (c === "lines" && s === "lax") return "bright-eyes";
  return "glow-on";
}

export function EyeAreaDisambiguator() {
  const [concern, setConcern] = useState<Concern>("hollow");
  const [expression, setExpression] = useState<Expression>("static");
  const [skin, setSkin] = useState<SkinTone>("firm");

  const result = decide(concern, expression, skin);

  return (
    <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)] lg:items-start">
      <div className="space-y-6">
        <Field label="Primary concern">
          <Pills
            value={concern}
            onChange={(v) => setConcern(v as Concern)}
            options={[
              { v: "lines", l: "Fine lines / wrinkles" },
              { v: "hollow", l: "Hollowing / volume loss" },
              { v: "lustre", l: "Lustre / radiance" },
            ]}
          />
        </Field>
        <Field label="Expression dynamics">
          <Pills
            value={expression}
            onChange={(v) => setExpression(v as Expression)}
            options={[
              { v: "hyperdynamic", l: "Hyperdynamic" },
              { v: "static", l: "Static / minimal" },
            ]}
          />
        </Field>
        <Field label="Skin envelope">
          <Pills
            value={skin}
            onChange={(v) => setSkin(v as SkinTone)}
            options={[
              { v: "firm", l: "Firm" },
              { v: "lax", l: "Lax" },
            ]}
          />
        </Field>
      </div>

      <aside
        aria-live="polite"
        className="rounded-[var(--radius-sheet)] border hairline bg-[var(--color-surface)] p-7"
      >
        <p className="text-[11px] uppercase tracking-[0.18em] text-[var(--color-ink-muted)]">
          Recommended HIT
        </p>
        {result === "bright-eyes" ? (
          <ResultCard
            href="/hits/bright-eyes"
            title="Bright Eyes HIT™"
            hue="#F2C9A1"
            body="Periorbital, temporal, superior-anterior midface — open the eye area through volume and selective relaxation."
            why="Structural and volumetric concerns dominate. Hollowing and dynamic-line effacement are the targets."
          />
        ) : (
          <ResultCard
            href="/hits/glow-on"
            title="Glow on HIT™"
            hue="#C9BBEE"
            body="Skin radiance, prevention, biostimulation. Subtle results focused on longevity."
            why="Surface concerns dominate. Skin quality and prevention take precedence."
          />
        )}
        <p className="mt-4 text-[11px] text-[var(--color-ink-muted)]">
          Both HITs may be combined — this picker resolves the dominant focus this visit.
        </p>
      </aside>
    </div>
  );
}

function ResultCard({
  href,
  title,
  hue,
  body,
  why,
}: {
  href: string;
  title: string;
  hue: string;
  body: string;
  why: string;
}) {
  return (
    <div
      className="mt-3 rounded-[var(--radius-card)] border hairline bg-[var(--color-surface-raised)] p-5"
      style={{
        borderColor: hue,
        backgroundImage: `linear-gradient(180deg, ${hue}1A 0%, transparent 65%)`,
      }}
    >
      <Link
        href={href}
        className="font-display text-2xl underline-offset-4 hover:underline"
        style={{ color: hue }}
      >
        {title}
      </Link>
      <p className="mt-2 text-sm text-[var(--color-ink-dim)]">{body}</p>
      <p className="mt-3 text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
        Why
      </p>
      <p className="mt-1 text-xs text-[var(--color-ink-dim)]">{why}</p>
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <p className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
        {label}
      </p>
      <div className="mt-2">{children}</div>
    </div>
  );
}

function Pills<T extends string>({
  value,
  onChange,
  options,
}: {
  value: T;
  onChange: (v: T) => void;
  options: Array<{ v: T; l: string }>;
}) {
  return (
    <div className="flex flex-wrap gap-2">
      {options.map((o) => {
        const active = value === o.v;
        return (
          <button
            key={o.v}
            onClick={() => onChange(o.v)}
            className="rounded-[var(--radius-button)] border hairline px-3 py-2 text-sm transition"
            style={{
              borderColor: active
                ? "var(--color-ink)"
                : "var(--color-hairline)",
              backgroundColor: active
                ? "color-mix(in srgb, var(--color-ink) 8%, transparent)"
                : "transparent",
              color: active ? "var(--color-ink)" : "var(--color-ink-dim)",
            }}
          >
            {o.l}
          </button>
        );
      })}
    </div>
  );
}
