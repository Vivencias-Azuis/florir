"use server"
import { redirect } from "next/navigation"
import { api } from "@/lib/api"
import { cookies } from "next/headers"

export async function loginAction(formData: FormData) {
  const email = formData.get("email") as string
  const password = formData.get("password") as string
  const clinic_slug = formData.get("clinic_slug") as string

  try {
    const data = await api.post<{ token: string }>("/auth/login", { email, password, clinic_slug })
    const cookieStore = await cookies()
    cookieStore.set("florir_token", data.token, { httpOnly: true, secure: process.env.NODE_ENV === "production", path: "/" })
  } catch {
    return { error: "Email, senha ou código da clínica inválidos" }
  }

  redirect("/dashboard")
}
