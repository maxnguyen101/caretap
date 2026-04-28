"use client";

import Image from "next/image";
import { motion } from "framer-motion";

const FEATURES = [
  {
    title: "A clear home screen",
    body:
      "See what is due, what is late, and what is already handled without digging through a spreadsheet.",
  },
  {
    title: "Tap or log manually",
    body:
      "NFC makes the routine faster, but manual logging is always there when a tag is not nearby.",
  },
  {
    title: "Family visibility by invite",
    body:
      "Share status with a trusted person so check-ins can be calmer and better timed.",
  },
  {
    title: "Refills and history",
    body:
      "Keep a useful record of dose history, source, and refill estimates for day-to-day planning.",
  },
] as const;

export function AppSection() {
  return (
    <section id="app" className="bg-canvas py-24 sm:py-32">
      <div className="mx-auto max-w-7xl px-5 sm:px-8">
        <div className="grid gap-12 lg:grid-cols-[0.9fr_1.1fr] lg:items-center">
          <motion.div
            initial={{ opacity: 0, y: 18 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-80px" }}
            transition={{ duration: 0.55, ease: [0.16, 1, 0.3, 1] }}
          >
            <h2 className="max-w-2xl text-4xl font-semibold leading-[1.06] tracking-tight text-ink sm:text-5xl">
              Built for the daily handoff between routine and reassurance.
            </h2>
            <p className="mt-5 max-w-xl text-lg leading-relaxed text-inkSecondary">
              TapCare is for the person taking medication and the person who
              wants to help without hovering. It keeps the schedule, the log,
              and the shared context in one calm place.
            </p>

            <div className="mt-9 grid gap-4 sm:grid-cols-2">
              {FEATURES.map((feature) => (
                <div
                  key={feature.title}
                  className="rounded-lg border border-stroke bg-white p-5 shadow-card"
                >
                  <h3 className="text-base font-semibold text-ink">
                    {feature.title}
                  </h3>
                  <p className="mt-2 text-sm leading-relaxed text-inkSecondary">
                    {feature.body}
                  </p>
                </div>
              ))}
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 22 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-80px" }}
            transition={{ duration: 0.65, ease: [0.16, 1, 0.3, 1], delay: 0.05 }}
            className="relative"
          >
            <div className="flex flex-col items-center gap-5 sm:flex-row sm:items-end sm:justify-center">
              <ScreenshotCard
                src="/assets/app-home-dashboard.png"
                alt="TapCare home dashboard showing a dose check-in, progress, and upcoming medication"
                label="Today dashboard"
                offset="sm:translate-y-8"
              />
              <ScreenshotCard
                src="/assets/app-workspace.png"
                alt="TapCare workspace screen for managing medication routines"
                label="Workspace"
                offset=""
              />
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}

function ScreenshotCard({
  src,
  alt,
  label,
  offset,
}: {
  src: string;
  alt: string;
  label: string;
  offset: string;
}) {
  return (
    <div
      className={[
        "relative w-full max-w-[230px] overflow-hidden rounded-[30px] border border-stroke bg-[#111314] p-1.5 shadow-card sm:max-w-[250px]",
        offset,
      ].join(" ")}
    >
      <div className="absolute left-4 top-4 z-10 rounded-md border border-stroke bg-white/90 px-3 py-1.5 text-xs font-semibold text-ink">
        {label}
      </div>
      <div className="relative aspect-[1320/2868] overflow-hidden rounded-[24px] bg-canvas">
        <Image
          src={src}
          alt={alt}
          fill
          sizes="(min-width: 1024px) 250px, (min-width: 640px) 230px, 82vw"
          className="object-contain"
        />
      </div>
    </div>
  );
}
