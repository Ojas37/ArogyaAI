import Link from "next/link"
import { Heart } from "lucide-react"

export function Footer() {
  return (
    <footer className="border-t border-border bg-muted/30">
      <div className="mx-auto max-w-7xl px-6 py-12">
        <div className="grid gap-8 md:grid-cols-4">
          <div className="md:col-span-2">
            <Link href="/" className="mb-4 flex items-center gap-2">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary">
                <Heart className="h-4 w-4 text-primary-foreground" />
              </div>
              <span className="text-lg font-bold text-foreground">ArogyaAI</span>
            </Link>
            <p className="max-w-sm text-sm leading-relaxed text-muted-foreground">
              Safe, explainable urgency guidance for everyone. Multilingual AI-powered
              medical triage assistant designed for accessibility.
            </p>
          </div>

          <div>
            <h3 className="mb-3 text-sm font-semibold text-foreground">Platform</h3>
            <ul className="flex flex-col gap-2">
              <li>
                <a href="#features" className="text-sm text-muted-foreground hover:text-foreground">
                  Features
                </a>
              </li>
              <li>
                <a href="#safety" className="text-sm text-muted-foreground hover:text-foreground">
                  Safety
                </a>
              </li>
              <li>
                <Link href="/auth" className="text-sm text-muted-foreground hover:text-foreground">
                  Get Started
                </Link>
              </li>
            </ul>
          </div>

          <div>
            <h3 className="mb-3 text-sm font-semibold text-foreground">Legal</h3>
            <ul className="flex flex-col gap-2">
              <li>
                <a href="#" className="text-sm text-muted-foreground hover:text-foreground">
                  Privacy Policy
                </a>
              </li>
              <li>
                <a href="#" className="text-sm text-muted-foreground hover:text-foreground">
                  Terms of Service
                </a>
              </li>
              <li>
                <a href="#" className="text-sm text-muted-foreground hover:text-foreground">
                  Disclaimer
                </a>
              </li>
            </ul>
          </div>
        </div>

        <div className="mt-10 border-t border-border pt-6">
          <div className="flex flex-col items-center justify-between gap-4 md:flex-row">
            <p className="text-xs text-muted-foreground">
              This platform provides safe urgency guidance only. It does not diagnose,
              prescribe, or replace a licensed medical professional.
            </p>
            <p className="text-xs text-muted-foreground">
              Open for NGO & Government collaboration.
            </p>
          </div>
        </div>
      </div>
    </footer>
  )
}
