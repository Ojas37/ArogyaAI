"use client"

import { useState, useEffect } from "react"
import {
  MapPin,
  Navigation,
  Phone,
  Clock,
  WifiOff,
  Loader2,
  ExternalLink,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"

interface Hospital {
  id: string
  name: string
  distance: string
  type: string
  address: string
  phone: string
  hours: string
  lat: number
  lng: number
}

const mockHospitals: Hospital[] = [
  {
    id: "1",
    name: "District General Hospital",
    distance: "1.2 km",
    type: "Government Hospital",
    address: "Main Road, Near Bus Stand",
    phone: "+91 98765 43210",
    hours: "24/7 Emergency",
    lat: 19.076,
    lng: 72.8777,
  },
  {
    id: "2",
    name: "Shri Krishna Community Health Center",
    distance: "3.4 km",
    type: "Community Health Center",
    address: "Gandhi Nagar, Sector 5",
    phone: "+91 98765 43211",
    hours: "8 AM - 8 PM",
    lat: 19.082,
    lng: 72.882,
  },
  {
    id: "3",
    name: "Primary Health Center - Block A",
    distance: "5.1 km",
    type: "Primary Health Center",
    address: "Village Road, Block A",
    phone: "+91 98765 43212",
    hours: "9 AM - 5 PM",
    lat: 19.09,
    lng: 72.87,
  },
  {
    id: "4",
    name: "Aarogya Multi-Specialty Hospital",
    distance: "7.8 km",
    type: "Private Hospital",
    address: "Highway Road, Near Petrol Pump",
    phone: "+91 98765 43213",
    hours: "24/7",
    lat: 19.095,
    lng: 72.89,
  },
  {
    id: "5",
    name: "Gram Panchayat Health Sub-Center",
    distance: "9.2 km",
    type: "Sub-Center",
    address: "Panchayat Building, Village Center",
    phone: "+91 98765 43214",
    hours: "10 AM - 4 PM",
    lat: 19.1,
    lng: 72.86,
  },
]

export default function HospitalsPage() {
  const [loading, setLoading] = useState(true)
  const [hospitals, setHospitals] = useState<Hospital[]>([])
  const [isOffline, setIsOffline] = useState(false)

  useEffect(() => {
    const timer = setTimeout(() => {
      setHospitals(mockHospitals)
      setLoading(false)
    }, 1200)

    function handleOffline() {
      setIsOffline(true)
    }
    function handleOnline() {
      setIsOffline(false)
    }

    window.addEventListener("offline", handleOffline)
    window.addEventListener("online", handleOnline)
    setIsOffline(!navigator.onLine)

    return () => {
      clearTimeout(timer)
      window.removeEventListener("offline", handleOffline)
      window.removeEventListener("online", handleOnline)
    }
  }, [])

  function openDirections(hospital: Hospital) {
    const url = `https://www.openstreetmap.org/directions?from=&to=${hospital.lat},${hospital.lng}`
    window.open(url, "_blank", "noopener,noreferrer")
  }

  return (
    <div className="flex h-full flex-col overflow-y-auto">
      {/* page header */}
      <div className="border-b border-border/50 bg-background/80 px-6 py-5 backdrop-blur-lg">
        <div className="mx-auto flex max-w-5xl items-center justify-between">
          <div>
            <h1 className="text-xl font-bold text-foreground md:text-2xl">Nearby Hospitals</h1>
            <p className="mt-0.5 text-sm text-muted-foreground">
              Find healthcare facilities within 10km of your location
            </p>
          </div>
        </div>
      </div>

      {/* Offline banner */}
      {isOffline && (
        <div className="flex items-center justify-center gap-2 border-b border-triage-urgent/30 bg-triage-urgent/10 px-4 py-2">
          <WifiOff className="h-4 w-4 text-triage-urgent" />
          <span className="text-xs font-medium text-foreground">
            Offline -- Showing cached results
          </span>
        </div>
      )}

      <div className="flex-1 px-6 py-6">
        <div className="mx-auto max-w-5xl">
          {/* Map placeholder */}
          <Card className="mb-6 overflow-hidden border-border/50">
            <div className="relative flex h-48 items-center justify-center bg-muted">
              <div className="flex flex-col items-center gap-2 text-muted-foreground">
                <MapPin className="h-8 w-8" />
                <span className="text-sm font-medium">OpenStreetMap Integration</span>
                <span className="text-xs">Hospitals within 10km of your location</span>
              </div>
              <div className="absolute left-[30%] top-[40%] h-3 w-3 animate-pulse rounded-full bg-triage-emergency" />
              <div className="absolute left-[50%] top-[30%] h-3 w-3 animate-pulse rounded-full bg-primary" />
              <div className="absolute left-[65%] top-[55%] h-3 w-3 animate-pulse rounded-full bg-primary" />
              <div className="absolute left-[40%] top-[65%] h-3 w-3 animate-pulse rounded-full bg-primary" />
              <div className="absolute left-[75%] top-[45%] h-3 w-3 animate-pulse rounded-full bg-primary" />
            </div>
          </Card>

          {/* Hospital list */}
          <div className="mb-4 flex items-center justify-between">
            <h2 className="text-lg font-semibold text-foreground">
              {loading ? "Searching..." : `${hospitals.length} hospitals found`}
            </h2>
            <span className="text-xs text-muted-foreground">Within 10km</span>
          </div>

          {loading ? (
            <div className="flex flex-col items-center gap-3 py-12">
              <Loader2 className="h-8 w-8 animate-spin text-primary" />
              <p className="text-sm text-muted-foreground">Finding nearby hospitals...</p>
            </div>
          ) : (
            <div className="grid gap-4 md:grid-cols-2">
              {hospitals.map((hospital) => (
                <Card
                  key={hospital.id}
                  className="border-border/50 bg-card shadow-sm transition-shadow hover:shadow-md"
                >
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex-1">
                        <h3 className="font-semibold text-card-foreground">{hospital.name}</h3>
                        <p className="mt-0.5 text-xs text-muted-foreground">{hospital.type}</p>

                        <div className="mt-3 flex flex-col gap-1.5">
                          <div className="flex items-center gap-2 text-xs text-muted-foreground">
                            <MapPin className="h-3 w-3 shrink-0" />
                            <span>{hospital.address}</span>
                          </div>
                          <div className="flex items-center gap-2 text-xs text-muted-foreground">
                            <Phone className="h-3 w-3 shrink-0" />
                            <span>{hospital.phone}</span>
                          </div>
                          <div className="flex items-center gap-2 text-xs text-muted-foreground">
                            <Clock className="h-3 w-3 shrink-0" />
                            <span>{hospital.hours}</span>
                          </div>
                        </div>
                      </div>

                      <div className="flex flex-col items-end gap-2">
                        <span className="rounded-full bg-primary/10 px-2.5 py-1 text-xs font-semibold text-primary">
                          {hospital.distance}
                        </span>
                        <Button
                          size="sm"
                          variant="outline"
                          className="gap-1 text-xs"
                          onClick={() => openDirections(hospital)}
                        >
                          <Navigation className="h-3 w-3" />
                          Directions
                          <ExternalLink className="h-3 w-3" />
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
