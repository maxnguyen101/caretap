"use client";

import { motion } from "framer-motion";
import { useState } from "react";

const FAQS = [
  {
    q: "Do I need a special phone for NFC?",
    a: "Any iPhone 7 or newer can read CareTap tags. The app pairs each tag in seconds — no extra hardware, no Bluetooth setup, no batteries.",
  },
  {
    q: "Is CareTap a replacement for my doctor or pharmacy?",
    a: "No. CareTap is an adherence tracker. We help you remember what to take and give caregivers visibility — but your prescriptions, dosing, and medical advice still come from your provider.",
  },
  {
    q: "What happens if I lose a tag?",
    a: "Pair a fresh one. The app has a “re-pair” option in Settings, so you can swap any tag for another in under a minute. Spare tags ship with every TapKit.",
  },
  {
    q: "Will the tag stick on my pill bottle?",
    a: "Yes. TapKit stickers use a medical-grade adhesive that holds on plastic, glass, paperboard, and pill organizers. Reposition once if needed.",
  },
  {
    q: "Can multiple people use the same TapKit?",
    a: "Yes — that’s actually the point. CareTap supports caregiver-patient pairs and shared households so the right tag logs to the right person, and everyone gets the right alerts.",
  },
  {
    q: "How fast does TapKit ship?",
    a: "Most orders ship within one business day from California, USPS first-class. Free shipping on orders $25+.",
  },
];

export function FAQ() {
  return (
    <section id="faq" className="bg-canvasMist/40 py-28 sm:py-36">
      <div className="mx-auto max-w-3xl px-6">
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-80px" }}
          transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
        >
          <p className="text-[12px] font-semibold uppercase tracking-wider text-sageStrong">
            FAQ
          </p>
          <h2 className="mt-4 text-4xl font-semibold leading-[1.08] tracking-tight text-ink sm:text-[2.75rem] sm:leading-tight">
            Questions, answered.
          </h2>
        </motion.div>

        <div className="mt-12 divide-y divide-stroke rounded-3xl bg-white shadow-card">
          {FAQS.map((item, i) => (
            <FAQItem key={item.q} item={item} defaultOpen={i === 0} />
          ))}
        </div>

        <p className="mt-8 text-center text-sm text-inkSecondary">
          Didn’t see your question?{" "}
          <a className="font-semibold text-sageStrong underline-offset-4 hover:underline" href="mailto:hello@tapcare.app">
            Email me directly.
          </a>
        </p>
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
    <div className="px-6 py-5">
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        aria-expanded={open}
        className="flex w-full items-center justify-between gap-4 text-left"
      >
        <span className="text-base font-semibold text-ink sm:text-lg">
          {item.q}
        </span>
        <span
          className={`grid h-7 w-7 shrink-0 place-items-center rounded-full bg-canvas text-sageStrong transition ${
            open ? "rotate-45" : ""
          }`}
          aria-hidden
        >
          <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round">
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
        transition={{ duration: 0.32, ease: [0.16, 1, 0.3, 1] }}
        className="overflow-hidden"
      >
        <p className="pt-3 text-base leading-relaxed text-inkSecondary">
          {item.a}
        </p>
      </motion.div>
    </div>
  );
}
