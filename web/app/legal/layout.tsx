import { PageShell } from "@/components/site-chrome";

export default function LegalLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <PageShell>{children}</PageShell>;
}
