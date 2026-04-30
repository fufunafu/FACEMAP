import Link from "next/link";
import { PageShell } from "@/components/site-chrome";

export default function NotFound() {
  return (
    <PageShell>
      <section className="container-page flex min-h-[60vh] flex-col items-center justify-center py-24 text-center">
        <p className="font-display text-7xl tracking-tight text-[var(--color-ink-dim)]">
          404
        </p>
        <h1 className="mt-6 font-display text-4xl tracking-tight md:text-5xl">
          The radar didn&apos;t find this page.
        </h1>
        <p className="mt-4 max-w-md text-[var(--color-ink-dim)]">
          The route doesn&apos;t exist or has moved. Try the AART-HIT methodology, the FAS, or the decision aid.
        </p>
        <div className="mt-8 flex flex-wrap justify-center gap-3">
          <Link
            href="/"
            className="rounded-[var(--radius-button)] bg-[var(--color-cta-bg)] px-5 py-3 text-sm font-medium text-[var(--color-cta-ink)] transition hover:opacity-90"
          >
            Home
          </Link>
          <Link
            href="/decision-aid"
            className="rounded-[var(--radius-button)] border hairline px-5 py-3 text-sm transition hover:border-[var(--color-ink-dim)]"
          >
            Decision aid
          </Link>
        </div>
      </section>
    </PageShell>
  );
}
