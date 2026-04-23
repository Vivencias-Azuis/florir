import { cookies } from "next/headers"
import { api } from "@/lib/api"
import { PatientCard } from "@/components/patients/PatientCard"

interface Patient { id: number; name: string; diagnosis_level: number; communication_method: string }

export default async function PatientsPage() {
  const token = (await cookies()).get("florir_token")?.value ?? ""
  const patients = await api.get<Patient[]>("/patients", token)

  return (
    <div className="p-6">
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-xl font-bold text-slate-900">Pacientes</h1>
        <a href="/pacientes/novo" className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700">
          + Novo paciente
        </a>
      </div>
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {patients.map((p) => (
          <PatientCard key={p.id} id={p.id} name={p.name}
                       diagnosisLevel={p.diagnosis_level}
                       communicationMethod={p.communication_method} />
        ))}
      </div>
    </div>
  )
}
