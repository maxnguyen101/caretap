"use client";

import { motion } from "framer-motion";

export function ProblemSection() {
  return (
    <section className="border-y border-stroke bg-white py-20 sm:py-24">
      <div className="mx-auto grid max-w-7xl gap-10 px-5 sm:px-8 lg:grid-cols-[0.85fr_1fr] lg:items-center">
        <motion.div
          initial={{ opacity: 0, y: 18 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-80px" }}
          transition={{ duration: 0.55, ease: [0.16, 1, 0.3, 1] }}
        >
          <h2 className="text-4xl font-semibold leading-[1.06] tracking-tight text-ink sm:text-5xl">
            It is hard to know without asking again.
          </h2>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 18 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-80px" }}
          transition={{ duration: 0.55, ease: [0.16, 1, 0.3, 1], delay: 0.05 }}
          className="grid gap-5 text-lg leading-relaxed text-inkSecondary"
        >
          <p>
            Many families are in that awkward middle ground: your parent is
            independent, but you still worry about daily routines.
          </p>
          <p>
            TapCare gives them a simple way to confirm when something is done,
            without turning support into a big monitoring system or another
            daily argument.
          </p>
          <div className="grid gap-3 text-sm text-ink sm:grid-cols-3">
            <CalmCard title="Independence" body="They keep the routine." />
            <CalmCard title="Clarity" body="You see simple confirmations." />
            <CalmCard title="Less tension" body="Fewer check-in texts." />
          </div>
        </motion.div>
      </div>
    </section>
  );
}

function CalmCard({ title, body }: { title: string; body: string }) {
  return (
    <div className="rounded-lg border border-stroke bg-canvas p-4">
      <p className="font-semibold text-ink">{title}</p>
      <p className="mt-1 text-sm leading-relaxed text-inkSecondary">{body}</p>
    </div>
  );
}
