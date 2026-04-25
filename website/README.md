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

| Command | Purpose |
| ------- | ------- |
| `npm install` | Install dependencies (run from `website/`). |
| `npm run dev` | Local dev server at http://localhost:3000. |
| `npm run build` | Production build; use to verify before deploy or in CI. |
| `npm run deploy:prod` | Production deploy via Vercel CLI (see below). |

```bash
cd website
npm install
cp .env.example .env.local   # fill in Stripe Payment Link URLs
npm run dev
```

**First time with Vercel (from `website/`):** `npx vercel login`, then `npx vercel link` so the CLI knows which project to deploy. Linking is stored under `.vercel/`, which is gitignored, so it stays local to your machine.

If `npm run build` fails with a filesystem error under `.next/`, remove the cache and retry: `rm -rf .next && npm run build`.

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

## Deploy (Vercel)

From the `website/` directory (after `npm install`):

1. **Log in once:** `npx vercel login`
2. **Link the project (first time only):** run `npx vercel link` in `website/` and follow the prompts (choose team/project or create new).
3. **Environment variables:** add Stripe and other public env vars in the [Vercel dashboard](https://vercel.com) for this project, or use `npx vercel env add` for each key (e.g. repeat for all `NEXT_PUBLIC_STRIPE_LINK_*` vars from the table above). Do not commit secrets; do not put tokens in the repo.
4. **Monorepos:** if this app lives in a subfolder of a larger repo, set **Root Directory** to `website` (or the path to this Next app) in the project **Settings** so builds run from the right place.
5. **Production deploy:** `npm run deploy:prod` (alias for `vercel --prod`).

**Preview / CI:** `npm run deploy` or `npm run vercel:preview` deploys a preview deployment.

After deploy, in the Vercel dashboard, add `tapcare.app` as a custom domain if needed.

## Update the App Store ID

Replace `id000000000` in `Hero.tsx` and `CTABand.tsx` with the real CareTap
App Store ID once the app is live.

## Update the Apple Team ID

`public/.well-known/apple-app-site-association` is configured for
`R662BH835Y.com.maxnguyen.caretap`, matching `project.yml` in the iOS
project. If the team ID changes, update both files.
