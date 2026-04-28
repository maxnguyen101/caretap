import Link from "next/link";
import { notFound } from "next/navigation";

type LegalPage = {
  title: string;
  description: string;
  sections: Array<{ heading: string; body: string[] }>;
};

const effectiveDate = "April 13, 2026";

const pages: Record<string, LegalPage> = {
  privacy: {
    title: "Privacy Policy",
    description:
      "How TapCare handles account, routine, medication, NFC tag, and caregiver relationship data.",
    sections: [
      {
        heading: "Information we collect",
        body: [
          "Account information such as email address, Apple ID identifier, display name, and selected role.",
          "Medication routine data such as medication names, schedules, dose occurrences, logs, reminder preferences, refill estimates, and optional notes.",
          "NFC tag association data used to connect a physical tag with a medication routine.",
          "Caregiver relationship and invitation data when you choose to share access.",
        ],
      },
      {
        heading: "How we use information",
        body: [
          "We use data to operate TapCare: displaying schedules, logging doses, sending reminders, syncing your account, and enabling caregiver access you explicitly create.",
          "TapCare does not sell personal information and does not use health data for advertising.",
        ],
      },
      {
        heading: "Storage and sharing",
        body: [
          "Synced account data is stored with Supabase infrastructure using security controls including TLS in transit and encryption at rest.",
          "Data is shared only with caregivers you invite, infrastructure providers needed to run the app, Apple when you use Sign in with Apple, or when required by law.",
        ],
      },
      {
        heading: "Deletion and contact",
        body: [
          "You can delete your account in the app. Server-side account data is removed within 30 days, and local cached data is erased on the device that initiated deletion.",
          "Questions can be sent to support@tapcare.app.",
        ],
      },
    ],
  },
  terms: {
    title: "Terms of Service",
    description: "The terms for using the TapCare app, website, and TapKit support.",
    sections: [
      {
        heading: "Service",
        body: [
          "TapCare is an organization and routine-support application. It supports NFC taps, manual logging, reminders, refill estimates, and optional family visibility.",
          "TapCare does not provide medical advice, diagnosis, or treatment.",
        ],
      },
      {
        heading: "Your responsibilities",
        body: [
          "You are responsible for entering accurate routine information, following your healthcare provider's instructions, and managing who you invite as a caregiver.",
          "You agree not to misuse the service, attempt to bypass security controls, or interfere with TapCare infrastructure.",
        ],
      },
      {
        heading: "Availability",
        body: [
          "We work to keep TapCare available, but we do not guarantee uninterrupted service. Features may change as the product improves.",
          "TapKit orders are processed through Stripe Payment Links, and Stripe handles checkout, receipts, and payment security.",
        ],
      },
      {
        heading: "Contact",
        body: ["Questions about these terms can be sent to support@tapcare.app."],
      },
    ],
  },
  "consumer-health-data": {
    title: "Consumer Health Data Policy",
    description:
      "Additional detail on how TapCare handles medication routine data that may be considered consumer health data.",
    sections: [
      {
        heading: "What counts as consumer health data",
        body: [
          "In TapCare, consumer health data can include medication names, dosages, schedules, dose logs, timestamps, sources of confirmation, reminders, refill estimates, and notes you enter.",
        ],
      },
      {
        heading: "Purpose of collection",
        body: [
          "We collect this data so the app can show your schedule, send reminders, log doses, sync your account, estimate refills, and support caregiver access you authorize.",
        ],
      },
      {
        heading: "Sharing and sale",
        body: [
          "TapCare does not sell consumer health data and does not share it for advertising.",
          "Consumer health data is shared only with caregivers you invite, infrastructure providers needed to operate TapCare, or when required by law.",
        ],
      },
      {
        heading: "Your rights",
        body: [
          "You can request access, correction, deletion, withdrawal of consent, or a portable copy of your data by contacting support@tapcare.app.",
        ],
      },
    ],
  },
  "data-deletion": {
    title: "Data Deletion",
    description: "How to delete your TapCare account and routine data.",
    sections: [
      {
        heading: "Delete in the app",
        body: [
          "Open TapCare, go to Settings, choose Legal & Privacy, then choose Delete Account. Confirm the prompt to remove your account and associated synced data.",
        ],
      },
      {
        heading: "What happens next",
        body: [
          "Local cached data is erased from the device that initiates deletion. Server-side account and routine data is permanently removed within 30 days.",
        ],
      },
      {
        heading: "Need help",
        body: [
          "If you cannot access the app, email support@tapcare.app from the email address associated with your TapCare account.",
        ],
      },
    ],
  },
  support: {
    title: "Support",
    description: "Get help with TapCare, TapKit pairing, shipping, and account questions.",
    sections: [
      {
        heading: "Contact",
        body: [
          "Email support@tapcare.app for app support, TapKit setup help, shipping questions, returns, or account deletion help.",
        ],
      },
      {
        heading: "Virtual setup support",
        body: [
          "Every TapKit includes optional virtual setup support. We can help pair the first tag, name routines clearly, and walk through caregiver invitations.",
        ],
      },
      {
        heading: "Shipping and returns",
        body: [
          "U.S. shipping is free on orders $25 and up. TapKit orders include 30-day returns. Stripe sends the receipt after checkout.",
        ],
      },
      {
        heading: "Medical disclaimer",
        body: [
          "TapCare is a personal organization tool. It does not provide medical advice, diagnosis, or treatment.",
        ],
      },
    ],
  },
};

type Props = {
  params: Promise<{ slug: string }>;
};

export async function generateMetadata({ params }: Props) {
  const { slug } = await params;
  const page = pages[slug];

  if (!page) {
    return { title: "TapCare" };
  }

  return {
    title: `${page.title} - TapCare`,
    description: page.description,
  };
}

export default async function LegalPage({ params }: Props) {
  const { slug } = await params;
  const page = pages[slug];

  if (!page) {
    notFound();
  }

  return (
    <main className="min-h-screen bg-canvas px-5 py-12 sm:px-8">
      <article className="mx-auto max-w-3xl rounded-lg border border-stroke bg-white p-6 shadow-card sm:p-10">
        <Link
          href="/"
          className="text-sm font-semibold text-sageStrong underline-offset-4 hover:underline"
        >
          Back to TapCare
        </Link>

        <p className="mt-10 text-sm font-semibold text-sageStrong">
          Effective {effectiveDate}
        </p>
        <h1 className="mt-3 text-4xl font-semibold tracking-tight text-ink">
          {page.title}
        </h1>
        <p className="mt-4 leading-relaxed text-inkSecondary">
          {page.description}
        </p>

        <div className="mt-10 space-y-9">
          {page.sections.map((section) => (
            <section key={section.heading}>
              <h2 className="text-xl font-semibold text-ink">{section.heading}</h2>
              <div className="mt-3 space-y-3 text-base leading-relaxed text-inkSecondary">
                {section.body.map((paragraph) => (
                  <p key={paragraph}>{paragraph}</p>
                ))}
              </div>
            </section>
          ))}
        </div>
      </article>
    </main>
  );
}
