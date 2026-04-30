import Link from "next/link";

export function ToolHeader({
  title,
  resolves,
  hue,
}: {
  title: string;
  resolves: string;
  hue: string;
}) {
  return (
    <section className="border-b hairline">
      <div className="container-page py-10 md:py-12">
        <Link
          href="/tools"
          className="text-sm text-[var(--color-ink-dim)] transition hover:text-[var(--color-ink)]"
        >
          ← All decision aids
        </Link>
        <span
          className="mt-6 inline-flex items-center gap-2 rounded-full px-3 py-1 text-[11px] uppercase tracking-[0.18em]"
          style={{ backgroundColor: `${hue}24`, color: hue }}
        >
          <span
            className="size-2 rounded-full"
            style={{ backgroundColor: hue }}
            aria-hidden="true"
          />
          Decision aid
        </span>
        <h1 className="mt-4 font-display text-4xl tracking-tight md:text-5xl">
          {title}
        </h1>
        <p className="mt-3 max-w-2xl text-[var(--color-ink-dim)]">
          Resolves: {resolves}
        </p>
        <p className="mt-2 max-w-2xl text-xs text-[var(--color-ink-muted)]">
          Educational only. Not a clinical recommendation.
        </p>
      </div>
    </section>
  );
}
