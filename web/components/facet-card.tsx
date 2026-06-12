import type { Facet } from "@/content/fas";
import { hits as hitsById } from "@/content/hits";
import { cn } from "@/lib/cn";

export function FacetBadge({ facet }: { facet: Facet }) {
  return (
    <span
      className="inline-flex items-center gap-2 rounded-full border hairline px-3 py-1 text-[11px] uppercase tracking-wider text-[var(--color-ink-dim)]"
      style={{ borderColor: `${facet.hue}66` }}
    >
      <span
        className="size-2 rounded-full"
        style={{ backgroundColor: facet.hue }}
        aria-hidden="true"
      />
      {facet.name}
    </span>
  );
}

export function FacetCard({
  facet,
  className,
}: {
  facet: Facet;
  className?: string;
}) {
  const linkedHits = facet.hits.map((id) => hitsById[id as keyof typeof hitsById]);
  return (
    <article
      className={cn(
        "rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-6",
        className,
      )}
      style={{
        backgroundImage: `linear-gradient(180deg, ${facet.hue}14 0%, transparent 60%)`,
      }}
    >
      <FacetBadge facet={facet} />
      <h3 className="mt-4 text-2xl">{facet.name}</h3>
      <p className="mt-2 text-[var(--color-ink-dim)]">{facet.blurb}</p>

      <div className="mt-5">
        <p className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
          Graded parameters
        </p>
        <ul className="mt-2 space-y-1 text-sm text-[var(--color-ink-dim)]">
          {facet.parameters.map((p) => (
            <li key={p} className="flex items-start gap-2">
              <span
                className="mt-1.5 size-1.5 rounded-full"
                style={{ backgroundColor: facet.hue }}
                aria-hidden="true"
              />
              {p}
            </li>
          ))}
        </ul>
      </div>

      <div className="mt-5">
        <p className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
          Addressed by
        </p>
        <p className="mt-2 text-sm text-[var(--color-ink-dim)]">
          {linkedHits.map((h) => h.name).join(" · ")}
        </p>
      </div>

      <p className="mt-5 rounded-md border hairline bg-[var(--color-surface-raised)] p-3 text-xs text-[var(--color-ink-dim)]">
        {facet.quantifiedNote}
      </p>
    </article>
  );
}
