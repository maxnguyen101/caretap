/**
 * TapKit pack catalog. Mirrors `TapKitPack.catalog` in the iOS app
 * (CareTap/Sources/Models/TapKitPack.swift) so pricing stays in sync
 * across product surfaces.
 *
 * `paymentLinkEnv` is read from environment variables in production. Each
 * Stripe Payment Link should be configured in Stripe Dashboard with a
 * success URL of `caretap://tapkit/success?pack=<slug>` AND a website
 * fallback of `https://tapcare.app/tapkit/thanks?pack=<slug>` so the
 * site works whether or not the iPhone app is installed.
 */
export type PackHighlight = "none" | "mostPopular";

export type Pack = {
  slug: "starter" | "family";
  title: string;
  subtitle: string;
  tagCount: number;
  priceCents: number;
  highlight: PackHighlight;
  summary: string;
  perks: string[];
  shippingNote: string;
  supportNote: string;
  /** ENV variable name that holds the Stripe Payment Link for this pack. */
  paymentLinkEnv: string;
  /** Hardcoded fallback URL used when the env var is empty. */
  paymentLinkFallback: string;
};

export const packs: Pack[] = [
  {
    slug: "starter",
    title: "Starter Pack",
    subtitle: "5 NFC tags",
    tagCount: 5,
    priceCents: 1499,
    highlight: "none",
    summary: "Best for one person getting started with up to five bottles or routines.",
    perks: [
      "5 TapCare-ready NFC stickers",
      "Virtual setup support included",
      "Hand-tested before shipping",
    ],
    shippingNote: "Standard U.S. shipping at checkout",
    supportNote: "Setup help included",
    paymentLinkEnv: "NEXT_PUBLIC_STRIPE_LINK_STARTER",
    paymentLinkFallback: "https://buy.stripe.com/28E3cvelbbTN6Ad8riao800",
  },
  {
    slug: "family",
    title: "Family Pack",
    subtitle: "10 NFC tags",
    tagCount: 10,
    priceCents: 2500,
    highlight: "mostPopular",
    summary: "Best for multiple bottles, vitamins, supplements, or shared household routines.",
    perks: [
      "10 TapCare-ready NFC stickers",
      "Free U.S. shipping",
      "Virtual setup support included",
    ],
    shippingNote: "Free U.S. shipping at $25+",
    supportNote: "Setup help included",
    paymentLinkEnv: "NEXT_PUBLIC_STRIPE_LINK_FAMILY",
    paymentLinkFallback: "https://buy.stripe.com/eVqfZh3GxcXR1fTcHyao801",
  },
];

export function formatPrice(cents: number): string {
  const dollars = cents / 100;
  return cents % 100 === 0
    ? `$${dollars.toFixed(0)}`
    : `$${dollars.toFixed(2)}`;
}

export function perTagPrice(pack: Pack): string {
  const perTag = pack.priceCents / pack.tagCount / 100;
  return `$${perTag.toFixed(2)} / tag`;
}

export function highlightLabel(highlight: PackHighlight): string | null {
  switch (highlight) {
    case "mostPopular":
      return "Best Value";
    default:
      return null;
  }
}

/**
 * Resolve the Stripe Payment Link for a pack. Prefers the env-var override
 * (so test-mode links can be swapped in without a code change), then falls
 * back to the hardcoded production URL.
 */
export function paymentLinkFor(pack: Pack): string {
  const fromEnv =
    typeof process !== "undefined" ? process.env[pack.paymentLinkEnv] : undefined;
  if (fromEnv && fromEnv.length > 0) return fromEnv;
  return pack.paymentLinkFallback;
}

export const tapKitPromises = [
  "Free U.S. shipping on orders $25+",
  "Virtual setup support included with every kit",
  "Secure Stripe checkout",
  "30-day returns",
] as const;
