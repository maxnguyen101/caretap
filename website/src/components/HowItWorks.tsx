"use client";

import { motion, MotionValue, useScroll, useTransform } from "framer-motion";
import { useRef } from "react";

const STEPS = [
  {
    title: "Place a tag where the routine already happens.",
    body:
      "Add a TapCare tag to a bottle, supplement tub, vitamin container, or weekly organizer.",
    accent: "warm",
  },
  {
    title: "Set the routine in the app.",
    body:
      "Choose the routine, timing, and whether a family member should be able to see check-ins.",
    accent: "sage",
  },
  {
    title: "They tap when it is done.",
    body:
      "The bottle becomes the check-in point. A quick tap creates a simple confirmation.",
    accent: "sage",
  },
  {
    title: "You can feel confident without hovering.",
    body:
      "Shared history makes support clearer, calmer, and less dependent on asking the same question every day.",
    accent: "sage",
  },
] as const;

/**
 * Scroll-pinned feature reveal. The left panel animates the physical routine
 * into a clear family confirmation while the steps scroll alongside it.
 */
export function HowItWorks() {
  const containerRef = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start start", "end end"],
  });

  const stage = useTransform(scrollYProgress, [0, 0.32, 0.64, 1], [0, 1, 2, 3]);

  return (
    <section
      id="how"
      ref={containerRef}
      className="relative overflow-hidden scroll-mt-24 bg-canvas"
    >
      <div className="relative mx-auto max-w-6xl px-6 pb-10 pt-24 sm:pt-28">
        <motion.div
          initial={{ opacity: 0, y: 28 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.65, ease: [0.16, 1, 0.3, 1] }}
          className="max-w-2xl"
        >
          <h2 className="text-4xl font-semibold leading-[1.08] tracking-tight text-ink sm:text-[2.75rem] sm:leading-tight">
            The bottle becomes the check-in point.
          </h2>
          <p className="mt-5 max-w-xl text-lg leading-relaxed text-inkSecondary">
            TapCare is designed to support routines, not take away
            independence. The goal is simple: make daily check-ins easier,
            clearer, and less stressful for everyone.
          </p>
        </motion.div>
      </div>

      <div className="relative mx-auto max-w-6xl px-6 pb-24">
        <div className="grid lg:grid-cols-[0.98fr_1fr] lg:gap-14">
          <div className="hidden lg:block">
            <div className="sticky top-24 grid min-h-[620px] place-items-center pb-20">
              <RoutineFlowPanel stage={stage} />
            </div>
          </div>

          <div className="hidden flex-col gap-8 pt-8 lg:flex lg:py-20">
            {STEPS.map((step, i) => (
              <Step key={step.title} index={i} step={step} />
            ))}
          </div>
        </div>

        <div className="grid gap-8 lg:hidden">
          <RoutineFlowPanel stage={stage} compact />
          <div className="grid gap-3">
            {STEPS.map((step, i) => (
              <Step key={`mobile-${step.title}`} index={i} step={step} />
            ))}
          </div>
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
      className="max-w-xl rounded-lg border border-stroke bg-white p-5 shadow-card sm:p-6"
    >
      <div className="flex gap-5">
        <div className="relative shrink-0">
          <span className="grid h-11 w-11 place-items-center rounded-lg border border-sage/20 bg-canvasMist text-sm font-semibold text-sageStrong">
            {index + 1}
          </span>
          {index < STEPS.length - 1 && (
            <span className="absolute left-1/2 top-12 h-[calc(100%+2rem)] w-px -translate-x-1/2 bg-gradient-to-b from-sage/30 to-transparent" />
          )}
        </div>
        <div>
          <p className="text-sm font-semibold text-sageStrong">
            Step {index + 1}
          </p>
          <h3 className="mt-2 text-2xl font-semibold leading-tight tracking-tight text-ink sm:text-3xl lg:text-4xl">
            {step.title}
          </h3>
          <p className="mt-4 text-lg leading-relaxed text-inkSecondary">
            {step.body}
          </p>
        </div>
      </div>
    </motion.div>
  );
}

