import { Navbar } from "@/components/landing/navbar";
import { Hero } from "@/components/landing/hero";
import { InfoCards } from "@/components/landing/info-cards";
import { CtaBanner } from "@/components/landing/cta-banner";
import { FadeInSection } from "@/components/landing/fade-in-section";

export default function Home() {
  return (
    <div className="min-h-screen bg-[#0a0a0a]">
      <Navbar />
      <main>
        <Hero />
        <FadeInSection>
          <InfoCards />
        </FadeInSection>
        <FadeInSection delay={150}>
          <CtaBanner />
        </FadeInSection>
      </main>
    </div>
  );
}