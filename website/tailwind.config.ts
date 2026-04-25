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
          "Inter",
          "Segoe UI",
          "Roboto",
          "sans-serif",
        ],
      },
      boxShadow: {
        card: "0 6px 24px -8px rgba(0, 0, 0, 0.08)",
        cardLg: "0 18px 60px -20px rgba(0, 0, 0, 0.16)",
        sage: "0 12px 32px -12px rgba(66, 108, 100, 0.32)",
      },
      backgroundImage: {
        "sage-gradient":
          "linear-gradient(135deg, #426C64 0%, #587D76 50%, rgba(88,125,118,0.85) 100%)",
        "porcelain-mesh":
          "radial-gradient(circle at 15% 12%, rgba(180,138,101,0.18), transparent 55%), radial-gradient(circle at 85% 0%, rgba(88,125,118,0.22), transparent 50%), linear-gradient(180deg, #F6F5F1 0%, #E7EEEA 100%)",
      },
      animation: {
        floatSlow: "float 8s ease-in-out infinite",
        floatSlower: "float 12s ease-in-out infinite reverse",
      },
      keyframes: {
        float: {
          "0%, 100%": { transform: "translateY(0px)" },
          "50%": { transform: "translateY(-14px)" },
        },
      },
    },
  },
  plugins: [],
};

export default config;
