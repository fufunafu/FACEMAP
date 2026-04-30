import type { Metadata } from "next";
import { rList } from "@/content/range";

export const metadata: Metadata = {
  title: "Range — Relax · Refine · Refresh · Renew",
  description:
    "The Galderma Aesthetic Portfolio organised as four R's — neuromodulators, HA fillers (NASHA & OBT/XpresHAn), Skinboosters, and biostimulators (PLLA-SCA).",
};

const PRODUCTS = [
  { name: "HA", volume: "++++", laxity: "+", indications: "Localised", results: "Instant", lasting: "+++" },
  { name: "Sculptra", volume: "++", laxity: "++++", indications: "Overall", results: "Gradual", lasting: "++++" },
  { name: "Skinboosters", volume: "None", laxity: "+", indications: "Overall", results: "Instant", lasting: "++" },
  { name: "Neurotoxin A", volume: "None", laxity: "None", indications: "Localised", results: "Gradual", lasting: "++" },
];

export default function RangePage() {
  return (
    <>
      <section className="border-b hairline">
        <div className="container-page py-20">
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            Range
          </p>
          <h1 className="mt-4 max-w-3xl font-display text-5xl tracking-tight md:text-6xl">
            The four R&apos;s.
          </h1>
          <p className="mt-5 max-w-2xl text-[var(--color-ink-dim)]">
            Two complementary HA technologies (NASHA and OBT/XpresHAn) plus neuromodulators and biostimulators. Organised as four R&apos;s — Relax, Refine, Refresh, Renew — so the right product matches the right tissue need.
          </p>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-16">
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            {rList.map((r) => (
              <article
                key={r.id}
                className="flex h-full flex-col rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-6"
                style={{
                  backgroundImage: `linear-gradient(180deg, ${r.hue}1A 0%, transparent 60%)`,
                }}
              >
                <span
                  className="font-display text-6xl leading-none tracking-tight"
                  style={{ color: r.hue }}
                >
                  R
                </span>
                <h2 className="mt-3 font-display text-3xl tracking-tight">
                  {r.title}
                </h2>
                <p className="mt-2 text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
                  {r.family}
                </p>
                <p className="mt-4 flex-1 text-sm text-[var(--color-ink-dim)]">
                  {r.description}
                </p>
                <p className="mt-4 text-xs text-[var(--color-ink-muted)]">
                  {r.technology}
                </p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-16">
          <h2 className="font-display text-3xl tracking-tight md:text-4xl">
            Comparison.
          </h2>
          <p className="mt-3 max-w-2xl text-[var(--color-ink-dim)]">
            Adapted from Table 1 of Nikolis et al., 2024. Higher symbols indicate stronger effect (++++ = Extremely, +++ = Very, ++ = Moderately, + = Slightly).
          </p>
          <div className="mt-8 overflow-x-auto rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)]">
            <table className="w-full min-w-[640px] text-sm">
              <thead>
                <tr className="text-left text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
                  <th className="px-5 py-4">Product</th>
                  <th className="px-5 py-4">Volumisation</th>
                  <th className="px-5 py-4">Laxity treatment</th>
                  <th className="px-5 py-4">Indications</th>
                  <th className="px-5 py-4">Results</th>
                  <th className="px-5 py-4">Lasting</th>
                </tr>
              </thead>
              <tbody>
                {PRODUCTS.map((p) => (
                  <tr key={p.name} className="border-t hairline">
                    <td className="px-5 py-4 font-medium">{p.name}</td>
                    <td className="num px-5 py-4 text-[var(--color-ink-dim)]">{p.volume}</td>
                    <td className="num px-5 py-4 text-[var(--color-ink-dim)]">{p.laxity}</td>
                    <td className="px-5 py-4 text-[var(--color-ink-dim)]">{p.indications}</td>
                    <td className="px-5 py-4 text-[var(--color-ink-dim)]">{p.results}</td>
                    <td className="num px-5 py-4 text-[var(--color-ink-dim)]">{p.lasting}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <section>
        <div className="container-page py-16">
          <h2 className="font-display text-3xl tracking-tight md:text-4xl">
            NASHA vs OBT/XpresHAn.
          </h2>
          <div className="mt-8 grid gap-4 md:grid-cols-2">
            <article className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-6">
              <p className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
                NASHA
              </p>
              <h3 className="mt-2 font-display text-2xl">Lifting &amp; precision</h3>
              <p className="mt-3 text-sm text-[var(--color-ink-dim)]">
                Less crosslinking creates a higher G&apos; and firmer HA-gel — ideal for lifting capacity in areas of thicker tissue.
              </p>
            </article>
            <article className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-6">
              <p className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
                OBT / XpresHAn
              </p>
              <h3 className="mt-2 font-display text-2xl">Contour &amp; expression</h3>
              <p className="mt-3 text-sm text-[var(--color-ink-dim)]">
                More HA-crosslinking creates a lower G&apos;, softer, more flexible HA-gel — designed for contouring and natural movement with expression.
              </p>
            </article>
          </div>
        </div>
      </section>
    </>
  );
}
