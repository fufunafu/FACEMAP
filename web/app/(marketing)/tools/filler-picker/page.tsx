import type { Metadata } from "next";
import { ToolHeader } from "../_tool-shell";
import { tools } from "@/content/tools";
import { FillerPicker } from "@/components/tools/filler-picker";

const TOOL = tools.find((t) => t.id === "filler-picker")!;

export const metadata: Metadata = {
  title: TOOL.title,
  description: TOOL.blurb,
};

export default function FillerPickerPage() {
  return (
    <>
      <ToolHeader title={TOOL.title} resolves={TOOL.resolves} hue={TOOL.hue} />
      <section>
        <div className="container-page py-10 md:py-12">
          <FillerPicker />
        </div>
      </section>
    </>
  );
}
