import type { Metric } from "@/content/metrics";
import { facets } from "@/content/fas";

export function MetricExplainer({ metric }: { metric: Metric }) {
  const facet = facets[metric.facet];
  return (
    <article className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-6">
      <div className="flex items-center justify-between gap-4">
        <h3 className="text-xl">{metric.name}</h3>
        <span
          className="inline-flex items-center gap-2 rounded-full border hairline px-2 py-0.5 text-[10px] uppercase tracking-wider text-[var(--color-ink-dim)]"
          style={{ borderColor: `${facet.hue}55` }}
        >
          <span
            className="size-1.5 rounded-full"
            style={{ backgroundColor: facet.hue }}
            aria-hidden="true"
          />
          {facet.name}
        </span>
      </div>
      <p className="mt-2 text-sm text-[var(--color-ink-dim)]">
        {metric.summary}
      </p>
      <p className="mt-3 text-sm text-[var(--color-ink-dim)]">
        {metric.description}
      </p>

      <dl className="mt-5 grid grid-cols-1 gap-3 text-sm sm:grid-cols-2">
        <div>
          <dt className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
            Target
          </dt>
          <dd className="num mt-1 text-[var(--color-ink)]">{metric.target}</dd>
        </div>
        <div>
          <dt className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
            Can flag
          </dt>
          <dd className="mt-1 text-[var(--color-ink-dim)]">
            {metric.flags.join(" · ")}
          </dd>
        </div>
      </dl>
    </article>
  );
}
