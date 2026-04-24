import { api } from "@/lib/api"

interface Message { id: number; body: string; sender_id: number; created_at: string; read_at: string | null }

export default async function FamiliaMensagensPage({ params }: { params: Promise<{ token: string }> }) {
  const { token } = await params
  const messages = await api.get<Message[]>(`/family/${token}/messages`)

  return (
    <div className="rounded-2xl bg-white p-5 shadow-sm border border-slate-200">
      <h1 className="mb-4 text-lg font-bold text-slate-900">Mensagens</h1>
      <div className="flex flex-col gap-3">
        {messages.map((m) => (
          <div key={m.id} className="rounded-lg bg-slate-50 p-3 border border-slate-100">
            <p className="text-sm text-slate-800">{m.body}</p>
            <p className="mt-1 text-xs text-slate-400">
              {new Date(m.created_at).toLocaleDateString("pt-BR", { day: "2-digit", month: "short", hour: "2-digit", minute: "2-digit" })}
              {!m.read_at && <span className="ml-2 rounded-full bg-blue-100 px-1.5 py-0.5 text-blue-600">Nova</span>}
            </p>
          </div>
        ))}
      </div>
    </div>
  )
}
