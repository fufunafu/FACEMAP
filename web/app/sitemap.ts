import type { MetadataRoute } from "next";
import { hitOrder } from "@/content/hits";

const BASE = "https://facemap.app";

export default function sitemap(): MetadataRoute.Sitemap {
  const now = new Date();
  const staticRoutes = [
    "",
    "/aart-hit",
    "/fas",
    "/hits",
    "/range",
    "/anatomy",
    "/lip-assessment",
    "/tools",
    "/decision-aid",
    "/app",
    "/methodology",
    "/practitioners",
    "/about",
    "/access",
    "/legal/disclaimer",
    "/legal/privacy",
    "/legal/terms",
  ];

  const hitRoutes = hitOrder.map((id) => `/hits/${id}`);
  const toolRoutes = [
    "scalp-grid",
    "filler-picker",
    "pinch-test",
    "lip-priorities",
    "age-sequencer",
    "eye-area",
    "profile-balance",
    "plan-builder",
    "visit-log",
  ].map((id) => `/tools/${id}`);

  return [...staticRoutes, ...hitRoutes, ...toolRoutes].map((path) => ({
    url: `${BASE}${path}`,
    lastModified: now,
    changeFrequency: "monthly",
    priority: path === "" ? 1 : 0.7,
  }));
}