function RoutineFlowPanel({
  stage,
  compact = false,
}: {
  stage: MotionValue<number>;
  compact?: boolean;
}) {
  const markerX = useTransform(stage, [0, 1, 2, 3], [78, 224, 302, 362]);
  const markerY = useTransform(stage, [0, 1, 2, 3], [78, 190, 286, 342]);
  const tapGlow = useTransform(stage, [0, 0.7, 1.5], [0.55, 1, 0.55]);
  const appOpacity = useTransform(stage, [0.35, 1.05], [0.38, 1]);
  const familyOpacity = useTransform(stage, [1.45, 2.35], [0.3, 1]);
  const historyOpacity = useTransform(stage, [2.25, 3], [0.3, 1]);
  const appProgress = useTransform(stage, [0.75, 1.6], ["18%", "100%"]);

  return (
    <div
      className={[
        "liquid-surface relative w-full max-w-[520px] overflow-hidden rounded-lg border border-sage/14 shadow-card",
        compact ? "min-h-[500px]" : "min-h-[600px]",
      ].join(" ")}
    >
      <div className="relative p-5 sm:p-6">
        <div className="flex items-center justify-between gap-4">
          <div>
            <p className="text-sm font-semibold text-sageStrong">
              Live routine flow
            </p>
            <p className="mt-1 text-sm text-inkSecondary">
              Physical cue to family clarity
            </p>
          </div>
          <motion.div
            animate={{ opacity: [0.62, 1, 0.62] }}
            transition={{ duration: 3.6, repeat: Infinity, ease: "easeInOut" }}
            className="rounded-md border border-sage/20 bg-canvasMist px-3 py-1.5 text-xs font-semibold text-sageStrong"
          >
            Synced
          </motion.div>
        </div>

        <div className="relative mt-8 min-h-[465px]">
          <svg
            viewBox="0 0 440 420"
            className="absolute inset-x-0 top-4 h-[420px] w-full text-sage/26"
            fill="none"
            aria-hidden
          >
            <path
              d="M78 78 C170 48 218 122 224 190 C230 270 292 310 362 342"
              stroke="currentColor"
              strokeWidth="2"
              strokeDasharray="7 9"
              strokeLinecap="round"
            />
            <path
              d="M74 78 C168 48 216 121 222 190 C228 268 290 308 360 342"
              stroke="url(#flowGradient)"
              strokeWidth="3"
              strokeLinecap="round"
            />
            <defs>
              <linearGradient id="flowGradient" x1="64" x2="368" y1="64" y2="356">
                <stop stopColor="#B48A65" stopOpacity="0.52" />
                <stop offset="0.52" stopColor="#587D76" stopOpacity="0.62" />
                <stop offset="1" stopColor="#426C64" stopOpacity="0.38" />
              </linearGradient>
            </defs>
          </svg>

          <motion.div
            style={{ x: markerX, y: markerY }}
            className="absolute left-0 top-0 z-[2] h-4 w-4 rounded-full border-2 border-white bg-sageStrong shadow-sage"
          />

          <motion.div
            style={{ opacity: tapGlow }}
            className="absolute left-0 top-2 z-10 w-[210px] rounded-lg border border-stroke bg-white p-4 shadow-card"
          >
            <div className="flex items-center justify-between">
              <p className="text-xs font-semibold text-inkTertiary">
                Tag placed
              </p>
              <span className="rounded-md bg-warm/12 px-2 py-1 text-[10px] font-semibold text-warm">
                Bottle
              </span>
            </div>
            <div className="mt-5 flex items-center gap-4">
              <div className="relative grid h-20 w-20 place-items-center rounded-lg border border-sage/18 bg-canvasMist">
                <motion.span
                  animate={{ scale: [0.78, 1.45], opacity: [0.32, 0] }}
                  transition={{ duration: 2.2, repeat: Infinity, ease: "easeOut" }}
                  className="absolute h-20 w-20 rounded-lg border border-sage/35"
                />
                <motion.span
                  animate={{ scale: [0.82, 1.28], opacity: [0.28, 0] }}
                  transition={{
                    duration: 2.2,
                    repeat: Infinity,
                    ease: "easeOut",
                    delay: 0.45,
                  }}
                  className="absolute h-20 w-20 rounded-lg border border-sage/35"
                />
                <span className="relative grid h-10 w-10 place-items-center rounded-md bg-sageStrong text-white shadow-sage">
                  <SignalIcon />
                </span>
              </div>
              <div>
                <p className="font-semibold tracking-tight text-ink">
                  Morning routine
                </p>
                <p className="mt-1 text-sm leading-relaxed text-inkSecondary">
                  The bottle is the check-in point.
                </p>
              </div>
            </div>
          </motion.div>

          <motion.div
            style={{ opacity: appOpacity }}
            className="absolute right-0 top-[128px] z-10 w-[230px] rounded-lg border border-stroke bg-[#fbfaf7]/95 p-4 shadow-card"
          >
            <div className="flex items-center justify-between">
              <p className="text-xs font-semibold text-sageStrong">
                TapCare app
              </p>
              <span className="h-2 w-2 rounded-full bg-sageStrong shadow-sage" />
            </div>
            <div className="mt-4 rounded-lg border border-stroke bg-white p-3">
              <p className="text-sm font-semibold text-ink">
                Vitamins + medication
              </p>
              <p className="mt-1 text-xs text-inkSecondary">
                Waiting for today&apos;s tap
              </p>
              <div className="mt-4 h-2 overflow-hidden rounded-full bg-canvasMist">
                <motion.div
                  className="h-full rounded-full bg-sageStrong"
                  style={{ width: appProgress }}
                />
              </div>
            </div>
            <motion.div
              animate={{ y: [0, -4, 0] }}
              transition={{ duration: 4.4, repeat: Infinity, ease: "easeInOut" }}
              className="mt-3 rounded-lg bg-ink px-4 py-3 text-white shadow-card"
            >
              <p className="text-sm font-semibold">Tap confirmed</p>
              <p className="mt-1 text-xs text-white/70">Logged at 9:41 AM</p>
            </motion.div>
          </motion.div>

          <motion.div
            style={{ opacity: familyOpacity }}
            className="absolute left-3 top-[302px] z-10 w-[220px] rounded-lg border border-stroke bg-white p-4 shadow-card"
          >
            <p className="text-xs font-semibold text-inkTertiary">
              Family view
            </p>
            <p className="mt-3 text-lg font-semibold leading-tight text-ink">
              Clear without another text.
            </p>
            <div className="mt-4 grid grid-cols-3 gap-2">
              {["Mon", "Tue", "Wed"].map((day) => (
                <span
                  key={day}
                  className="rounded-md bg-sage/12 px-2 py-2 text-center text-[11px] font-semibold text-sageStrong"
                >
                  {day}
                </span>
              ))}
            </div>
          </motion.div>

          <motion.div
            style={{ opacity: historyOpacity }}
            className="absolute bottom-0 right-2 z-10 w-[210px] rounded-lg border border-sage/18 bg-canvasMist p-4 shadow-card"
          >
            <div className="flex items-center justify-between gap-3">
              <p className="text-sm font-semibold text-ink">Peace of mind</p>
              <CheckIcon />
            </div>
            <p className="mt-2 text-sm leading-relaxed text-inkSecondary">
              A simple history makes support feel lighter.
            </p>
          </motion.div>
        </div>
      </div>
    </div>
  );
}

function SignalIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      className="h-5 w-5"
      fill="none"
      stroke="currentColor"
      strokeWidth="2.4"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden
    >
      <path d="M7 8h10" />
      <path d="M7 12h6" />
      <path d="M7 16h4" />
      <path d="M17 12c1.4 0.8 2.3 2.1 2.7 3.8" />
    </svg>
  );
}

function CheckIcon() {
  return (
    <span className="grid h-7 w-7 place-items-center rounded-md bg-sageStrong text-white shadow-sage">
      <svg
        viewBox="0 0 24 24"
        className="h-4 w-4"
        fill="none"
        stroke="currentColor"
        strokeWidth="2.8"
        strokeLinecap="round"
        strokeLinejoin="round"
        aria-hidden
      >
        <path d="M5 12.5 10 17.5 19.5 8" />
      </svg>
    </span>
  );
}
