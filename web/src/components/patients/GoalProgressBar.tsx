interface Props {
  title: string
  score: number
  domain: string
}

const COLORS: Record<string, string> = {
  communication: "bg-blue-500",
  social_skills: "bg-purple-500",
  motor: "bg-green-500",
  behavior: "bg-red-400",
  daily_living: "bg-amber-500",
  cognitive: "bg-cyan-500",
}

export function GoalProgressBar({ title, score, domain }: Props) {
  const color = COLORS[domain] ?? "bg-slate-400"
  return (
    <div>
      <div className="mb-1 flex justify-between text-xs">
        <span className="text-slate-700">{title}</span>
        <span className="font-semibold text-slate-600">{score}%</span>
      </div>
      <div className="h-1.5 w-full rounded-full bg-slate-100">
        <div className={`h-1.5 rounded-full ${color} transition-all`} style={{ width: `${score}%` }} />
      </div>
    </div>
  )
}
