import Link from "next/link";
import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { hits, hitOrder, type HitId } from "@/content/hits";
import { facets as facetsById } from "@/content/fas";
import { rs as rsById } from "@/content/range";

export function generateStaticParams() {
  return hitOrder.map((id) => ({ id }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ id: string }>;
}): Promise<Metadata> {
  const { id } = await params;
  const hit = hits[id as HitId];
  if (!hit) return {};
  return {
    title: hit.name,
    description: hit.blurb,
  };
}

export default async function HitDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const hit = hits[id as HitId];
  if (!hit) return notFound();

  return (
    <>
      <section
        className="border-b hairline"
        style={{
          backgroundImage: `linear-gradient(180deg, ${hit.hue}1F 0%, transparent 60%)`,
        }}
      >
        <div className="container-page py-20">
          <p
            className="text-[11px] uppercase tracking-[0.2em]"
            style={{ color: hit.hue }}
          >
            {hit.region}
          </p>
          <h1 className="mt-4 max-w-3xl font-display text-5xl tracking-tight md:text-6xl">
            {hit.name}
          </h1>
          <p className="mt-5 max-w-2xl text-lg text-[var(--color-ink-dim)]">
            {hit.blurb}
          </p>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-16">
          <div className="grid gap-12 lg:grid-cols-[minmax(0,2fr)_minmax(0,1fr)]">
            <article>
              <h2 className="font-display text-3xl tracking-tight">Approach</h2>
              <p className="mt-4 text-[var(--color-ink-dim)]">
                {hit.description}
              </p>

              <h3 className="mt-10 text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
                Anatomical areas
              </h3>
              <ul className="mt-3 grid grid-cols-1 gap-2 text-sm text-[var(--color-ink-dim)] sm:grid-cols-2">
                {hit.areas.map((a) => (
                  <li
                    key={a}
                    className="flex items-start gap-2 rounded-md border hairline bg-[var(--color-surface)] p-3"
                  >
                    <span
                      className="mt-1.5 size-1.5 shrink-0 rounded-full"
                      style={{ backgroundColor: hit.hue }}
                      aria-hidden="true"
                    />
                    {a}
                  </li>
                ))}
              </ul>

              <h3 className="mt-10 text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
                Suggested products from the Galderma portfolio
              </h3>
              <ul className="mt-3 space-y-2">
                {hit.products.map((p) => (
                  <li
                    key={`${p.name}-${p.use}`}
                    className="rounded-md border hairline bg-[var(--color-surface)] p-3"
                  >
                    <div className="flex flex-wrap items-baseline gap-2">
                      <span className="text-sm font-medium">{p.name}</span>
                      {p.brand ? (
                        <span className="text-xs text-[var(--color-ink-muted)]">
                          · {p.brand}
                        </span>
                      ) : null}
                    </div>
                    <p className="mt-1 text-xs text-[var(--color-ink-dim)]">
                      {p.use}
                    </p>
                  </li>
                ))}
              </ul>
              <p className="mt-3 text-[11px] text-[var(--color-ink-muted)]">
                Adapted from Nikolis et al., Clin Cosmet Investig Dermatol 2024:17. Practitioner judgement is the final authority.
              </p>
            </article>

            <aside className="space-y-6">
              <div className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-5">
                <p className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
                  FAS facets addressed
                </p>
                <ul className="mt-3 space-y-2">
                  {hit.facets.map((f) => {
                    const facet = facetsById[f];
                    return (
                      <li
                        key={f}
                        className="flex items-center justify-between rounded-md border hairline bg-[var(--color-surface-raised)] p-3"
                      >
                        <span className="text-sm">{facet.name}</span>
                        <span
                          className="size-2 rounded-full"
                          style={{ backgroundColor: facet.hue }}
                          aria-hidden="true"
                        />
                      </li>
                    );
                  })}
                </ul>
              </div>

              <div className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-5">
                <p className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
                  Range used
                </p>
                <ul className="mt-3 space-y-2">
                  {hit.rs.map((r) => {
                    const range = rsById[r];
                    return (
                      <li
                        key={r}
                        className="rounded-md border hairline bg-[var(--color-surface-raised)] p-3"
                      >
                        <div className="flex items-baseline gap-2">
                          <span
                            className="font-display text-lg"
                            style={{ color: range.hue }}
                          >
                            R
                          </span>
                          <span className="text-sm font-medium">{range.title}</span>
                        </div>
                        <p className="mt-1 text-xs text-[var(--color-ink-dim)]">
                          {range.family}
                        </p>
                      </li>
                    );
                  })}
                </ul>
              </div>
            </aside>
          </div>
        </div>
      </section>

      {hit.id === "kiss-and-smile" ? (
        <section className="border-b hairline">
          <div className="container-page py-12">
            <p className="text-sm text-[var(--color-ink-dim)]">
              The Kiss &amp; Smile HIT uses a site-specific FAS variant for lips —{" "}
              <Link
                href="/lip-assessment"
                className="text-[var(--color-ink)] underline-offset-4 hover:underline"
              >
                the Lip Assessment Scale (LAS)
              </Link>
              .
            </p>
          </div>
        </section>
      ) : null}

      <section>
        <div className="container-page py-12">
          <Link
            href="/hits"
            className="text-sm text-[var(--color-ink-dim)] transition hover:text-[var(--color-ink)]"
          >
            ← All HITs
          </Link>
        </div>
      </section>
    </>
  );
}
