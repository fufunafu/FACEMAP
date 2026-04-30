import type { Metadata } from "next";
import { ToolHeader } from "../_tool-shell";
import { tools } from "@/content/tools";
import { VisitLog } from "@/components/tools/visit-log";

const TOOL = tools.find((t) => t.id === "visit-log")!;

export const metadata: Metadata = {
  title: TOOL.title,
  description: TOOL.blurb,
};

export default function VisitLogPage() {
  return (
    <>
      <ToolHeader title={TOOL.title} resolves={TOOL.resolves} hue={TOOL.hue} />
      <section>
        <div className="container-page py-10 md:py-12">
          <VisitLog />
        </div>
      </section>
    </>
  );
}
