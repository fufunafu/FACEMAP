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

  return [...staticRoutes, ...hitRoutes].map((path) => ({
    url: `${BASE}${path}`,
    lastModified: now,
    changeFrequency: "monthly",
    priority: path === "" ? 1 : 0.7,
  }));
}
