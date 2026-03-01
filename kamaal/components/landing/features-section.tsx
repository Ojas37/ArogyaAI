import {
  Mic,
  Brain,
  WifiOff,
  MapPin,
} from "lucide-react"
import { Card, CardContent } from "@/components/ui/card"

const features = [
  {
    icon: Mic,
    title: "Multilingual Voice & Text",
    description:
      "Speak or type in 10 Indian languages. Auto-detection ensures you get responses in your preferred language.",
    color: "bg-primary/10 text-primary",
  },
  {
    icon: Brain,
    title: "3-Level Urgency Triage",
    description:
      "AI-powered triage classifies symptoms into Self-Care, Urgent, or Emergency — never diagnosis, only safe guidance.",
    color: "bg-accent/10 text-accent",
  },
  {
    icon: WifiOff,
    title: "Offline-First Core",
    description:
      "Core triage works without internet using cached ML models. Reports sync automatically when connectivity returns.",
    color: "bg-triage-safe/10 text-triage-safe",
  },
  {
    icon: MapPin,
    title: "Nearby Hospitals",
    description:
      "Find hospitals within 10km using OpenStreetMap. Get directions with one tap, even in low-bandwidth areas.",
    color: "bg-triage-urgent/10 text-triage-urgent",
  },
]

export function FeaturesSection() {
  return (
    <section id="features" className="py-20">
      <div className="mx-auto max-w-7xl px-6">
        <div className="mx-auto mb-12 max-w-2xl text-center">
          <p className="mb-2 text-sm font-semibold uppercase tracking-wider text-primary">
            Solution
          </p>
          <h2 className="text-balance text-3xl font-bold tracking-tight text-foreground md:text-4xl">
            Smart Health Guidance, Built for Everyone
          </h2>
          <p className="mt-4 text-pretty leading-relaxed text-muted-foreground">
            ArogyaAI combines medical NLP, deterministic ML, and safety-first
            architecture to deliver reliable triage in any language.
          </p>
        </div>

        <div className="grid gap-6 sm:grid-cols-2">
          {features.map((feature) => (
            <Card
              key={feature.title}
              className="group border-border/50 bg-card shadow-sm transition-all hover:shadow-md"
            >
              <CardContent className="flex gap-5 p-6">
                <div
                  className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-xl ${feature.color}`}
                >
                  <feature.icon className="h-6 w-6" />
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-card-foreground">
                    {feature.title}
                  </h3>
                  <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                    {feature.description}
                  </p>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </section>
  )
}
