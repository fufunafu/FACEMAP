import type { Metadata } from "next";
import { ToolHeader } from "../_tool-shell";
import { tools } from "@/content/tools";
import { PlanBuilder } from "@/components/tools/plan-builder";

const TOOL = tools.find((t) => t.id === "plan-builder")!;

export const metadata: Metadata = {
  title: TOOL.title,
  description: TOOL.blurb,
};

export default function PlanBuilderPage() {
  return (
    <>
      <ToolHeader title={TOOL.title} resolves={TOOL.resolves} hue={TOOL.hue} />
      <section>
        <div className="container-page py-10 md:py-12">
          <PlanBuilder />
        </div>
      </section>
    </>
  );
}
