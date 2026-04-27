import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "TapCare - Care for Them Without Hovering",
  description:
    "TapCare helps families support daily medication, vitamin, and supplement routines with simple tap-to-confirm check-ins.",
  metadataBase: new URL("https://tapcare.app"),
  openGraph: {
    title: "TapCare - Care for them without hovering.",
    description:
      "Less guessing, less nagging, and more peace of mind for families supporting daily routines from a distance.",
    type: "website",
    url: "https://tapcare.app",
    siteName: "TapCare",
  },
  twitter: {
    card: "summary_large_image",
    title: "TapCare - Care for them without hovering.",
    description:
      "Simple tap-to-confirm check-ins for medication, vitamin, and supplement routines.",
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
