# Florir

SaaS multi-tenant para clínicas de autismo. Prontuário especializado para TEA com objetivos terapêuticos por domínio, gráficos de evolução e portal da família via magic link.

## Stack

| Camada | Tecnologia |
|--------|-----------|
| API | Rails 8.1, Ruby 4.0.2, API-only |
| Banco | SQLite3 (dev/test) + Turso/libSQL (prod) |
| Jobs | Solid Queue |
| Auth clínica | JWT (24h) via cookie httpOnly |
| Auth família | Magic link — token gerado automaticamente |
| Frontend | Next.js 15, TypeScript, Tailwind CSS, App Router |
| Charts | Recharts |

## Estrutura

```
florir/
  api/    ← Rails API
  web/    ← Next.js frontend
```

## Rodando localmente

```bash
./dev.sh
```

Sobe a API em `http://localhost:4000` e o frontend em `http://localhost:3000`.

### Manual

**API:**
```bash
cd api
bundle install
bin/rails db:create db:migrate
bin/rails server -p 4000
```

**Frontend:**
```bash
cd web
npm install
npm run dev
```

## Variáveis de ambiente

**`api/.env`** (copie de `api/.env.example`):
```
DATABASE_URL=      # Turso libSQL URL (só produção)
JWT_SECRET=        # secret para assinar tokens
```

**`web/.env.local`**:
```
NEXT_PUBLIC_API_URL=http://localhost:4000
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

## API — Endpoints

### Auth
```
POST /auth/register   { clinic_name, clinic_slug, email, password }
POST /auth/login      { clinic_slug, email, password } → { token }
```

### Pacientes (requer JWT)
```
GET    /patients
POST   /patients
GET    /patients/:id
PUT    /patients/:id
DELETE /patients/:id
GET    /patients/:id/goals
GET    /patients/:id/sessions
```

### Sessões terapêuticas
```
GET    /therapy_sessions
POST   /therapy_sessions
PUT    /therapy_sessions/:id
DELETE /therapy_sessions/:id
```

### Objetivos terapêuticos
```
GET    /therapeutic_goals
POST   /therapeutic_goals
PUT    /therapeutic_goals/:id
DELETE /therapeutic_goals/:id
GET    /therapeutic_goals/:id/progresses
POST   /therapeutic_goals/:id/progresses
```

### Mensagens
```
GET  /messages
POST /messages
PUT  /messages/:id/read
```

### Portal família (magic link)
```
GET  /family/:token/dashboard
GET  /family/:token/sessions
GET  /family/:token/goals
GET  /family/:token/messages
POST /family/:token/messages
```

## Multi-tenancy

Row-level via `Current.clinic_id`. Cada request autenticado seta o `clinic_id` do JWT — todos os models tenant-scoped filtram automaticamente via `default_scope`.

## Testes

```bash
cd api && bin/rails test
# 37 runs, 0 failures
```

## CI

GitHub Actions em `.github/workflows/ci.yml`:
- Rails: testes + Brakeman
- Next.js: tsc + build
