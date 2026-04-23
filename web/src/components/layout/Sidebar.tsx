"use client"
import Link from "next/link"
import { usePathname } from "next/navigation"

const NAV = [
  { href: "/dashboard", label: "Dashboard", icon: "⊡" },
  { href: "/agenda", label: "Agenda", icon: "📅" },
  { href: "/pacientes", label: "Pacientes", icon: "👤" },
  { href: "/configuracoes", label: "Config", icon: "⚙" },
]

export function Sidebar() {
  const pathname = usePathname()
  return (
    <aside className="flex h-screen w-14 flex-col items-center bg-slate-900 py-4 gap-4">
      <div className="mb-2 flex h-8 w-8 items-center justify-center rounded-lg bg-blue-600 text-white text-xs font-bold">F</div>
      {NAV.map((item) => (
        <Link
          key={item.href}
          href={item.href}
          title={item.label}
          className={`flex h-9 w-9 items-center justify-center rounded-lg text-lg transition-colors ${
            pathname.startsWith(item.href)
              ? "bg-blue-600 text-white"
              : "text-slate-400 hover:bg-slate-700 hover:text-white"
          }`}
        >
          {item.icon}
        </Link>
      ))}
    </aside>
  )
}
