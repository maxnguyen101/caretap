import Link from "next/link";

type Props = {
  searchParams: Promise<{ pack?: string }>;
};

export const metadata = {
  title: "Thanks — TapKit on the way",
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
    <main className="grid min-h-screen place-items-center bg-porcelain-mesh px-6 py-16">
      <div className="w-full max-w-md rounded-3xl bg-white p-8 text-center shadow-cardLg">
        <div className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-sage-gradient text-white shadow-sage">
          <svg
            viewBox="0 0 24 24"
            className="h-8 w-8"
            fill="none"
            stroke="currentColor"
            strokeWidth="2.6"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M5 12.5 10 17.5 19.5 8" />
          </svg>
        </div>

        <h1 className="mt-6 text-3xl font-semibold tracking-tight text-ink">
          Order confirmed
        </h1>
        <p className="mt-3 text-inkSecondary">
          Your <span className="font-semibold text-ink">{packLabel}</span> is
          on the way. Stripe will email you a receipt and tracking once it
          ships.
        </p>

        <div className="mt-6 rounded-2xl bg-canvas p-4 text-left text-sm text-inkSecondary">
          <p className="font-semibold text-ink">Next step</p>
          <p className="mt-1">
            If you haven’t already, download CareTap on iPhone and pair the
            tags when they arrive.
          </p>
        </div>

        <div className="mt-6 flex flex-col gap-3">
          <a
            href="https://apps.apple.com/app/caretap/id000000000"
            target="_blank"
            rel="noopener"
            className="inline-flex items-center justify-center gap-2 rounded-full bg-sage-gradient px-5 py-3 text-sm font-semibold text-white shadow-sage transition hover:brightness-110"
          >
            Download CareTap
          </a>
          <Link
            href="/"
            className="inline-flex items-center justify-center gap-1.5 rounded-full px-5 py-3 text-sm font-semibold text-ink ring-1 ring-stroke transition hover:bg-canvas"
          >
            Back to TapCare
          </Link>
        </div>
      </div>
    </main>
  );
}
