"use client";

import { useMemo, useState } from "react";
import { motion } from "framer-motion";
import {
  Pack,
  formatPrice,
  highlightLabel,
  packs,
  paymentLinkFor,
  perTagPrice,
  tapKitPromises,
} from "@/lib/packs";

type Recommendation = "starter" | "family" | "unsure";

const recommendationOptions: Array<{
  id: Recommendation;
  label: string;
  detail: string;
  recommendedSlug: Pack["slug"];
}> = [
  {
    id: "starter",
    label: "1 to 5 routines",
    detail: "Start with the 5-tag kit.",
    recommendedSlug: "starter",
  },
  {
    id: "family",
    label: "6 to 10 routines",
    detail: "Use the 10-tag kit.",
    recommendedSlug: "family",
  },
  {
    id: "unsure",
    label: "Not sure yet",
    detail: "Starter is the simplest first step.",
    recommendedSlug: "starter",
  },
];

export function TapKitSection() {
  const [selection, setSelection] = useState<Recommendation>("starter");
  const recommendedSlug = useMemo(
    () => recommendationOptions.find((option) => option.id === selection)?.recommendedSlug ?? "starter",
    [selection]
  );

  return (
    <section
      id="kits"
      className="scroll-mt-24 border-y border-stroke bg-white py-20 sm:py-28"
    >
      <div className="mx-auto max-w-7xl px-5 sm:px-8">
        <div className="grid gap-12 lg:grid-cols-[0.72fr_1fr] lg:gap-16">
          <motion.div
            initial={{ opacity: 0, y: 18 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-80px" }}
            transition={{ duration: 0.55, ease: [0.16, 1, 0.3, 1] }}
            className="max-w-xl"
          >
            <h2 className="text-4xl font-semibold leading-[1.06] tracking-tight text-ink sm:text-5xl">
              How many bottles or routines do you want to tag?
            </h2>
            <p className="mt-5 text-lg leading-relaxed text-inkSecondary">
              Start small or cover the whole routine. Both kits include app
              access, setup help, and TapCare-ready NFC tags for medications,
              vitamins, supplements, and organizers.
            </p>

            <div className="mt-8 grid gap-3">
              {recommendationOptions.map((option) => (
                <button
                  key={option.id}
                  type="button"
                  onClick={() => setSelection(option.id)}
                  className={[
                    "rounded-lg border p-4 text-left transition focus:outline-none focus:ring-2 focus:ring-sage/25",
                    selection === option.id
                      ? "border-sage/45 bg-canvasMist"
                      : "border-stroke bg-canvas hover:bg-white",
                  ].join(" ")}
                >
                  <span className="block font-semibold text-ink">{option.label}</span>
                  <span className="mt-1 block text-sm text-inkSecondary">
                    {option.detail}
                  </span>
                </button>
              ))}
            </div>
          </motion.div>

          <div className="grid gap-4 md:grid-cols-2">
            {packs.map((pack, index) => (
              <PackCard
                key={pack.slug}
                pack={pack}
                index={index}
                isRecommended={pack.slug === recommendedSlug}
              />
            ))}
          </div>
        </div>

        <ComparisonTable />

        <motion.div
          initial={{ opacity: 0, y: 14 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-80px" }}
          transition={{ duration: 0.55, ease: [0.16, 1, 0.3, 1], delay: 0.08 }}
          className="mt-10 grid gap-4 border-t border-stroke pt-8 text-sm text-inkSecondary md:grid-cols-3"
        >
          {tapKitPromises.map((promise) => (
            <p key={promise} className="flex items-start gap-3">
              <span className="mt-0.5 grid h-5 w-5 shrink-0 place-items-center rounded-md bg-canvas text-sageStrong">
                <CheckIcon />
              </span>
              <span>{promise}</span>
            </p>
          ))}
        </motion.div>
      </div>
    </section>
  );
}

function PackCard({
  pack,
  index,
  isRecommended,
}: {
  pack: Pack;
  index: number;
  isRecommended: boolean;
}) {
  const label = isRecommended ? "Recommended" : highlightLabel(pack.highlight);

  return (
    <motion.a
      href={paymentLinkFor(pack)}
      target="_blank"
      rel="noopener"
      initial={{ opacity: 0, y: 18 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-80px" }}
      transition={{
        duration: 0.55,
        ease: [0.16, 1, 0.3, 1],
        delay: index * 0.06,
      }}
      className={[
        "group flex min-h-[390px] flex-col rounded-lg border p-6 transition focus:outline-none focus:ring-2 focus:ring-sage/25",
        isRecommended
          ? "border-sage/55 bg-canvasMist/45 shadow-card"
          : "border-stroke bg-canvas hover:border-sage/30 hover:bg-white",
      ].join(" ")}
    >
      <div className="flex items-start justify-between gap-4">
        <div>
          {label && (
            <span className="mb-3 inline-flex rounded-md bg-sageStrong px-2.5 py-1 text-[11px] font-semibold text-white">
              {label}
            </span>
          )}
          <h3 className="text-2xl font-semibold tracking-tight text-ink">
            {pack.title}
          </h3>
          <p className="mt-1 text-sm text-inkSecondary">{pack.subtitle}</p>
        </div>
        <div className="text-right">
          <p className="text-3xl font-semibold tracking-tight text-ink tabular">
            {formatPrice(pack.priceCents)}
          </p>
          <p className="mt-1 text-xs text-inkTertiary">{perTagPrice(pack)}</p>
        </div>
      </div>

      <p className="mt-6 text-base leading-relaxed text-inkSecondary">
        {pack.summary}
      </p>

      <ul className="mt-6 space-y-3 text-sm text-ink">
        {pack.perks.map((perk) => (
          <li key={perk} className="flex items-start gap-3">
            <span className="mt-0.5 grid h-5 w-5 shrink-0 place-items-center rounded-md bg-white text-sageStrong">
              <CheckIcon />
            </span>
            <span>{perk}</span>
          </li>
        ))}
      </ul>

      <div className="mt-auto pt-7">
        <div className="rounded-lg border border-stroke bg-white p-4 text-sm text-inkSecondary">
          <p className="font-semibold text-ink">{pack.shippingNote}</p>
          <p className="mt-1">{pack.supportNote}</p>
        </div>
        <span
          className={[
            "mt-4 inline-flex w-full items-center justify-center rounded-lg px-5 py-3 text-sm font-semibold transition",
            isRecommended
              ? "bg-ink text-white group-hover:bg-sageStrong"
              : "bg-white text-ink ring-1 ring-stroke group-hover:ring-sage/35",
          ].join(" ")}
        >
          Order {pack.title}
        </span>
      </div>
    </motion.a>
  );
}

function ComparisonTable() {
  return (
    <motion.div
      initial={{ opacity: 0, y: 18 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-80px" }}
      transition={{ duration: 0.55, ease: [0.16, 1, 0.3, 1] }}
      className="mt-12 overflow-hidden rounded-lg border border-stroke bg-canvas shadow-card"
    >
      <div className="grid grid-cols-[1fr_0.8fr_0.8fr] border-b border-stroke bg-white text-sm font-semibold text-ink">
        <div className="p-4">Compare</div>
        <div className="border-l border-stroke p-4">Starter Pack</div>
        <div className="border-l border-stroke p-4">Family Pack</div>
      </div>
      {[
        ["NFC tags/cards", "5", "10"],
        ["Best for", "One person getting started", "Multiple bottles or routines"],
        ["App access", "Included", "Included"],
        ["Setup help", "Included", "Included"],
      ].map(([label, starter, family]) => (
        <div
          key={label}
          className="grid grid-cols-[1fr_0.8fr_0.8fr] border-b border-stroke last:border-b-0 text-sm text-inkSecondary"
        >
          <div className="p-4 font-semibold text-ink">{label}</div>
          <div className="border-l border-stroke p-4">{starter}</div>
          <div className="border-l border-stroke p-4">{family}</div>
        </div>
      ))}
    </motion.div>
  );
}

function CheckIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      className="h-3.5 w-3.5"
      fill="none"
      stroke="currentColor"
      strokeWidth="3"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden
    >
      <path d="M5 12.5 10 17.5 19.5 8" />
    </svg>
  );
}
