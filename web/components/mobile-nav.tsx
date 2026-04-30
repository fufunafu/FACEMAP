"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { BrandMark } from "./brand-mark";

interface NavItem {
  href: string;
  label: string;
}

interface NavSection {
  title: string;
  items: NavItem[];
}

const SECTIONS: NavSection[] = [
  {
    title: "Methodology",
    items: [
      { href: "/aart-hit", label: "AART-HIT" },
      { href: "/fas", label: "FAS" },
      { href: "/anatomy", label: "Anatomy" },
      { href: "/methodology", label: "Methodology" },
    ],
  },
  {
    title: "Treatment",
    items: [
      { href: "/hits", label: "The five HITs" },
      { href: "/range", label: "Range" },
      { href: "/lip-assessment", label: "Lip assessment" },
    ],
  },
  {
    title: "Decision aids",
    items: [
      { href: "/tools", label: "All tools" },
      { href: "/decision-aid", label: "FAS facet decision aid" },
    ],
  },
  {
    title: "Product",
    items: [
      { href: "/app", label: "The app" },
      { href: "/practitioners", label: "For practitioners" },
      { href: "/about", label: "About" },
    ],
  },
];

export function MobileNav() {
  const [open, setOpen] = useState(false);
  const [theme, setTheme] = useState<"light" | "dark">("light");
  const pathname = usePathname();

  useEffect(() => {
    setOpen(false);
  }, [pathname]);

  useEffect(() => {
    const stored = (localStorage.getItem("facemap-theme") as
      | "light"
      | "dark"
      | null) ?? "light";
    setTheme(stored);
  }, []);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    document.addEventListener("keydown", onKey);
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = prev;
    };
  }, [open]);

  function toggleTheme() {
    const next: "light" | "dark" = theme === "light" ? "dark" : "light";
    setTheme(next);
    document.documentElement.setAttribute("data-theme", next);
    localStorage.setItem("facemap-theme", next);
  }

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        aria-label="Open menu"
        aria-expanded={open}
        aria-controls="mobile-nav-sheet"
        className="inline-flex size-10 items-center justify-center rounded-full border hairline text-[var(--color-ink-dim)] transition hover:text-[var(--color-ink)] md:hidden"
      >
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round">
          <path d="M3 7h18M3 12h18M3 17h18" />
        </svg>
      </button>

      {/* Backdrop */}
      <div
        aria-hidden="true"
        onClick={() => setOpen(false)}
        className="fixed inset-0 z-40 bg-black/50 backdrop-blur-sm transition-opacity duration-200 md:hidden"
        style={{
          opacity: open ? 1 : 0,
          pointerEvents: open ? "auto" : "none",
        }}
      />

      {/*
        Sheet — absolute layout so header/footer can never collapse the body.
        Header pinned at top:0, footer pinned at bottom:0, body fills the gap
        with explicit top/bottom offsets and its own scroll.
      */}
      <div
        id="mobile-nav-sheet"
        role="dialog"
        aria-modal="true"
        aria-hidden={!open}
        className="fixed top-0 bottom-0 right-0 z-50 w-full max-w-[360px] bg-[var(--color-canvas)] shadow-2xl transition-transform duration-300 ease-out md:hidden"
        style={{
          transform: open ? "translateX(0)" : "translateX(100%)",
          height: "100dvh",
        }}
      >
        {/* Header */}
        <div className="absolute inset-x-0 top-0 z-10 flex h-14 items-center justify-between border-b hairline bg-[var(--color-canvas)] px-5">
          <Link href="/" className="flex items-center gap-2" onClick={() => setOpen(false)}>
            <BrandMark size={22} />
            <span className="font-display text-base tracking-tight">FaceMap</span>
          </Link>
          <button
            type="button"
            onClick={() => setOpen(false)}
            aria-label="Close menu"
            className="inline-flex size-10 items-center justify-center rounded-full border hairline text-[var(--color-ink-dim)] transition hover:text-[var(--color-ink)]"
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round">
              <path d="M6 6l12 12M18 6L6 18" />
            </svg>
          </button>
        </div>

        {/* Body — absolute, scrollable, between header (56px) and footer (~140px) */}
        <nav
          aria-label="Mobile"
          className="absolute inset-x-0 overflow-y-auto overscroll-contain px-5 py-6"
          style={{ top: 56, bottom: 140 }}
        >
          {SECTIONS.map((section) => (
            <div key={section.title} className="mb-7 last:mb-0">
              <p className="text-[10px] uppercase tracking-[0.22em] text-[var(--color-ink-muted)]">
                {section.title}
              </p>
              <ul className="mt-3 space-y-0.5">
                {section.items.map((item) => {
                  const active = pathname === item.href;
                  return (
                    <li key={item.href}>
                      <Link
                        href={item.href}
                        className="flex min-h-[44px] items-center justify-between gap-3 rounded-md px-2 py-2 text-base font-display tracking-tight transition"
                        style={{
                          color: active ? "var(--color-ink)" : "var(--color-ink-dim)",
                          fontWeight: active ? 500 : 400,
                          backgroundColor: active
                            ? "color-mix(in srgb, var(--color-ink) 6%, transparent)"
                            : "transparent",
                        }}
                      >
                        <span>{item.label}</span>
                        {active ? (
                          <span
                            className="size-1.5 rounded-full"
                            style={{ backgroundColor: "var(--color-facet-symmetry)" }}
                            aria-hidden="true"
                          />
                        ) : null}
                      </Link>
                    </li>
                  );
                })}
              </ul>
            </div>
          ))}
        </nav>

        {/* Footer — pinned at bottom */}
        <div
          className="absolute inset-x-0 bottom-0 border-t hairline bg-[var(--color-canvas)] px-5 pb-6 pt-4"
          style={{ paddingBottom: "max(1.5rem, env(safe-area-inset-bottom))" }}
        >
          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={toggleTheme}
              className="inline-flex h-10 items-center gap-2 rounded-full border hairline px-3 text-xs uppercase tracking-wider text-[var(--color-ink-dim)] transition hover:text-[var(--color-ink)]"
              aria-label={`Switch to ${theme === "light" ? "dark" : "light"} mode`}
            >
              {theme === "light" ? (
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79Z" />
                </svg>
              ) : (
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
                  <circle cx="12" cy="12" r="4" />
                  <path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41" />
                </svg>
              )}
              {theme === "light" ? "Dark" : "Light"}
            </button>
            <Link
              href="/access"
              className="inline-flex h-10 flex-1 items-center justify-center rounded-[var(--radius-button)] bg-[var(--color-cta-bg)] px-4 text-sm font-medium text-[var(--color-cta-ink)]"
            >
              Get access
            </Link>
          </div>
          <div className="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-[11px] text-[var(--color-ink-muted)]">
            <Link href="/legal/disclaimer" className="hover:text-[var(--color-ink-dim)]">Disclaimer</Link>
            <Link href="/legal/privacy" className="hover:text-[var(--color-ink-dim)]">Privacy</Link>
            <Link href="/legal/terms" className="hover:text-[var(--color-ink-dim)]">Terms</Link>
          </div>
        </div>
      </div>
    </>
  );
}
