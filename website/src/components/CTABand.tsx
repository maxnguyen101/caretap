"use client";

import { motion } from "framer-motion";

export function CTABand() {
  return (
    <section className="bg-ink py-20 text-white">
      <motion.div
        initial={{ opacity: 0, y: 18 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, margin: "-80px" }}
        transition={{ duration: 0.55, ease: [0.16, 1, 0.3, 1] }}
        className="mx-auto grid max-w-7xl gap-8 px-5 sm:px-8 lg:grid-cols-[1fr_auto] lg:items-end"
      >
        <div>
          <h2 className="max-w-3xl text-4xl font-semibold leading-[1.06] tracking-tight sm:text-5xl">
            Start with the kit, then set up the first routine with help if you
            need it.
          </h2>
          <p className="mt-5 max-w-2xl text-lg leading-relaxed text-white/68">
            Family Kit orders qualify for free U.S. shipping. Every kit includes
            optional virtual setup support.
          </p>
        </div>

        <div className="flex flex-col gap-3 sm:flex-row lg:flex-col">
          <a
            href="#kits"
            className="inline-flex items-center justify-center rounded-lg bg-white px-6 py-3.5 text-base font-semibold text-ink transition hover:bg-canvas"
          >
            Choose a kit
          </a>
          <a
            href="mailto:support@tapcare.app"
            className="inline-flex items-center justify-center rounded-lg border border-white/18 px-6 py-3.5 text-base font-semibold text-white transition hover:bg-white/8"
          >
            Ask a question
          </a>
        </div>
      </motion.div>
    </section>
  );
}
