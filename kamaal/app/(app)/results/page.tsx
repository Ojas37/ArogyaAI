"use client"

import { useRouter } from "next/navigation"
import {
  Download,
  MapPin,
  RefreshCw,
  PhoneCall,
  AlertTriangle,
  ShieldCheck,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Progress } from "@/components/ui/progress"

const triageResult = {
  level: "urgent" as const,
  confidence: 78,
  symptom: "Persistent High Fever",
  date: "March 1, 2026",
  explanation:
    "Your symptoms indicate a persistent high fever that has lasted for more than 48 hours. While not immediately life-threatening, this warrants medical evaluation within the next 24 hours to determine the underlying cause and begin appropriate treatment.",
  redFlags: ["Fever above 102\u00b0F for extended period"],
  tips: [
    "Stay hydrated with water and electrolyte solutions",
    "Rest and avoid strenuous activity",
    "Monitor your temperature every 4 hours",
    "Seek medical attention within 24 hours",
  ],
}

const levelConfig = {
  "self-care": {
    label: "Self-Care",
    badgeClass: "bg-triage-safe text-triage-safe-foreground",
    icon: ShieldCheck,
  },
  urgent: {
    label: "Urgent",
    badgeClass: "bg-triage-urgent text-triage-urgent-foreground",
    icon: AlertTriangle,
  },
  emergency: {
    label: "Emergency",
    badgeClass: "bg-triage-emergency text-triage-emergency-foreground",
    icon: AlertTriangle,
  },
}

export default function ResultsPage() {
  const router = useRouter()
  const config = levelConfig[triageResult.level]

  return (
    <div className="flex h-full flex-col overflow-y-auto">
      {/* page header */}
      <div className="border-b border-border/50 bg-background/80 px-6 py-5 backdrop-blur-lg">
        <div className="mx-auto flex max-w-5xl items-center justify-between">
          <div>
            <h1 className="text-xl font-bold text-foreground md:text-2xl">Triage Results</h1>
            <p className="mt-0.5 text-sm text-muted-foreground">
              View your assessment results and recommendations
            </p>
          </div>
          <span className="text-xs text-muted-foreground">{triageResult.date}</span>
        </div>
      </div>

      <div className="flex-1 px-6 py-6">
        <div className="mx-auto max-w-2xl">
          <Card className="border-border/50 shadow-lg">
            <CardContent className="flex flex-col gap-6 p-6">
              {/* Level badge and confidence */}
              <div className="flex flex-col items-center gap-4 text-center">
                <div
                  className={`flex h-16 w-16 items-center justify-center rounded-full ${config.badgeClass}`}
                >
                  <config.icon className="h-8 w-8" />
                </div>
                <span
                  className={`inline-flex rounded-full px-4 py-1.5 text-sm font-bold ${config.badgeClass}`}
                >
                  {config.label}
                </span>
                <div className="w-full max-w-xs">
                  <div className="mb-1 flex items-center justify-between text-xs">
                    <span className="text-muted-foreground">Confidence Score</span>
                    <span className="font-semibold text-foreground">
                      {triageResult.confidence}%
                    </span>
                  </div>
                  <Progress value={triageResult.confidence} className="h-2" />
                </div>
              </div>

              {/* Symptom summary */}
              <div className="rounded-lg bg-muted/50 p-4">
                <p className="text-xs font-medium uppercase tracking-wider text-muted-foreground">
                  Assessed Symptom
                </p>
                <p className="mt-1 text-lg font-semibold text-foreground">
                  {triageResult.symptom}
                </p>
              </div>

              {/* Explanation */}
              <div>
                <p className="mb-2 text-xs font-medium uppercase tracking-wider text-muted-foreground">
                  Explanation
                </p>
                <p className="text-sm leading-relaxed text-foreground">
                  {triageResult.explanation}
                </p>
              </div>

              {/* Red flags */}
              {triageResult.redFlags.length > 0 && (
                <div className="rounded-lg border border-triage-emergency/30 bg-triage-emergency/5 p-4">
                  <p className="mb-2 text-xs font-semibold text-triage-emergency">
                    Red Flags Detected
                  </p>
                  <ul className="flex flex-col gap-1.5">
                    {triageResult.redFlags.map((flag) => (
                      <li key={flag} className="flex items-center gap-2 text-sm text-foreground">
                        <AlertTriangle className="h-3.5 w-3.5 shrink-0 text-triage-emergency" />
                        {flag}
                      </li>
                    ))}
                  </ul>
                </div>
              )}

              {/* Tips */}
              {triageResult.tips.length > 0 && (
                <div className="rounded-lg border border-triage-safe/30 bg-triage-safe/5 p-4">
                  <p className="mb-2 text-xs font-semibold text-triage-safe">
                    Recommended Actions
                  </p>
                  <ul className="flex flex-col gap-1.5">
                    {triageResult.tips.map((tip, i) => (
                      <li key={i} className="flex items-start gap-2 text-sm text-foreground">
                        <span className="mt-0.5 flex h-4 w-4 shrink-0 items-center justify-center rounded-full bg-triage-safe/20 text-[10px] font-bold text-triage-safe">
                          {i + 1}
                        </span>
                        {tip}
                      </li>
                    ))}
                  </ul>
                </div>
              )}

              {/* Action buttons */}
              <div className="flex flex-wrap gap-3">
                {triageResult.level === "emergency" && (
                  <Button className="gap-2 bg-triage-emergency text-triage-emergency-foreground hover:bg-triage-emergency/90">
                    <PhoneCall className="h-4 w-4" />
                    Call Ambulance
                  </Button>
                )}
                <Button
                  variant="outline"
                  className="gap-2"
                  onClick={() => router.push("/hospitals")}
                >
                  <MapPin className="h-4 w-4" />
                  Find Nearby Hospitals
                </Button>
                <Button variant="outline" className="gap-2">
                  <Download className="h-4 w-4" />
                  Download Report
                </Button>
                <Button variant="ghost" className="gap-2" onClick={() => router.push("/chat")}>
                  <RefreshCw className="h-4 w-4" />
                  New Assessment
                </Button>
              </div>
            </CardContent>
          </Card>

          <p className="mt-6 text-center text-xs text-muted-foreground">
            This is not a medical diagnosis. Always consult a licensed healthcare professional.
          </p>
        </div>
      </div>
    </div>
  )
}
