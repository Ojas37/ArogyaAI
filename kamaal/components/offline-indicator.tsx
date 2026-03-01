"use client"

import { useState, useEffect } from "react"
import { Wifi, WifiOff, RefreshCw } from "lucide-react"

export function OfflineIndicator() {
  const [isOffline, setIsOffline] = useState(false)
  const [showSync, setShowSync] = useState(false)

  useEffect(() => {
    function handleOffline() {
      setIsOffline(true)
    }

    function handleOnline() {
      setIsOffline(false)
      setShowSync(true)
      const timer = setTimeout(() => setShowSync(false), 3000)
      return () => clearTimeout(timer)
    }

    window.addEventListener("offline", handleOffline)
    window.addEventListener("online", handleOnline)

    setIsOffline(!navigator.onLine)

    return () => {
      window.removeEventListener("offline", handleOffline)
      window.removeEventListener("online", handleOnline)
    }
  }, [])

  if (!isOffline && !showSync) return null

  return (
    <div className="fixed bottom-4 left-4 z-50 animate-in fade-in slide-in-from-bottom-2">
      {isOffline ? (
        <div className="flex items-center gap-2 rounded-full border border-triage-urgent/30 bg-triage-urgent/10 px-4 py-2 shadow-lg backdrop-blur-lg">
          <WifiOff className="h-4 w-4 text-triage-urgent" />
          <span className="text-xs font-medium text-foreground">Offline Mode Active</span>
        </div>
      ) : showSync ? (
        <div className="flex items-center gap-2 rounded-full border border-triage-safe/30 bg-triage-safe/10 px-4 py-2 shadow-lg backdrop-blur-lg">
          <RefreshCw className="h-4 w-4 animate-spin text-triage-safe" />
          <span className="text-xs font-medium text-foreground">Syncing data...</span>
        </div>
      ) : (
        <div className="flex items-center gap-2 rounded-full border border-triage-safe/30 bg-triage-safe/10 px-4 py-2 shadow-lg backdrop-blur-lg">
          <Wifi className="h-4 w-4 text-triage-safe" />
          <span className="text-xs font-medium text-foreground">Connected</span>
        </div>
      )}
    </div>
  )
}
