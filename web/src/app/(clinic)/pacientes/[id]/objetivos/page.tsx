import { cookies } from "next/headers"
import { api } from "@/lib/api"
import { GoalProgressChart } from "@/components/goals/GoalProgressChart"

interface Goal { id: number; title: string; domain: string; method: string; status: string; target: string }
interface Progress { id: number; recorded_at: string; score: number; notes: string }

const DOMAIN_LABELS: Record<string, string> = {
  communication: "Comunicação",
  social_skills: "Habilidades Sociais",
  behavior: "Comportamento",
  motor: "Motricidade",
  daily_living: "Vida Diária",
  cognitive: "Cognitivo",
}

const STATUS_BADGE: Record<string, string> = {
  active: "bg-green-100 text-green-700",
  achieved: "bg-blue-100 text-blue-700",
  paused: "bg-amber-100 text-amber-700",
  discontinued: "bg-slate-100 text-slate-500",
}

export default async function GoalsPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const token = (await cookies()).get("florir_token")?.value ?? ""
  const goals = await api.get<Goal[]>(`/patients/${id}/goals`, token)

  const goalsWithProgress = await Promise.all(
    goals.map(async (g) => {
      const progress = await api.get<Progress[]>(`/therapeutic_goals/${g.id}/progresses`, token)
      return { ...g, progress }
    })
  )

  return (
    <div className="p-6">
      <h1 className="mb-6 text-xl font-bold text-slate-900">Plano Terapêutico</h1>
      <div className="flex flex-col gap-4">
        {goalsWithProgress.map((g) => (
          <div key={g.id} className="rounded-xl border border-slate-200 bg-white p-4">
            <div className="mb-3 flex items-start justify-between">
              <div>
                <h2 className="font-semibold text-slate-900">{g.title}</h2>
                <p className="text-xs text-slate-400">{DOMAIN_LABELS[g.domain]} · {g.method?.toUpperCase()}</p>
              </div>
              <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${STATUS_BADGE[g.status]}`}>
                {g.status}
              </span>
            </div>
            {g.target && <p className="mb-3 text-sm text-slate-600">{g.target}</p>}
            {g.progress.length > 0 ? (
              <GoalProgressChart data={g.progress} />
            ) : (
              <p className="text-sm text-slate-400 italic">Sem registros de evolução ainda.</p>
            )}
          </div>
        ))}
      </div>
    </div>
  )
}
