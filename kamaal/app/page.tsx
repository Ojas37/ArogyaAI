import { Navbar } from "@/components/navbar"
import { Footer } from "@/components/footer"
import { DisclaimerBanner } from "@/components/disclaimer-banner"
import { HeroSection } from "@/components/landing/hero-section"
import { ProblemSection } from "@/components/landing/problem-section"
import { FeaturesSection } from "@/components/landing/features-section"
import { TriageLevelsSection } from "@/components/landing/triage-levels-section"
import { SafetySection } from "@/components/landing/safety-section"
import { OfflineIndicator } from "@/components/offline-indicator"

export default function LandingPage() {
  return (
    <div className="flex min-h-screen flex-col">
      <DisclaimerBanner />
      <Navbar />
      <main className="flex-1">
        <HeroSection />
        <ProblemSection />
        <FeaturesSection />
        <TriageLevelsSection />
        <SafetySection />
      </main>
      <Footer />
      <OfflineIndicator />
    </div>
  )
}
