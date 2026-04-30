"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";

interface NavItem {
  href: string;
  label: string;
}

export function MobileNav({ items }: { items: NavItem[] }) {
  const [open, setOpen] = useState(false);
  const pathname = usePathname();

  useEffect(() => {
    setOpen(false);
  }, [pathname]);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    document.addEventListener("keydown", onKey);
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = "";
    };
  }, [open]);

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        aria-label="Open menu"
        aria-expanded={open}
        aria-controls="mobile-nav-sheet"
        className="inline-flex size-9 items-center justify-center rounded-full border hairline text-[var(--color-ink-dim)] transition hover:text-[var(--color-ink)] md:hidden"
      >
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round">
          <path d="M3 6h18M3 12h18M3 18h18" />
        </svg>
      </button>

      {open ? (
        <div
          id="mobile-nav-sheet"
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex flex-col bg-[var(--color-canvas)]"
        >
          <div className="container-page flex h-14 items-center justify-end">
            <button
              type="button"
              onClick={() => setOpen(false)}
              aria-label="Close menu"
              className="inline-flex size-9 items-center justify-center rounded-full border hairline text-[var(--color-ink-dim)] transition hover:text-[var(--color-ink)]"
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round">
                <path d="M6 6l12 12M18 6L6 18" />
              </svg>
            </button>
          </div>
          <nav aria-label="Mobile" className="container-page flex flex-1 flex-col justify-center gap-1 pb-20">
            {items.map((n) => (
              <Link
                key={n.href}
                href={n.href}
                className="border-b hairline py-4 font-display text-3xl tracking-tight transition hover:text-[var(--color-facet-symmetry)]"
              >
                {n.label}
              </Link>
            ))}
            <Link
              href="/access"
              className="mt-8 inline-flex w-fit rounded-[var(--radius-button)] bg-[var(--color-cta-bg)] px-5 py-3 text-sm font-medium text-[var(--color-cta-ink)]"
            >
              Get access
            </Link>
          </nav>
        </div>
      ) : null}
    </>
  );
}
