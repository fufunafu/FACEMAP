import type { Metadata } from "next";
import { Newsreader, Inter, JetBrains_Mono } from "next/font/google";
import { Analytics } from "@vercel/analytics/next";
import { SpeedInsights } from "@vercel/speed-insights/next";
import "./globals.css";

const newsreader = Newsreader({
  subsets: ["latin"],
  weight: ["300", "400", "500", "600"],
  style: ["normal", "italic"],
  variable: "--font-newsreader",
  display: "swap",
});

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

const mono = JetBrains_Mono({
  subsets: ["latin"],
  variable: "--font-mono-num",
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL("https://facemap.app"),
  title: {
    default: "FaceMap — facial aesthetic analysis for practitioners",
    template: "%s · FaceMap",
  },
  description:
    "FaceMap captures a 3D face mesh on iPhone, evaluates Dr Andreas Nikolis's four-domain Facial Aesthetic framework, and flags regions for practitioner planning. A planning aid, not a medical device.",
  applicationName: "FaceMap",
  authors: [{ name: "Dr Andreas Nikolis and team" }],
  openGraph: {
    title: "FaceMap — facial aesthetic analysis for practitioners",
    description:
      "Capture, analyse, plan. Built on Dr Andreas Nikolis's four-domain Facial Aesthetic framework.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html
      lang="en"
      data-theme="light"
      className={`${newsreader.variable} ${inter.variable} ${mono.variable}`}
      suppressHydrationWarning
    >
      <head>
        <script
          dangerouslySetInnerHTML={{
            __html: `(function(){try{var t=localStorage.getItem('facemap-theme')||'light';document.documentElement.setAttribute('data-theme',t);}catch(e){}})();`,
          }}
        />
      </head>
      <body>
        {children}
        <Analytics />
        <SpeedInsights />
      </body>
    </html>
  );
}
