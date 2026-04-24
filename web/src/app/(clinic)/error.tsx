"use client"

export default function ClinicError({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center h-full p-12 text-center">
      <p className="text-slate-500 mb-4">Erro ao carregar dados. Verifique sua conexão.</p>
      <button onClick={reset} className="rounded-lg bg-blue-600 px-4 py-2 text-sm text-white hover:bg-blue-700">
        Tentar novamente
      </button>
    </div>
  )
}
