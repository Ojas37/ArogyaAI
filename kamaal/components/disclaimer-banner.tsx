import { AlertTriangle } from "lucide-react"

export function DisclaimerBanner() {
  return (
    <div className="border-b border-triage-urgent/20 bg-triage-urgent/5 px-4 py-2">
      <div className="mx-auto flex max-w-7xl items-center justify-center gap-2 text-center">
        <AlertTriangle className="hidden h-3.5 w-3.5 shrink-0 text-triage-urgent sm:block" />
        <p className="text-xs font-medium text-foreground">
          This platform provides safe urgency guidance only. It does not
          diagnose, prescribe, or replace a licensed medical professional.
        </p>
      </div>
    </div>
  )
}
