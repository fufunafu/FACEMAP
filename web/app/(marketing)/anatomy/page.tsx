import type { Metadata } from "next";
import { ScalpStack } from "@/components/scalp-stack";

export const metadata: Metadata = {
  title: "Anatomy — SCALP layers",
  description:
    "Skin · Connective tissue · Aponeurosis · Loose connective tissue · Periosteum. The five anatomical layers used by Nikolis et al. as the canonical model of facial layered anatomy.",
};

const TROUBLE_SPOTS = [
  {
    title: "Glabellar region",
    body:
      "Vertical and horizontal wrinkles due to aging of orbicularis oculi muscles, procerus, corrugator supercilii, and depressor supercilii muscles.",
  },
  {
    title: "Retro-orbicularis oculi fat (ROOF)",
    body:
      "Sagging due to changes in underlying bone and laxity of the orbicularis oculi muscle, orbicularis retaining ligament, and frontalis muscle.",
  },
  {
    title: "Suborbicularis oculi fat (SOOF)",
    body:
      "Bounded by the tear-trough ligament and zygomatic ligament. Partially responsible for malar mound appearance.",
  },
  {
    title: "Nasolabial sulcus",
    body:
      "Formed by traction of underlying expression muscles and overlying superficial nasolabial fat compartment. Impression deepens with aging.",
  },
  {
    title: "Mandibular ligament",
    body:
      "Anchor point connecting skin to bone. Jowl deformity here results from inferior migration of fat compartments.",
  },
];

export default function AnatomyPage() {
  return (
    <>
      <section className="border-b hairline">
        <div className="container-page py-20">
          <p className="text-[11px] uppercase tracking-[0.2em] text-[var(--color-ink-muted)]">
            Anatomy
          </p>
          <h1 className="mt-4 max-w-3xl font-display text-5xl tracking-tight md:text-6xl">
            SCALP — five layers from skin to bone.
          </h1>
          <p className="mt-5 max-w-2xl text-[var(--color-ink-dim)]">
            Facial areas consist of five anatomical layers: <strong>S</strong>kin, <strong>C</strong>onnective tissue, <strong>A</strong>poneurosis (SMAS), <strong>L</strong>oose connective tissue, <strong>P</strong>eriosteum / deep fascia. The SCALP classification frames where each treatment goes.
          </p>
        </div>
      </section>

      <section className="border-b hairline">
        <div className="container-page py-16">
          <div className="grid gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
            <ScalpStack />
            <div>
              <h2 className="font-display text-3xl tracking-tight md:text-4xl">
                Why SCALP matters.
              </h2>
              <p className="mt-4 text-[var(--color-ink-dim)]">
                The SMAS, when manipulated, can affect positioning of other soft tissues. Bones such as the zygoma stay stable with age and act as anchors; ligaments shift in position with bony changes. Knowing how each layer ages — and how injection at one layer transmits to another — is the difference between safe, reproducible treatment and a one-size-fits-all approach.
              </p>
              <p className="mt-4 text-[var(--color-ink-dim)]">
                Anteriorly to the line of ligaments, the face is voluminous and supportive — ideal for volumization. Laterally, the face is rich in ligamentous attachments — ideal for treatments focused on lift and projection.
              </p>
            </div>
          </div>
        </div>
      </section>

      <section>
        <div className="container-page py-16">
          <h2 className="font-display text-3xl tracking-tight md:text-4xl">
            Common trouble spots of the aged face.
          </h2>
          <p className="mt-3 max-w-2xl text-[var(--color-ink-dim)]">
            Adapted from Figure 3 of Nikolis et al., 2024.
          </p>
          <ul className="mt-10 grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {TROUBLE_SPOTS.map((s) => (
              <li
                key={s.title}
                className="rounded-[var(--radius-card)] border hairline bg-[var(--color-surface)] p-6"
              >
                <h3 className="text-lg">{s.title}</h3>
                <p className="mt-2 text-sm text-[var(--color-ink-dim)]">
                  {s.body}
                </p>
              </li>
            ))}
          </ul>
        </div>
      </section>
    </>
  );
}
