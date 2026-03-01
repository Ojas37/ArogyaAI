import {
  ShieldCheck,
  Ban,
  Lock,
  FileCheck,
  Layers,
} from "lucide-react"
import { Card, CardContent } from "@/components/ui/card"

const safetyLayers = [
  {
    layer: 1,
    icon: Ban,
    title: "LLM Never Controls Triage",
    description: "The language model generates explanations only. All triage decisions are made by deterministic ML.",
  },
  {
    layer: 2,
    icon: ShieldCheck,
    title: "ML + Rule Engine Decides",
    description: "XGBoost classifier combined with a medical rule engine determines urgency level with full auditability.",
  },
  {
    layer: 3,
    icon: Lock,
    title: "Red Flag Override",
    description: "Hard-coded safety rules override any ML prediction when critical symptoms like chest pain are detected.",
  },
  {
    layer: 4,
    icon: FileCheck,
    title: "LLM Explains Only",
    description: "After triage, the LLM generates a plain-language explanation of the decision in the user's language.",
  },
  {
    layer: 5,
    icon: Layers,
    title: "Output Validation & Fallback",
    description: "Every output is validated. If anything fails, safe fallback templates ensure users always get guidance.",
  },
]

const safetyBadges = [
  { label: "No Prescriptions", description: "Never prescribes medication" },
  { label: "No Diagnosis", description: "Only urgency triage" },
  { label: "Zero Hallucinations", description: "In triage decisions" },
]

export function SafetySection() {
  return (
    <section id="safety" className="bg-muted/40 py-20">
      <div className="mx-auto max-w-7xl px-6">
        <div className="mx-auto mb-12 max-w-2xl text-center">
          <p className="mb-2 text-sm font-semibold uppercase tracking-wider text-primary">
            Safety First
          </p>
          <h2 className="text-balance text-3xl font-bold tracking-tight text-foreground md:text-4xl">
            5-Layer Safety Architecture
          </h2>
          <p className="mt-4 text-pretty leading-relaxed text-muted-foreground">
            Medical safety is non-negotiable. Our architecture ensures
            deterministic, auditable decisions with zero LLM control over triage.
          </p>
        </div>

        {/* Safety badges */}
        <div className="mb-10 flex flex-wrap items-center justify-center gap-4">
          {safetyBadges.map((badge) => (
            <div
              key={badge.label}
              className="flex items-center gap-2 rounded-full border border-triage-safe/30 bg-triage-safe/10 px-4 py-2"
            >
              <ShieldCheck className="h-4 w-4 text-triage-safe" />
              <span className="text-sm font-medium text-foreground">
                {badge.label}
              </span>
            </div>
          ))}
        </div>

        {/* Safety layers */}
        <div className="mx-auto max-w-3xl">
          <div className="flex flex-col gap-4">
            {safetyLayers.map((layer) => (
              <Card
                key={layer.layer}
                className="border-border/50 bg-card shadow-sm"
              >
                <CardContent className="flex items-start gap-4 p-5">
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-primary/10">
                    <span className="text-sm font-bold text-primary">
                      {layer.layer}
                    </span>
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <layer.icon className="h-4 w-4 text-primary" />
                      <h3 className="font-semibold text-card-foreground">
                        {layer.title}
                      </h3>
                    </div>
                    <p className="mt-1 text-sm leading-relaxed text-muted-foreground">
                      {layer.description}
                    </p>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}
