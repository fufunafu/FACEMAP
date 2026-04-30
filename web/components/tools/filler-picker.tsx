"use client";

import { useState } from "react";

type Skin = "thick" | "thin";
type Layer = "deep" | "superficial" | "lip-body" | "skin-surface";
type Goal = "lift" | "contour" | "fill-line" | "hydrate";

interface Suggestion {
  family: "NASHA" | "OBT" | "Skinboosters" | "Biostimulator";
  product: string;
  brand: string;
  why: string;
}

function suggest(skin: Skin, layer: Layer, goal: Goal): Suggestion {
  // Hydration goal short-circuits.
  if (goal === "hydrate" || layer === "skin-surface") {
    return {
      family: "Skinboosters",
      product: "HA-SBs",
      brand: "Skinboosters Vital / Vital Light",
      why: "Microdroplet HA for hydration, structure, and elasticity. Not a volumiser.",
    };
  }

  // Lip body — different rules.
  if (layer === "lip-body") {
    if (goal === "lift") {
      return {
        family: "NASHA",
        product: "HA-RES",
        brand: "Restylane",
        why: "Higher G′, more projection. Use when lip projection is the goal.",
      };
    }
    return {
      family: "OBT",
      product: "HA-KYS",
      brand: "Restylane Kysse",
      why: "Lower G′, more natural movement and contour. Default for the lip body.",
    };
  }

  // Lift goal at deep layer → NASHA family.
  if (goal === "lift" && layer === "deep") {
    return {
      family: "NASHA",
      product: "HA-LYF",
      brand: "Restylane Lyft",
      why: "Higher G′, firm gel — lifting capacity in deeper layers.",
    };
  }

  // Contour at deep layer with thin skin → HA-VOL (OBT, integrates well).
  if (goal === "contour" && layer === "deep" && skin === "thin") {
    return {
      family: "OBT",
      product: "HA-VOL",
      brand: "Restylane Volyme",
      why: "Soft, integrating gel for medial midface deep volume in thinner skin.",
    };
  }

  // Contour deep, thick skin → HA-LYF (NASHA) for definition.
  if (goal === "contour" && layer === "deep" && skin === "thick") {
    return {
      family: "NASHA",
      product: "HA-LYF",
      brand: "Restylane Lyft",
      why: "Firmer gel reads through thicker skin for clearer contour.",
    };
  }

  // Superficial line filling.
  if (goal === "fill-line" && layer === "superficial") {
    return {
      family: "OBT",
      product: "HA-REF",
      brand: "Restylane Refyne",
      why: "Soft, flexible gel for fine lines and subtle perioral correction.",
    };
  }

  // Superficial contour.
  if (goal === "contour" && layer === "superficial") {
    return {
      family: "OBT",
      product: "HA-DEF",
      brand: "Restylane Defyne",
      why: "Mid-firmness OBT — contour with movement at superficial / mid layers.",
    };
  }

  // Default fallback.
  return {
    family: "OBT",
    product: "HA-DEF",
    brand: "Restylane Defyne",
    why: "General-purpose OBT for contour with natural expression.",
  };
}

export function FillerPicker() {
  const [skin, setSkin] = useState<Skin>("thin");
  const [layer, setLayer] = useState<Layer>("deep");
  const [goal, setGoal] = useState<Goal>("lift");
  const result = suggest(skin, layer, goal);

  return (
    <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)] lg:items-start">
      <div className="space-y-6">
        <Field label="Skin thickness">
          <Pills
            value={skin}
            onChange={(v) => setSkin(v as Skin)}
            options={[
              { v: "thin", l: "Thin" },
              { v: "thick", l: "Thick" },
            ]}
          />
        </Field>
        <Field label="Target depth">
          <Pills
            value={layer}
            onChange={(v) => setLayer(v as Layer)}
            options={[
              { v: "skin-surface", l: "Skin surface" },
              { v: "superficial", l: "Superficial" },
              { v: "deep", l: "Deep / supraperiosteal" },
              { v: "lip-body", l: "Lip body" },
            ]}
          />
        </Field>
        <Field label="Goal">
          <Pills
            value={goal}
            onChange={(v) => setGoal(v as Goal)}
            options={[
              { v: "lift", l: "Lift / projection" },
              { v: "contour", l: "Contour with expression" },
              { v: "fill-line", l: "Fill a line" },
              { v: "hydrate", l: "Hydrate / restore quality" },
            ]}
          />
        </Field>
      </div>

      <aside
        aria-live="polite"
        className="rounded-[var(--radius-sheet)] border hairline bg-[var(--color-surface)] p-7"
      >
        <p className="text-[11px] uppercase tracking-[0.18em] text-[var(--color-ink-muted)]">
          Suggested family
        </p>
        <p className="mt-2 font-display text-3xl tracking-tight">
          {result.family}
        </p>
        <div className="mt-6 rounded-md border hairline bg-[var(--color-surface-raised)] p-4">
          <p className="num text-sm font-medium">{result.product}</p>
          <p className="mt-1 text-xs text-[var(--color-ink-dim)]">
            {result.brand}
          </p>
          <p className="mt-3 text-sm text-[var(--color-ink-dim)]">
            {result.why}
          </p>
        </div>
        <p className="mt-4 text-[11px] text-[var(--color-ink-muted)]">
          NASHA = higher G′, lifting/precision. OBT/XpresHAn = lower G′, contour with movement.
        </p>
      </aside>
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
