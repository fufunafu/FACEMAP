import { ImageResponse } from "next/og";

export const alt = "FaceMap — facial aesthetic analysis for practitioners";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

const HUES = ["#C9BBEE", "#A6B4DD", "#7A8094", "#E9B5E0", "#F2C9A1"];

export default function OG() {
  // Pre-compute radar geometry — render entirely as SVG (no <text>, which
  // ImageResponse doesn't support).
  const cx = 250;
  const cy = 250;
  const rMax = 200;
  const grades = [1, 2, 1, 2, 1];
  const points = grades
    .map((g, i) => {
      const a = -Math.PI / 2 + (i * (2 * Math.PI)) / 5;
      const r = (g / 3) * rMax;
      return `${cx + r * Math.cos(a)},${cy + r * Math.sin(a)}`;
    })
    .join(" ");

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          background: "#000",
          color: "#fff",
          display: "flex",
          padding: "60px",
        }}
      >
        {/* Left: text */}
        <div style={{ display: "flex", flexDirection: "column", justifyContent: "space-between", flex: 1, paddingRight: 40 }}>
          <div style={{ display: "flex", flexDirection: "column" }}>
            <div style={{ fontSize: 18, letterSpacing: 4, textTransform: "uppercase", color: "rgba(255,255,255,0.45)", display: "flex" }}>
              AART-HIT · For practitioners
            </div>
            <div style={{ fontSize: 86, lineHeight: 1.05, marginTop: 32, fontWeight: 500, fontFamily: "serif", display: "flex", flexDirection: "column" }}>
              <span>Turn your AART</span>
              <span>
                into a{" "}
                <span style={{ fontStyle: "italic", color: "#E9B5E0" }}>HIT</span>.
              </span>
            </div>
            <div style={{ fontSize: 22, marginTop: 28, color: "rgba(255,255,255,0.7)", maxWidth: 580, lineHeight: 1.4, display: "flex" }}>
              The Facial Assessment Scale, on iPhone. Five facets, one radar, mapped to five Holistic Individualised Treatments.
            </div>
          </div>
          <div style={{ fontSize: 18, color: "rgba(255,255,255,0.45)", display: "flex" }}>
            facemap · by Dr Andreas Nikolis &amp; team
          </div>
        </div>

        {/* Right: FAS radar (SVG only, no <text>) */}
        <div style={{ width: 500, height: 500, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <svg width={500} height={500} viewBox="0 0 500 500">
            {[1, 2, 3].map((i) => (
              <circle key={i} cx={cx} cy={cy} r={(i / 3) * rMax} stroke="rgba(255,255,255,0.14)" fill="none" strokeWidth={1} />
            ))}
            {Array.from({ length: 5 }).map((_, i) => {
              const a = -Math.PI / 2 + (i * (2 * Math.PI)) / 5;
              return (
                <line
                  key={i}
                  x1={cx}
                  y1={cy}
                  x2={cx + rMax * Math.cos(a)}
                  y2={cy + rMax * Math.sin(a)}
                  stroke="rgba(255,255,255,0.14)"
                  strokeWidth={1}
                />
              );
            })}
            <polygon points={points} fill="rgba(201,187,238,0.22)" stroke="rgba(255,255,255,0.9)" strokeWidth={1.5} />
            {grades.map((g, i) => {
              const a = -Math.PI / 2 + (i * (2 * Math.PI)) / 5;
              const r = (g / 3) * rMax;
              return (
                <circle
                  key={i}
                  cx={cx + r * Math.cos(a)}
                  cy={cy + r * Math.sin(a)}
                  r={9}
                  fill={HUES[i]}
                  stroke="#000"
                  strokeWidth={3}
                />
              );
            })}
            <circle cx={cx} cy={cy} r={4} fill="rgba(255,255,255,0.5)" />
          </svg>
        </div>
      </div>
    ),
    { ...size },
  );
}
