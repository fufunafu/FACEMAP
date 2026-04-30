import { ImageResponse } from "next/og";

export const size = { width: 180, height: 180 };
export const contentType = "image/png";

export default function AppleIcon() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          background: "#000",
          position: "relative",
        }}
      >
        {/* Quadrants */}
        <div style={{ position: "absolute", top: 8, left: 90, width: 82, height: 82, background: "#7A8094", borderTopRightRadius: 82 }} />
        <div style={{ position: "absolute", top: 90, left: 90, width: 82, height: 82, background: "#A6B4DD", borderBottomRightRadius: 82 }} />
        <div style={{ position: "absolute", top: 90, left: 8, width: 82, height: 82, background: "#E9B5E0", borderBottomLeftRadius: 82 }} />
        <div style={{ position: "absolute", top: 8, left: 8, width: 82, height: 82, background: "#C9BBEE", borderTopLeftRadius: 82 }} />
        {/* Hub */}
        <div style={{ position: "relative", width: 44, height: 44, background: "#000", borderRadius: "50%" }} />
      </div>
    ),
    { ...size },
  );
}
