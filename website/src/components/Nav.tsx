"use client";

import Link from "next/link";
import { motion, useScroll, useTransform } from "framer-motion";

export function Nav() {
  const { scrollY } = useScroll();
  const opacity = useTransform(scrollY, [0, 80], [0, 1]);
  const blur = useTransform(scrollY, [0, 80], [0, 12]);
  const filter = useTransform(blur, (v) => `blur(${v}px)`);

  return (
    <header className="fixed inset-x-0 top-0 z-50">
      <motion.div
        aria-hidden
        style={{ opacity, backdropFilter: filter, WebkitBackdropFilter: filter }}
        className="absolute inset-0 bg-canvas/70 border-b border-stroke/60"
      />
      <nav className="relative mx-auto flex max-w-6xl items-center justify-between px-6 py-4 sm:py-5">
        <Link href="/" className="flex items-center gap-2.5 text-ink">
          <span className="grid h-8 w-8 place-items-center rounded-lg bg-sage-gradient text-white shadow-sage">
            <svg
              viewBox="0 0 24 24"
              className="h-4 w-4"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.4"
              strokeLinecap="round"
              strokeLinejoin="round"
              aria-hidden
            >
              <path d="M12 2v4" />
              <path d="m4.93 10.93 2.83 2.83" />
              <circle cx="12" cy="12" r="4" />
              <path d="M12 18v4" />
            </svg>
          </span>
          <span className="text-base font-semibold tracking-tight">TapCare</span>
        </Link>

        <div className="hidden items-center gap-8 text-sm text-inkSecondary md:flex">
          <a href="#tapkit" className="transition hover:text-ink">TapKit</a>
          <a href="#how" className="transition hover:text-ink">The app</a>
          <a href="#story" className="transition hover:text-ink">Story</a>
          <a href="#faq" className="transition hover:text-ink">FAQ</a>
        </div>

        <a
          href="#tapkit"
          className="inline-flex items-center gap-1.5 rounded-full bg-sage-gradient px-4 py-2 text-sm font-semibold text-white shadow-sage transition hover:brightness-110"
        >
          Get TapKit
          <svg
            viewBox="0 0 24 24"
            className="h-3.5 w-3.5"
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
      </nav>
    </header>
  );
}
