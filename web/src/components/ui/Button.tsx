interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "ghost"
  loading?: boolean
}

export function Button({ children, variant = "primary", loading, className = "", ...props }: ButtonProps) {
  const base = "inline-flex items-center justify-center rounded-lg px-4 py-2 text-sm font-medium transition-colors disabled:opacity-50"
  const variants = {
    primary: "bg-blue-600 text-white hover:bg-blue-700",
    ghost: "bg-transparent text-slate-600 hover:bg-slate-100",
  }
  return (
    <button className={`${base} ${variants[variant]} ${className}`} disabled={loading || props.disabled} {...props}>
      {loading ? "Carregando..." : children}
    </button>
  )
}
