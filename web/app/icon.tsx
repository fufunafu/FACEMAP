import { ImageResponse } from "next/og";

export const size = { width: 32, height: 32 };
export const contentType = "image/png";

export default function Icon() {
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
          borderRadius: 8,
          position: "relative",
        }}
      >
        <div
          style={{
            position: "absolute",
            top: 1,
            left: 16,
            width: 15,
            height: 15,
            background: "#7A8094",
            borderTopRightRadius: 15,
          }}
        />
        <div
          style={{
            position: "absolute",
            top: 16,
            left: 16,
            width: 15,
            height: 15,
            background: "#A6B4DD",
            borderBottomRightRadius: 15,
          }}
        />
        <div
          style={{
            position: "absolute",
            top: 16,
            left: 1,
            width: 15,
            height: 15,
            background: "#E9B5E0",
            borderBottomLeftRadius: 15,
          }}
        />
        <div
          style={{
            position: "absolute",
            top: 1,
            left: 1,
            width: 15,
            height: 15,
            background: "#C9BBEE",
            borderTopLeftRadius: 15,
          }}
        />
        <div
          style={{
            position: "relative",
            width: 8,
            height: 8,
            background: "#000",
            borderRadius: "50%",
          }}
        />
      </div>
    ),
    { ...size },
  );
}
