"use client";

import Image from "next/image";
import { motion } from "framer-motion";
import { PhoneMockup } from "./PhoneMockup";

export function Hero() {
  return (
    <section className="relative overflow-hidden bg-canvas pt-24">
      <div className="mx-auto grid max-w-7xl gap-10 px-5 pb-14 pt-12 sm:px-8 lg:min-h-[calc(100svh-2rem)] lg:grid-cols-[0.95fr_1.05fr] lg:items-center lg:gap-12 lg:pt-20">
        <motion.div
          initial={{ opacity: 0, y: 18 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.65, ease: [0.16, 1, 0.3, 1] }}
          className="max-w-3xl"
        >
          <h1 className="max-w-3xl text-[44px] font-semibold leading-[0.98] tracking-tight text-ink sm:text-[64px] lg:text-[74px]">
            Care for them without hovering.
          </h1>

          <p className="mt-6 max-w-2xl text-lg leading-[1.6] text-inkSecondary sm:text-xl">
            TapCare helps families support daily medication, vitamin, and
            supplement routines with simple tap-to-confirm check-ins.
          </p>

          <div className="mt-8 flex flex-col gap-3 sm:flex-row">
            <a
              href="#kits"
              className="inline-flex items-center justify-center rounded-lg bg-ink px-6 py-3.5 text-base font-semibold text-white transition hover:bg-sageStrong focus:outline-none focus:ring-2 focus:ring-sage/30"
            >
              Choose a TapKit
            </a>
            <a
              href="#how"
              className="inline-flex items-center justify-center rounded-lg border border-stroke bg-white px-6 py-3.5 text-base font-semibold text-ink transition hover:border-sage/35 hover:bg-canvasMist/40 focus:outline-none focus:ring-2 focus:ring-sage/20"
            >
              See how it works
            </a>
          </div>

          <div className="mt-7 grid gap-3 text-sm text-inkSecondary sm:grid-cols-3">
            <ProofPoint label="Less guessing" value="Clear check-ins" />
            <ProofPoint label="Less nagging" value="Shared history" />
            <ProofPoint label="More peace" value="Setup help" />
          </div>

          <motion.div
            initial={{ opacity: 0, y: 18 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{
              duration: 0.65,
              ease: [0.16, 1, 0.3, 1],
              delay: 0.14,
            }}
            className="mt-8 overflow-hidden rounded-lg border border-stroke bg-white shadow-card lg:hidden"
          >
            <div className="relative h-[245px] bg-canvasMist">
              <Image
                src="/assets/tapkit-hero.png"
                alt="TapCare tags on a bottle, organizer, and phone"
                fill
                sizes="100vw"
                className="object-cover object-[44%_50%]"
                priority
              />
              <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-ink/58 to-transparent p-4 text-white">
                <p className="text-sm font-semibold">TapKit + TapCare app</p>
                <p className="mt-1 text-sm text-white/82">
                  The routine stays physical. The confirmation becomes clear.
                </p>
              </div>
            </div>
          </motion.div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20, scale: 0.98 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1], delay: 0.08 }}
          className="relative hidden lg:block"
        >
          <div className="liquid-surface relative overflow-hidden rounded-lg border border-stroke shadow-card">
            <div className="grid min-h-[560px] grid-cols-1 lg:grid-cols-[0.92fr_1fr]">
              <div className="relative order-2 min-h-[330px] bg-canvasMist/45 lg:order-1 lg:min-h-full">
                <Image
                  src="/assets/tapkit-hero.png"
                  alt="TapCare NFC tags on a medication bottle, weekly organizer, and iPhone"
                  fill
                  sizes="(min-width: 1024px) 42vw, 100vw"
                  className="object-cover object-[44%_50%]"
                  priority
                />
                <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-ink/50 to-transparent p-5 text-white">
                  <p className="text-sm font-semibold">TapKit hardware</p>
                  <p className="mt-1 max-w-xs text-sm text-white/82">
                    NFC stickers for bottles, trays, organizers, and refill
                    routines.
                  </p>
                </div>
              </div>

              <div className="relative order-1 flex min-h-[520px] items-center justify-center bg-canvas px-6 py-10 lg:order-2">
                <div className="absolute left-6 top-6 rounded-md border border-stroke bg-white/85 px-3 py-2 text-xs font-semibold text-sageStrong">
                  TapCare app
                </div>
                <PhoneMockup scene="logged" className="max-w-[270px]" />
                <div className="absolute bottom-8 right-5 hidden max-w-[220px] rounded-lg border border-stroke bg-white/92 p-4 shadow-card sm:block">
                  <p className="text-sm font-semibold text-ink">
                    Not monitoring. Just support.
                  </p>
                  <p className="mt-1 text-xs leading-relaxed text-inkSecondary">
                    A simple confirmation point for routines they already do.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}

function ProofPoint({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-lg border border-stroke bg-white p-4">
      <p className="text-sm font-medium text-inkTertiary">
        {label}
      </p>
      <p className="mt-1 text-xl font-semibold tracking-tight text-ink tabular">
        {value}
      </p>
    </div>
  );
}
