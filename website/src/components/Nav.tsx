"use client";

import Link from "next/link";
import { motion, useScroll, useTransform } from "framer-motion";
import { LogoMark } from "./LogoMark";

export function Nav() {
  const { scrollY } = useScroll();
  const opacity = useTransform(scrollY, [0, 96], [0, 1]);

  return (
    <header className="fixed inset-x-0 top-0 z-50">
      <motion.div
        aria-hidden
        style={{ opacity }}
        className="absolute inset-0 border-b border-stroke/80 bg-canvas/92 backdrop-blur-xl"
      />
      <nav className="relative mx-auto flex max-w-7xl items-center justify-between px-5 py-4 sm:px-8">
        <Link href="/" className="flex items-center gap-3 text-ink">
          <LogoMark />
          <span className="text-base font-semibold tracking-tight">TapCare</span>
        </Link>

        <div className="hidden items-center gap-7 text-sm text-inkSecondary md:flex">
          <a href="#how" className="transition hover:text-ink">
            How it works
          </a>
          <a href="#kits" className="transition hover:text-ink">
            Kits
          </a>
          <a href="#support" className="transition hover:text-ink">
            Support
          </a>
          <a href="#faq" className="transition hover:text-ink">
            FAQ
          </a>
        </div>

        <a
          href="#kits"
          className="inline-flex items-center justify-center rounded-lg bg-ink px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-sageStrong focus:outline-none focus:ring-2 focus:ring-sage/30"
        >
          Choose a TapKit
        </a>
      </nav>
    </header>
  );
}
