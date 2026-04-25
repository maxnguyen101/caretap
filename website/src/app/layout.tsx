import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "TapCare — Tap once. Logged.",
  description:
    "TapCare turns medication adherence into a single tap. Pre-printed NFC tags pair with the iPhone app so people remember what to take, and caregivers know it's done.",
  metadataBase: new URL("https://tapcare.app"),
  openGraph: {
    title: "TapCare — Tap once. Logged.",
    description:
      "Medication adherence, reimagined. Tap a CareTap-ready NFC tag and the dose is logged.",
    type: "website",
    url: "https://tapcare.app",
    siteName: "TapCare",
  },
  twitter: {
    card: "summary_large_image",
    title: "TapCare — Tap once. Logged.",
    description:
      "Medication adherence, reimagined. Tap a CareTap-ready NFC tag and the dose is logged.",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="scroll-smooth antialiased">
      <body className="bg-canvas text-ink font-sans">{children}</body>
    </html>
  );
}
