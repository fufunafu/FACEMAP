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

## 6. Copy check
16. More tab footer should read v0.2.0 (stale); About screen says "FOUR-DOMAIN" above five listed domains; Settings sync says "Phase 2".