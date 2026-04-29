import Link from "next/link";
import { BrandMark } from "./brand-mark";
import { DisclaimerBanner } from "./disclaimer-banner";
import { ThemeToggle } from "./theme-toggle";

const NAV: Array<{ href: string; label: string }> = [
  { href: "/framework", label: "Framework" },
  { href: "/decision-aid", label: "Decision aid" },
  { href: "/app", label: "App" },
  { href: "/methodology", label: "Methodology" },
  { href: "/practitioners", label: "Practitioners" },
  { href: "/about", label: "About" },
];

export function NavBar() {
  return (
    <header className="sticky top-0 z-40 border-b hairline bg-[var(--color-canvas)]/80 backdrop-blur">
      <div className="container-page flex h-14 items-center justify-between gap-6">
        <Link href="/" className="flex items-center gap-2">
          <BrandMark />
          <span className="font-display text-lg tracking-tight">FaceMap</span>
        </Link>
        <nav aria-label="Primary" className="hidden items-center gap-6 md:flex">
          {NAV.map((n) => (
            <Link
              key={n.href}
              href={n.href}
              className="text-sm text-[var(--color-ink-dim)] transition hover:text-[var(--color-ink)]"
            >
              {n.label}
            </Link>
          ))}
        </nav>
        <div className="flex items-center gap-3">
          <ThemeToggle />
          <Link
            href="/access"
            className="rounded-[var(--radius-button)] bg-[var(--color-cta-bg)] px-4 py-2 text-sm font-medium text-[var(--color-cta-ink)] transition hover:opacity-90"
          >
            Get access
          </Link>
        </div>
      </div>
    </header>
  );
}

export function Footer() {
  return (
    <footer>
      <DisclaimerBanner />
      <div className="border-t hairline">
        <div className="container-page flex flex-col gap-6 py-10 md:flex-row md:items-start md:justify-between">
          <div className="flex items-center gap-3">
            <BrandMark size={20} />
            <p className="text-sm text-[var(--color-ink-dim)]">
              FaceMap · A planning aid for licensed practitioners.
            </p>
          </div>
          <nav aria-label="Footer" className="grid grid-cols-2 gap-x-10 gap-y-2 text-sm sm:grid-cols-3">
            {[
              { href: "/framework", label: "Framework" },
              { href: "/decision-aid", label: "Decision aid" },
              { href: "/app", label: "App" },
              { href: "/methodology", label: "Methodology" },
              { href: "/practitioners", label: "Practitioners" },
              { href: "/about", label: "About" },
              { href: "/access", label: "Get access" },
              { href: "/legal/disclaimer", label: "Disclaimer" },
              { href: "/legal/privacy", label: "Privacy" },
              { href: "/legal/terms", label: "Terms" },
            ].map((n) => (
              <Link
                key={n.href}
                href={n.href}
                className="text-[var(--color-ink-dim)] transition hover:text-[var(--color-ink)]"
              >
                {n.label}
              </Link>
            ))}
          </nav>
        </div>
        <div className="container-page pb-8 text-xs text-[var(--color-ink-muted)]">
          © {new Date().getFullYear()} FaceMap. Developed by Dr Andreas Nikolis and team.
        </div>
      </div>
    </footer>
  );
}

export function PageShell({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-dvh flex-col">
      <NavBar />
      <main className="flex-1">{children}</main>
      <Footer />
    </div>
  );
}
