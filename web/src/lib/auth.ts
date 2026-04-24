// JWT payload decoder — storage functions removed, auth uses httpOnly cookie
export function parseToken(token: string): { role: string; clinic_id: number; user_id: number } | null {
  try {
    const b64 = token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/")
    const payload = JSON.parse(atob(b64))
    return payload
  } catch {
    return null
  }
}
