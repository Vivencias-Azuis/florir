"use client"

export default function FamiliaError({ reset }: { error: Error; reset: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-blue-50 text-center p-8">
      <p className="text-slate-500 mb-4">Erro ao carregar informações. Tente novamente.</p>
      <button onClick={reset} className="rounded-lg bg-blue-600 px-4 py-2 text-sm text-white hover:bg-blue-700">
        Tentar novamente
      </button>
    </div>
  )
}
