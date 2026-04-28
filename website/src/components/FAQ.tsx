"use client";

import { motion } from "framer-motion";
import { useState } from "react";

const FAQS = [
  {
    q: "Can I set this up for my parent?",
    a: "Yes. You can order the kit, place tags on bottles or organizers, create the routines in the app, and use the included setup help if you want someone to walk through the first setup with you.",
  },
  {
    q: "What if my parent is not techy?",
    a: "TapCare is built around a simple routine: tap the phone near the tag when the routine is done. Setup support is included so the first tags and routines do not have to be figured out alone.",
  },
  {
    q: "Can it work with pill organizers?",
    a: "Yes. TapCare tags can be placed on pill organizers, medication bottles, supplement tubs, vitamin containers, or another spot where the routine already happens.",
  },
  {
    q: "Can it work with vitamins and supplements?",
    a: "Yes. TapCare is for daily routines, including medications, vitamins, supplements, and other repeat check-ins that are easier when there is a clear confirmation point.",
  },
  {
    q: "What happens if a tag does not scan?",
    a: "You can still log a routine manually in the app, and setup support is included if a tag needs troubleshooting, repositioning, or replacing.",
  },
  {
    q: "Is this medical advice?",
    a: "No. TapCare is an organization and routine-support tool. It does not provide medical advice, diagnosis, or treatment. Always follow instructions from a qualified healthcare professional.",
  },
];

export function FAQ() {
  return (
    <section
      id="faq"
      className="scroll-mt-24 border-y border-stroke bg-white py-24 sm:py-32"
    >
      <div className="mx-auto grid max-w-7xl gap-10 px-5 sm:px-8 lg:grid-cols-[0.65fr_1fr]">
        <motion.div
          initial={{ opacity: 0, y: 18 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-80px" }}
          transition={{ duration: 0.55, ease: [0.16, 1, 0.3, 1] }}
        >
          <h2 className="text-4xl font-semibold leading-[1.06] tracking-tight text-ink sm:text-5xl">
            Practical answers before you order.
          </h2>
          <p className="mt-5 max-w-md text-lg leading-relaxed text-inkSecondary">
            Clear answers for families who want support to feel simple,
            respectful, and easy to start.
          </p>
        </motion.div>

        <div className="divide-y divide-stroke rounded-lg border border-stroke bg-canvas shadow-card">
          {FAQS.map((item, i) => (
            <FAQItem key={item.q} item={item} defaultOpen={i === 0} />
          ))}
        </div>
      </div>
    </section>
  );
}

function FAQItem({
  item,
  defaultOpen,
}: {
  item: { q: string; a: string };
  defaultOpen: boolean;
}) {
  const [open, setOpen] = useState(defaultOpen);

  return (
    <div className="px-5 py-5 sm:px-6">
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        aria-expanded={open}
        className="flex w-full items-center justify-between gap-4 text-left focus:outline-none focus:ring-2 focus:ring-sage/20"
      >
        <span className="text-base font-semibold text-ink sm:text-lg">
          {item.q}
        </span>
        <span
          className={`grid h-8 w-8 shrink-0 place-items-center rounded-lg bg-white text-sageStrong transition ${
            open ? "rotate-45" : ""
          }`}
          aria-hidden
        >
          <svg
            viewBox="0 0 24 24"
            className="h-4 w-4"
            fill="none"
            stroke="currentColor"
            strokeWidth="2.6"
            strokeLinecap="round"
          >
            <path d="M12 5v14" />
            <path d="M5 12h14" />
          </svg>
        </span>
      </button>
      <motion.div
        initial={false}
        animate={{
          height: open ? "auto" : 0,
          opacity: open ? 1 : 0,
        }}
        transition={{ duration: 0.28, ease: [0.16, 1, 0.3, 1] }}
        className="overflow-hidden"
      >
        <p className="max-w-2xl pt-3 text-base leading-relaxed text-inkSecondary">
          {item.a}
        </p>
      </motion.div>
    </div>
  );
}
