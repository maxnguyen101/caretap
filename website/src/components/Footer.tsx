export function Footer() {
  return (
    <footer className="border-t border-stroke bg-canvas py-12">
      <div className="mx-auto flex max-w-6xl flex-col gap-8 px-6 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <div className="flex items-center gap-2.5">
            <span className="grid h-8 w-8 place-items-center rounded-lg bg-sage-gradient text-white">
              <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
                <path d="M12 2v4" />
                <path d="m4.93 10.93 2.83 2.83" />
                <circle cx="12" cy="12" r="4" />
                <path d="M12 18v4" />
              </svg>
            </span>
            <span className="text-base font-semibold tracking-tight text-ink">
              TapCare
            </span>
          </div>
          <p className="mt-3 max-w-md text-sm text-inkSecondary">
            Built in Los Angeles by Max Nguyen. Designed to make medication
            adherence less work for everyone in the room.
          </p>
        </div>

        <div className="flex flex-col gap-3 text-sm text-inkSecondary sm:items-end">
          <div className="flex gap-6">
            <a className="transition hover:text-ink" href="mailto:hello@tapcare.app">Contact</a>
            <a className="transition hover:text-ink" href="/privacy">Privacy</a>
            <a className="transition hover:text-ink" href="/terms">Terms</a>
          </div>
          <p className="text-xs text-inkTertiary">
            © {new Date().getFullYear()} TapCare. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
  );
}
