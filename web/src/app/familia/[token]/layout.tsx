import Link from "next/link"

const NAV = [
  { href: "progresso", label: "Progresso" },
  { href: "sessoes", label: "Sessões" },
  { href: "mensagens", label: "Mensagens" },
]

export default async function FamiliaLayout({
  children,
  params,
}: {
  children: React.ReactNode
  params: Promise<{ token: string }>
}) {
  const { token } = await params
  return (
    <div className="min-h-screen bg-blue-50">
      <header className="bg-white border-b border-slate-200 px-4 py-3 flex items-center justify-between">
        <span className="font-bold text-blue-700">Florir</span>
        <nav className="flex gap-4">
          {NAV.map((n) => (
            <Link key={n.href} href={`/familia/${token}/${n.href}`}
                  className="text-sm text-slate-600 hover:text-blue-600 transition-colors">
              {n.label}
            </Link>
          ))}
        </nav>
      </header>
      <main className="mx-auto max-w-2xl px-4 py-6">{children}</main>
    </div>
  )
}
