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
    const payload = JSON.parse(atob(token.split(".")[1]))
    return payload
  } catch {
    return null
  }
}
