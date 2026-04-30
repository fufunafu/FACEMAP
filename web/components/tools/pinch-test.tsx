"use client";

import { useState } from "react";

interface Q {
  id: string;
  prompt: string;
  /** "Yes" implies firmer skin (toward shape & lift). "No" implies laxity (toward firm & lift). */
  yesMeansFirm: boolean;
}

const QUESTIONS: Q[] = [
  {
    id: "pinch",
    prompt: "When you pinch the cheek skin, does it spring back quickly?",
    yesMeansFirm: true,
  },
  {
    id: "slide",
    prompt: "On the slide test, does the skin glide easily over the bone?",
    yesMeansFirm: false,
  },
  {
    id: "jowls",
    prompt: "Are jowls visible at rest?",
    yesMeansFirm: false,
  },
  {
    id: "hollow",
    prompt: "Is there visible midface hollowing?",
    yesMeansFirm: true,
  },
];

type Answer = "yes" | "no" | null;

export function PinchTest() {
  const [answers, setAnswers] = useState<Record<string, Answer>>({});

  const score = QUESTIONS.reduce((s, q) => {
    const a = answers[q.id];
    if (a === null || a === undefined) return s;
    const firm = (a === "yes") === q.yesMeansFirm;
    return s + (firm ? 1 : -1);
  }, 0);

  const answered = QUESTIONS.every((q) => answers[q.id] === "yes" || answers[q.id] === "no");
  const archetype = !answered ? null : score > 0 ? "shape" : "firm";

  return (
    <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)] lg:items-start">
      <ol className="space-y-4">
        {QUESTIONS.map((q, i) => (
          <li
            key={q.id}
            className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-5"
          >
            <p className="num text-[11px] uppercase tracking-[0.18em] text-[var(--color-ink-muted)]">
              Q{String(i + 1).padStart(2, "0")}
            </p>
            <p className="mt-2 text-base">{q.prompt}</p>
            <div className="mt-4 flex gap-2">
              {(["yes", "no"] as const).map((v) => {
                const active = answers[q.id] === v;
                return (
                  <button
                    key={v}
                    onClick={() => setAnswers((p) => ({ ...p, [q.id]: v }))}
                    className="rounded-[var(--radius-button)] border hairline px-4 py-2 text-sm transition"
                    style={{
                      borderColor: active
                        ? "var(--color-ink)"
                        : "var(--color-hairline)",
                      backgroundColor: active
                        ? "color-mix(in srgb, var(--color-ink) 8%, transparent)"
                        : "transparent",
                    }}
                  >
                    {v.charAt(0).toUpperCase() + v.slice(1)}
                  </button>
                );
              })}
            </div>
          </li>
        ))}
      </ol>

      <aside
        aria-live="polite"
        className="rounded-[var(--radius-sheet)] border hairline bg-[var(--color-surface)] p-7"
      >
        <p className="text-[11px] uppercase tracking-[0.18em] text-[var(--color-ink-muted)]">
          Patient archetype
        </p>
        {!answered ? (
          <>
            <p className="mt-3 font-display text-2xl tracking-tight text-[var(--color-ink-dim)]">
              {answers && Object.keys(answers).length > 0 ? "Almost there…" : "Awaiting answers"}
            </p>
            <p className="mt-2 text-sm text-[var(--color-ink-dim)]">
              Answer all four questions to resolve the archetype.
            </p>
          </>
        ) : archetype === "shape" ? (
          <Result
            title="Shape & lift"
            sub="Sufficient skin firmness, but volume loss"
            body="Treat the deep layers (3, 4, 5) to restore volume. Skin envelope can carry the lift."
            products={[
              { p: "HA-VOL", brand: "Restylane Volyme", use: "Medial midface deep volume" },
              { p: "HA-LYF", brand: "Restylane Lyft", use: "Zygoma anchoring (thick skin)" },
              { p: "HA-DEF", brand: "Restylane Defyne", use: "Zygoma (thin skin), pyriform" },
            ]}
          />
        ) : (
          <Result
            title="Firm & lift"
            sub="Skin laxity is dominant"
            body="Skin firmness must come first. Treat superficial layers (1, 2) and stimulate fibroblasts; volumise more conservatively."
            products={[
              { p: "PLLA-SCA", brand: "Sculptra", use: "Collagen biostimulation, skin firming" },
              { p: "HA-DEF", brand: "Restylane Defyne", use: "Superficial contour" },
              { p: "HA-LYF", brand: "Restylane Lyft", use: "Restrained deep support" },
            ]}
          />
        )}
      </aside>
    </div>
  );
}

function Result({
  title,
  sub,
  body,
  products,
}: {
  title: string;
  sub: string;
  body: string;
  products: Array<{ p: string; brand: string; use: string }>;
}) {
  return (
    <>
      <p className="mt-2 font-display text-3xl tracking-tight">{title}</p>
      <p className="text-sm text-[var(--color-ink-dim)]">{sub}</p>
      <p className="mt-4 text-sm text-[var(--color-ink-dim)]">{body}</p>
      <ul className="mt-5 space-y-2">
        {products.map((p) => (
          <li
            key={p.p}
            className="rounded-md border hairline bg-[var(--color-surface-raised)] p-3"
          >
            <p className="num text-sm font-medium">{p.p}</p>
            <p className="mt-1 text-xs text-[var(--color-ink-muted)]">
              {p.brand} · {p.use}
            </p>
          </li>
        ))}
      </ul>
    </>
  );
}
