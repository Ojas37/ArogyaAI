"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import Link from "next/link"
import { Heart, Phone, ArrowRight, Globe, User } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import {
  InputOTP,
  InputOTPGroup,
  InputOTPSlot,
} from "@/components/ui/input-otp"

const languages = [
  { code: "en", label: "English" },
  { code: "hi", label: "Hindi" },
  { code: "mr", label: "Marathi" },
  { code: "gu", label: "Gujarati" },
  { code: "pa", label: "Punjabi" },
  { code: "te", label: "Telugu" },
  { code: "ta", label: "Tamil" },
  { code: "bn", label: "Bengali" },
  { code: "kn", label: "Kannada" },
  { code: "bho", label: "Bhojpuri" },
]

export default function AuthPage() {
  const router = useRouter()
  const [step, setStep] = useState<"phone" | "otp">("phone")
  const [name, setName] = useState("")
  const [phone, setPhone] = useState("")
  const [otp, setOtp] = useState("")
  const [language, setLanguage] = useState("en")

  function handleSendOTP(e: React.FormEvent) {
    e.preventDefault()
    if (phone.length >= 10 && name.trim().length >= 2) {
      setStep("otp")
    }
  }

  function handleVerifyOTP() {
    if (otp.length === 6) {
      // Save user data to localStorage
      localStorage.setItem("userName", name)
      localStorage.setItem("userPhone", phone)
      localStorage.setItem("userLanguage", language)
      router.push("/dashboard")
    }
  }

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-background px-4">
      {/* Soft gradient background */}
      <div className="absolute inset-0 -z-10 bg-[radial-gradient(ellipse_at_center,var(--primary)_0%,transparent_70%)] opacity-[0.04]" />

      <Link href="/" className="mb-8 flex items-center gap-2">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary">
          <Heart className="h-5 w-5 text-primary-foreground" />
        </div>
        <span className="text-2xl font-bold text-foreground">ArogyaAI</span>
      </Link>

      <Card className="w-full max-w-md border-border/50 shadow-lg">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl font-bold text-card-foreground">
            {step === "phone" ? "Welcome" : "Verify Your Number"}
          </CardTitle>
          <p className="text-sm text-muted-foreground">
            {step === "phone"
              ? "Enter your phone number to start your health check"
              : `We sent a code to +91 ${phone}`}
          </p>
        </CardHeader>
        <CardContent>
          {step === "phone" ? (
            <form onSubmit={handleSendOTP} className="flex flex-col gap-5">
              {/* Name input */}
              <div className="flex flex-col gap-2">
                <Label className="flex items-center gap-2 text-sm font-medium">
                  <User className="h-4 w-4 text-muted-foreground" />
                  Full Name
                </Label>
                <Input
                  type="text"
                  placeholder="Enter your full name"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  required
                  minLength={2}
                />
              </div>

              {/* Language selector */}
              <div className="flex flex-col gap-2">
                <Label className="flex items-center gap-2 text-sm font-medium">
                  <Globe className="h-4 w-4 text-muted-foreground" />
                  Preferred Language
                </Label>
                <Select value={language} onValueChange={setLanguage}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {languages.map((lang) => (
                      <SelectItem key={lang.code} value={lang.code}>
                        {lang.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {/* Phone input */}
              <div className="flex flex-col gap-2">
                <Label className="flex items-center gap-2 text-sm font-medium">
                  <Phone className="h-4 w-4 text-muted-foreground" />
                  Phone Number
                </Label>
                <div className="flex gap-2">
                  <div className="flex h-10 items-center rounded-md border border-input bg-secondary px-3 text-sm text-secondary-foreground">
                    +91
                  </div>
                  <Input
                    type="tel"
                    placeholder="Enter your phone number"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value.replace(/\D/g, "").slice(0, 10))}
                    className="flex-1"
                    required
                    maxLength={10}
                  />
                </div>
              </div>

              <Button
                type="submit"
                size="lg"
                className="mt-2 w-full gap-2"
                disabled={phone.length < 10 || name.trim().length < 2}
              >
                Send OTP
                <ArrowRight className="h-4 w-4" />
              </Button>
            </form>
          ) : (
            <div className="flex flex-col items-center gap-5">
              <InputOTP
                maxLength={6}
                value={otp}
                onChange={setOtp}
              >
                <InputOTPGroup>
                  <InputOTPSlot index={0} />
                  <InputOTPSlot index={1} />
                  <InputOTPSlot index={2} />
                  <InputOTPSlot index={3} />
                  <InputOTPSlot index={4} />
                  <InputOTPSlot index={5} />
                </InputOTPGroup>
              </InputOTP>

              <Button
                size="lg"
                className="w-full gap-2"
                disabled={otp.length < 6}
                onClick={handleVerifyOTP}
              >
                Verify & Continue
                <ArrowRight className="h-4 w-4" />
              </Button>

              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <span>{"Didn't receive code?"}</span>
                <button
                  className="font-medium text-primary hover:underline"
                  onClick={() => setStep("phone")}
                  type="button"
                >
                  Resend
                </button>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      <p className="mt-6 max-w-sm text-center text-xs leading-relaxed text-muted-foreground">
        This platform provides safe urgency guidance only. It does not diagnose,
        prescribe, or replace a licensed medical professional.
      </p>
    </div>
  )
}
