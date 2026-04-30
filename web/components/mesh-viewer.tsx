"use client";

import { Suspense } from "react";
import dynamic from "next/dynamic";

/**
 * Mesh viewer for the FaceMap sample face. Lazy-loaded so the three.js
 * runtime is only sent to the browser when the viewer actually mounts.
 *
 * Usage:
 *   <MeshViewer hasMesh={true} src="/sample-face.glb" />   // real
 *   <MeshViewer hasMesh={false} />                          // placeholder
 *
 * Drop a .glb at web/public/sample-face.glb and flip `hasMesh` to true to
 * activate. Until then the placeholder card renders with no three.js cost.
 */

const MeshCanvas = dynamic(() => import("./mesh-canvas").then((m) => m.MeshCanvas), {
  ssr: false,
  loading: () => <Loading />,
});

export function MeshViewer({
  hasMesh,
  src = "/sample-face.glb",
  className,
}: {
  hasMesh: boolean;
  src?: string;
  className?: string;
}) {
  return (
    <div
      className={`relative aspect-[4/3] w-full overflow-hidden rounded-[var(--radius-sheet)] border hairline bg-[var(--color-surface)] ${className ?? ""}`}
      role="region"
      aria-label="3D facial mesh viewer"
    >
      {hasMesh ? (
        <Suspense fallback={<Loading />}>
          <MeshCanvas src={src} />
        </Suspense>
      ) : (
        <Placeholder />
      )}
    </div>
  );
}

function Loading() {
  return (
    <div className="absolute inset-0 flex items-center justify-center text-[var(--color-ink-muted)]">
      <div className="flex items-center gap-3">
        <span className="size-2 animate-pulse rounded-full bg-[var(--color-facet-symmetry)]" />
        <span className="num text-xs uppercase tracking-[0.2em]">Loading mesh</span>
      </div>
    </div>
  );
}

function Placeholder() {
  // Decorative gradient + iconography, no three.js cost.
  return (
    <div className="absolute inset-0 flex flex-col items-center justify-center gap-5 p-8 text-center">
      <svg width="120" height="120" viewBox="0 0 120 120" aria-hidden="true">
        <defs>
          <radialGradient id="mesh-gradient" cx="50%" cy="40%" r="60%">
            <stop offset="0%" stopColor="#C9BBEE" stopOpacity="0.6" />
            <stop offset="60%" stopColor="#A6B4DD" stopOpacity="0.25" />
            <stop offset="100%" stopColor="#7A8094" stopOpacity="0" />
          </radialGradient>
        </defs>
        <ellipse cx="60" cy="62" rx="36" ry="46" fill="url(#mesh-gradient)" />
        <g stroke="rgba(255,255,255,0.18)" fill="none">
          {Array.from({ length: 8 }).map((_, i) => (
            <ellipse
              key={i}
              cx="60"
              cy="62"
              rx={36 - i * 4}
              ry={46 - i * 5}
              strokeWidth="0.6"
            />
          ))}
        </g>
        <g stroke="rgba(255,255,255,0.18)" fill="none">
          {Array.from({ length: 9 }).map((_, i) => (
            <line
              key={i}
              x1="60"
              y1="16"
              x2={24 + i * 9}
              y2="108"
              strokeWidth="0.6"
              transform={`rotate(${(i - 4) * 8} 60 62)`}
            />
          ))}
        </g>
      </svg>
      <p className="text-sm text-[var(--color-ink-dim)]">
        Sample 3D mesh viewer coming soon — embedded direct from the iOS app&apos;s TrueDepth capture.
      </p>
    </div>
  );
}
