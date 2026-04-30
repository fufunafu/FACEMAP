import type { Metadata } from "next";
import { ToolHeader } from "../_tool-shell";
import { tools } from "@/content/tools";
import { LipPriorities } from "@/components/tools/lip-priorities";

const TOOL = tools.find((t) => t.id === "lip-priorities")!;

export const metadata: Metadata = {
  title: TOOL.title,
  description: TOOL.blurb,
};

export default function LipPrioritiesPage() {
  return (
    <>
      <ToolHeader title={TOOL.title} resolves={TOOL.resolves} hue={TOOL.hue} />
      <section>
        <div className="container-page py-12">
          <LipPriorities />
        </div>
      </section>
    </>
  );
}
