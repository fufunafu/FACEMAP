export default function Loading() {
  return (
    <div className="container-page flex min-h-[40vh] items-center justify-center py-20">
      <div className="flex items-center gap-3 text-[var(--color-ink-muted)]">
        <span className="size-2 animate-pulse rounded-full bg-[var(--color-facet-symmetry)]" />
        <span className="num text-xs uppercase tracking-[0.2em]">Loading</span>
      </div>
    </div>
  );
}
