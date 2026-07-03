# FaceMap On-Device Test Script (PM journey verification)

Device: iPhone with TrueDepth (X or newer), app freshly installed.

## 1. First run
1. Launch FaceMap. Confirm the disclaimer gate appears; tap "I am a licensed practitioner — continue".
2. Confirm you land on the Patients tab with the empty state. Note the copy promising an "Unassigned bucket you can re-bind later".

## 2. Patient-first journey (the blocker)
3. Tap "Add patient", create code `P-001`.
4. Open P-001 → tap "Add visit" → complete the 3-pose capture (frontal, oblique L, oblique R).
5. On the Analysis screen tap Save, enter label `Visit 1`, save.
6. EXPECTED BUG: go back to P-001's detail screen — it still says "No visits yet". Return to the Patients list: a patient named "Unassigned" now exists and contains Visit 1.
7. Try to find any way to move Visit 1 from Unassigned to P-001 (long-press the visit row, check Analysis toolbar, check menus). EXPECTED: none exists.

## 3. Stale capture state (cross-visit mixing)
8. Go to the Capture tab. Complete a full 3-pose session and reach Analysis WITHOUT saving; go back.
9. Re-enter the Capture flow and let it auto-capture once. EXPECTED BUG: it captures only Oblique R and immediately jumps to Analysis using the frontal mesh from the PREVIOUS session.

## 4. Comparison journey
10. Under the Unassigned patient (or P-001 if you worked around step 6), save a second visit.
11. In patient detail: tap ellipsis → "Compare visits" → select both visits → "Compare 2/2". Note how many taps this took.
12. In the CHANGES table, find "Surface displacement". EXPECTED BUG: value shown as a tiny percentage (e.g. "0.2%") instead of mm.
13. Look for any share/export button on the Compare screen. EXPECTED: none.

## 5. Settings traps
14. More → Settings → enable "Lock with Face ID" (authenticate). Force-quit and relaunch the app. EXPECTED BUG: app opens straight to patient data with no Face ID prompt.
15. Patients list: swipe-archive a patient. Try to find/restore it anywhere. EXPECTED: impossible.

## 6. Copy check (previously-stale items, now fixed — verify the fixes)
16. More tab footer reads the real bundle version (v0.8.0); About screen header says "THE FIVE FAS FACETS" above the five facets; Settings cloud sync says "Planned — Phase 5".

## 7. Capture quality & gating (v0.8 pipeline upgrade)
17. Frontal pose while smiling / jaw open / head rolled: auto-capture must NOT fire; the status banner shows the matching coaching line ("Relax the face — neutral expression", "Close the mouth gently", "Straighten the head — ears level"). Relax → captures within ~0.6 s.
18. Manual capture (tap the button) while smiling: capture succeeds; Analysis shows a Fair/Poor quality badge and, if Poor, the low-quality warning row. Save is NOT blocked.
19. Capture normally (level head, neutral face): Analysis shows "Capture quality: Good".
20. Open a visit saved with a previous build: loads fine, NO quality badge, no warning (legacy compat).

## 8. Photo-textured 3D model
21. New capture → Analysis → tap the mesh thumbnail: the full-screen model shows the patient's actual skin projected onto the mesh (not the grey clay). Nose tip, eye corners, and lip line must land on the right geometry — this validates the projection formula end-to-end.
22. CHIRALITY: put a small sticker dot on the patient's LEFT cheek before capture. In the viewer's Front preset, the dot must appear on the mesh's left cheek (viewer's right), matching the unmirrored clinical photo.
23. Full-screen viewer: "Clay" toggle switches to the neutral surface and back; the heatmap toggle hides/shows region tinting. Orbit to the profile presets: the sides of the face fade smoothly to clay instead of smearing stretched photo pixels.
24. Old (pre-upgrade) record: renders as smooth-shaded clay with the heatmap overlay, no crash, no blank viewport; no photo toggle appears.
25. Shading: the mesh must look smooth (no visible hard triangle facets) in every view preset, on both old and new records.
26. Heatmap: flagged regions show their domain hue ON the mesh surface, tracking rotation; metric constructions and billboard labels stay aligned in all presets.
27. Calibration screens: tap-picking still selects the intended vertex (collision + original topology unchanged).
28. Export the treatment-plan PDF and a comparison PDF: mesh images are PRESENT (no blank slots), textured, and sharp at print zoom. (The old ImageRenderer path produced blank mesh snapshots.)
29. Same-day re-capture of an untreated face → Compare: surface-change table stays within the ±0.3 mm noise floor (median frame aggregation must not regress comparisons).

## 9. Calibration gate (v0.8.0)
30. Fresh install (or Reset all landmarks + Save from a calibration screen): both capture entry points — Capture tab AND patient detail "Add visit" — show the "Calibrate before clinical capture" gate instead of the camera, with "0 of 18 landmarks calibrated".
31. "Calibrate now" → calibration capture: the same level-head/neutral-expression gating coaches the capture; the captured mesh opens the landmark walkthrough directly. Confirm NO patient case is created by this flow (Patients tab unchanged).
32. Calibrate a few landmarks, Save, navigate away: gate now shows "n of 18" and the CTA reads "Resume calibration"; resuming continues at the first uncalibrated landmark without recapturing.
33. Finish all 18 → Save & finish: you land back on the capture screen and the gate has lifted LIVE (no app restart), on both entry points.
34. "Continue uncalibrated (evaluation only)": confirmation dialog → capture unlocks; force-quit and relaunch → the gate is back (override is session-only, never persisted). Calibration warning banners still appear on analyses and PDFs while uncalibrated.
35. Alternative path: with the override active, save a case, open it, calibrate via the Analysis toolbar scope icon → completing calibration there also lifts the gate everywhere.
