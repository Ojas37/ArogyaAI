"use client"

import { useState } from "react"
import {
  Landmark,
  Search,
  ExternalLink,
  Users,
  Stethoscope,
  Baby,
  Heart,
  Pill,
  ShieldCheck,
  ChevronDown,
  ChevronUp,
  IndianRupee,
  CheckCircle2,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"

/* ---------- types ---------- */
interface Scheme {
  id: string
  name: string
  hindiName: string
  ministry: string
  icon: typeof Landmark
  category: string
  coverage: string
  eligibility: string[]
  benefits: string[]
  link: string
  highlight?: string
}

/* ---------- mock data ---------- */
const categories = ["All", "Insurance", "Maternal", "Child Health", "Senior", "Medicine", "Rural"]

const schemes: Scheme[] = [
  {
    id: "ayushman",
    name: "Ayushman Bharat - PMJAY",
    hindiName: "\u0906\u092f\u0941\u0937\u094d\u092e\u093e\u0928 \u092d\u093e\u0930\u0924",
    ministry: "Ministry of Health & Family Welfare",
    icon: ShieldCheck,
    category: "Insurance",
    coverage: "Up to Rs. 5,00,000 per family per year",
    eligibility: [
      "BPL families identified via SECC data",
      "No restriction on family size or age",
      "Covers pre-existing diseases from day one",
      "Portable across India (any empanelled hospital)",
    ],
    benefits: [
      "Cashless treatment at empanelled hospitals",
      "Covers 1,929+ treatment packages",
      "Includes 3 days pre-hospitalization expenses",
      "15 days post-hospitalization expenses covered",
    ],
    link: "https://pmjay.gov.in",
    highlight: "Most Popular",
  },
  {
    id: "jssk",
    name: "Janani Shishu Suraksha Karyakram (JSSK)",
    hindiName: "\u091c\u0928\u0928\u0940 \u0936\u093f\u0936\u0941 \u0938\u0941\u0930\u0915\u094d\u0937\u093e \u0915\u093e\u0930\u094d\u092f\u0915\u094d\u0930\u092e",
    ministry: "Ministry of Health & Family Welfare",
    icon: Baby,
    category: "Maternal",
    coverage: "Free delivery & treatment for mother and child",
    eligibility: [
      "All pregnant women delivering in public institutions",
      "Sick newborns up to 30 days after birth",
      "No income criteria required",
    ],
    benefits: [
      "Free and cashless delivery (normal & C-section)",
      "Free medicines, diagnostics, and blood",
      "Free transport from home to facility and back",
      "Free diet during stay at the facility",
    ],
    link: "https://nhm.gov.in/index1.php?lang=1&level=3&sublinkid=842&lid=308",
  },
  {
    id: "pmsma",
    name: "Pradhan Mantri Surakshit Matritva Abhiyan",
    hindiName: "\u092a\u094d\u0930\u0927\u093e\u0928\u092e\u0902\u0924\u094d\u0930\u0940 \u0938\u0941\u0930\u0915\u094d\u0937\u093f\u0924 \u092e\u093e\u0924\u0943\u0924\u094d\u0935 \u0905\u092d\u093f\u092f\u093e\u0928",
    ministry: "Ministry of Health & Family Welfare",
    icon: Stethoscope,
    category: "Maternal",
    coverage: "Free antenatal checkups on 9th of every month",
    eligibility: [
      "All pregnant women in their 2nd/3rd trimester",
      "Available at government health facilities",
      "No registration or ID required",
    ],
    benefits: [
      "Free comprehensive antenatal check-up",
      "Ultrasound and lab tests included",
      "Specialist OB/GYN consultation",
      "Early detection of high-risk pregnancies",
    ],
    link: "https://pmsma.nhp.gov.in",
  },
  {
    id: "rbsk",
    name: "Rashtriya Bal Swasthya Karyakram (RBSK)",
    hindiName: "\u0930\u093e\u0937\u094d\u091f\u094d\u0930\u0940\u092f \u092c\u093e\u0932 \u0938\u094d\u0935\u093e\u0938\u094d\u0925\u094d\u092f \u0915\u093e\u0930\u094d\u092f\u0915\u094d\u0930\u092e",
    ministry: "Ministry of Health & Family Welfare",
    icon: Users,
    category: "Child Health",
    coverage: "Free health screening for children 0-18 years",
    eligibility: [
      "All children from birth to 18 years",
      "Covers children in government and aided schools",
      "Anganwadi center children included",
    ],
    benefits: [
      "Screening for 4Ds: Defects, Diseases, Deficiencies, Development delays",
      "Free referral and treatment at District Early Intervention Centers",
      "Follow-up care included",
      "Mobile health teams visit schools and AWCs",
    ],
    link: "https://nhm.gov.in/index1.php?lang=1&level=4&sublinkid=1190&lid=583",
  },
  {
    id: "pmbjp",
    name: "Pradhan Mantri Bhartiya Jan Aushadhi Pariyojana",
    hindiName: "\u092a\u094d\u0930\u0927\u093e\u0928\u092e\u0902\u0924\u094d\u0930\u0940 \u092d\u093e\u0930\u0924\u0940\u092f \u091c\u0928 \u0914\u0937\u0927\u093f \u092a\u0930\u093f\u092f\u094b\u091c\u0928\u093e",
    ministry: "Dept. of Pharmaceuticals",
    icon: Pill,
    category: "Medicine",
    coverage: "Medicines at 50-90% cheaper than market price",
    eligibility: [
      "Open to all citizens (no income criteria)",
      "Available at Jan Aushadhi Kendras across India",
      "No prescription requirement for OTC medicines",
    ],
    benefits: [
      "1,900+ medicines and 280+ surgical supplies available",
      "Quality equivalent to branded medicines (WHO-GMP)",
      "Savings of 50-90% on medicine costs",
      "Jan Aushadhi Suvidha sanitary pads at Rs. 1 each",
    ],
    link: "https://janaushadhi.gov.in",
  },
  {
    id: "nphce",
    name: "National Programme for Health Care of the Elderly",
    hindiName: "\u0935\u0930\u093f\u0937\u094d\u0920 \u0928\u093e\u0917\u0930\u093f\u0915\u094b\u0902 \u0915\u0947 \u0938\u094d\u0935\u093e\u0938\u094d\u0925\u094d\u092f",
    ministry: "Ministry of Health & Family Welfare",
    icon: Heart,
    category: "Senior",
    coverage: "Free geriatric healthcare services",
    eligibility: [
      "All citizens aged 60 years and above",
      "Available at CHCs, District Hospitals, and Regional Geriatric Centers",
      "No income or BPL restriction",
    ],
    benefits: [
      "Dedicated geriatric OPD at district hospitals",
      "Free medicines for common elderly conditions",
      "Physiotherapy and rehabilitation services",
      "Home-based care for bed-ridden elderly",
    ],
    link: "https://nhm.gov.in",
  },
]

/* ---------- scheme card ---------- */
function SchemeCard({ scheme }: { scheme: Scheme }) {
  const [expanded, setExpanded] = useState(false)

  return (
    <Card className="border-border/50 bg-card shadow-sm transition-shadow hover:shadow-md">
      <CardContent className="flex flex-col gap-4 p-5">
        {/* top row */}
        <div className="flex items-start gap-4">
          <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-primary/10">
            <scheme.icon className="h-5 w-5 text-primary" />
          </div>
          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-2">
              <h3 className="text-sm font-semibold text-card-foreground">{scheme.name}</h3>
              {scheme.highlight && (
                <span className="rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-semibold text-primary">
                  {scheme.highlight}
                </span>
              )}
            </div>
            <p className="mt-0.5 text-xs text-muted-foreground">{scheme.hindiName}</p>
            <p className="mt-0.5 text-[11px] text-muted-foreground">{scheme.ministry}</p>
          </div>
        </div>

        {/* coverage */}
        <div className="flex items-center gap-2 rounded-lg bg-primary/5 px-3 py-2.5">
          <IndianRupee className="h-4 w-4 shrink-0 text-primary" />
          <span className="text-sm font-medium text-foreground">{scheme.coverage}</span>
        </div>

        {/* expand/collapse */}
        <button
          onClick={() => setExpanded(!expanded)}
          className="flex items-center gap-1.5 text-xs font-medium text-primary hover:underline"
        >
          {expanded ? "Show less" : "View eligibility & benefits"}
          {expanded ? <ChevronUp className="h-3 w-3" /> : <ChevronDown className="h-3 w-3" />}
        </button>

        {expanded && (
          <div className="flex flex-col gap-4">
            {/* eligibility */}
            <div>
              <p className="mb-2 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                Eligibility
              </p>
              <ul className="flex flex-col gap-1.5">
                {scheme.eligibility.map((item) => (
                  <li key={item} className="flex items-start gap-2 text-xs text-foreground">
                    <CheckCircle2 className="mt-0.5 h-3 w-3 shrink-0 text-triage-safe" />
                    {item}
                  </li>
                ))}
              </ul>
            </div>

            {/* benefits */}
            <div>
              <p className="mb-2 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                Benefits
              </p>
              <ul className="flex flex-col gap-1.5">
                {scheme.benefits.map((item) => (
                  <li key={item} className="flex items-start gap-2 text-xs text-foreground">
                    <CheckCircle2 className="mt-0.5 h-3 w-3 shrink-0 text-accent" />
                    {item}
                  </li>
                ))}
              </ul>
            </div>

            {/* apply link */}
            <a
              href={scheme.link}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex w-fit items-center gap-1.5"
            >
              <Button size="sm" variant="outline" className="gap-1.5">
                Visit Official Website
                <ExternalLink className="h-3 w-3" />
              </Button>
            </a>
          </div>
        )}
      </CardContent>
    </Card>
  )
}

/* ---------- main page ---------- */
export default function SchemesPage() {
  const [activeCategory, setActiveCategory] = useState("All")
  const [search, setSearch] = useState("")

  const filtered = schemes.filter((s) => {
    const matchesCategory = activeCategory === "All" || s.category === activeCategory
    const matchesSearch =
      !search ||
      s.name.toLowerCase().includes(search.toLowerCase()) ||
      s.hindiName.includes(search) ||
      s.category.toLowerCase().includes(search.toLowerCase())
    return matchesCategory && matchesSearch
  })

  return (
    <div className="flex h-full flex-col overflow-y-auto">
      {/* page header */}
      <div className="border-b border-border/50 bg-background/80 px-6 py-5 backdrop-blur-lg">
        <div className="mx-auto max-w-5xl">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10">
              <Landmark className="h-5 w-5 text-primary" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-foreground md:text-2xl">
                Government Health Schemes
              </h1>
              <p className="text-sm text-muted-foreground">
                Explore free and subsidized healthcare programs you may be eligible for
              </p>
            </div>
          </div>

          {/* search */}
          <div className="mt-4 flex items-center gap-2 rounded-xl border border-input bg-card px-3 py-2.5">
            <Search className="h-4 w-4 shrink-0 text-muted-foreground" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search schemes by name, category..."
              className="flex-1 bg-transparent text-sm text-card-foreground placeholder:text-muted-foreground focus:outline-none"
            />
          </div>

          {/* category filters */}
          <div className="mt-3 flex flex-wrap gap-2">
            {categories.map((cat) => (
              <button
                key={cat}
                onClick={() => setActiveCategory(cat)}
                className={`rounded-full border px-3 py-1.5 text-xs font-medium transition-colors ${
                  activeCategory === cat
                    ? "border-primary bg-primary/10 text-primary"
                    : "border-border bg-background text-muted-foreground hover:border-primary/40 hover:text-foreground"
                }`}
              >
                {cat}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* scheme cards */}
      <div className="flex-1 px-6 py-6">
        <div className="mx-auto max-w-5xl">
          <p className="mb-4 text-sm text-muted-foreground">
            {filtered.length} scheme{filtered.length !== 1 ? "s" : ""} found
          </p>

          {filtered.length > 0 ? (
            <div className="grid gap-4 md:grid-cols-2">
              {filtered.map((scheme) => (
                <SchemeCard key={scheme.id} scheme={scheme} />
              ))}
            </div>
          ) : (
            <Card className="border-border/50">
              <CardContent className="flex flex-col items-center gap-3 p-12 text-center">
                <Landmark className="h-10 w-10 text-muted-foreground/40" />
                <p className="text-sm text-muted-foreground">
                  No schemes match your search. Try a different keyword.
                </p>
              </CardContent>
            </Card>
          )}

          <p className="mt-8 text-center text-xs text-muted-foreground">
            Information is based on publicly available government data. Verify eligibility at your
            nearest government health facility or the official website.
          </p>
        </div>
      </div>
    </div>
  )
}
