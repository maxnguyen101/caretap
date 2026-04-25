# TapKit Stripe Setup

CareTap's TapKit shop uses **Stripe Payment Links** for hosted, PCI-compliant
checkout. No backend is required. Users tap **Buy TapKit**, an `SFSafariViewController`
opens the Payment Link in-app, and Stripe redirects back to
`caretap://tapkit/success` (or `caretap://tapkit/cancel`) when the session ends.

---

## 1. Create Products + Prices in Stripe Dashboard

Go to https://dashboard.stripe.com/products and create one Product per pack
size. Each Product needs a one-time Price.

| Pack            | Tags | Price (USD) | Stripe Product Name | Payment Link Variable             |
| --------------- | ---- | ----------- | ------------------- | --------------------------------- |
| Starter Pack    | 5    | $14.99      | TapKit Starter Pack | `CareTapTapKitStarterPaymentLink` |
| Family Pack     | 10   | $25.00      | TapKit Family Pack  | `CareTapTapKitFamilyPaymentLink`  |

For each Product:

1. **Type:** One-time
2. **Currency:** USD
3. **Image:** Upload a TapKit hero image (use `Resources/Assets.xcassets/TapKitHeroArt`).
4. **Description:** Use the pack summary from `TapKitPack.catalog`.

> Tip: enable **Automatic tax** on the account if you collect tax on iPhone
> purchases in any state.

---

## 2. Payment Links — already wired in

The Stripe Payment Link URLs are **already configured** in `project.yml` and
`Info.plist`:

| Pack         | Payment Link URL                                              |
| ------------ | ------------------------------------------------------------- |
| Starter Pack | `https://buy.stripe.com/28E3cvelbbTN6Ad8riao800`             |
| Family Pack  | `https://buy.stripe.com/eVqfZh3GxcXR1fTcHyao801`            |

**The only remaining manual step** is to verify these Payment Links in Stripe
Dashboard are set to the correct prices ($14.99 for Starter, $25.00 for
Family). If they show different amounts, edit the Payment Link → Price in
Stripe Dashboard.

### Payment Link settings to verify

#### Settings tab

- **Price:** The pack's one-time Price ($14.99 or $25.00).
- **Quantity:** Allow customers to adjust → **disabled** (one pack per checkout).
- **Apple Pay / Google Pay:** Enabled (default).

#### Shipping tab

- **Collect shipping address:** **Required** (TapKit ships physical product).
- **Allowed countries:** Start with **United States**. Add more as you expand.
- **Shipping rates:**
  - Free shipping for orders $25+ → create a `Free over $25` rate (free) for
    cart totals ≥ $25 (Family Pack qualifies), and a flat-rate `$3.99` for the
    Starter Pack.
  - Or simpler: free shipping for all packs. Adjust to taste.

#### Customer information

- **Email:** Required (Stripe will email the receipt).
- **Phone number:** Optional.
- **Promotion codes:** Enabled (lets you ship discount codes to early users).

#### After payment

- **Don't show confirmation page → Redirect customers to your website**
- **Success URL** (use the matching slug):
  - Starter: `caretap://tapkit/success?pack=starter`
  - Family:  `caretap://tapkit/success?pack=family`

> Stripe will warn that custom URL schemes "may not work in all browsers" —
> that's fine. The app's `onOpenURL` handler picks up the redirect even when
> SFSafariViewController displays it.

---

## 3. Test the Flow

### Test mode

1. In Stripe Dashboard, switch to **Test mode** (top-left toggle).
2. Recreate the 2 Payment Links in test mode (test mode and live mode have
   separate Payment Links).
3. Override the live URLs with test-mode `https://buy.stripe.com/test_...`
   URLs via the `NEXT_PUBLIC_STRIPE_LINK_*` env vars (website) or by
   temporarily editing `project.yml` for the iOS app.
4. Use `4242 4242 4242 4242` (any future date, any CVC) to simulate a
   successful $14.99 checkout. Stripe will redirect to
   `caretap://tapkit/success?pack=starter`.
5. Tap **Done** in Safari to test the cancel path. The shop will show an
   info banner: "TapKit order canceled — your selection is still saved."

### Live mode

The live URLs are already in `project.yml` and `Info.plist`. No changes
needed before archiving for the App Store — just make sure the Stripe
Dashboard prices match ($14.99 Starter, $25.00 Family).

---

## 4. Confirm the Universal Link Domain (optional but recommended)

Right now CareTap uses the **custom URL scheme** `caretap://` for the success
redirect. iOS will always prefer the foreground app for custom schemes, so
this works in development. For App Store distribution you may also want a
**Universal Link** so the success page works in Safari even when the app
isn't installed (e.g. someone bought TapKit on Mac Safari).

The repo's `project.yml` already references `vercel-links-mu.vercel.app`
as the universal link host. Once the marketing website is live at
`tapcare.app`, you can switch the Stripe success URLs to:

```
https://tapcare.app/tapkit/success?pack=starter
```

…and add an `apple-app-site-association` entry mapping `/tapkit/*` to
the CareTap App ID (the existing AASA already handles `/tap/*`).

---

## 5. Order Fulfillment

Stripe handles the payment + receipt + shipping address collection. You'll
need to:

- Set up **email notifications** in Stripe → Settings → Email so you (Max)
  get an email when a TapKit ships.
- Print + ship the order. Stripe Dashboard → Payments shows the shipping
  address for each session.
- Optional: connect Stripe to **Shippo** or **EasyPost** via Zapier to
  auto-generate USPS labels.

Stripe will send the buyer:

- Receipt email (immediately on payment)
- Shipping update (when you mark the order fulfilled in Stripe Dashboard
  → Payments → … → Update tracking)

---

## 6. Webhooks (future)

Today, the app only knows about a successful purchase via the redirect URL.
That's good enough for the in-app confirmation card, but it does **not**
verify with Stripe that the payment really succeeded — a sufficiently
motivated user could open `caretap://tapkit/success` directly and see a
fake confirmation.

When you have a backend (Supabase Edge Functions are already in the project),
add:

1. A `stripe-webhook` Edge Function that listens for `checkout.session.completed`.
2. Persist the order to a `tapkit_orders` table (already a natural fit for
   Supabase).
3. Have the iOS shop fetch real order history from that table on launch
   (replacing the in-memory `tapKitOrderConfirmation`).

The current implementation is intentionally simple — a Stripe Payment Link
flow is the right shape for v1 because it's PCI-compliant, ships fast, and
needs no server.

---

## Quick checklist

- [x] Create 2 Products + Prices in Stripe Dashboard ($14.99 Starter, $25.00 Family)
- [x] Wire Payment Link URLs into `project.yml` and `Info.plist`
- [ ] **Verify** the prices on the two live Payment Links match $14.99 and $25.00
- [ ] Create 2 Payment Links in test mode (for dev builds)
- [ ] Verify in-app purchase works with test card `4242 4242 4242 4242`
- [ ] Verify cancel path shows the "saved" banner
