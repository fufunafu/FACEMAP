import type { Metadata } from "next";
import { ToolHeader } from "../_tool-shell";
import { tools } from "@/content/tools";
import { PinchTest } from "@/components/tools/pinch-test";

const TOOL = tools.find((t) => t.id === "pinch-test")!;

export const metadata: Metadata = {
  title: TOOL.title,
  description: TOOL.blurb,
};

export default function PinchTestPage() {
  return (
    <>
      <ToolHeader title={TOOL.title} resolves={TOOL.resolves} hue={TOOL.hue} />
      <section>
        <div className="container-page py-12">
          <PinchTest />
        </div>
      </section>
    </>
  );
}
