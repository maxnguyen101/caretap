"use client";

import { motion } from "framer-motion";

export function CTABand() {
  return (
    <section className="relative overflow-hidden bg-sage-gradient py-20">
      <div className="pointer-events-none absolute inset-0 mix-blend-soft-light opacity-30">
        <div className="absolute -top-32 left-1/4 h-[500px] w-[500px] rounded-full bg-white/30 blur-3xl" />
        <div className="absolute -bottom-24 right-10 h-[400px] w-[400px] rounded-full bg-warm/30 blur-3xl" />
      </div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, margin: "-80px" }}
        transition={{ duration: 0.6 }}
        className="relative mx-auto flex max-w-4xl flex-col items-center px-6 text-center text-white"
      >
        <h2 className="text-4xl font-semibold leading-tight tracking-tight sm:text-5xl">
          Start with TapKit. Finish with one tap.
        </h2>
        <p className="mt-4 max-w-2xl text-lg text-white/85">
          Choose a TapKit pack, then add CareTap on iPhone. The first pairing
          takes about a minute. Every dose after that is a single tap at the
          bottle.
        </p>

        <div className="mt-8 flex flex-col items-center gap-3 sm:flex-row">
          <a
            href="#tapkit"
            className="inline-flex items-center justify-center gap-2 rounded-full bg-white px-7 py-3.5 text-base font-semibold text-sageStrong shadow-cardLg transition hover:brightness-105"
          >
            Order TapKit
            <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round">
              <path d="M5 12h14" />
              <path d="m12 5 7 7-7 7" />
            </svg>
          </a>
          <a
            href="https://apps.apple.com/app/caretap/id000000000"
            target="_blank"
            rel="noopener"
            className="inline-flex items-center justify-center gap-2 rounded-full bg-white/15 px-6 py-3.5 text-base font-semibold text-white ring-1 ring-white/30 backdrop-blur transition hover:bg-white/20"
          >
            <svg viewBox="0 0 24 24" className="h-5 w-5" fill="currentColor">
              <path d="M16.4 12.85a4.7 4.7 0 0 1 2.55-4.18 5.32 5.32 0 0 0-4.2-2.27c-1.78-.18-3.5 1.05-4.4 1.05-.93 0-2.32-1.03-3.83-1-1.97.03-3.81 1.15-4.84 2.92-2.07 3.59-.53 8.86 1.46 11.76.97 1.42 2.13 3.01 3.65 2.95 1.46-.06 2.02-.94 3.78-.94 1.76 0 2.27.94 3.83.91 1.59-.03 2.59-1.43 3.55-2.86a12.78 12.78 0 0 0 1.62-3.32 4.55 4.55 0 0 1-2.97-4.02ZM13.61 4.92a4.55 4.55 0 0 0 1.05-3.27 4.65 4.65 0 0 0-3.05 1.57 4.36 4.36 0 0 0-1.07 3.16c1.18.09 2.33-.55 3.07-1.46Z" />
            </svg>
            Download CareTap
          </a>
        </div>
      </motion.div>
    </section>
  );
}
