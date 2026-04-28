import Link from "next/link";
import { LogoMark } from "@/components/LogoMark";

type Props = {
  searchParams: Promise<{ pack?: string }>;
};

export const metadata = {
  title: "Thanks - TapKit on the way",
};

export default async function ThanksPage({ searchParams }: Props) {
  const params = await searchParams;
  const packLabel = (() => {
    switch (params?.pack) {
      case "starter":
        return "Starter Pack (5 tags)";
      case "family":
        return "Family Pack (10 tags)";
      default:
        return "TapKit";
    }
  })();

  return (
    <main className="grid min-h-screen place-items-center bg-canvas px-5 py-16">
      <div className="w-full max-w-lg rounded-lg border border-stroke bg-white p-6 shadow-card sm:p-8">
        <div className="flex items-center gap-3">
          <LogoMark className="h-11 w-11" />
          <div>
            <p className="text-sm font-semibold text-ink">TapCare</p>
            <p className="text-xs text-inkTertiary">Order confirmed</p>
          </div>
        </div>

        <h1 className="mt-8 text-3xl font-semibold tracking-tight text-ink">
          Your kit is on the way.
        </h1>
        <p className="mt-3 leading-relaxed text-inkSecondary">
          Your <span className="font-semibold text-ink">{packLabel}</span> order
          is confirmed. Stripe will email your receipt, and we will send
          shipping updates when the kit is fulfilled.
        </p>

        <div className="mt-6 grid gap-3 rounded-lg border border-stroke bg-canvas p-4 text-sm text-inkSecondary">
          <p>
            <span className="font-semibold text-ink">Next step:</span> when the
            tags arrive, place the first one where the routine already happens
            and pair it in the TapCare iPhone app.
          </p>
          <p>
            <span className="font-semibold text-ink">Need help?</span> Virtual
            setup support is included with your kit.
          </p>
        </div>

        <div className="mt-6 flex flex-col gap-3 sm:flex-row">
          <a
            href="mailto:support@tapcare.app"
            className="inline-flex flex-1 items-center justify-center rounded-lg bg-ink px-5 py-3 text-sm font-semibold text-white transition hover:bg-sageStrong"
          >
            Email setup support
          </a>
          <Link
            href="/"
            className="inline-flex flex-1 items-center justify-center rounded-lg px-5 py-3 text-sm font-semibold text-ink ring-1 ring-stroke transition hover:bg-canvas"
          >
            Back to TapCare
          </Link>
        </div>
      </div>
    </main>
  );
}
