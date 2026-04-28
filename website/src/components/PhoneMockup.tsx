"use client";

import { motion } from "framer-motion";

type PhoneMockupProps = {
  scene?: "due" | "tapping" | "logged";
  className?: string;
};

/**
 * A clean, code-only iPhone mockup. We intentionally avoid raster images so
 * the page stays sharp at any resolution and ships a small bundle. The
 * `scene` prop swaps the body content to show the three core moments:
 * "due now" → "tap to log" → "logged".
 */
export function PhoneMockup({ scene = "due", className = "" }: PhoneMockupProps) {
  return (
    <div className={`relative aspect-[9/19] w-full max-w-[320px] ${className}`}>
      {/* Outer device frame */}
      <div className="absolute inset-0 rounded-[44px] bg-gradient-to-b from-[#1a1d1f] to-[#0d0f10] shadow-cardLg ring-1 ring-black/20" />
      <div className="absolute inset-[3px] rounded-[42px] bg-[#0e1112]" />

      {/* Side buttons */}
      <div className="absolute -right-[3px] top-[120px] h-12 w-[3px] rounded-r-md bg-[#202325]" />
      <div className="absolute -left-[3px] top-[100px] h-7 w-[3px] rounded-l-md bg-[#202325]" />
      <div className="absolute -left-[3px] top-[140px] h-12 w-[3px] rounded-l-md bg-[#202325]" />

      {/* Screen */}
      <div className="absolute inset-[8px] overflow-hidden rounded-[38px] bg-canvas">
        {/* Dynamic island */}
        <div className="absolute left-1/2 top-2 z-10 h-6 w-24 -translate-x-1/2 rounded-full bg-black" />

        <PhoneContent scene={scene} />
      </div>
    </div>
  );
}

function PhoneContent({ scene }: { scene: PhoneMockupProps["scene"] }) {
  return (
    <div className="flex h-full w-full flex-col bg-canvas px-5 pt-12 pb-6">
      {/* Time + small status */}
      <div className="flex items-center justify-between text-[10px] font-semibold text-ink">
        <span>9:41</span>
        <div className="flex items-center gap-1 opacity-70">
          <span>●●●●</span>
          <svg viewBox="0 0 16 12" className="h-3 w-4" fill="currentColor">
            <rect x="0" y="3" width="14" height="6" rx="1.5" stroke="currentColor" strokeWidth="0.8" fill="none" />
            <rect x="1.5" y="4.5" width="9" height="3" rx="0.5" />
            <rect x="14.5" y="5" width="1" height="2" rx="0.5" />
          </svg>
        </div>
      </div>

      <p className="mt-6 text-[11px] font-medium text-inkTertiary">
        Today
      </p>
      <h2 className="mt-1 text-[22px] font-semibold leading-tight">
        {scene === "logged" ? "All set." : "Lisinopril"}
      </h2>
      <p className="text-[13px] text-inkSecondary">
        {scene === "due" && "Due now • 10mg"}
          {scene === "tapping" && "Hold near the bottle..."}
        {scene === "logged" && "Logged at 9:41 AM"}
      </p>

      {/* Hero card */}
      <div className="mt-5 flex-1 rounded-2xl bg-white p-4 shadow-card">
        <div className="flex items-center gap-3">
          <div className="grid h-10 w-10 place-items-center rounded-xl bg-sage/15 text-sage">
            <svg viewBox="0 0 24 24" className="h-5 w-5" fill="currentColor">
              <path d="M12 2C7.58 2 4 5.58 4 10c0 4.62 4.4 8.62 7.04 10.55a1.6 1.6 0 0 0 1.92 0C15.6 18.62 20 14.62 20 10c0-4.42-3.58-8-8-8Zm0 11a3 3 0 1 1 0-6 3 3 0 0 1 0 6Z" />
            </svg>
          </div>
          <div className="flex-1">
            <p className="text-[13px] font-semibold">Bedside bottle</p>
            <p className="text-[11px] text-inkSecondary">10mg • once daily</p>
          </div>
          {scene === "logged" && (
            <span className="rounded-full bg-sage/15 px-2 py-1 text-[10px] font-semibold text-sageStrong">
              Done
            </span>
          )}
        </div>

        <div className="mt-4 grid place-items-center pb-2">
          {scene === "tapping" && (
            <div className="relative grid place-items-center">
              <motion.div
                className="absolute h-32 w-32 rounded-full bg-sage/15"
                animate={{ scale: [0.85, 1.15, 0.85], opacity: [0.4, 0.1, 0.4] }}
                transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
              />
              <motion.div
                className="absolute h-24 w-24 rounded-full bg-sage/20"
                animate={{ scale: [0.9, 1.1, 0.9], opacity: [0.7, 0.3, 0.7] }}
                transition={{ duration: 2, repeat: Infinity, ease: "easeInOut", delay: 0.4 }}
              />
              <div className="grid h-20 w-20 place-items-center rounded-full bg-sageStrong text-white">
                <svg viewBox="0 0 24 24" className="h-9 w-9" fill="currentColor">
                  <path d="M5 4h14a2 2 0 0 1 2 2v3h-2V6H5v12h3v2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2Zm10 9 6 6-2.4 2.4-3-3V22h-3v-7h7l-3-3 2.4-2.4Z" />
                </svg>
              </div>
            </div>
          )}

          {scene === "due" && (
            <div className="relative grid place-items-center pt-2">
              <div className="grid h-20 w-20 place-items-center rounded-full bg-sageStrong text-white">
                <svg viewBox="0 0 24 24" className="h-10 w-10" fill="currentColor">
                  <path d="M12 2a10 10 0 1 0 10 10A10 10 0 0 0 12 2Zm1 11h-4v-2h2V7h2Z" />
                </svg>
              </div>
              <p className="mt-3 text-[12px] font-semibold text-sageStrong">Due now</p>
            </div>
          )}

          {scene === "logged" && (
            <div className="grid place-items-center pt-2">
              <div className="grid h-20 w-20 place-items-center rounded-full bg-sage/15 text-sageStrong">
                <svg
                  viewBox="0 0 24 24"
                  className="h-10 w-10"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2.4"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <path d="M5 12.5 10 17.5 19.5 8" />
                </svg>
              </div>
              <p className="mt-3 text-[12px] font-semibold text-sageStrong">
                Logged · 9:41 AM
              </p>
            </div>
          )}
        </div>

        <div className="mt-4 grid grid-cols-3 gap-2">
          {["Mon", "Tue", "Wed"].map((day, i) => (
            <div
              key={day}
              className={`rounded-xl px-2 py-2 text-center text-[10px] font-semibold ${
                i < 2
                  ? "bg-sage/15 text-sageStrong"
                  : i === 2 && scene === "logged"
                  ? "bg-sage/15 text-sageStrong"
                  : "bg-canvas text-inkTertiary"
              }`}
            >
              {day}
            </div>
          ))}
        </div>
      </div>

      {/* Tab bar */}
      <div className="mt-3 flex items-center justify-around rounded-2xl bg-white px-2 py-2 shadow-card">
        <TabIcon active label="Home" />
        <TabIcon label="Plan" />
        <TabIcon label="Settings" />
      </div>
    </div>
  );
}

function TabIcon({ active = false, label }: { active?: boolean; label: string }) {
  return (
    <div
      className={`flex flex-col items-center gap-0.5 px-3 py-1.5 ${
        active ? "text-sageStrong" : "text-inkTertiary"
      }`}
    >
      <div className="h-[18px] w-[18px] rounded-md bg-current opacity-80" />
      <span className="text-[9px] font-semibold">{label}</span>
    </div>
  );
}
