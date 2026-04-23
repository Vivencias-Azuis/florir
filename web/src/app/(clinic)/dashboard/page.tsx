import { cookies } from "next/headers"
import { api } from "@/lib/api"

interface Patient { id: number; name: string }
interface Session { id: number; scheduled_at: string; status: string; modality: string }

async function getDashboardData(token: string) {
  const [patients, sessions] = await Promise.all([
    api.get<Patient[]>("/patients", token),
    api.get<Session[]>("/therapy_sessions?today=true", token),
  ])
  return { patients, sessions }
}

export default async function DashboardPage() {
  const cookieStore = await cookies()
  const token = cookieStore.get("florir_token")?.value ?? ""
  const { patients, sessions } = await getDashboardData(token)

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-xl font-bold text-slate-900">Dashboard</h1>
        <p className="text-sm text-slate-500">Visão geral da clínica</p>
      </div>

      <div className="mb-6 grid grid-cols-2 gap-4 lg:grid-cols-4">
        {[
          { label: "Pacientes ativos", value: patients.length, color: "text-slate-900" },
          { label: "Sessões hoje", value: sessions.length, color: "text-blue-600" },
          { label: "Objetivos ativos", value: "—", color: "text-slate-900" },
          { label: "Mensagens", value: "—", color: "text-amber-500" },
        ].map((stat) => (
          <div key={stat.label} className="rounded-xl border border-slate-200 bg-white p-4">
            <p className="text-xs text-slate-400">{stat.label}</p>
            <p className={`mt-1 text-2xl font-bold ${stat.color}`}>{stat.value}</p>
          </div>
        ))}
      </div>

      <div className="rounded-xl border border-slate-200 bg-white p-4">
        <h2 className="mb-3 text-sm font-semibold text-slate-600">Agenda de hoje</h2>
        {sessions.length === 0 ? (
          <p className="text-sm text-slate-400">Nenhuma sessão hoje.</p>
        ) : (
          <div className="flex flex-col gap-2">
            {sessions.map((s) => (
              <div key={s.id} className="flex items-center gap-3 rounded-lg bg-blue-50 px-3 py-2 border-l-4 border-blue-500">
                <span className="text-xs text-slate-500 w-10">
                  {new Date(s.scheduled_at).toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit" })}
                </span>
                <span className="flex-1 text-sm font-medium text-blue-900">{s.modality.toUpperCase()}</span>
                <span className="rounded-full bg-green-100 px-2 py-0.5 text-xs text-green-700">{s.status}</span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
