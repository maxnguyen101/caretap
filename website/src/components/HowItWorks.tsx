"use client";

import { motion, MotionValue, useScroll, useTransform } from "framer-motion";
import { useRef } from "react";
import { PhoneMockup } from "./PhoneMockup";

const STEPS = [
  {
    title: "Stick a tag where the routine already lives.",
    body:
      "Bottles, weekly organizers, packets, trays — anywhere you reach when it’s time. The tag is thinner than a sticker.",
    accent: "warm",
  },
  {
    title: "Tap your iPhone. CareTap learns the moment.",
    body:
      "First tap pairs the tag in seconds. After that, the same physical motion logs the dose — no app to open, no buttons to press.",
    accent: "sage",
  },
  {
    title: "Caregivers see what was taken, in real time.",
    body:
      "Doses sync to anyone you’ve invited. Quiet hours, missed-dose alerts, and shared timeline — all built in.",
    accent: "sage",
  },
] as const;

const SCENES: Array<"due" | "tapping" | "logged"> = [
  "due",
  "tapping",
  "logged",
];

/**
 * Scroll-pinned feature reveal. The phone stays sticky while the user scrolls
 * through three feature copy blocks. The phone scene swaps on scroll progress.
 */
export function HowItWorks() {
  const containerRef = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start start", "end end"],
  });

  // 0 → 1 maps to step 0..2 with smooth interpolation between scenes
  const sceneIndex = useTransform(scrollYProgress, [0, 0.5, 1], [0, 1, 2]);

  return (
    <section id="how" ref={containerRef} className="relative bg-canvas">
      <div className="absolute inset-0 bg-porcelain-mesh opacity-60" />

      <div className="relative mx-auto max-w-6xl px-6 pt-28 pb-14 sm:pt-32">
        <motion.div
          initial={{ opacity: 0, y: 28 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.65, ease: [0.16, 1, 0.3, 1] }}
          className="max-w-2xl"
        >
          <p className="text-[12px] font-semibold uppercase tracking-wider text-sageStrong">
            The CareTap app
          </p>
          <h2 className="mt-4 text-4xl font-semibold leading-[1.08] tracking-tight text-ink sm:text-[2.75rem] sm:leading-tight">
            What happens after your TapKit arrives.
          </h2>
          <p className="mt-5 max-w-xl text-lg leading-relaxed text-inkSecondary">
            TapKit is the hardware. CareTap on iPhone is the quiet layer that
            pairs tags, syncs doses, and keeps caregivers in the loop — without
            turning your routine into another app to manage.
          </p>
        </motion.div>
      </div>

      {/* Sticky / scrubbing layout */}
      <div className="relative mx-auto max-w-6xl px-6 pb-24">
        <div className="grid lg:grid-cols-[1.1fr_1fr] lg:gap-12">
          {/* Sticky phone column */}
          <div className="hidden lg:block">
            <div className="sticky top-32 grid place-items-center pb-24">
              <ScrubbingPhone sceneIndex={sceneIndex} />
            </div>
          </div>

          {/* Scrolling text column */}
          <div className="flex flex-col gap-32 pt-12 lg:pt-32">
            {STEPS.map((step, i) => (
              <Step key={step.title} index={i} step={step} />
            ))}
          </div>
        </div>

        {/* Mobile fallback — show the three phone scenes inline */}
        <div className="grid gap-12 lg:hidden">
          {STEPS.map((step, i) => (
            <div key={`mobile-${step.title}`} className="grid gap-6">
              <PhoneMockup scene={SCENES[i]} className="mx-auto" />
              <div>
                <p className="text-[12px] font-semibold uppercase tracking-wider text-sageStrong">
                  Step {i + 1}
                </p>
                <h3 className="mt-2 text-2xl font-semibold leading-tight">
                  {step.title}
                </h3>
                <p className="mt-3 text-inkSecondary">{step.body}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function Step({
  step,
  index,
}: {
  step: (typeof STEPS)[number];
  index: number;
}) {
  return (
    <motion.div
      initial={{ opacity: 0.3, y: 24 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ amount: 0.55, once: false }}
      transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
      className="max-w-xl"
    >
      <p className="text-[12px] font-semibold uppercase tracking-wider text-sageStrong">
        Step {index + 1}
      </p>
      <h3 className="mt-2 text-3xl font-semibold leading-tight tracking-tight text-ink sm:text-4xl">
        {step.title}
      </h3>
      <p className="mt-4 text-lg text-inkSecondary">{step.body}</p>
    </motion.div>
  );
}

function ScrubbingPhone({
  sceneIndex,
}: {
  sceneIndex: MotionValue<number>;
}) {
  // Render three phone scenes stacked, fade between them based on sceneIndex.
  // Using `useTransform` for opacity per scene gives smooth crossfade.
  const opacity0 = useTransform(sceneIndex, [0, 1], [1, 0]);
  const opacity1 = useTransform(sceneIndex, [0.5, 1, 1.5], [0, 1, 0]);
  const opacity2 = useTransform(sceneIndex, [1.5, 2], [0, 1]);

  return (
    <div className="relative">
      <motion.div style={{ opacity: opacity0 }} className="absolute inset-0">
        <PhoneMockup scene="due" />
      </motion.div>
      <motion.div style={{ opacity: opacity1 }} className="absolute inset-0">
        <PhoneMockup scene="tapping" />
      </motion.div>
      <motion.div style={{ opacity: opacity2 }} className="relative">
        <PhoneMockup scene="logged" />
      </motion.div>
    </div>
  );
}
