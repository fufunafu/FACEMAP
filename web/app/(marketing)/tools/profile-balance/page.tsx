import type { Metadata } from "next";
import { ToolHeader } from "../_tool-shell";
import { tools } from "@/content/tools";
import { ProfileBalance } from "@/components/tools/profile-balance";

const TOOL = tools.find((t) => t.id === "profile-balance")!;

export const metadata: Metadata = {
  title: TOOL.title,
  description: TOOL.blurb,
};

export default function ProfileBalancePage() {
  return (
    <>
      <ToolHeader title={TOOL.title} resolves={TOOL.resolves} hue={TOOL.hue} />
      <section>
        <div className="container-page py-10 md:py-12">
          <ProfileBalance />
        </div>
      </section>
    </>
  );
}
