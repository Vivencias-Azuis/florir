import { loginAction } from "./actions"
import { Input } from "@/components/ui/Input"
import { Button } from "@/components/ui/Button"

export default function LoginPage() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-slate-50">
      <div className="w-full max-w-sm rounded-2xl border border-slate-200 bg-white p-8 shadow-sm">
        <div className="mb-8 text-center">
          <h1 className="text-2xl font-bold text-slate-900">Florir</h1>
          <p className="mt-1 text-sm text-slate-500">Acesse sua clínica</p>
        </div>
        <form action={loginAction as (formData: FormData) => void} className="flex flex-col gap-4">
          <Input label="Código da clínica" name="clinic_slug" placeholder="minha-clinica" required />
          <Input label="E-mail" name="email" type="email" placeholder="voce@clinica.com" required />
          <Input label="Senha" name="password" type="password" placeholder="••••••••" required />
          <Button type="submit" className="mt-2 w-full">Entrar</Button>
        </form>
      </div>
    </main>
  )
}
