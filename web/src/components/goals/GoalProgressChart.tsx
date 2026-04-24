"use client"
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer } from "recharts"

interface ProgressEntry { recorded_at: string; score: number }

export function GoalProgressChart({ data }: { data: ProgressEntry[] }) {
  const chartData = data.map((p) => ({
    date: new Date(p.recorded_at).toLocaleDateString("pt-BR", { day: "2-digit", month: "2-digit" }),
    score: p.score,
  }))

  return (
    <ResponsiveContainer width="100%" height={160}>
      <LineChart data={chartData}>
        <XAxis dataKey="date" tick={{ fontSize: 10 }} />
        <YAxis domain={[0, 100]} tick={{ fontSize: 10 }} />
        <Tooltip />
        <Line type="monotone" dataKey="score" stroke="#3B82F6" strokeWidth={2} dot={{ r: 3 }} />
      </LineChart>
    </ResponsiveContainer>
  )
}
