"use client";

import { useEffect, useMemo, useState } from "react";
import { facetOrder, facetsList, type FacetId } from "@/content/fas";
import { FasComparison } from "@/components/fas-comparison";

interface Visit {
  id: string;
  date: string; // ISO YYYY-MM-DD
  grades: Record<FacetId, number>;
}

interface PatientLog {
  patientCode: string;
  visits: Visit[];
}

const STORAGE_KEY = "facemap-visit-log";

const EMPTY_GRADES: Record<FacetId, number> = {
  skinQuality: 0,
  facialShape: 0,
  proportions: 0,
  symmetry: 0,
  expression: 0,
};

export function VisitLog() {
  const [logs, setLogs] = useState<Record<string, PatientLog>>({});
  const [hydrated, setHydrated] = useState(false);
  const [active, setActive] = useState<string>("");
  const [draftCode, setDraftCode] = useState("");
  const [draftDate, setDraftDate] = useState(() => new Date().toISOString().slice(0, 10));
  const [draftGrades, setDraftGrades] = useState<Record<FacetId, number>>(EMPTY_GRADES);

  useEffect(() => {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) setLogs(JSON.parse(raw));
    } catch {
      /* ignore */
    }
    setHydrated(true);
  }, []);

  useEffect(() => {
    if (!hydrated) return;
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(logs));
    } catch {
      /* ignore */
    }
  }, [logs, hydrated]);

  function addVisit() {
    const code = (active || draftCode).trim();
    if (!code) return;
    const visit: Visit = {
      id: `${Date.now()}`,
      date: draftDate,
      grades: { ...draftGrades },
    };
    setLogs((cur) => {
      const existing = cur[code] ?? { patientCode: code, visits: [] };
      const next = {
        ...cur,
        [code]: {
          ...existing,
          visits: [...existing.visits, visit].sort((a, b) =>
            a.date.localeCompare(b.date),
          ),
        },
      };
      return next;
    });
    setActive(code);
    setDraftCode("");
    setDraftGrades(EMPTY_GRADES);
  }

  function deleteVisit(code: string, id: string) {
    setLogs((cur) => {
      const log = cur[code];
      if (!log) return cur;
      const visits = log.visits.filter((v) => v.id !== id);
      if (visits.length === 0) {
        const { [code]: _drop, ...rest } = cur;
        return rest;
      }
      return { ...cur, [code]: { ...log, visits } };
    });
  }

  const codes = Object.keys(logs).sort();
  const log = active ? logs[active] : null;

  const baseline = log?.visits[0];
  const latest = log?.visits[log.visits.length - 1];
  const showRadar = baseline && latest && baseline.id !== latest.id;

  return (
    <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)] lg:items-start">
      <div className="space-y-6">
        <div className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-5">
          <p className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
            Patients on this device
          </p>
          {codes.length === 0 ? (
            <p className="mt-3 text-sm text-[var(--color-ink-muted)]">
              No patients yet. Add a visit below to start tracking.
            </p>
          ) : (
            <ul className="mt-3 flex flex-wrap gap-2">
              {codes.map((c) => (
                <li key={c}>
                  <button
                    onClick={() => setActive(c)}
                    className="rounded-full border hairline px-3 py-1.5 text-sm transition"
                    style={{
                      borderColor:
                        active === c ? "var(--color-ink)" : "var(--color-hairline)",
                      backgroundColor:
                        active === c
                          ? "color-mix(in srgb, var(--color-ink) 8%, transparent)"
                          : "transparent",
                    }}
                  >
                    <span className="num">{c}</span>
                    <span className="ml-2 text-xs text-[var(--color-ink-muted)]">
                      {logs[c].visits.length}
                    </span>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>

        <div className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-5">
          <p className="text-[11px] uppercase tracking-wider text-[var(--color-ink-muted)]">
            Add a visit
          </p>
          <div className="mt-3 grid gap-3 sm:grid-cols-2">
            <label className="block">
              <span className="text-[10px] uppercase tracking-wider text-[var(--color-ink-muted)]">
                Patient code
              </span>
              <input
                value={active || draftCode}
                onChange={(e) => {
                  setActive("");
                  setDraftCode(e.target.value);
                }}
                placeholder="P-014"
                className="mt-1 block w-full rounded-[var(--radius-button)] border hairline bg-[var(--color-surface-raised)] px-3 py-2 text-sm outline-none focus:border-[var(--color-ink-dim)]"
              />
            </label>
            <label className="block">
              <span className="text-[10px] uppercase tracking-wider text-[var(--color-ink-muted)]">
                Visit date
              </span>
              <input
                type="date"
                value={draftDate}
                onChange={(e) => setDraftDate(e.target.value)}
                className="mt-1 block w-full rounded-[var(--radius-button)] border hairline bg-[var(--color-surface-raised)] px-3 py-2 text-sm outline-none focus:border-[var(--color-ink-dim)]"
              />
            </label>
          </div>

          <div className="mt-4 space-y-3">
            {facetsList.map((f) => (
              <div key={f.id}>
                <div className="flex items-center justify-between text-xs">
                  <span style={{ color: f.hue }}>{f.name}</span>
                  <span className="num text-[var(--color-ink-dim)]">
                    {draftGrades[f.id]}
                  </span>
                </div>
                <div className="mt-1.5 grid grid-cols-4 gap-1.5">
                  {[0, 1, 2, 3].map((g) => {
                    const isOn = draftGrades[f.id] === g;
                    return (
                      <button
                        key={g}
                        onClick={() =>
                          setDraftGrades((p) => ({ ...p, [f.id]: g }))
                        }
                        className="rounded-[var(--radius-button)] border hairline px-2 py-1 text-xs transition"
                        style={{
                          borderColor: isOn ? f.hue : "var(--color-hairline)",
                          backgroundColor: isOn
                            ? `color-mix(in srgb, ${f.hue} 18%, transparent)`
                            : "transparent",
                        }}
                      >
                        {g}
                      </button>
                    );
                  })}
                </div>
              </div>
            ))}
          </div>

          <button
            onClick={addVisit}
            disabled={!(active || draftCode.trim())}
            className="mt-5 w-full rounded-[var(--radius-button)] bg-[var(--color-cta-bg)] px-4 py-2 text-sm font-medium text-[var(--color-cta-ink)] transition hover:opacity-90 disabled:opacity-40"
          >
            Save visit
          </button>
        </div>
      </div>

      <aside className="space-y-6">
        {!log ? (
          <div className="rounded-[var(--radius-sheet)] border hairline bg-[var(--color-surface)] p-7">
            <p className="text-[11px] uppercase tracking-[0.18em] text-[var(--color-ink-muted)]">
              Patient timeline
            </p>
            <p className="mt-3 text-sm text-[var(--color-ink-muted)]">
              Select a patient code on the left, or add a new visit, to view their FAS timeline.
            </p>
          </div>
        ) : (
          <>
            {showRadar ? (
              <div className="rounded-[var(--radius-sheet)] border hairline bg-[var(--color-surface)] p-7">
                <p className="text-[11px] uppercase tracking-[0.18em] text-[var(--color-ink-muted)]">
                  Baseline → latest
                </p>
                <p className="mt-1 num text-sm">
                  {baseline.date} → {latest.date}
                </p>
                <div className="mt-4 flex justify-center">
                  <FasComparison
                    baseline={baseline.grades}
                    followUp={latest.grades}
                    size={360}
                  />
                </div>
              </div>
            ) : null}

            <div className="rounded-[var(--radius-sheet)] border hairline bg-[var(--color-surface)] p-7">
              <p className="text-[11px] uppercase tracking-[0.18em] text-[var(--color-ink-muted)]">
                {log.patientCode}
              </p>
              <ol className="mt-3 space-y-2">
                {log.visits.map((v, i) => {
                  const total = facetOrder.reduce((s, f) => s + v.grades[f], 0);
                  return (
                    <li
                      key={v.id}
                      className="rounded-md border hairline bg-[var(--color-surface-raised)] p-3"
                    >
                      <div className="flex items-center justify-between gap-3">
                        <span className="num text-sm">
                          {String(i + 1).padStart(2, "0")} · {v.date}
                        </span>
                        <span className="num text-xs text-[var(--color-ink-muted)]">
                          Σ {total}
                        </span>
                      </div>
                      <div className="mt-2 flex flex-wrap gap-1">
                        {facetOrder.map((f) => (
                          <span
                            key={f}
                            className="rounded-full border hairline px-2 py-0.5 text-[10px] num"
                          >
                            {v.grades[f]}
                          </span>
                        ))}
                      </div>
                      <button
                        onClick={() => deleteVisit(log.patientCode, v.id)}
                        className="mt-3 text-[10px] uppercase tracking-wider text-[var(--color-ink-muted)] transition hover:text-[var(--color-ink)]"
                      >
                        Delete
                      </button>
                    </li>
                  );
                })}
              </ol>
              <p className="mt-4 text-[11px] text-[var(--color-ink-muted)]">
                Stored locally on this device. Nothing is uploaded.
              </p>
            </div>
          </>
        )}
      </aside>
    </div>
  );
}
