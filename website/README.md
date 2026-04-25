# tapcare.app — TapCare marketing website

Next.js 15 + Tailwind CSS + Framer Motion landing page for TapCare and the
TapKit shop. Designed to match the iOS app's sage/porcelain palette and to
sell TapKit purchases through Stripe Payment Links.

## What's included

- **Apple-style hero** — large headline, gradient TapKit CTA, App Store CTA, code-only iPhone mockup with floating decorative cards. No raster art needed.
- **Scroll-pinned "How it works"** — phone mockup stays sticky on desktop while three feature blocks scrub past. The phone scene swaps from "due → tapping → logged" based on `useScroll` progress.
- **TapKit pricing section** — same 4 packs as the iOS app, "Best Value" + "Most Popular" highlights, per-tag pricing, and direct links to Stripe Payment Links via env vars.
- **Founder note** — USC pre-med framing, hand-test stat, contact email.
- **FAQ** — accessible accordion with 6 starter questions.
- **Sticky nav, CTA band, footer** — calm, motion-respecting transitions.
- **`/tapkit/thanks`** — Stripe success redirect target (web fallback for buyers without the app).
- **`/.well-known/apple-app-site-association`** — universal-link manifest covering `/tag/*`, `/tap/*`, `/tapkit/*`.

## Local development

```bash
cd website
npm install
cp .env.example .env.local   # fill in Stripe Payment Link URLs
npm run dev
```

Open http://localhost:3000.

## Stripe Payment Links

The website sells the same TapKit packs as the iOS app. For each pack create
a Stripe Payment Link in the Stripe Dashboard and put the URL in
`.env.local`:

| Pack       | Env Var                          |
| ---------- | -------------------------------- |
| Starter    | `NEXT_PUBLIC_STRIPE_LINK_STARTER`    |
| Family     | `NEXT_PUBLIC_STRIPE_LINK_FAMILY`     |
| Household  | `NEXT_PUBLIC_STRIPE_LINK_HOUSEHOLD`  |
| Pro        | `NEXT_PUBLIC_STRIPE_LINK_PRO`        |

Configure each Payment Link's **success redirect** to:

```
https://tapcare.app/tapkit/thanks?pack=<slug>
```

That URL deep-links into the iPhone app (via the AASA file in
`public/.well-known/apple-app-site-association`) when CareTap is installed,
and renders the friendly thanks page when it isn't.

The full Stripe configuration walkthrough lives in
`../TAPKIT_STRIPE_SETUP.md`.

## Deploy to Vercel

```bash
npx vercel link        # one-time
npx vercel env add NEXT_PUBLIC_STRIPE_LINK_STARTER  # repeat for each pack
npx vercel --prod
```

Then in the Vercel dashboard, add `tapcare.app` as a custom domain.

## Update the App Store ID

Replace `id000000000` in `Hero.tsx` and `CTABand.tsx` with the real CareTap
App Store ID once the app is live.

## Update the Apple Team ID

`public/.well-known/apple-app-site-association` is configured for
`R662BH835Y.com.maxnguyen.caretap`, matching `project.yml` in the iOS
project. If the team ID changes, update both files.
