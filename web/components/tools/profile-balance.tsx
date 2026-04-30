"use client";

import { useState } from "react";

type Pt = { x: number; y: number } | null;
type Step = "nose" | "lip" | "chin" | "done";

const W = 480;
const H = 600;

const STEPS: Record<Step, string> = {
  nose: "Click the most anterior point of the nose tip (pronasale).",
  lip: "Click the most anterior point of the upper lip (labrale superius).",
  chin: "Click the most anterior point of the chin (pogonion).",
  done: "Done. Adjust by clicking again to reset.",
};

export function ProfileBalance() {
  const [nose, setNose] = useState<Pt>(null);
  const [lip, setLip] = useState<Pt>(null);
  const [chin, setChin] = useState<Pt>(null);

  function handleClick(e: React.MouseEvent<SVGSVGElement>) {
    const rect = e.currentTarget.getBoundingClientRect();
    const x = ((e.clientX - rect.left) / rect.width) * W;
    const y = ((e.clientY - rect.top) / rect.height) * H;
    if (!nose) return setNose({ x, y });
    if (!lip) return setLip({ x, y });
    if (!chin) return setChin({ x, y });
    setNose(null);
    setLip(null);
    setChin(null);
  }

  const step: Step = !nose ? "nose" : !lip ? "lip" : !chin ? "chin" : "done";

  // Compute Ricketts' line: line from nose tip → chin pogonion.
  // Distance of lip from that line, signed (positive = anterior to line, negative = posterior).
  let lipDelta: number | null = null;
  if (nose && lip && chin) {
    const dx = chin.x - nose.x;
    const dy = chin.y - nose.y;
    const len = Math.sqrt(dx * dx + dy * dy);
    if (len > 0) {
      // Cross product magnitude → distance with sign.
      lipDelta = ((lip.x - nose.x) * dy - (lip.y - nose.y) * dx) / len;
      // In our SVG, +x is right (anterior in a left-facing profile). For a generic
      // profile, we want positive delta = anterior; flip sign so the math reads
      // intuitively regardless of which way the silhouette faces.
      lipDelta = -lipDelta;
    }
  }

  const verdict = (() => {
    if (lipDelta === null) return null;
    const px = lipDelta;
    if (Math.abs(px) < 8) return { tone: "Balanced", body: "Lip lies close to Ricketts' line — balanced profile." };
    if (px > 0) return { tone: "Lips over-projected", body: "Lip falls anterior to the line. Consider whether chin under-projection is the cause." };
    return { tone: "Chin under-projected", body: "Lip falls posterior to the line — the chin / pogonion may need projection." };
  })();

  return (
    <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)] lg:items-start">
      <div>
        <p className="mb-3 text-sm text-[var(--color-ink-dim)]">
          {STEPS[step]}
        </p>
        <div className="overflow-hidden rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)]">
          <svg
            viewBox={`0 0 ${W} ${H}`}
            width="100%"
            height="auto"
            onClick={handleClick}
            role="application"
            aria-label="Profile silhouette — click to place nose, lip, and chin points"
            style={{ cursor: step === "done" ? "pointer" : "crosshair" }}
          >
            {/* Decorative profile silhouette. Stylised, not anatomically precise. */}
            <ProfileSilhouette />

            {/* Markers + line */}
            {nose ? (
              <Marker x={nose.x} y={nose.y} hue="#C9BBEE" label="Nose" />
            ) : null}
            {lip ? (
              <Marker x={lip.x} y={lip.y} hue="#E9B5E0" label="Lip" />
            ) : null}
            {chin ? (
              <Marker x={chin.x} y={chin.y} hue="#A6B4DD" label="Chin" />
            ) : null}

            {nose && chin ? (
              <line
                x1={nose.x}
                y1={nose.y}
                x2={chin.x}
                y2={chin.y}
                stroke="var(--color-ink)"
                strokeWidth={1.5}
                strokeDasharray="6 4"
              />
            ) : null}
          </svg>
        </div>
      </div>

      <aside
        aria-live="polite"
        className="rounded-[var(--radius-sheet)] border hairline bg-[var(--color-surface)] p-7"
      >
        <p className="text-[11px] uppercase tracking-[0.18em] text-[var(--color-ink-muted)]">
          Ricketts&apos; line
        </p>
        {!verdict ? (
          <p className="mt-3 text-sm text-[var(--color-ink-muted)]">
            Place the three points to evaluate the line. The line runs from nose tip to chin pogonion; the upper lip should sit close to it in a balanced profile.
          </p>
        ) : (
          <>
            <p className="mt-2 font-display text-3xl tracking-tight">
              {verdict.tone}
            </p>
            <p className="mt-3 text-sm text-[var(--color-ink-dim)]">
              {verdict.body}
            </p>
            <p className="mt-4 text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
              Lip displacement from line
            </p>
            <p className="num mt-1 text-2xl">
              {lipDelta!.toFixed(1)}
              <span className="ml-1 text-sm text-[var(--color-ink-muted)]">px</span>
            </p>
            <p className="mt-4 text-[11px] text-[var(--color-ink-muted)]">
              Quantitative offset on the rendered silhouette only — not in real units. Use as a directional indicator, not a measurement.
            </p>
          </>
        )}
      </aside>
    </div>
  );
}

function Marker({ x, y, hue, label }: { x: number; y: number; hue: string; label: string }) {
  return (
    <g>
      <circle cx={x} cy={y} r={9} fill={hue} stroke="var(--color-canvas)" strokeWidth={2} />
      <text
        x={x + 14}
        y={y + 4}
        fontSize={12}
        fontFamily="var(--font-display)"
        fill="var(--color-ink)"
      >
        {label}
      </text>
    </g>
  );
}

function ProfileSilhouette() {
  // Decorative, gestural left-facing profile. Built from a single bezier path.
  return (
    <>
      <rect width={W} height={H} fill="var(--color-surface-raised)" />
      <path
        d="M 130 80
           C 200 80, 240 160, 240 220
           C 240 250, 230 280, 240 300
           C 260 320, 290 320, 300 340
           C 320 360, 290 380, 280 400
           C 270 420, 290 440, 280 460
           C 270 480, 240 490, 230 510
           C 220 530, 240 555, 220 570
           L 110 570
           L 110 80 Z"
        fill="var(--color-surface)"
        stroke="var(--color-hairline)"
        strokeWidth={1}
      />
      <text
        x={W - 140}
        y={H - 16}
        fill="var(--color-ink-muted)"
        fontSize={11}
        fontFamily="var(--font-mono)"
      >
        decorative silhouette
      </text>
    </>
  );
}
