"use client"

import { useState } from "react"
import {
  Activity,
  Heart,
  Thermometer,
  Droplets,
  Wind,
  Scale,
  Plus,
  TrendingUp,
  TrendingDown,
  Minus,
  Calendar,
  Clock,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Progress } from "@/components/ui/progress"

/* ---------- types ---------- */
interface VitalRecord {
  id: string
  type: string
  value: string
  unit: string
  date: string
  time: string
  status: "normal" | "warning" | "critical"
}

interface VitalCard {
  key: string
  label: string
  icon: typeof Activity
  value: string
  unit: string
  range: string
  status: "normal" | "warning" | "critical"
  trend: "up" | "down" | "stable"
  lastUpdated: string
  fill: number
}

/* ---------- mock data ---------- */
const vitalCards: VitalCard[] = [
  {
    key: "heart-rate",
    label: "Heart Rate",
    icon: Heart,
    value: "72",
    unit: "bpm",
    range: "60-100 bpm",
    status: "normal",
    trend: "stable",
    lastUpdated: "2 hrs ago",
    fill: 72,
  },
  {
    key: "blood-pressure",
    label: "Blood Pressure",
    icon: Activity,
    value: "120/80",
    unit: "mmHg",
    range: "< 120/80 mmHg",
    status: "normal",
    trend: "stable",
    lastUpdated: "2 hrs ago",
    fill: 60,
  },
  {
    key: "temperature",
    label: "Temperature",
    icon: Thermometer,
    value: "98.6",
    unit: "\u00b0F",
    range: "97.8-99.1\u00b0F",
    status: "normal",
    trend: "stable",
    lastUpdated: "1 hr ago",
    fill: 50,
  },
  {
    key: "oxygen",
    label: "SpO2",
    icon: Droplets,
    value: "97",
    unit: "%",
    range: "95-100%",
    status: "normal",
    trend: "up",
    lastUpdated: "1 hr ago",
    fill: 97,
  },
  {
    key: "respiratory",
    label: "Respiratory Rate",
    icon: Wind,
    value: "16",
    unit: "breaths/min",
    range: "12-20 breaths/min",
    status: "normal",
    trend: "stable",
    lastUpdated: "3 hrs ago",
    fill: 55,
  },
  {
    key: "weight",
    label: "Weight",
    icon: Scale,
    value: "68.5",
    unit: "kg",
    range: "BMI 22.3",
    status: "normal",
    trend: "down",
    lastUpdated: "1 day ago",
    fill: 45,
  },
]

const recentHistory: VitalRecord[] = [
  {
    id: "1",
    type: "Heart Rate",
    value: "72",
    unit: "bpm",
    date: "Mar 1, 2026",
    time: "10:30 AM",
    status: "normal",
  },
  {
    id: "2",
    type: "Blood Pressure",
    value: "120/80",
    unit: "mmHg",
    date: "Mar 1, 2026",
    time: "10:30 AM",
    status: "normal",
  },
  {
    id: "3",
    type: "Temperature",
    value: "99.4",
    unit: "\u00b0F",
    date: "Feb 28, 2026",
    time: "8:00 PM",
    status: "warning",
  },
  {
    id: "4",
    type: "SpO2",
    value: "96",
    unit: "%",
    date: "Feb 28, 2026",
    time: "8:00 PM",
    status: "normal",
  },
  {
    id: "5",
    type: "Heart Rate",
    value: "88",
    unit: "bpm",
    date: "Feb 27, 2026",
    time: "3:15 PM",
    status: "warning",
  },
]

/* ---------- helpers ---------- */
const statusConfig = {
  normal: {
    label: "Normal",
    dot: "bg-triage-safe",
    badge: "bg-triage-safe/10 text-triage-safe",
  },
  warning: {
    label: "Elevated",
    dot: "bg-triage-urgent",
    badge: "bg-triage-urgent/10 text-triage-urgent",
  },
  critical: {
    label: "Critical",
    dot: "bg-triage-emergency",
    badge: "bg-triage-emergency/10 text-triage-emergency",
  },
}

function TrendIcon({ trend }: { trend: "up" | "down" | "stable" }) {
  if (trend === "up") return <TrendingUp className="h-3.5 w-3.5 text-triage-urgent" />
  if (trend === "down") return <TrendingDown className="h-3.5 w-3.5 text-accent" />
  return <Minus className="h-3.5 w-3.5 text-muted-foreground" />
}

