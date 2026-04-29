import Link from "next/link";
import { AestheticWheel } from "@/components/aesthetic-wheel";
import { DomainCard } from "@/components/domain-card";
import { domainsList } from "@/content/domains";

export default function HomePage() {
  return (
    <>
      <Hero />
      <FrameworkTeaser />
      <Workflow />
      <Built />
      <CTA />
    </>
  );
}

function Hero() {
  return (
    <section className="relative overflow-hidden border-b hairline">
      <div className="container-page grid gap-10 py-20 lg:grid-cols-[minmax(0,1fr)_auto] lg:items-center lg:gap-16 lg:py-28">
        <div>
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            For licensed aesthetic practitioners
          </p>
          <h1 className="mt-5 text-balance font-display text-5xl leading-[1.05] tracking-tight md:text-6xl lg:text-7xl">
            Facial aesthetic analysis,{" "}
            <span className="italic text-[var(--color-domain-symmetry)]">
              computed.
            </span>
          </h1>
          <p className="mt-6 max-w-xl text-balance text-lg text-[var(--color-ink-dim)]">
            FaceMap captures a 3D face mesh on iPhone, evaluates Dr Andreas
            Nikolis&apos;s four-domain Facial Aesthetic framework, and flags
            anatomical regions on an interactive 3D model — so you can plan
            with the geometry already done.
          </p>
          <div className="mt-8 flex flex-wrap items-center gap-3">
            <Link
              href="/access"
              className="rounded-[var(--radius-button)] bg-[var(--color-cta-bg)] px-5 py-3 text-sm font-medium text-[var(--color-cta-ink)] transition hover:opacity-90"
            >
              Get the app
            </Link>
            <Link
              href="/decision-aid"
              className="rounded-[var(--radius-button)] border hairline px-5 py-3 text-sm transition hover:border-white/40"
            >
              Try the decision aid
            </Link>
          </div>
          <p className="mt-6 max-w-md text-xs text-[var(--color-ink-muted)]">
            A planning aid for licensed practitioners. Not a medical device.
            Does not diagnose, prescribe, or recommend treatment.
          </p>
        </div>

        <div className="flex justify-center lg:justify-end">
          <AestheticWheel size={420} />
        </div>
      </div>
    </section>
  );
}

function FrameworkTeaser() {
  return (
    <section className="border-b hairline">
      <div className="container-page py-20">
        <div className="flex flex-col gap-2">
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            The framework
          </p>
          <h2 className="font-display text-4xl tracking-tight md:text-5xl">
            Four domains. One language for the aesthetic face.
          </h2>
          <p className="mt-3 max-w-2xl text-[var(--color-ink-dim)]">
            Dr Nikolis&apos;s four-domain framework gives every observation a
            home. FaceMap evaluates each domain in turn and reports its findings
            on the same wheel published in the literature.
          </p>
        </div>
        <div className="mt-12 grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          {domainsList.map((d) => (
            <DomainCard key={d.id} domain={d} />
          ))}
        </div>
        <div className="mt-10">
          <Link
            href="/framework"
            className="text-sm text-[var(--color-ink-dim)] transition hover:text-[var(--color-ink)]"
          >
            Explore each domain →
          </Link>
        </div>
      </div>
    </section>
  );
}

const STEPS = [
  {
    n: "01",
    title: "Capture",
    body:
      "Use the iPhone TrueDepth camera to capture a high-fidelity 3D face mesh in seconds. On-device, no cloud upload.",
  },
  {
    n: "02",
    title: "Analyse",
    body:
      "FaceMap evaluates five geometric metrics — facial thirds, fifths, golden ratio, canthal tilt, and surface asymmetry — and flags anatomical regions.",
  },
  {
    n: "03",
    title: "Plan",
    body:
      "Severity is encoded as opacity of the domain hue, layered onto the 3D model. Save the case under a non-PII patient code.",
  },
];

function Workflow() {
  return (
    <section className="border-b hairline">
      <div className="container-page py-20">
        <div className="flex flex-col gap-2">
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            How it works
          </p>
          <h2 className="font-display text-4xl tracking-tight md:text-5xl">
            Capture &middot; Analyse &middot; Plan.
          </h2>
        </div>
        <ol className="mt-10 grid gap-6 md:grid-cols-3">
          {STEPS.map((s) => (
            <li
              key={s.n}
              className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-6"
            >
              <span className="num text-[11px] tracking-widest text-[var(--color-ink-muted)]">
                {s.n}
              </span>
              <h3 className="mt-3 text-2xl">{s.title}</h3>
              <p className="mt-2 text-sm text-[var(--color-ink-dim)]">
                {s.body}
              </p>
            </li>
          ))}
        </ol>
      </div>
    </section>
  );
}

function Built() {
  return (
    <section className="border-b hairline">
      <div className="container-page grid gap-10 py-20 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)] lg:items-center">
        <div>
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            Built by clinicians
          </p>
          <h2 className="mt-3 font-display text-4xl tracking-tight md:text-5xl">
            By Dr Andreas Nikolis &amp; team.
          </h2>
          <p className="mt-4 text-[var(--color-ink-dim)]">
            FaceMap implements the four-domain Facial Aesthetic framework
            developed by Dr Andreas Nikolis and his team. Every metric, every
            colour, every disclaimer was designed to fit the way clinicians
            already work.
          </p>
          <Link
            href="/about"
            className="mt-6 inline-block text-sm text-[var(--color-ink-dim)] transition hover:text-[var(--color-ink)]"
          >
            About the team →
          </Link>
        </div>
        <blockquote className="rounded-[var(--radius-sheet)] border hairline bg-[var(--color-surface)] p-8">
          <p className="font-display text-2xl leading-snug text-[var(--color-ink)]">
            &ldquo;Geometric measurement should be a starting point, not a
            shortcut. FaceMap does the math so the practitioner can focus on the
            judgment.&rdquo;
          </p>
          <footer className="mt-5 text-sm text-[var(--color-ink-dim)]">
            — Dr Andreas Nikolis
          </footer>
        </blockquote>
      </div>
    </section>
  );
}

function CTA() {
  return (
    <section>
      <div className="container-page py-20 text-center">
        <h2 className="mx-auto max-w-2xl font-display text-4xl tracking-tight md:text-5xl">
          Ready to put the geometry on autopilot?
        </h2>
        <p className="mx-auto mt-4 max-w-xl text-[var(--color-ink-dim)]">
          FaceMap runs on iPhone with a TrueDepth front camera. Practitioner
          access required.
        </p>
        <div className="mt-8 flex justify-center gap-3">
          <Link
            href="/access"
            className="rounded-[var(--radius-button)] bg-[var(--color-cta-bg)] px-5 py-3 text-sm font-medium text-[var(--color-cta-ink)] transition hover:opacity-90"
          >
            Get access
          </Link>
          <Link
            href="/methodology"
            className="rounded-[var(--radius-button)] border hairline px-5 py-3 text-sm transition hover:border-white/40"
          >
            Read the methodology
          </Link>
        </div>
      </div>
    </section>
  );
}
