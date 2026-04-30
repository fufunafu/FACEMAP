import type { Metadata } from "next";
import { ToolHeader } from "../_tool-shell";
import { tools } from "@/content/tools";
import { EyeAreaDisambiguator } from "@/components/tools/eye-area";

const TOOL = tools.find((t) => t.id === "eye-area")!;

export const metadata: Metadata = {
  title: TOOL.title,
  description: TOOL.blurb,
};

export default function EyeAreaPage() {
  return (
    <>
      <ToolHeader title={TOOL.title} resolves={TOOL.resolves} hue={TOOL.hue} />
      <section>
        <div className="container-page py-12">
          <EyeAreaDisambiguator />
        </div>
      </section>
    </>
  );
}
