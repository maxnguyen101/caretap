"use client";

import { motion } from "framer-motion";
import { PhoneMockup } from "./PhoneMockup";

export function Hero() {
  return (
    <section className="relative overflow-hidden bg-porcelain-mesh">
      <div className="pointer-events-none absolute -top-40 left-1/2 h-[600px] w-[600px] -translate-x-1/2 rounded-full bg-sage/15 blur-3xl" />
      <div className="pointer-events-none absolute -bottom-40 right-[-200px] h-[400px] w-[400px] rounded-full bg-warm/15 blur-3xl" />

      <div className="relative mx-auto flex max-w-6xl flex-col items-center gap-14 px-6 pt-32 pb-28 sm:pt-40 sm:pb-36 lg:flex-row lg:gap-20 lg:py-48">
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
          className="max-w-xl text-center lg:text-left"
        >
          <span className="inline-flex items-center gap-2 rounded-full border border-sage/25 bg-white/60 px-3 py-1 text-[12px] font-semibold uppercase tracking-wide text-sageStrong backdrop-blur">
            <span className="h-1.5 w-1.5 rounded-full bg-sageStrong" />
            TapKit — NFC tags for real routines
          </span>

          <h1 className="mt-8 text-[40px] font-semibold leading-[1.06] tracking-tight text-ink sm:text-[52px] lg:text-[60px]">
            CareTap-ready tags.
            <br />
            <span className="bg-gradient-to-br from-sageStrong to-warm bg-clip-text text-transparent">
              One tap logs the dose.
            </span>
          </h1>

          <p className="mt-7 text-lg leading-[1.55] text-inkSecondary sm:text-xl">
            TapKit ships pre-printed NFC stickers you pair once in the CareTap
            iPhone app. After that, the physical motion at the bottle or organizer
            is the log — for you and the people who care.
          </p>

          <motion.p
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{
              duration: 0.55,
              ease: [0.16, 1, 0.3, 1],
              delay: 0.15,
            }}
            className="mt-5 text-[15px] leading-relaxed text-ink sm:text-base"
          >
            <span className="font-medium text-ink">Starter</span>
            {" — "}
            <span className="tabular font-semibold text-ink">$14.99</span>
            <span className="text-inkSecondary"> · 5 tags</span>
            <span className="mx-2 text-inkTertiary" aria-hidden>
              ·
            </span>
            <span className="font-medium text-ink">Family</span>
            {" — "}
            <span className="tabular font-semibold text-ink">$25</span>
            <span className="text-inkSecondary"> · 10 tags</span>
            <span className="mt-2 block text-sm text-inkSecondary">
              Free U.S. shipping on orders $25+.
            </span>
          </motion.p>

          <div className="mt-10 flex flex-col items-center gap-4 sm:flex-row sm:items-stretch lg:items-stretch lg:justify-start">
            <a
              href="#tapkit"
              className="inline-flex items-center justify-center gap-2 rounded-full bg-sage-gradient px-7 py-3.5 text-base font-semibold text-white shadow-sage transition hover:brightness-110"
            >
              Shop TapKit
              <svg
                viewBox="0 0 24 24"
                className="h-4 w-4"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.6"
                strokeLinecap="round"
                strokeLinejoin="round"
                aria-hidden
              >
                <path d="M5 12h14" />
                <path d="m12 5 7 7-7 7" />
              </svg>
            </a>
            <a
              href="https://apps.apple.com/app/caretap/id000000000"
              target="_blank"
              rel="noopener"
              className="inline-flex items-center justify-center gap-2 rounded-full border border-stroke bg-white/80 px-6 py-3.5 text-base font-semibold text-ink backdrop-blur transition hover:bg-white"
            >
              <svg viewBox="0 0 24 24" className="h-5 w-5" fill="currentColor">
                <path d="M16.4 12.85a4.7 4.7 0 0 1 2.55-4.18 5.32 5.32 0 0 0-4.2-2.27c-1.78-.18-3.5 1.05-4.4 1.05-.93 0-2.32-1.03-3.83-1-1.97.03-3.81 1.15-4.84 2.92-2.07 3.59-.53 8.86 1.46 11.76.97 1.42 2.13 3.01 3.65 2.95 1.46-.06 2.02-.94 3.78-.94 1.76 0 2.27.94 3.83.91 1.59-.03 2.59-1.43 3.55-2.86a12.78 12.78 0 0 0 1.62-3.32 4.55 4.55 0 0 1-2.97-4.02ZM13.61 4.92a4.55 4.55 0 0 0 1.05-3.27 4.65 4.65 0 0 0-3.05 1.57 4.36 4.36 0 0 0-1.07 3.16c1.18.09 2.33-.55 3.07-1.46Z" />
              </svg>
              Download on App Store
            </a>
          </div>

          <div className="mt-10 flex flex-wrap items-center justify-center gap-x-6 gap-y-2 text-sm text-inkSecondary lg:justify-start">
            <span className="inline-flex items-center gap-2">
              <Dot /> Hand-tested before they ship
            </span>
            <span className="inline-flex items-center gap-2">
              <Dot /> CareTap on iPhone pairs in seconds
            </span>
            <span className="inline-flex items-center gap-2">
              <Dot /> Free U.S. ship $25+
            </span>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, scale: 0.92, y: 20 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          transition={{ duration: 0.9, ease: [0.16, 1, 0.3, 1], delay: 0.2 }}
          className="relative flex flex-1 justify-center lg:justify-end"
        >
          <div className="absolute inset-0 -z-10 mx-auto my-auto h-[420px] w-[420px] rounded-full bg-sage/15 blur-3xl" />

          <motion.div
            animate={{ y: [0, -10, 0] }}
            transition={{ duration: 6, repeat: Infinity, ease: "easeInOut" }}
            className="relative"
          >
            <PhoneMockup scene="due" className="drop-shadow-2xl" />

            {/* Floating bottle + tag accents */}
            <motion.div
              animate={{ y: [0, -8, 0], rotate: [0, -2, 0] }}
              transition={{ duration: 7, repeat: Infinity, ease: "easeInOut", delay: 0.5 }}
              className="absolute -bottom-6 -left-12 hidden rounded-3xl bg-white/90 p-4 shadow-cardLg backdrop-blur sm:block"
            >
              <div className="flex items-center gap-3">
                <div className="grid h-10 w-10 place-items-center rounded-xl bg-warm/15 text-warm">
                  <svg viewBox="0 0 24 24" className="h-5 w-5" fill="currentColor">
                    <path d="M5 4h14v3l-3 4v9H8v-9L5 7Z" />
                  </svg>
                </div>
                <div>
                  <p className="text-xs font-semibold">Bottle paired</p>
                  <p className="text-[10px] text-inkTertiary">+ NFC tag</p>
                </div>
              </div>
            </motion.div>

            <motion.div
              animate={{ y: [0, 8, 0], rotate: [0, 2, 0] }}
              transition={{ duration: 8, repeat: Infinity, ease: "easeInOut", delay: 1.2 }}
              className="absolute -top-4 -right-12 hidden rounded-3xl bg-white/90 p-4 shadow-cardLg backdrop-blur sm:block"
            >
              <div className="flex items-center gap-3">
                <div className="grid h-10 w-10 place-items-center rounded-xl bg-sage/15 text-sageStrong">
                  <svg viewBox="0 0 24 24" className="h-5 w-5" fill="currentColor">
                    <path d="M9 12.5 13 16.5 20.5 9 22 10.5 13 19.5 7.5 14Z" />
                  </svg>
                </div>
                <div>
                  <p className="text-xs font-semibold">9:41 AM</p>
                  <p className="text-[10px] text-inkTertiary">Logged</p>
                </div>
              </div>
            </motion.div>
          </motion.div>
        </motion.div>
      </div>
    </section>
  );
}

function Dot() {
  return <span className="h-1.5 w-1.5 rounded-full bg-sage" aria-hidden />;
}
