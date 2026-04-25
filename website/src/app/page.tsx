import { CTABand } from "@/components/CTABand";
import { FAQ } from "@/components/FAQ";
import { Footer } from "@/components/Footer";
import { FounderNote } from "@/components/FounderNote";
import { Hero } from "@/components/Hero";
import { HowItWorks } from "@/components/HowItWorks";
import { Nav } from "@/components/Nav";
import { TapKitSection } from "@/components/TapKitSection";

export default function HomePage() {
  return (
    <main className="relative">
      <Nav />
      <Hero />
      <TapKitSection />
      <HowItWorks />
      <FounderNote />
      <FAQ />
      <CTABand />
      <Footer />
    </main>
  );
}
