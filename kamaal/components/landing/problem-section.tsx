import {
  Heart,
  Globe,
  AlertTriangle,
  Clock,
} from "lucide-react"
import { Card, CardContent } from "@/components/ui/card"

const problems = [
  {
    icon: Heart,
    title: "Healthcare Access Gap",
    description:
      "Millions in rural areas lack access to timely medical guidance and basic health screening.",
  },
  {
    icon: Globe,
    title: "Language Barriers",
    description:
      "Healthcare information is rarely available in regional languages, leaving many underserved.",
  },
  {
    icon: AlertTriangle,
    title: "Doctor Shortage",
    description:
      "Severe shortage of doctors in rural regions means delayed consultations and overwhelmed clinics.",
  },
  {
    icon: Clock,
    title: "Delayed Emergency Detection",
    description:
      "Critical symptoms often go unrecognized, leading to dangerous delays in emergency care.",
  },
]

export function ProblemSection() {
  return (
    <section id="about" className="bg-muted/40 py-20">
      <div className="mx-auto max-w-7xl px-6">
        <div className="mx-auto mb-12 max-w-2xl text-center">
          <p className="mb-2 text-sm font-semibold uppercase tracking-wider text-primary">
            The Problem
          </p>
          <h2 className="text-balance text-3xl font-bold tracking-tight text-foreground md:text-4xl">
            Healthcare Shouldn{"'"}t Depend on Where You Live
          </h2>
          <p className="mt-4 text-pretty leading-relaxed text-muted-foreground">
            Millions face barriers to timely medical guidance every day. ArogyaAI
            bridges that gap with accessible, safe triage.
          </p>
        </div>

        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {problems.map((problem) => (
            <Card
              key={problem.title}
              className="border-border/50 bg-card shadow-sm transition-shadow hover:shadow-md"
            >
              <CardContent className="flex flex-col gap-4 p-6">
                <div className="flex h-11 w-11 items-center justify-center rounded-lg bg-primary/10">
                  <problem.icon className="h-5 w-5 text-primary" />
                </div>
                <h3 className="text-lg font-semibold text-card-foreground">
                  {problem.title}
                </h3>
                <p className="text-sm leading-relaxed text-muted-foreground">
                  {problem.description}
                </p>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </section>
  )
}
