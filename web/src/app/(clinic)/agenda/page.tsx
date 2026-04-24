import { cookies } from "next/headers"
import { api } from "@/lib/api"
import { SessionCard } from "@/components/agenda/SessionCard"

interface Session {
  id: number
  scheduled_at: string
  status: string
  modality: string
  patient_id: number
}

const DAYS = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]

function startOfWeek(date: Date): Date {
  const d = new Date(date)
  d.setDate(d.getDate() - d.getDay())
  d.setHours(0, 0, 0, 0)
  return d
}

export default async function AgendaPage() {
  const token = (await cookies()).get("florir_token")?.value ?? ""
  const sessions = await api.get<Session[]>("/therapy_sessions", token)

  const now = new Date()
  const weekStart = startOfWeek(now)
  const weekDays = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(weekStart)
    d.setDate(weekStart.getDate() + i)
    return d
  })

  function sessionsForDay(day: Date) {
    return sessions.filter((s) => {
      const d = new Date(s.scheduled_at)
      return d.toDateString() === day.toDateString()
    }).sort((a, b) => new Date(a.scheduled_at).getTime() - new Date(b.scheduled_at).getTime())
  }

  return (
    <div className="p-6">
      <h1 className="mb-6 text-xl font-bold text-slate-900">Agenda</h1>
      <div className="grid grid-cols-7 gap-2">
        {weekDays.map((day, i) => {
          const daySessions = sessionsForDay(day)
          const isToday = day.toDateString() === now.toDateString()
          return (
            <div key={i} className="rounded-xl border border-slate-200 bg-white p-3 min-h-32">
              <div className={`mb-2 text-center text-xs font-semibold ${isToday ? "text-blue-600" : "text-slate-400"}`}>
                <div>{DAYS[i]}</div>
                <div className={`mt-0.5 text-lg ${isToday ? "bg-blue-600 text-white rounded-full w-7 h-7 flex items-center justify-center mx-auto" : "text-slate-700"}`}>
                  {day.getDate()}
                </div>
              </div>
              <div className="flex flex-col gap-1">
                {daySessions.map((s) => (
                  <SessionCard
                    key={s.id}
                    patientName={`Paciente #${s.patient_id}`}
                    time={new Date(s.scheduled_at).toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit" })}
                    modality={s.modality}
                    status={s.status}
                  />
                ))}
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
