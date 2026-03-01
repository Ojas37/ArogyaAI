"use client"

import { useState, useEffect, createContext, useContext, type ReactNode } from "react"
import Link from "next/link"
import { usePathname } from "next/navigation"
import {
  Heart,
  MessageSquarePlus,
  LayoutDashboard,
  Activity,
  MapPin,
  Landmark,
  FolderOpen,
  Languages,
  PanelLeftClose,
  PanelLeft,
  ChevronDown,
  Clock,
  Check,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { cn } from "@/lib/utils"

const languages = [
  { code: "en", label: "English", native: "English" },
  { code: "hi", label: "Hindi", native: "\u0939\u093F\u0928\u094D\u0926\u0940" },
  { code: "ta", label: "Tamil", native: "\u0BA4\u0BAE\u0BBF\u0BB4\u0BCD" },
  { code: "te", label: "Telugu", native: "\u0C24\u0C46\u0C32\u0C41\u0C17\u0C41" },
  { code: "bn", label: "Bengali", native: "\u09AC\u09BE\u0982\u09B2\u09BE" },
  { code: "mr", label: "Marathi", native: "\u092E\u0930\u093E\u0920\u0940" },
  { code: "kn", label: "Kannada", native: "\u0C95\u0CA8\u0CCD\u0CA8\u0CA1" },
  { code: "gu", label: "Gujarati", native: "\u0A97\u0AC1\u0A9C\u0AB0\u0ABE\u0AA4\u0AC0" },
]

/* ---------- sidebar context for child pages ---------- */
const SidebarCtx = createContext({
  collapsed: false,
  toggle: () => {},
  currentLang: "en",
  setCurrentLang: (_code: string) => {},
  userName: "User",
  setUserName: (_name: string) => {},
  userPhone: "+91 98765 XXXXX",
  setUserPhone: (_phone: string) => {},
})
export function useSidebar() {
  return useContext(SidebarCtx)
}

/* ---------- nav items ---------- */
const mainNav = [
  { label: "New Chat", href: "/chat", icon: MessageSquarePlus, accent: true },
  { label: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
  { label: "Vitals", href: "/vitals", icon: Activity },
  { label: "Hospitals", href: "/hospitals", icon: MapPin },
  { label: "Govt. Schemes", href: "/schemes", icon: Landmark },
  { label: "Reports", href: "/results", icon: FolderOpen },
]

const chatHistory = [
  { id: "1", title: "Headache & Mild Fever", date: "Today" },
  { id: "2", title: "Persistent Cough", date: "Yesterday" },
  { id: "3", title: "Skin Rash on Arm", date: "Feb 26" },
  { id: "4", title: "Stomach Pain Assessment", date: "Feb 24" },
  { id: "5", title: "Back Pain Follow-up", date: "Feb 20" },
]

/* ---------- main shell ---------- */
export function AppShell({ children }: { children: ReactNode }) {
  const [collapsed, setCollapsed] = useState(false)
  const [mobileOpen, setMobileOpen] = useState(false)
  const [currentLang, setCurrentLang] = useState("en")
  const [userName, setUserName] = useState("User")
  const [userPhone, setUserPhone] = useState("+91 98765 XXXXX")
  const [mounted, setMounted] = useState(false)
  const pathname = usePathname()

  // Load user data from localStorage
  useEffect(() => {
    setMounted(true)
    const loadUserData = () => {
      const storedName = localStorage.getItem("userName")
      const storedPhone = localStorage.getItem("userPhone")
      const storedLang = localStorage.getItem("userLanguage")
      
      if (storedName) setUserName(storedName)
      if (storedPhone) setUserPhone(storedPhone)
      if (storedLang) setCurrentLang(storedLang)
    }

    loadUserData()

    // Listen for storage changes
    window.addEventListener("storage", loadUserData)
    return () => window.removeEventListener("storage", loadUserData)
  }, [])

  function toggle() {
    setCollapsed((v) => !v)
  }

  return (
    <SidebarCtx.Provider value={{ collapsed, toggle, currentLang, setCurrentLang }}>
      <div className="flex h-dvh overflow-hidden bg-background">
        {/* ---------- mobile overlay ---------- */}
        {mobileOpen && (
          <div
            className="fixed inset-0 z-40 bg-foreground/20 backdrop-blur-sm lg:hidden"
            onClick={() => setMobileOpen(false)}
            aria-hidden
          />
        )}

        {/* ---------- sidebar ---------- */}
        <aside
          className={cn(
            "fixed inset-y-0 left-0 z-50 flex flex-col border-r border-sidebar-border bg-sidebar transition-all duration-300 lg:relative lg:z-0",
            collapsed ? "w-[68px]" : "w-72",
            mobileOpen ? "translate-x-0" : "-translate-x-full lg:translate-x-0"
          )}
        >
          {/* top brand area */}
          <div className="flex items-center justify-between border-b border-sidebar-border px-4 py-4">
            <Link
              href="/"
              className={cn(
                "flex items-center gap-2.5 overflow-hidden",
                collapsed && "justify-center"
              )}
            >
              <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-sidebar-primary">
                <Heart className="h-5 w-5 text-sidebar-primary-foreground" />
              </div>
              {!collapsed && (
                <span className="text-lg font-bold tracking-tight text-sidebar-foreground">
                  ArogyaAI
                </span>
              )}
            </Link>
            <Button
              variant="ghost"
              size="icon"
              onClick={toggle}
              className="hidden shrink-0 text-sidebar-foreground/60 hover:text-sidebar-foreground lg:flex"
              aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
            >
              {collapsed ? (
                <PanelLeft className="h-4 w-4" />
              ) : (
                <PanelLeftClose className="h-4 w-4" />
              )}
            </Button>
          </div>

          {/* main nav */}
          <nav className="flex flex-col gap-1 px-3 pt-4" aria-label="Main navigation">
            {mainNav.map((item) => {
              const active = pathname === item.href
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={() => setMobileOpen(false)}
                  className={cn(
                    "group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors",
                    active
                      ? "bg-sidebar-accent text-sidebar-accent-foreground"
                      : "text-sidebar-foreground/70 hover:bg-sidebar-accent/50 hover:text-sidebar-foreground",
                    item.accent && !active && "text-sidebar-primary",
                    collapsed && "justify-center px-0"
                  )}
                >
                  <item.icon
                    className={cn(
                      "h-[18px] w-[18px] shrink-0",
                      active && "text-sidebar-primary"
                    )}
                  />
                  {!collapsed && <span>{item.label}</span>}
                </Link>
              )
            })}
          </nav>

          {/* chat history section */}
          {!collapsed && (
            <div className="mt-6 flex flex-1 flex-col overflow-hidden px-3">
              <div className="mb-2 flex items-center justify-between px-3">
                <span className="text-[11px] font-semibold uppercase tracking-wider text-sidebar-foreground/40">
                  Recent Chats
                </span>
                <ChevronDown className="h-3 w-3 text-sidebar-foreground/40" />
              </div>
              <div className="flex flex-1 flex-col gap-0.5 overflow-y-auto">
                {chatHistory.map((chat) => (
                  <Link
                    key={chat.id}
                    href="/chat"
                    onClick={() => setMobileOpen(false)}
                    className="group flex items-start gap-2.5 rounded-lg px-3 py-2 transition-colors hover:bg-sidebar-accent/50"
                  >
                    <Clock className="mt-0.5 h-3.5 w-3.5 shrink-0 text-sidebar-foreground/30" />
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-xs font-medium text-sidebar-foreground/70 group-hover:text-sidebar-foreground">
                        {chat.title}
                      </p>
                      <p className="text-[10px] text-sidebar-foreground/35">
                        {chat.date}
                      </p>
                    </div>
                  </Link>
                ))}
              </div>
            </div>
          )}

          {/* bottom user area */}
          <div className="border-t border-sidebar-border px-3 py-3">
            <div
              className={cn(
                "flex items-center gap-3",
                collapsed && "justify-center"
              )}
            >
              <Link
                href="/settings"
                className="flex items-center gap-3 flex-1 min-w-0 rounded-lg px-2 py-2 transition-colors hover:bg-sidebar-accent/50"
              >
                <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-sidebar-primary/15 text-xs font-bold text-sidebar-primary">
                  {mounted ? userName.charAt(0).toUpperCase() : "U"}
                </div>
                {!collapsed && (
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-medium text-sidebar-foreground">
                      {userName}
                    </p>
                    <p className="truncate text-[10px] text-sidebar-foreground/50">
                      +91 {userPhone}
                    </p>
                  </div>
                )}
              </Link>
              {!collapsed && (
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-7 w-7 text-sidebar-foreground/50 hover:text-sidebar-foreground"
                      aria-label="Change language"
                    >
                      <Languages className="h-3.5 w-3.5" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent side="top" align="end" className="w-48">
                    {languages.map((lang) => (
                      <DropdownMenuItem
                        key={lang.code}
                        onClick={() => {
                          setCurrentLang(lang.code)
                          localStorage.setItem("userLanguage", lang.code)
                        }}
                        className="flex items-center justify-between"
                      >
                        <span>
                          {lang.native}{" "}
                          <span className="text-muted-foreground">({lang.label})</span>
                        </span>
                        {currentLang === lang.code && (
                          <Check className="h-3.5 w-3.5 text-primary" />
                        )}
                      </DropdownMenuItem>
                    ))}
                  </DropdownMenuContent>
                </DropdownMenu>
              )}
            </div>
          </div>
        </aside>

        {/* ---------- main content ---------- */}
        <div className="flex flex-1 flex-col overflow-hidden">
          {/* mobile top bar */}
          <header className="flex items-center gap-3 border-b border-border/50 bg-background/80 px-4 py-3 backdrop-blur-lg lg:hidden">
            <Button
              variant="ghost"
              size="icon"
              onClick={() => setMobileOpen(true)}
              aria-label="Open sidebar"
            >
              <PanelLeft className="h-5 w-5" />
            </Button>
            <Link href="/" className="flex items-center gap-2">
              <div className="flex h-7 w-7 items-center justify-center rounded-md bg-primary">
                <Heart className="h-3.5 w-3.5 text-primary-foreground" />
              </div>
              <span className="text-sm font-bold text-foreground">ArogyaAI</span>
            </Link>
            <div className="flex-1" />
            <div className="flex items-center gap-1.5 rounded-full border border-triage-safe/30 bg-triage-safe/10 px-2 py-0.5">
              <div className="h-1.5 w-1.5 rounded-full bg-triage-safe" />
              <span className="text-[10px] font-medium text-foreground">Online</span>
            </div>
          </header>

          {/* page content */}
          <main className="flex-1 overflow-y-auto">{children}</main>
        </div>
      </div>
    </SidebarCtx.Provider>
  )
}
