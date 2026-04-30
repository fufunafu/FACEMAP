import Image from "next/image";

/**
 * iPhone bezel that wraps a screenshot. Designed for 3:2 portrait aspect
 * (iPhone 15 Pro is ~393:852 ≈ 1:2.17) but renders as a CSS-sized box so
 * any portrait image will look correct.
 *
 * Pass `src` to render a real screenshot. Pass `placeholder` to render a
 * neutral gradient that matches the app's dark canvas.
 */

export interface PhoneFrameProps {
  /** Path under /public, e.g. "/screenshots/fas-radar.png" */
  src?: string;
  alt?: string;
  /** Width of the entire frame in px (height auto-derives at 1:2.17). */
  width?: number;
  /** Set true to render a stylised placeholder instead of an image. */
  placeholder?: boolean;
  /** Optional caption rendered under the frame. */
  caption?: string;
  priority?: boolean;
}

const ASPECT = 2.17; // iPhone 15-class ratio (height ÷ width)

export function PhoneFrame({
  src,
  alt,
  width = 280,
  placeholder = false,
  caption,
  priority,
}: PhoneFrameProps) {
  const height = Math.round(width * ASPECT);
  const innerW = width - 16;
  const innerH = height - 16;
  return (
    <figure className="flex flex-col items-center gap-3">
      <div
        className="relative shrink-0 rounded-[44px] border bg-black p-2"
        style={{
          width,
          height,
          borderColor: "rgba(255,255,255,0.08)",
          boxShadow: "0 30px 60px rgba(0,0,0,0.45)",
        }}
      >
        {/* Notch / Dynamic Island */}
        <div
          className="absolute left-1/2 top-2 z-10 h-6 w-24 -translate-x-1/2 rounded-full bg-black"
          aria-hidden="true"
        />
        <div
          className="relative overflow-hidden rounded-[36px]"
          style={{ width: innerW, height: innerH }}
        >
          {placeholder || !src ? (
            <PlaceholderScreen />
          ) : (
            <Image
              src={src}
              alt={alt ?? ""}
              width={innerW}
              height={innerH}
              priority={priority}
              className="h-full w-full object-cover"
            />
          )}
        </div>
      </div>
      {caption ? (
        <figcaption className="max-w-[260px] text-center text-xs text-[var(--color-ink-muted)]">
          {caption}
        </figcaption>
      ) : null}
    </figure>
  );
}

function PlaceholderScreen() {
  return (
    <div
      className="flex h-full w-full flex-col justify-between bg-black p-5"
      aria-label="App screenshot placeholder"
    >
      <div className="flex justify-between text-[10px] text-white/60">
        <span className="num">9:41</span>
        <span>FaceMap</span>
      </div>
      <div className="flex flex-1 items-center justify-center">
        <svg width="180" height="180" viewBox="0 0 200 200" aria-hidden="true">
          {[1, 2, 3].map((i) => (
            <circle
              key={i}
              cx="100"
              cy="100"
              r={(i / 3) * 78}
              fill="none"
              stroke="rgba(255,255,255,0.12)"
              strokeWidth="1"
            />
          ))}
          {Array.from({ length: 5 }).map((_, i) => {
            const a = -Math.PI / 2 + (i * 2 * Math.PI) / 5;
            return (
              <line
                key={i}
                x1="100"
                y1="100"
                x2={100 + 78 * Math.cos(a)}
                y2={100 + 78 * Math.sin(a)}
                stroke="rgba(255,255,255,0.12)"
                strokeWidth="1"
              />
            );
          })}
          <polygon
            points={[
              [1, "#C9BBEE"],
              [2, "#A6B4DD"],
              [1, "#7A8094"],
              [2, "#E9B5E0"],
              [1, "#F2C9A1"],
            ]
              .map(([g, _], i) => {
                const a = -Math.PI / 2 + (i * 2 * Math.PI) / 5;
                const r = ((g as number) / 3) * 78;
                return `${100 + r * Math.cos(a)},${100 + r * Math.sin(a)}`;
              })
              .join(" ")}
            fill="rgba(201,187,238,0.18)"
            stroke="rgba(255,255,255,0.6)"
            strokeWidth="1.2"
          />
        </svg>
      </div>
      <div className="text-[10px] uppercase tracking-[0.2em] text-white/30">
        FAS · 5 facets
      </div>
    </div>
  );
}
