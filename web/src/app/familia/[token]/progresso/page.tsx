import { api } from "@/lib/api"
import { GoalProgressBar } from "@/components/patients/GoalProgressBar"

interface DashboardData {
  patient: { name: string; diagnosis_level: number }
  goals: { id: number; title: string; domain: string; last_score: number | null }[]
  next_session: { scheduled_at: string; modality: string } | null
}

export default async function FamiliaProgressoPage({ params }: { params: Promise<{ token: string }> }) {
  const { token } = await params
  const data = await api.get<DashboardData>(`/family/${token}/dashboard`)

  return (
    <div className="flex flex-col gap-4">
      <div className="rounded-2xl bg-white p-5 shadow-sm border border-slate-200">
        <h1 className="text-lg font-bold text-slate-900">Olá! 👋</h1>
        <p className="text-sm text-slate-500">Acompanhando: <strong>{data.patient.name}</strong> · Nível {data.patient.diagnosis_level}</p>
        {data.next_session && (
          <div className="mt-3 rounded-lg bg-blue-50 px-3 py-2 text-xs text-blue-700 border border-blue-100">
            Próxima sessão: {new Date(data.next_session.scheduled_at).toLocaleDateString("pt-BR")} · {data.next_session.modality.toUpperCase()}
          </div>
        )}
      </div>

      <div className="rounded-2xl bg-white p-5 shadow-sm border border-slate-200">
        <h2 className="mb-4 text-sm font-semibold text-slate-600">Objetivos em andamento</h2>
        <div className="flex flex-col gap-3">
          {data.goals.map((g) => (
            <GoalProgressBar key={g.id} title={g.title} domain={g.domain} score={g.last_score ?? 0} />
          ))}
        </div>
      </div>
    </div>
  )
}
