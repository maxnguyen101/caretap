"use client";

import { motion } from "framer-motion";
import {
  Pack,
  formatPrice,
  highlightLabel,
  packs,
  paymentLinkFor,
  perTagPrice,
} from "@/lib/packs";

export function TapKitSection() {
  return (
    <section
      id="tapkit"
      className="relative overflow-hidden bg-gradient-to-br from-canvas via-canvasMist/60 to-canvasWarm/80 py-28 sm:py-36"
    >
      <div className="pointer-events-none absolute -left-40 top-20 h-[420px] w-[420px] rounded-full bg-sage/20 blur-3xl" />
      <div className="pointer-events-none absolute -right-32 bottom-10 h-[360px] w-[360px] rounded-full bg-warm/20 blur-3xl" />

      <div className="relative mx-auto max-w-6xl px-6">
        <motion.div
          initial={{ opacity: 0, y: 28 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.65, ease: [0.16, 1, 0.3, 1] }}
          className="max-w-2xl"
        >
          <motion.p
            initial={{ opacity: 0, y: 12 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{
              duration: 0.5,
              ease: [0.16, 1, 0.3, 1],
              delay: 0.02,
            }}
            className="text-[12px] font-semibold uppercase tracking-wider text-sageStrong"
          >
            TapKit
          </motion.p>
          <motion.h2
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{
              duration: 0.6,
              ease: [0.16, 1, 0.3, 1],
              delay: 0.06,
            }}
            className="mt-4 text-4xl font-semibold leading-[1.08] tracking-tight text-ink sm:text-[2.75rem] sm:leading-tight"
          >
            Choose your pack. Checkout with Stripe.
          </motion.h2>
          <motion.p
            initial={{ opacity: 0, y: 14 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{
              duration: 0.55,
              ease: [0.16, 1, 0.3, 1],
              delay: 0.1,
            }}
            className="mt-5 max-w-xl text-lg leading-relaxed text-inkSecondary"
          >
            CareTap-ready NFC stickers, hand-tested before they ship. Pair once
            in the app and your bottle, organizer, or tray becomes the
            check-in. Free U.S. shipping on orders $25+.
          </motion.p>
        </motion.div>

        <div className="mt-14 grid gap-6 sm:grid-cols-2 lg:max-w-3xl">
          {packs.map((pack, i) => (
            <PackCard pack={pack} key={pack.slug} index={i} />
          ))}
        </div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-60px" }}
          transition={{ duration: 0.55, ease: [0.16, 1, 0.3, 1], delay: 0.12 }}
        >
          <TrustStrip />
        </motion.div>
      </div>
    </section>
  );
}

function PackCard({ pack, index }: { pack: Pack; index: number }) {
  const isRecommended = pack.highlight === "mostPopular";
  const label = highlightLabel(pack.highlight);

  return (
    <motion.a
      href={paymentLinkFor(pack)}
      target="_blank"
      rel="noopener"
      initial={{ opacity: 0, y: 24 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-80px" }}
      transition={{
        duration: 0.55,
        ease: [0.16, 1, 0.3, 1],
        delay: 0.08 + index * 0.07,
      }}
      className={[
        "group relative flex flex-col rounded-3xl border p-6 backdrop-blur-sm transition",
        isRecommended
          ? "border-sageStrong/40 bg-white/95 shadow-cardLg"
          : "border-stroke bg-white/85 shadow-card hover:shadow-cardLg",
      ].join(" ")}
    >
      {label && (
        <span
          className={[
            "absolute -top-3 left-6 rounded-full px-3 py-1 text-[10px] font-bold uppercase tracking-wider",
            pack.highlight === "mostPopular" && "bg-sageStrong text-white shadow-sage",
          ]
            .filter(Boolean)
            .join(" ")}
        >
          {label}
        </span>
      )}

      <div className="flex items-start justify-between gap-3">
        <div>
          <h3 className="text-lg font-semibold text-ink">{pack.title}</h3>
          <p className="text-sm text-inkSecondary">{pack.subtitle}</p>
        </div>
        <div className="grid h-10 w-10 place-items-center rounded-xl bg-sage/10 text-sageStrong">
          <svg viewBox="0 0 24 24" className="h-5 w-5" fill="currentColor">
            <path d="M5 6.5A2.5 2.5 0 0 1 7.5 4h9A2.5 2.5 0 0 1 19 6.5v.6L20.4 9 19 11v6.5a2.5 2.5 0 0 1-2.5 2.5h-9A2.5 2.5 0 0 1 5 17.5V11l-1.4-2 1.4-1.9V6.5Z" />
          </svg>
        </div>
      </div>

      <div className="mt-5 flex items-baseline gap-2">
        <span className="text-3xl font-semibold tracking-tight tabular text-ink">
          {formatPrice(pack.priceCents)}
        </span>
        <span className="text-sm text-inkTertiary">{perTagPrice(pack)}</span>
      </div>

      <p className="mt-3 text-sm text-inkSecondary">{pack.summary}</p>

      <ul className="mt-5 space-y-2 text-sm text-ink">
        {pack.perks.map((perk) => (
          <li key={perk} className="flex items-start gap-2">
            <svg
              viewBox="0 0 24 24"
              className="mt-1 h-3.5 w-3.5 shrink-0 text-sageStrong"
              fill="none"
              stroke="currentColor"
              strokeWidth="3"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M5 12.5 10 17.5 19.5 8" />
            </svg>
            <span>{perk}</span>
          </li>
        ))}
      </ul>

      <div className="mt-auto pt-6">
        <span
          className={[
            "inline-flex w-full items-center justify-center gap-1.5 rounded-full px-4 py-3 text-sm font-semibold transition",
            isRecommended
              ? "bg-sage-gradient text-white shadow-sage group-hover:brightness-110"
              : "bg-canvas text-ink ring-1 ring-stroke group-hover:bg-white",
          ].join(" ")}
        >
          Buy {pack.title}
          <svg
            viewBox="0 0 24 24"
            className="h-3.5 w-3.5"
            fill="none"
            stroke="currentColor"
            strokeWidth="2.6"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M5 12h14" />
            <path d="m12 5 7 7-7 7" />
          </svg>
        </span>
      </div>
    </motion.a>
  );
}

function TrustStrip() {
  const items = [
    { label: "Free U.S. shipping on orders $25+", icon: "ship" },
    { label: "30-day returns", icon: "return" },
    { label: "Secure Stripe checkout", icon: "lock" },
    { label: "Apple Pay supported", icon: "apple-pay" },
  ];
  return (
    <ul className="mt-12 flex flex-wrap items-center justify-center gap-x-6 gap-y-3 text-sm text-inkSecondary">
      {items.map((item) => (
        <li key={item.label} className="inline-flex items-center gap-2">
          <span className="grid h-7 w-7 place-items-center rounded-full bg-white shadow-card text-sageStrong">
            <TrustIcon kind={item.icon as TrustIconKind} />
          </span>
          {item.label}
        </li>
      ))}
    </ul>
  );
}

type TrustIconKind = "ship" | "return" | "lock" | "apple-pay";

function TrustIcon({ kind }: { kind: TrustIconKind }) {
  switch (kind) {
    case "ship":
      return (
        <svg viewBox="0 0 24 24" className="h-3.5 w-3.5" fill="currentColor">
          <path d="M3 6h11v9H3Zm12 3h4l2 3v3h-2a2 2 0 1 1-4 0h-4a2 2 0 1 1-4 0H4v-2h11Z" />
        </svg>
      );
    case "return":
      return (
        <svg viewBox="0 0 24 24" className="h-3.5 w-3.5" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
          <path d="M3 12a9 9 0 1 0 3-6.7" />
          <path d="M3 4v5h5" />
        </svg>
      );
    case "lock":
      return (
        <svg viewBox="0 0 24 24" className="h-3.5 w-3.5" fill="currentColor">
          <path d="M6 10V8a6 6 0 0 1 12 0v2h1v11H5V10Zm2 0h8V8a4 4 0 0 0-8 0Z" />
        </svg>
      );
    case "apple-pay":
      return (
        <svg viewBox="0 0 24 24" className="h-4 w-4" fill="currentColor">
          <path d="M6 5.5C5 4.6 5.2 3 6.4 2.4 7.4 3.3 7.2 4.9 6 5.5Zm2.4 1.4c-.3 0-1 .3-1.6.3s-1.3-.3-2-.3c-1 0-2.1.6-2.7 1.6-1.1 1.9-.3 4.7.8 6.2.5.7 1.2 1.6 2 1.5.8 0 1.1-.5 2.1-.5s1.2.5 2.1.5 1.4-.8 1.9-1.5c.6-.8.9-1.6 1-1.7-.1 0-1.9-.7-1.9-2.8 0-1.7 1.4-2.5 1.5-2.6-.8-1.2-2.1-1.3-2.6-1.3-.4 0-1.6.5-2.6.5ZM18 12.4h1.7c1.5 0 2.5-.8 2.5-2.2 0-1.4-1-2.2-2.5-2.2H17v8.4h1Zm0-5.4h1.4c1 0 1.7.5 1.7 1.4s-.6 1.5-1.7 1.5H18Zm5.6 7.8c1.4 0 1.9-1 2-1.4 0 .7.5 1.3 1.4 1.3h.5v-.8h-.4c-.4 0-.6-.3-.6-.6V11c0-1-.7-1.6-2.3-1.6s-2.4.6-2.4 1.7h.9c.1-.5.6-.8 1.5-.8s1.4.4 1.4 1v.5h-1.6c-1.4 0-2.4.6-2.4 1.7 0 1 .9 1.7 2 1.7Zm.3-.7c-.6 0-1.1-.3-1.1-.9 0-.6.5-.9 1.4-.9h1.4v.5c0 .9-.8 1.3-1.7 1.3Zm5 1c1.6 0 2.4-.6 2.4-1.6 0-.8-.4-1.3-1.3-1.5l-.7-.2c-.7-.2-1-.4-1-.8 0-.5.4-.8 1-.8.7 0 1 .3 1.1.7h.9c-.1-1-.9-1.6-2-1.6s-2 .6-2 1.7c0 .8.5 1.3 1.4 1.5l.8.1c.7.2 1 .4 1 .9 0 .5-.4.8-1.1.8s-1.2-.3-1.2-.8h-1c.1 1 .9 1.6 2.2 1.6Z" />
        </svg>
      );
  }
}
