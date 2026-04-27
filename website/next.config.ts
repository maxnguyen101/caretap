import type { NextConfig } from "next";

const config: NextConfig = {
  reactStrictMode: true,
  experimental: {
    optimizePackageImports: ["framer-motion"],
  },
  async redirects() {
    return [
      { source: "/pricing", destination: "/#kits", permanent: false },
      { source: "/how-it-works", destination: "/#how", permanent: false },
      { source: "/about", destination: "/#support", permanent: false },
      { source: "/apply", destination: "/#kits", permanent: false },
      { source: "/contact", destination: "/legal/support", permanent: false },
      { source: "/privacy", destination: "/legal/privacy", permanent: false },
      { source: "/terms", destination: "/legal/terms", permanent: false },
    ];
  },
};

export default config;
