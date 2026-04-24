const STATUS_STYLES: Record<string, string> = {
  scheduled: "border-l-blue-400 bg-blue-50",
  confirmed: "border-l-green-400 bg-green-50",
  completed: "border-l-slate-300 bg-slate-50",
  cancelled: "border-l-red-300 bg-red-50 opacity-60",
  no_show: "border-l-amber-300 bg-amber-50 opacity-60",
}

interface Props {
  patientName: string
  time: string
  modality: string
  status: string
}

export function SessionCard({ patientName, time, modality, status }: Props) {
  return (
    <div className={`rounded-lg border-l-4 px-3 py-2 text-xs ${STATUS_STYLES[status] ?? "border-l-slate-300 bg-slate-50"}`}>
      <p className="font-semibold text-slate-800">{time} — {patientName}</p>
      <p className="text-slate-500 uppercase tracking-wide">{modality}</p>
    </div>
  )
}
