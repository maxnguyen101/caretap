"use client";

import { motion } from "framer-motion";

export function FounderNote() {
  return (
    <section id="support" className="scroll-mt-24 bg-canvas py-20 sm:py-28">
      <div className="mx-auto max-w-7xl px-5 sm:px-8">
        <motion.div
          initial={{ opacity: 0, y: 18 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-80px" }}
          transition={{ duration: 0.55, ease: [0.16, 1, 0.3, 1] }}
          className="grid gap-10 rounded-lg border border-stroke bg-white p-6 shadow-card lg:grid-cols-[0.72fr_1fr] lg:p-10"
        >
          <div>
            <h2 className="text-4xl font-semibold leading-[1.06] tracking-tight text-ink sm:text-5xl">
              Not techy? We help with setup.
            </h2>
            <p className="mt-5 text-lg leading-relaxed text-inkSecondary">
              Every TapKit includes simple setup support, so you or your parent
              do not have to figure it out alone.
            </p>
          </div>

          <div className="grid gap-5">
            <SupportCard
              title="Set up for a parent"
              body="You can help place tags, name routines, and get the first check-ins ready without turning it into a complicated tech project."
            />
            <SupportCard
              title="Support, not monitoring"
              body="TapCare is designed to support routines, not take away independence. The goal is simple: make daily check-ins easier, clearer, and less stressful for everyone."
            />

            <div className="grid gap-4 sm:grid-cols-3">
              <SupportStat value="Setup" label="Help included" />
              <SupportStat value="$25+" label="Free U.S. shipping" />
              <SupportStat value="30 days" label="Returns" />
            </div>

            <p className="text-sm leading-relaxed text-inkSecondary">
              If a tag does not scan, a routine needs renaming, or the first
              setup feels unclear, email support and we will help get the
              system working simply.
            </p>
          </div>
        </motion.div>
      </div>
    </section>
  );
}

function SupportCard({ title, body }: { title: string; body: string }) {
  return (
    <div className="rounded-lg border border-stroke bg-canvas p-5">
      <h3 className="text-lg font-semibold text-ink">{title}</h3>
      <p className="mt-2 leading-relaxed text-inkSecondary">{body}</p>
    </div>
  );
}

function SupportStat({ value, label }: { value: string; label: string }) {
  return (
    <div className="rounded-lg border border-stroke bg-white p-4">
      <p className="text-2xl font-semibold tracking-tight text-ink tabular">
        {value}
      </p>
      <p className="mt-1 text-xs font-medium text-inkTertiary">
        {label}
      </p>
    </div>
  );
}
