import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{ts,tsx,mdx}"],
  theme: {
    extend: {
      colors: {
        // Mirrors CareTapTheme.swift sage/porcelain palette.
        canvas: "#F6F5F1",
        canvasWarm: "#F1EFE9",
        canvasMist: "#E7EEEA",
        sage: "#587D76",
        sageStrong: "#426C64",
        warm: "#B48A65",
        ink: "#171A1C",
        inkSecondary: "#646C69",
        inkTertiary: "#919996",
        stroke: "#E5E5E0",
      },
      fontFamily: {
        sans: [
          "-apple-system",
          "BlinkMacSystemFont",
          '"SF Pro Display"',
          '"SF Pro Text"',
          '"Helvetica Neue"',
          "sans-serif",
        ],
      },
      boxShadow: {
        card: "0 2px 10px -6px rgba(0, 0, 0, 0.12)",
        cardLg: "0 8px 28px -18px rgba(0, 0, 0, 0.22)",
        sage: "0 4px 14px -10px rgba(66, 108, 100, 0.28)",
      },
    },
  },
  plugins: [],
};

export default config;
