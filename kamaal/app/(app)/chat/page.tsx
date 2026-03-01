"use client"

import { useState, useRef, useEffect, useCallback } from "react"
import { useRouter } from "next/navigation"
import {
  Send,
  Mic,
  MicOff,
  ImagePlus,
  X,
  ChevronDown,
  Loader2,
  ShieldCheck,
  Brain,
  Globe,
  Search,
  BarChart3,
  FileCheck,
  AlertTriangle,
  Sparkles,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible"

/* ---------- types ---------- */
interface ChatMessage {
  id: string
  role: "user" | "assistant"
  content: string
  imageUrl?: string
  triage?: TriageResult
  aiPipeline?: AIPipelineStep[]
}

interface TriageResult {
  level: "self-care" | "urgent" | "emergency"
  confidence: number
  redFlags: string[]
  explanation: string
  tips: string[]
}

interface AIPipelineStep {
  name: string
  status: "done" | "processing"
  detail: string
}

/* ---------- simulated AI responses ---------- */
const triageResponses: Record<
  string,
  { response: string; triage?: TriageResult; pipeline: AIPipelineStep[] }
> = {
  default: {
    response:
      "I understand you're not feeling well. Can you tell me more about your symptoms? For example:\n\n- When did this start?\n- How severe is the pain (1-10)?\n- Any other symptoms like fever, nausea, or dizziness?",
    pipeline: [
      { name: "Language Detection", status: "done", detail: "English (confidence: 98%)" },
      { name: "Intent Classification", status: "done", detail: "Symptom reporting" },
      { name: "Symptom Extraction", status: "done", detail: "Processing..." },
    ],
  },
  headache: {
    response:
      "Based on your symptoms, this appears to be a mild tension headache. Here's my assessment:",
    triage: {
      level: "self-care",
      confidence: 87,
      redFlags: [],
      explanation:
        "Your symptoms suggest a common tension-type headache. There are no red-flag indicators present. Rest, hydration, and over-the-counter pain relief should help.",
      tips: [
        "Stay hydrated \u2014 drink water regularly",
        "Rest in a quiet, dark room",
        "Apply a cool compress to your forehead",
        "Gentle neck stretches may relieve tension",
      ],
    },
    pipeline: [
      { name: "Language Detection", status: "done", detail: "English (fastText, confidence: 98%)" },
      { name: "Intent Classification", status: "done", detail: "Symptom Report (XLM-RoBERTa)" },
      { name: "Symptom Extraction", status: "done", detail: "Headache, mild (Biomedical NER)" },
      { name: "Feature Scoring", status: "done", detail: "Severity: 3/10, Duration: acute" },
      { name: "XGBoost Triage", status: "done", detail: "Self-Care (87% confidence)" },
      { name: "Safety Override", status: "done", detail: "No red flags detected" },
      { name: "LLM Explanation", status: "done", detail: "Generated localized explanation" },
    ],
  },
  chest: {
    response:
      "IMPORTANT: Chest pain is a red-flag symptom. This requires immediate medical attention.",
    triage: {
      level: "emergency",
      confidence: 96,
      redFlags: ["Chest pain detected", "Potential cardiac event"],
      explanation:
        "Chest pain is classified as a red-flag symptom regardless of other factors. The safety override system has forced this to Emergency level. Please seek immediate medical attention.",
      tips: [],
    },
    pipeline: [
      { name: "Language Detection", status: "done", detail: "English (fastText, confidence: 99%)" },
      { name: "Intent Classification", status: "done", detail: "Emergency Symptom (XLM-RoBERTa)" },
      { name: "Symptom Extraction", status: "done", detail: "Chest pain (Biomedical NER)" },
      { name: "Feature Scoring", status: "done", detail: "Severity: 8/10, critical region" },
      { name: "XGBoost Triage", status: "done", detail: "Emergency (96% confidence)" },
      { name: "Safety Override", status: "done", detail: "RED FLAG: Chest pain \u2014 forced Emergency" },
      { name: "LLM Explanation", status: "done", detail: "Generated emergency guidance" },
    ],
  },
  fever: {
    response: "I've assessed your fever symptoms. Here's the triage result:",
    triage: {
      level: "urgent",
      confidence: 78,
      redFlags: ["Fever above 102\u00b0F for extended period"],
      explanation:
        "Persistent high fever warrants medical evaluation within 24 hours. While not immediately life-threatening, this needs professional assessment to determine the underlying cause.",
      tips: [
        "Stay hydrated with fluids",
        "Rest and monitor temperature",
        "Visit a doctor within 24 hours",
      ],
    },
    pipeline: [
      { name: "Language Detection", status: "done", detail: "English (fastText, confidence: 97%)" },
      { name: "Intent Classification", status: "done", detail: "Symptom Report (XLM-RoBERTa)" },
      { name: "Symptom Extraction", status: "done", detail: "High fever, persistent (Biomedical NER)" },
      { name: "Feature Scoring", status: "done", detail: "Severity: 6/10, Duration: 3+ days" },
      { name: "XGBoost Triage", status: "done", detail: "Urgent (78% confidence)" },
      { name: "Safety Override", status: "done", detail: "Monitoring flag: prolonged fever" },
      { name: "LLM Explanation", status: "done", detail: "Generated urgent care guidance" },
    ],
  },
}

function getTriageResponse(message: string) {
  const lower = message.toLowerCase()
  if (lower.includes("chest") || lower.includes("heart")) return triageResponses.chest
  if (lower.includes("fever") || lower.includes("temperature") || lower.includes("hot"))
    return triageResponses.fever
  if (lower.includes("head") || lower.includes("migraine")) return triageResponses.headache
  return triageResponses.default
}

/* ---------- sub-components ---------- */

function TriageBadge({ level }: { level: TriageResult["level"] }) {
  const config = {
    "self-care": { label: "Self-Care", className: "bg-triage-safe text-triage-safe-foreground" },
    urgent: { label: "Urgent", className: "bg-triage-urgent text-triage-urgent-foreground" },
    emergency: {
      label: "Emergency",
      className: "bg-triage-emergency text-triage-emergency-foreground",
    },
  }
  const c = config[level]
  return (
    <span
      className={`inline-flex items-center rounded-full px-3 py-1 text-xs font-bold ${c.className}`}
    >
      {c.label}
    </span>
  )
}

function TriageResultCard({
  triage,
  onFindHospitals,
  onNewAssessment,
}: {
  triage: TriageResult
  onFindHospitals: () => void
  onNewAssessment: () => void
}) {
  return (
    <Card className="mt-3 border-border/50 shadow-sm">
      <CardContent className="flex flex-col gap-4 p-5">
        <div className="flex items-center justify-between">
          <TriageBadge level={triage.level} />
          <span className="text-sm font-medium text-muted-foreground">
            Confidence: {triage.confidence}%
          </span>
        </div>

        <p className="text-sm leading-relaxed text-card-foreground">{triage.explanation}</p>

        {triage.redFlags.length > 0 && (
          <div className="rounded-lg border border-triage-emergency/30 bg-triage-emergency/5 p-3">
            <p className="mb-1 text-xs font-semibold text-triage-emergency">Red Flags Detected:</p>
            <ul className="flex flex-col gap-1">
              {triage.redFlags.map((flag) => (
                <li key={flag} className="flex items-center gap-2 text-xs text-foreground">
                  <AlertTriangle className="h-3 w-3 shrink-0 text-triage-emergency" />
                  {flag}
                </li>
              ))}
            </ul>
          </div>
        )}

        {triage.tips.length > 0 && (
          <div className="rounded-lg border border-triage-safe/30 bg-triage-safe/5 p-3">
            <p className="mb-1 text-xs font-semibold text-triage-safe">Home-Care Tips:</p>
            <ul className="flex flex-col gap-1">
              {triage.tips.map((tip) => (
                <li key={tip} className="text-xs text-foreground">
                  {tip}
                </li>
              ))}
            </ul>
          </div>
        )}

        <div className="flex flex-wrap gap-2">
          {triage.level === "emergency" && (
            <Button
              size="sm"
              className="gap-1 bg-triage-emergency text-triage-emergency-foreground hover:bg-triage-emergency/90"
            >
              Call Ambulance
            </Button>
          )}
          <Button size="sm" variant="outline" className="gap-1" onClick={onFindHospitals}>
            Find Nearby Hospitals
          </Button>
          <Button size="sm" variant="ghost" onClick={onNewAssessment}>
            New Assessment
          </Button>
        </div>

        <p className="text-center text-[10px] text-muted-foreground">
          This is not a medical diagnosis. Always consult a doctor.
        </p>
      </CardContent>
    </Card>
  )
}

function AIPipelineExplainer({ steps }: { steps: AIPipelineStep[] }) {
  const icons = [Globe, Brain, Search, BarChart3, BarChart3, ShieldCheck, FileCheck]
  return (
    <Collapsible>
      <CollapsibleTrigger asChild>
        <button className="mt-2 flex items-center gap-1.5 text-xs font-medium text-primary hover:underline">
          <Brain className="h-3 w-3" />
          Why this result?
          <ChevronDown className="h-3 w-3" />
        </button>
      </CollapsibleTrigger>
      <CollapsibleContent>
        <div className="mt-2 flex flex-col gap-1.5 rounded-lg border border-border/50 bg-muted/50 p-3">
          {steps.map((step, i) => {
            const Icon = icons[i] || Brain
            return (
              <div key={step.name} className="flex items-start gap-2">
                <Icon className="mt-0.5 h-3.5 w-3.5 shrink-0 text-primary" />
                <div>
                  <span className="text-xs font-medium text-foreground">{step.name}</span>
                  <span className="ml-1.5 text-xs text-muted-foreground">{step.detail}</span>
                </div>
              </div>
            )
          })}
        </div>
      </CollapsibleContent>
    </Collapsible>
  )
}

/* ---------- empty state ---------- */
function ChatEmptyState() {
  return (
    <div className="flex flex-1 flex-col items-center justify-center gap-6 px-4 py-12">
      <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-primary/10">
        <Sparkles className="h-8 w-8 text-primary" />
      </div>
      <div className="max-w-md text-center">
        <h2 className="text-xl font-bold text-foreground">How are you feeling?</h2>
        <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
          Describe your symptoms below and I will assess the urgency level, flag any red flags, and guide you to the right care.
        </p>
      </div>
      <div className="flex flex-wrap justify-center gap-2">
        {["I have a headache", "Fever since 2 days", "Chest pain", "Skin rash on arm"].map(
          (q) => (
            <button
              key={q}
              className="rounded-full border border-border bg-card px-4 py-2 text-xs font-medium text-card-foreground transition-colors hover:border-primary/40 hover:bg-primary/5"
              data-quick={q}
            >
              {q}
            </button>
          )
        )}
      </div>
    </div>
  )
}

/* ---------- main chat page ---------- */
export default function ChatPage() {
  const router = useRouter()
  const [messages, setMessages] = useState<ChatMessage[]>([])
  const [input, setInput] = useState("")
  const [isTyping, setIsTyping] = useState(false)
  const [isRecording, setIsRecording] = useState(false)
  const [imagePreview, setImagePreview] = useState<string | null>(null)
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const textareaRef = useRef<HTMLTextAreaElement>(null)

  const scrollToBottom = useCallback(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" })
  }, [])

  useEffect(() => {
    scrollToBottom()
  }, [messages, isTyping, scrollToBottom])

  /* handle quick-prompt clicks from empty state */
  useEffect(() => {
    function handleClick(e: MouseEvent) {
      const target = e.target as HTMLElement
      const quick = target.closest<HTMLElement>("[data-quick]")
      if (quick) {
        setInput(quick.dataset.quick || "")
        textareaRef.current?.focus()
      }
    }
    document.addEventListener("click", handleClick)
    return () => document.removeEventListener("click", handleClick)
  }, [])

  function handleSendMessage(e?: React.FormEvent) {
    e?.preventDefault()
    const text = input.trim()
    if (!text && !imagePreview) return

    const userMsg: ChatMessage = {
      id: Date.now().toString(),
      role: "user",
      content: text || "Uploaded an image for analysis",
      imageUrl: imagePreview || undefined,
    }

    setMessages((prev) => [...prev, userMsg])
    setInput("")
    setImagePreview(null)
    setIsTyping(true)

    if (textareaRef.current) {
      textareaRef.current.style.height = "auto"
    }

    setTimeout(() => {
      const response = getTriageResponse(text)
      const aiMsg: ChatMessage = {
        id: (Date.now() + 1).toString(),
        role: "assistant",
        content: response.response,
        triage: response.triage,
        aiPipeline: response.pipeline,
      }
      setMessages((prev) => [...prev, aiMsg])
      setIsTyping(false)
    }, 1500)
  }

  function handleVoiceToggle() {
    if (isRecording) {
      setIsRecording(false)
      setInput("I have a headache and mild fever since yesterday")
    } else {
      setIsRecording(true)
      setTimeout(() => {
        setIsRecording(false)
        setInput("I have a headache and mild fever since yesterday")
      }, 2000)
    }
  }

  function handleImageUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (file) {
      const reader = new FileReader()
      reader.onload = (ev) => setImagePreview(ev.target?.result as string)
      reader.readAsDataURL(file)
    }
  }

  function handleNewAssessment() {
    setMessages([])
  }

  const isEmpty = messages.length === 0

  return (
    <div className="flex h-full flex-col">
      {/* messages or empty state */}
      {isEmpty ? (
        <ChatEmptyState />
      ) : (
        <div className="flex-1 overflow-y-auto px-4 py-6">
          <div className="mx-auto flex max-w-2xl flex-col gap-6">
            {messages.map((msg) => (
              <div
                key={msg.id}
                className={`flex ${msg.role === "user" ? "justify-end" : "justify-start"}`}
              >
                <div
                  className={`max-w-[85%] rounded-2xl px-4 py-3 ${
                    msg.role === "user"
                      ? "bg-primary text-primary-foreground"
                      : "bg-secondary text-secondary-foreground"
                  }`}
                >
                  {msg.imageUrl && (
                    <div className="mb-2 overflow-hidden rounded-lg">
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img
                        src={msg.imageUrl}
                        alt="Uploaded symptom"
                        className="max-h-48 w-auto rounded-lg"
                      />
                    </div>
                  )}
                  <p className="whitespace-pre-wrap text-sm leading-relaxed">{msg.content}</p>

                  {msg.triage && (
                    <TriageResultCard
                      triage={msg.triage}
                      onFindHospitals={() => router.push("/hospitals")}
                      onNewAssessment={handleNewAssessment}
                    />
                  )}

                  {msg.aiPipeline && <AIPipelineExplainer steps={msg.aiPipeline} />}
                </div>
              </div>
            ))}

            {isTyping && (
              <div className="flex justify-start">
                <div className="rounded-2xl bg-secondary px-4 py-3">
                  <div className="flex items-center gap-2 text-sm text-muted-foreground">
                    <Loader2 className="h-4 w-4 animate-spin" />
                    Analyzing your symptoms...
                  </div>
                </div>
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>
        </div>
      )}

      {/* Image preview bar */}
      {imagePreview && (
        <div className="border-t border-border bg-muted/50 px-4 py-2">
          <div className="mx-auto flex max-w-2xl items-center gap-3">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={imagePreview} alt="Preview" className="h-16 w-16 rounded-lg object-cover" />
            <div className="flex-1">
              <p className="text-xs font-medium text-foreground">Image attached</p>
              <p className="text-[10px] text-muted-foreground">
                Will be analyzed for visual symptoms
              </p>
            </div>
            <Button
              variant="ghost"
              size="icon"
              onClick={() => setImagePreview(null)}
              className="h-8 w-8"
              aria-label="Remove image"
            >
              <X className="h-4 w-4" />
            </Button>
          </div>
        </div>
      )}

      {/* Input area */}
      <div className="border-t border-border bg-background px-4 pb-6 pt-4">
        <form onSubmit={handleSendMessage} className="mx-auto flex max-w-2xl items-end gap-2">
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={handleImageUpload}
            aria-label="Upload symptom image"
          />
          <Button
            type="button"
            variant="ghost"
            size="icon"
            className="shrink-0"
            onClick={() => fileInputRef.current?.click()}
            aria-label="Upload image"
          >
            <ImagePlus className="h-5 w-5 text-muted-foreground" />
          </Button>

          <Button
            type="button"
            variant="ghost"
            size="icon"
            className={`shrink-0 ${isRecording ? "text-triage-emergency" : ""}`}
            onClick={handleVoiceToggle}
            aria-label={isRecording ? "Stop recording" : "Start recording"}
          >
            {isRecording ? (
              <MicOff className="h-5 w-5 animate-pulse" />
            ) : (
              <Mic className="h-5 w-5 text-muted-foreground" />
            )}
          </Button>

          <div className="flex flex-1 items-end rounded-2xl border border-input bg-card px-4 py-2.5">
            <textarea
              ref={textareaRef}
              rows={1}
              value={input}
              onChange={(e) => {
                setInput(e.target.value)
                e.target.style.height = "auto"
                e.target.style.height = `${Math.min(e.target.scrollHeight, 120)}px`
              }}
              onKeyDown={(e) => {
                if (e.key === "Enter" && !e.shiftKey) {
                  e.preventDefault()
                  handleSendMessage()
                }
              }}
              placeholder="Describe your symptoms..."
              className="max-h-[120px] flex-1 resize-none bg-transparent text-sm text-card-foreground placeholder:text-muted-foreground focus:outline-none"
            />
          </div>

          <Button
            type="submit"
            size="icon"
            className="shrink-0 rounded-full"
            disabled={!input.trim() && !imagePreview}
            aria-label="Send message"
          >
            <Send className="h-4 w-4" />
          </Button>
        </form>

        <p className="mx-auto mt-2 max-w-2xl text-center text-[10px] text-muted-foreground">
          This is not a medical diagnosis. Always consult a healthcare professional.
        </p>
      </div>
    </div>
  )
}
