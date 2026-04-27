import { LogoMark } from "./LogoMark";

export function Footer() {
  return (
    <footer className="bg-canvas py-12">
      <div className="mx-auto grid max-w-7xl gap-10 px-5 sm:px-8 lg:grid-cols-[1fr_auto]">
        <div>
          <div className="flex items-center gap-3">
            <LogoMark />
            <span className="text-base font-semibold tracking-tight text-ink">
              TapCare
            </span>
          </div>
          <p className="mt-4 max-w-md text-sm leading-relaxed text-inkSecondary">
            TapCare helps families support daily routines with simple
            tap-to-confirm check-ins. It is an organization tool, not medical
            advice.
          </p>
        </div>

        <div className="grid gap-6 text-sm text-inkSecondary sm:grid-cols-3 lg:text-right">
          <div>
            <p className="font-semibold text-ink">Product</p>
            <div className="mt-3 grid gap-2">
              <a className="transition hover:text-ink" href="#how">
                How it works
              </a>
              <a className="transition hover:text-ink" href="#kits">
                Kits
              </a>
              <a className="transition hover:text-ink" href="#support">
                Support
              </a>
            </div>
          </div>
          <div>
            <p className="font-semibold text-ink">Help</p>
            <div className="mt-3 grid gap-2">
              <a className="transition hover:text-ink" href="mailto:support@tapcare.app">
                Email support
              </a>
              <a className="transition hover:text-ink" href="/legal/support">
                Support policy
              </a>
              <a className="transition hover:text-ink" href="/legal/data-deletion">
                Data deletion
              </a>
            </div>
          </div>
          <div>
            <p className="font-semibold text-ink">Legal</p>
            <div className="mt-3 grid gap-2">
              <a className="transition hover:text-ink" href="/legal/privacy">
                Privacy
              </a>
              <a className="transition hover:text-ink" href="/legal/terms">
                Terms
              </a>
              <a
                className="transition hover:text-ink"
                href="/legal/consumer-health-data"
              >
                Health data
              </a>
            </div>
          </div>
        </div>
      </div>

      <div className="mx-auto mt-10 flex max-w-7xl flex-col gap-3 border-t border-stroke px-5 pt-6 text-xs text-inkTertiary sm:flex-row sm:items-center sm:justify-between sm:px-8">
        <p>© {new Date().getFullYear()} TapCare. All rights reserved.</p>
        <p>Secure checkout by Stripe. Free U.S. shipping on orders $25+.</p>
      </div>
    </footer>
  );
}
