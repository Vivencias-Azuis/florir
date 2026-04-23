import { cookies } from "next/headers"
import { api } from "@/lib/api"
import { GoalProgressBar } from "@/components/patients/GoalProgressBar"
import Link from "next/link"

interface Patient { id: number; name: string; birth_date: string; diagnosis_level: number; communication_method: string; diagnosis_date: string }
interface Goal { id: number; title: string; domain: string; status: string; last_score: number | null }

export default async function PatientPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const token = (await cookies()).get("florir_token")?.value ?? ""
  const [patient, goals] = await Promise.all([
    api.get<Patient>(`/patients/${id}`, token),
    api.get<Goal[]>(`/patients/${id}/goals`, token),
  ])

  const activeGoals = goals.filter((g) => g.status === "active")

  return (
    <div className="p-6">
      <div className="mb-6 flex items-center gap-4">
        <div className="flex h-12 w-12 items-center justify-center rounded-full bg-blue-100 text-blue-700 font-bold text-lg">
          {patient.name[0]}
        </div>
        <div>
          <h1 className="text-xl font-bold text-slate-900">{patient.name}</h1>
          <p className="text-sm text-slate-500">Nível {patient.diagnosis_level} · {patient.communication_method}</p>
        </div>
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <div className="rounded-xl border border-slate-200 bg-white p-4">
          <h2 className="mb-3 text-sm font-semibold text-slate-500">Informações</h2>
          <dl className="flex flex-col gap-2 text-sm">
            <div><dt className="text-slate-400">Nascimento</dt><dd className="font-medium">{new Date(patient.birth_date).toLocaleDateString("pt-BR")}</dd></div>
            {patient.diagnosis_date && <div><dt className="text-slate-400">Diagnóstico</dt><dd className="font-medium">{new Date(patient.diagnosis_date).toLocaleDateString("pt-BR")}</dd></div>}
          </dl>
        </div>

        <div className="rounded-xl border border-slate-200 bg-white p-4 lg:col-span-2">
          <div className="mb-3 flex items-center justify-between">
            <h2 className="text-sm font-semibold text-slate-500">Objetivos terapêuticos</h2>
            <Link href={`/pacientes/${id}/objetivos`} className="text-xs text-blue-600 hover:underline">Ver todos →</Link>
          </div>
          <div className="flex flex-col gap-3">
            {activeGoals.length === 0 ? (
              <p className="text-sm text-slate-400">Nenhum objetivo ativo.</p>
            ) : (
              activeGoals.slice(0, 4).map((g) => (
                <GoalProgressBar key={g.id} title={g.title} domain={g.domain} score={g.last_score ?? 0} />
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
