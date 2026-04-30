import Link from "next/link";
import type { Hit } from "@/content/hits";
import { rs as rsById } from "@/content/range";
import { facets as facetsById } from "@/content/fas";
import { cn } from "@/lib/cn";

export function HitCard({
  hit,
  className,
  href,
}: {
  hit: Hit;
  className?: string;
  href?: string;
}) {
  const body = (
    <article
      className={cn(
        "group flex h-full flex-col rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-6 transition",
        href && "hover:border-[color-mix(in_srgb,var(--color-ink)_30%,transparent)]",
        className,
      )}
      style={{
        backgroundImage: `linear-gradient(180deg, ${hit.hue}1A 0%, transparent 65%)`,
      }}
    >
      <div className="flex items-center justify-between">
        <span
          className="text-[11px] uppercase tracking-[0.18em]"
          style={{ color: hit.hue }}
        >
          {hit.region}
        </span>
        <span
          className="size-2 rounded-full"
          style={{ backgroundColor: hit.hue }}
          aria-hidden="true"
        />
      </div>
      <h3 className="mt-3 font-display text-2xl tracking-tight">{hit.name}</h3>
      <p className="mt-2 flex-1 text-sm text-[var(--color-ink-dim)]">
        {hit.blurb}
      </p>

      <div className="mt-4 flex flex-wrap gap-1.5">
        {hit.facets.map((f) => (
          <span
            key={f}
            className="inline-flex items-center gap-1.5 rounded-full border hairline px-2 py-0.5 text-[10px] uppercase tracking-wider text-[var(--color-ink-dim)]"
            style={{ borderColor: `${facetsById[f].hue}55` }}
          >
            <span
              className="size-1.5 rounded-full"
              style={{ backgroundColor: facetsById[f].hue }}
              aria-hidden="true"
            />
            {facetsById[f].name}
          </span>
        ))}
      </div>

      <div className="mt-3 flex flex-wrap gap-1.5">
        {hit.rs.map((r) => (
          <span
            key={r}
            className="rounded-full bg-[var(--color-surface-raised)] px-2 py-0.5 text-[10px] uppercase tracking-wider text-[var(--color-ink-dim)]"
          >
            {rsById[r].title}
          </span>
        ))}
      </div>
    </article>
  );

  if (href) {
    return (
      <Link href={href} className="block h-full">
        {body}
      </Link>
    );
  }
  return body;
}
