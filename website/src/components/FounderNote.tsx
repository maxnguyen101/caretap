"use client";

import { motion } from "framer-motion";

export function FounderNote() {
  return (
    <section id="story" className="relative bg-canvas py-28 sm:py-36">
      <div className="mx-auto max-w-4xl px-6">
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6 }}
          className="grid gap-10 rounded-3xl bg-white p-8 shadow-card sm:p-12 lg:grid-cols-[200px_1fr] lg:items-start lg:gap-16"
        >
          <div className="flex flex-col items-center gap-4 lg:items-start">
            <div className="grid h-32 w-32 place-items-center rounded-3xl bg-sage-gradient text-white shadow-sage">
              <span className="text-5xl font-semibold tracking-tight">M</span>
            </div>
            <div className="text-center lg:text-left">
              <p className="text-base font-semibold text-ink">Max Nguyen</p>
              <p className="text-sm text-inkSecondary">
                Founder, USC pre-med
              </p>
            </div>
          </div>

          <div>
            <p className="text-[12px] font-semibold uppercase tracking-wider text-sageStrong">
              A note from the founder
            </p>
            <h2 className="mt-3 text-3xl font-semibold leading-tight tracking-tight text-ink sm:text-4xl">
              I built CareTap because reminder apps don’t work.
            </h2>
            <div className="mt-6 space-y-4 text-lg leading-relaxed text-inkSecondary">
              <p>
                I’m a USC pre-med student. Over the last year, I sat with
                families in my own neighborhood — parents, grandparents,
                people on five-medication routines — and I watched the same
                pattern: the reminder fires, the bottle stays sealed, and
                the spreadsheet of doses never gets filled in.
              </p>
              <p>
                CareTap takes the bottle that’s already there and teaches it
                to log itself. One tap. No app to open. The dose is
                recorded. Caregivers see it.
              </p>
              <p>
                Every TapKit ships from my desk. I hand-test each tag with
                the app before I package it, and I write the shipping label
                myself. If anything feels off when it arrives, email me at
                {" "}
                <a
                  className="font-semibold text-sageStrong underline-offset-4 hover:underline"
                  href="mailto:hello@tapcare.app"
                >
                  hello@tapcare.app
                </a>
                {" "}
                and I’ll make it right.
              </p>
            </div>

            <div className="mt-8 flex flex-wrap gap-x-8 gap-y-3 text-sm text-inkSecondary">
              <Stat value="20+" label="Local families onboarded" />
              <Stat value="1-day" label="Typical ship time" />
              <Stat value="100%" label="Tags hand-tested" />
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}

function Stat({ value, label }: { value: string; label: string }) {
  return (
    <div>
      <p className="text-2xl font-semibold tracking-tight text-ink tabular">
        {value}
      </p>
      <p className="text-xs uppercase tracking-wider text-inkTertiary">
        {label}
      </p>
    </div>
  );
}
