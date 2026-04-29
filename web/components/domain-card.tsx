import type { Domain } from "@/content/domains";
import { cn } from "@/lib/cn";

export function DomainBadge({ domain }: { domain: Domain }) {
  return (
    <span
      className="inline-flex items-center gap-2 rounded-full border hairline px-3 py-1 text-[11px] uppercase tracking-wider text-[var(--color-ink-dim)]"
      style={{ borderColor: `${domain.hue}55` }}
    >
      <span
        className="size-2 rounded-full"
        style={{ backgroundColor: domain.hue }}
        aria-hidden="true"
      />
      {domain.name}
    </span>
  );
}

export function DomainCard({
  domain,
  className,
}: {
  domain: Domain;
  className?: string;
}) {
  return (
    <article
      className={cn(
        "rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-6",
        className,
      )}
      style={{
        backgroundImage: `linear-gradient(180deg, ${domain.hue}10 0%, transparent 60%)`,
      }}
    >
      <DomainBadge domain={domain} />
      <h3 className="mt-4 text-2xl">{domain.name}</h3>
      <p className="mt-2 text-[var(--color-ink-dim)]">{domain.blurb}</p>

      <div className="mt-5">
        <p className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
          Sub-concerns
        </p>
        <ul className="mt-2 space-y-1 text-sm text-[var(--color-ink-dim)]">
          {domain.subConcerns.map((c) => (
            <li key={c} className="flex items-start gap-2">
              <span
                className="mt-1.5 size-1.5 rounded-full"
                style={{ backgroundColor: domain.hue }}
                aria-hidden="true"
              />
              {c}
            </li>
          ))}
        </ul>
      </div>

      <div className="mt-5">
        <p className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
          Example regions
        </p>
        <p className="mt-2 text-sm text-[var(--color-ink-dim)]">
          {domain.exampleRegions.join(" · ")}
        </p>
      </div>

      {!domain.quantifiedInV1 ? (
        <p className="mt-5 rounded-md border hairline bg-[var(--color-surface-raised)] p-3 text-xs text-[var(--color-ink-muted)]">
          Quantified metrics in this quadrant are on the v0.1 roadmap. The framework is published in full; the iOS app currently measures the Symmetry & proportions quadrant.
        </p>
      ) : (
        <p className="mt-5 rounded-md border hairline bg-[var(--color-surface-raised)] p-3 text-xs text-[var(--color-ink-dim)]">
          Quantified in v0.1 of the iOS app via five geometric metrics.
        </p>
      )}
    </article>
  );
}
