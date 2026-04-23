import Link from "next/link"

interface Props {
  id: number
  name: string
  diagnosisLevel: number
  communicationMethod: string
}

export function PatientCard({ id, name, diagnosisLevel, communicationMethod }: Props) {
  return (
    <Link href={`/pacientes/${id}`} className="block rounded-xl border border-slate-200 bg-white p-4 hover:border-blue-300 hover:shadow-sm transition-all">
      <div className="flex items-center gap-3">
        <div className="flex h-10 w-10 items-center justify-center rounded-full bg-blue-100 text-blue-700 font-semibold text-sm">
          {name[0]}
        </div>
        <div>
          <p className="font-semibold text-slate-900">{name}</p>
          <p className="text-xs text-slate-400">Nível {diagnosisLevel} · {communicationMethod}</p>
        </div>
      </div>
    </Link>
  )
}
