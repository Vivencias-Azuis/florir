export function getToken(): string | null {
  if (typeof window === "undefined") return null
  return localStorage.getItem("florir_token")
}

export function setToken(token: string): void {
  localStorage.setItem("florir_token", token)
}

export function clearToken(): void {
  localStorage.removeItem("florir_token")
}

export function parseToken(token: string): { role: string; clinic_id: number; user_id: number } | null {
  try {
    const b64 = token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/")
    const payload = JSON.parse(atob(b64))
    return payload
  } catch {
    return null
  }
}
