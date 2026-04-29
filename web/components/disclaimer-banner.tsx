import { disclaimer } from "@/content/disclaimer";

export function DisclaimerBanner() {
  return (
    <aside
      role="note"
      className="border-t hairline bg-[var(--color-surface)]/80 backdrop-blur"
    >
      <div className="container-page py-4 text-xs text-[var(--color-ink-muted)]">
        <p>
          <span className="font-medium text-[var(--color-ink-dim)]">
            {disclaimer.firstLaunchTitle}.
          </span>{" "}
          {disclaimer.analysisFooter} For licensed medical practitioners only.
          FaceMap is not a medical device, does not diagnose any condition, and
          does not prescribe treatment, dose, or specific injection sites.
        </p>
      </div>
    </aside>
  );
}
