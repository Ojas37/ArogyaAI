import Link from "next/link"
import { ArrowRight } from "lucide-react"
import { Button } from "@/components/ui/button"

const urgencyLevels = [
  {
    level: "Self-Care",
    color: "bg-triage-safe",
    textColor: "text-triage-safe-foreground",
    borderColor: "border-triage-safe/30",
    bgLight: "bg-triage-safe/10",
    description: "Mild symptoms that can be managed at home with rest, hydration, and basic care.",
    examples: "Common cold, mild headache, minor cuts",
  },
  {
    level: "Urgent",
    color: "bg-triage-urgent",
    textColor: "text-triage-urgent-foreground",
    borderColor: "border-triage-urgent/30",
    bgLight: "bg-triage-urgent/10",
    description: "Symptoms requiring medical attention within 24 hours. Not immediately life-threatening.",
    examples: "Persistent high fever, severe infection signs",
  },
  {
    level: "Emergency",
    color: "bg-triage-emergency",
    textColor: "text-triage-emergency-foreground",
    borderColor: "border-triage-emergency/30",
    bgLight: "bg-triage-emergency/10",
    description: "Critical symptoms requiring immediate medical attention. Seek emergency care now.",
    examples: "Chest pain, difficulty breathing, severe bleeding",
  },
]

export function TriageLevelsSection() {
  return (
    <section className="py-20">
      <div className="mx-auto max-w-7xl px-6">
        <div className="mx-auto mb-12 max-w-2xl text-center">
          <p className="mb-2 text-sm font-semibold uppercase tracking-wider text-primary">
            Triage System
          </p>
          <h2 className="text-balance text-3xl font-bold tracking-tight text-foreground md:text-4xl">
            Three Levels of Urgency Guidance
          </h2>
          <p className="mt-4 text-pretty leading-relaxed text-muted-foreground">
            Our AI classifies symptoms into three clear levels. This is urgency
            triage, not diagnosis — always consult a doctor for medical advice.
          </p>
        </div>

        <div className="grid gap-6 md:grid-cols-3">
          {urgencyLevels.map((item) => (
            <div
              key={item.level}
              className={`flex flex-col items-center rounded-2xl border ${item.borderColor} ${item.bgLight} p-8 text-center`}
            >
              <div className={`mb-4 flex h-16 w-16 items-center justify-center rounded-full ${item.color}`}>
                <span className={`text-lg font-bold ${item.textColor}`}>
                  {item.level === "Self-Care" ? "SC" : item.level === "Urgent" ? "UR" : "EM"}
                </span>
              </div>
              <h3 className="mb-2 text-xl font-bold text-foreground">{item.level}</h3>
              <p className="mb-3 text-sm leading-relaxed text-muted-foreground">
                {item.description}
              </p>
              <p className="text-xs text-muted-foreground">
                <span className="font-medium">Examples:</span> {item.examples}
              </p>
            </div>
          ))}
        </div>

        <div className="mt-10 text-center">
          <Link href="/auth">
            <Button size="lg" className="gap-2">
              Try It Now
              <ArrowRight className="h-4 w-4" />
            </Button>
          </Link>
        </div>
      </div>
    </section>
  )
}
