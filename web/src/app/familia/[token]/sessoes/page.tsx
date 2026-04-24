import { api } from "@/lib/api"

interface Session { id: number; scheduled_at: string; modality: string; status: string; duration_minutes: number }

export default async function FamiliaSessoesPage({ params }: { params: Promise<{ token: string }> }) {
  const { token } = await params
  const sessions = await api.get<Session[]>(`/family/${token}/sessions`)

  return (
    <div className="rounded-2xl bg-white p-5 shadow-sm border border-slate-200">
      <h1 className="mb-4 text-lg font-bold text-slate-900">Próximas sessões</h1>
      {sessions.length === 0 ? (
        <p className="text-sm text-slate-400">Nenhuma sessão agendada.</p>
      ) : (
        <div className="flex flex-col gap-3">
          {sessions.map((s) => (
            <div key={s.id} className="flex items-center gap-4 rounded-lg border border-slate-100 p-3">
              <div className="text-center">
                <p className="text-lg font-bold text-blue-600">{new Date(s.scheduled_at).getDate()}</p>
                <p className="text-xs text-slate-400">{new Date(s.scheduled_at).toLocaleDateString("pt-BR", { month: "short" })}</p>
              </div>
              <div>
                <p className="font-medium text-slate-800">{s.modality.toUpperCase()} · {s.duration_minutes} min</p>
                <p className="text-xs text-slate-400">{new Date(s.scheduled_at).toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit" })}</p>
              </div>
              <span className="ml-auto rounded-full bg-green-100 px-2 py-0.5 text-xs text-green-700">{s.status}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
