import type { Metadata } from "next";
import { ToolHeader } from "../_tool-shell";
import { tools } from "@/content/tools";
import { AgeSequencer } from "@/components/tools/age-sequencer";

const TOOL = tools.find((t) => t.id === "age-sequencer")!;

export const metadata: Metadata = {
  title: TOOL.title,
  description: TOOL.blurb,
};

export default function AgeSequencerPage() {
  return (
    <>
      <ToolHeader title={TOOL.title} resolves={TOOL.resolves} hue={TOOL.hue} />
      <section>
        <div className="container-page py-10 md:py-12">
          <AgeSequencer />
        </div>
      </section>
    </>
  );
}
