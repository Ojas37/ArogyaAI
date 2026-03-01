"use client"

import Link from "next/link"
import {
  Plus,
  FolderOpen,
  MapPin,
  Settings,
  Activity,
  Landmark,
  Clock,
  Shield,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"

const navCards = [
  {
    icon: Plus,
    title: "New Assessment",
    description: "Start a new symptom check with voice or text input",
    href: "/chat",
    color: "bg-primary/10 text-primary",
    cta: "Start Now",
    primary: true,
  },
  {
    icon: Activity,
    title: "Vitals Monitor",
    description: "Track your health vitals like heart rate, BP, and SpO2",
    href: "/vitals",
    color: "bg-accent/10 text-accent",
    cta: "View Vitals",
    primary: false,
  },
  {
    icon: MapPin,
    title: "Nearby Hospitals",
    description: "Find hospitals within 10km using your current location",
    href: "/hospitals",
    color: "bg-triage-safe/10 text-triage-safe",
    cta: "Find Hospitals",
    primary: false,
  },
  {
    icon: FolderOpen,
    title: "Previous Reports",
    description: "View your past triage assessments and recommendations",
    href: "/results",
    color: "bg-triage-urgent/10 text-triage-urgent",
    cta: "View Reports",
    primary: false,
  },
  {
    icon: Landmark,
    title: "Govt. Schemes",
    description: "Explore free government healthcare programs you may be eligible for",
    href: "/schemes",
    color: "bg-primary/10 text-primary",
    cta: "Explore Schemes",
    primary: false,
  },
]

const recentAssessments = [
  {
    date: "Feb 28, 2026",
    symptom: "Headache & Mild Fever",
    level: "Self-Care",
    color: "bg-triage-safe text-triage-safe-foreground",
  },
  {
    date: "Feb 25, 2026",
    symptom: "Persistent Cough",
    level: "Urgent",
    color: "bg-triage-urgent text-triage-urgent-foreground",
  },
  {
    date: "Feb 20, 2026",
    symptom: "Skin Rash on Arm",
    level: "Self-Care",
    color: "bg-triage-safe text-triage-safe-foreground",
  },
]

export default function DashboardPage() {
  return (
    <div className="flex h-full flex-col overflow-y-auto">
      {/* page header */}
      <div className="border-b border-border/50 bg-background/80 px-6 py-5 backdrop-blur-lg">
        <div className="mx-auto max-w-5xl">
          <h1 className="text-xl font-bold tracking-tight text-foreground md:text-2xl">
            Welcome Back
          </h1>
          <p className="mt-0.5 text-sm text-muted-foreground">
            How can we help you today? Start a new assessment or explore your health data.
          </p>
        </div>
      </div>

      <div className="flex-1 px-6 py-6">
        <div className="mx-auto max-w-5xl">
          {/* Main action cards */}
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {navCards.map((card) => (
              <Link key={card.title} href={card.href}>
                <Card
                  className={`group h-full cursor-pointer border-border/50 transition-all hover:shadow-md ${
                    card.primary ? "border-primary/30 bg-primary/[0.03]" : "bg-card"
                  }`}
                >
                  <CardContent className="flex flex-col gap-4 p-5">
                    <div
                      className={`flex h-11 w-11 items-center justify-center rounded-xl ${card.color}`}
                    >
                      <card.icon className="h-5 w-5" />
                    </div>
                    <div>
                      <h2 className="text-base font-semibold text-card-foreground">{card.title}</h2>
                      <p className="mt-1 text-sm leading-relaxed text-muted-foreground">
                        {card.description}
                      </p>
                    </div>
                    <Button
                      variant={card.primary ? "default" : "outline"}
                      size="sm"
                      className="mt-auto w-fit"
                      tabIndex={-1}
                    >
                      {card.cta}
                    </Button>
                  </CardContent>
                </Card>
              </Link>
            ))}

            {/* Settings card */}
            <Link href="/settings">
              <Card
                className="group h-full cursor-pointer border-border/50 bg-card transition-all hover:shadow-md"
              >
                <CardContent className="flex flex-col gap-4 p-5">
                  <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-muted-foreground/10 text-muted-foreground">
                    <Settings className="h-5 w-5" />
                  </div>
                  <div>
                    <h2 className="text-base font-semibold text-card-foreground">Settings</h2>
                    <p className="mt-1 text-sm leading-relaxed text-muted-foreground">
                      Manage your profile and preferences
                    </p>
                  </div>
                  <Button variant="outline" size="sm" className="mt-auto w-fit" tabIndex={-1}>
                    Open Settings
                  </Button>
                </CardContent>
              </Card>
            </Link>
          </div>

          {/* Recent assessments */}
          <div className="mt-8">
            <div className="mb-4 flex items-center gap-2">
              <Clock className="h-4 w-4 text-muted-foreground" />
              <h2 className="text-lg font-semibold text-foreground">Recent Assessments</h2>
            </div>

            {recentAssessments.length > 0 ? (
              <div className="flex flex-col gap-3">
                {recentAssessments.map((assessment, i) => (
                  <Card key={i} className="border-border/50 bg-card shadow-sm">
                    <CardContent className="flex items-center justify-between p-4">
                      <div className="flex flex-col gap-1">
                        <p className="text-sm font-medium text-card-foreground">
                          {assessment.symptom}
                        </p>
                        <p className="text-xs text-muted-foreground">{assessment.date}</p>
                      </div>
                      <span
                        className={`rounded-full px-3 py-1 text-xs font-semibold ${assessment.color}`}
                      >
                        {assessment.level}
                      </span>
                    </CardContent>
                  </Card>
                ))}
              </div>
            ) : (
              <Card className="border-border/50 bg-card">
                <CardContent className="flex flex-col items-center gap-2 p-8 text-center">
                  <Shield className="h-8 w-8 text-muted-foreground/50" />
                  <p className="text-sm text-muted-foreground">
                    No assessments yet. Start your first health check above.
                  </p>
                </CardContent>
              </Card>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
