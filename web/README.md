# FaceMap — web

Marketing site for FaceMap, the iOS facial-aesthetic analysis app developed by Dr Andreas Nikolis and team.

## Stack

- Next.js 16 (App Router)
- Tailwind CSS v4
- Framer Motion
- TypeScript

## Develop

```bash
npm install
npm run dev
```

Site runs at http://localhost:3000.

## Sources of truth

The site mirrors the iOS app. Keep these files in sync when the app changes:

| Web file | iOS source of truth |
| --- | --- |
| `content/domains.ts` | `FaceMap/Analysis/FaceDomain.swift` |
| `content/metrics.ts` | `FaceMap/Analysis/MetricRegistry.swift` + `Metrics/*.swift` |
| `content/disclaimer.ts` | `FaceMap/UI/DisclaimerCopy.swift` |
| `lib/tokens.ts` | `FaceMap/UI/DesignSystem/Theme.swift` |

## Positioning

This site matches the in-app planning-aid wording. Never say "recommends fillers" — the app flags regions based on geometric analysis only.
