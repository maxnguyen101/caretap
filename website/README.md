# tapcare.app - TapCare website

Next.js 15 + Tailwind CSS + Framer Motion website for TapCare and the TapKit
shop. The site is centered on the iPhone app, the two live TapKit packs, and
virtual setup support.

## Current packs

| Pack | Tags | Price | Stripe Payment Link |
| --- | ---: | ---: | --- |
| Starter Pack | 5 | $14.99 | `https://buy.stripe.com/28E3cvelbbTN6Ad8riao800` |
| Family Pack | 10 | $25.00 | `https://buy.stripe.com/eVqfZh3GxcXR1fTcHyao801` |

Free U.S. shipping applies to orders $25 and up, so the Family Pack qualifies
by itself. Both packs include virtual setup support.

## Local development

| Command | Purpose |
| --- | --- |
| `npm install` | Install dependencies from `website/`. |
| `npm run dev` | Run local dev at `http://localhost:3000`. |
| `npm run build` | Verify a production build. |
| `npm run deploy:prod` | Publish to Vercel production. |

```bash
cd website
npm install
npm run dev
```

## Environment overrides

Production Stripe links are hardcoded in `src/lib/packs.ts` as fallbacks. Use
`.env.local` only when you need to override them with test-mode links:

```bash
NEXT_PUBLIC_STRIPE_LINK_STARTER=
NEXT_PUBLIC_STRIPE_LINK_FAMILY=
```

## Routes preserved for launch

- `/` - main product and kit page
- `/tapkit/thanks` - Stripe success fallback
- `/legal/privacy`
- `/legal/terms`
- `/legal/consumer-health-data`
- `/legal/data-deletion`
- `/legal/support`

Older URLs such as `/pricing`, `/how-it-works`, `/about`, `/apply`, `/contact`,
`/privacy`, and `/terms` redirect to the new page or legal routes.