/* ---------- add vitals modal ---------- */
function AddVitalForm({ onClose }: { onClose: () => void }) {
  const [vitalType, setVitalType] = useState("")
  const [value, setValue] = useState("")

  const vitalTypes = [
    "Heart Rate",
    "Blood Pressure",
    "Temperature",
    "SpO2",
    "Respiratory Rate",
    "Weight",
    "Blood Sugar",
  ]

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-foreground/20 backdrop-blur-sm">
      <Card className="mx-4 w-full max-w-md shadow-xl">
        <CardContent className="flex flex-col gap-5 p-6">
          <div>
            <h3 className="text-lg font-semibold text-card-foreground">Log Vital</h3>
            <p className="text-sm text-muted-foreground">Record a new vital sign reading</p>
          </div>

          <div className="flex flex-col gap-3">
            <label className="text-xs font-medium text-muted-foreground">Vital Type</label>
            <div className="flex flex-wrap gap-2">
              {vitalTypes.map((type) => (
                <button
                  key={type}
                  onClick={() => setVitalType(type)}
                  className={`rounded-full border px-3 py-1.5 text-xs font-medium transition-colors ${
                    vitalType === type
                      ? "border-primary bg-primary/10 text-primary"
                      : "border-border bg-card text-card-foreground hover:border-primary/40"
                  }`}
                >
                  {type}
                </button>
              ))}
            </div>
          </div>

          <div className="flex flex-col gap-1.5">
            <label htmlFor="vital-value" className="text-xs font-medium text-muted-foreground">
              Value
            </label>
            <input
              id="vital-value"
              type="text"
              value={value}
              onChange={(e) => setValue(e.target.value)}
              placeholder="e.g. 120/80"
              className="rounded-lg border border-input bg-background px-3 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
            />
          </div>

          <div className="flex gap-3">
            <Button variant="outline" className="flex-1" onClick={onClose}>
              Cancel
            </Button>
            <Button
              className="flex-1"
              disabled={!vitalType || !value}
              onClick={onClose}
            >
              Save Reading
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

/* ---------- main page ---------- */
export default function VitalsPage() {
  const [showForm, setShowForm] = useState(false)

  return (
    <div className="flex h-full flex-col overflow-y-auto">
      {/* page header */}
      <div className="border-b border-border/50 bg-background/80 px-6 py-5 backdrop-blur-lg">
        <div className="mx-auto flex max-w-5xl items-center justify-between">
          <div>
            <h1 className="text-xl font-bold text-foreground md:text-2xl">Vitals Monitor</h1>
            <p className="mt-0.5 text-sm text-muted-foreground">
              Track and log your health vitals over time
            </p>
          </div>
          <Button className="gap-2" onClick={() => setShowForm(true)}>
            <Plus className="h-4 w-4" />
            <span className="hidden sm:inline">Log Vital</span>
          </Button>
        </div>
      </div>

      <div className="flex-1 px-6 py-6">
        <div className="mx-auto max-w-5xl">
          {/* vital cards grid */}
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {vitalCards.map((vital) => {
              const sc = statusConfig[vital.status]
              return (
                <Card
                  key={vital.key}
                  className="border-border/50 bg-card shadow-sm transition-shadow hover:shadow-md"
                >
                  <CardContent className="flex flex-col gap-4 p-5">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2.5">
                        <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-primary/10">
                          <vital.icon className="h-4 w-4 text-primary" />
                        </div>
                        <span className="text-sm font-medium text-card-foreground">
                          {vital.label}
                        </span>
                      </div>
                      <TrendIcon trend={vital.trend} />
                    </div>

                    <div className="flex items-baseline gap-1.5">
                      <span className="text-3xl font-bold tracking-tight text-card-foreground">
                        {vital.value}
                      </span>
                      <span className="text-sm text-muted-foreground">{vital.unit}</span>
                    </div>

                    <div className="flex flex-col gap-1.5">
                      <div className="flex items-center justify-between text-[11px]">
                        <span className="text-muted-foreground">
                          Normal: {vital.range}
                        </span>
                        <span
                          className={`flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-semibold ${sc.badge}`}
                        >
                          <span className={`h-1.5 w-1.5 rounded-full ${sc.dot}`} />
                          {sc.label}
                        </span>
                      </div>
                      <Progress value={vital.fill} className="h-1.5" />
                    </div>

                    <p className="text-[10px] text-muted-foreground">
                      Last updated {vital.lastUpdated}
                    </p>
                  </CardContent>
                </Card>
              )
            })}
          </div>

          {/* recent readings */}
          <div className="mt-8">
            <div className="mb-4 flex items-center gap-2">
              <Clock className="h-4 w-4 text-muted-foreground" />
              <h2 className="text-lg font-semibold text-foreground">Recent Readings</h2>
            </div>

            <div className="flex flex-col gap-2">
              {recentHistory.map((record) => {
                const sc = statusConfig[record.status]
                return (
                  <Card key={record.id} className="border-border/50 bg-card shadow-sm">
                    <CardContent className="flex items-center justify-between p-4">
                      <div className="flex items-center gap-4">
                        <div className="flex flex-col items-center gap-0.5">
                          <Calendar className="h-3 w-3 text-muted-foreground" />
                          <span className="text-[10px] text-muted-foreground">{record.date}</span>
                          <span className="text-[10px] text-muted-foreground">{record.time}</span>
                        </div>
                        <div>
                          <p className="text-sm font-medium text-card-foreground">{record.type}</p>
                          <p className="text-xs text-muted-foreground">
                            {record.value} {record.unit}
                          </p>
                        </div>
                      </div>
                      <span
                        className={`flex items-center gap-1 rounded-full px-2.5 py-1 text-[10px] font-semibold ${sc.badge}`}
                      >
                        <span className={`h-1.5 w-1.5 rounded-full ${sc.dot}`} />
                        {sc.label}
                      </span>
                    </CardContent>
                  </Card>
                )
              })}
            </div>
          </div>
        </div>
      </div>

      {showForm && <AddVitalForm onClose={() => setShowForm(false)} />}
    </div>
  )
}
