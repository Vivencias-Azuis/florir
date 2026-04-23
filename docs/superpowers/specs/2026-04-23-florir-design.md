# Florir — Design Spec

**Data:** 2026-04-23  
**Produto:** Florir — SaaS de gestão para clínicas de autismo  
**Domínios:** florir.app · florir.io  
**Status:** Aprovado para implementação

---

## Visão Geral

Florir é um SaaS multi-tenant voltado a clínicas de autismo. Diferencia-se de gestores genéricos (como Zenfisio) por dois pilares: **prontuário especializado para TEA** com objetivos terapêuticos por domínio e gráficos de evolução, e **portal da família** com acesso simplificado ao progresso do filho.

Design visual: Calmo & Clínico — azuis e brancos suaves, tipografia clara, próximo ao Notion/Linear. Profissional e acolhedor.

---

## Stack

| Camada | Tecnologia |
|--------|-----------|
| Frontend | Next.js 15, TypeScript, Tailwind CSS, App Router |
| Backend | Rails 8 API, rails-harness (github.com/puppe1990/rails-harness) |
| Banco | Turso (libSQL/SQLite-compatible) |
| Jobs | Solid Queue (sem Redis, jobs no banco) |
| Testes Rails | Minitest |
| Qualidade | RuboCop, Brakeman, rails-harness scripts |
| CI | GitHub Actions |

---

## Arquitetura

### Multi-tenancy
Row-level isolation: todas as tabelas principais carregam `clinic_id`. Queries sempre escopadas ao tenant via before_action no Rails.

### Subdomínios
- `florir.app` — landing e onboarding
- `web.florir.app` — dashboard da clínica (admin + terapeuta)
- `familia.florir.app` — portal família (acesso por magic link)
- `api.florir.app` — Rails JSON API

### Auth
- Clínica/terapeuta: JWT com roles (`admin`, `therapist`)
- Família: magic link com `access_token` único por paciente (sem senha)

---

## Módulos do MVP

### 1. Auth & Multi-tenant
- Onboarding de nova clínica (nome, e-mail, slug)
- Login/logout com JWT
- Roles: `admin`, `therapist`, `family`
- Magic link para família enviado por e-mail via Solid Queue

### 2. Agendamento
- Calendário semanal e mensal
- Criar, editar e cancelar sessões
- Status: `scheduled` / `confirmed` / `completed` / `cancelled` / `no_show`
- Modalidade: `aba` / `pecs` / `dir_floortime` / `speech` / `occupational` / `psycho` / `other`
- Nota pós-sessão preenchida pelo terapeuta
- Notificação e-mail para família ao confirmar sessão (Solid Queue)

### 3. Prontuário TEA
- Ficha do paciente: nome, data nascimento, data diagnóstico, nível TEA (1/2/3), modo de comunicação (verbal/não-verbal/AAC)
- Plano terapêutico: objetivos por domínio (comunicação, habilidades sociais, comportamento, motricidade, vida diária, cognitivo)
- Método por objetivo: ABA, PECS, DIR/Floortime, VB-MAPP, outro
- Registro de evolução por sessão (score 0–100 + nota)
- Gráfico de progresso por objetivo ao longo do tempo
- Status do objetivo: `active` / `achieved` / `paused` / `discontinued`

### 4. Portal Família
- Acesso via magic link por e-mail (sem cadastro de senha)
- Visão do progresso do filho: objetivos ativos com % de evolução
- Próximas sessões agendadas
- Última nota do terapeuta pós-sessão
- Chat simples com o terapeuta (mensagens texto)

---

## Modelo de Dados

```
Clinic
  id, name, slug, email, phone, plan, created_at

User
  id, clinic_id, name, email, password_digest, role (admin/therapist/family)

Patient
  id, clinic_id, name, birth_date, diagnosis_date, diagnosis_level (1/2/3)
  communication_method (verbal/non_verbal/aac), notes

TherapySession
  id, clinic_id, patient_id, therapist_id (user)
  scheduled_at, duration_minutes, status, modality, session_notes

TherapeuticGoal
  id, clinic_id, patient_id
  domain, method, title, description, target
  status, started_at, achieved_at

GoalProgress
  id, goal_id, session_id, therapist_id
  score (0–100), notes, recorded_at

FamilyAccess
  id, patient_id, user_id, relation (mother/father/guardian/other)
  access_token, active

Message
  id, clinic_id, patient_id, sender_id, receiver_id, body, read_at
```

---

## Rotas Next.js

### Público — florir.app
| Rota | Tela |
|------|------|
| `/` | Landing / marketing |
| `/login` | Autenticação |
| `/onboarding` | Cadastro nova clínica |

### Clínica — web.florir.app
| Rota | Tela |
|------|------|
| `/dashboard` | Visão geral, métricas, agenda do dia |
| `/agenda` | Calendário semanal/mensal |
| `/pacientes` | Lista de pacientes |
| `/pacientes/[id]` | Prontuário completo (tabs) |
| `/pacientes/[id]/objetivos` | Plano terapêutico TEA |
| `/pacientes/[id]/objetivos/[gid]` | Objetivo individual + gráfico evolução |
| `/configuracoes` | Dados da clínica, gestão de usuários |

### Família — familia.florir.app
| Rota | Tela |
|------|------|
| `/[token]` | Login via magic link |
| `/[token]/progresso` | Evolução do filho |
| `/[token]/sessoes` | Próximas sessões |
| `/[token]/mensagens` | Chat com terapeuta |

---

## Rotas Rails API — api.florir.app

```
POST   /auth/login
POST   /auth/register
DELETE /auth/logout

GET    /patients
POST   /patients
GET    /patients/:id
PUT    /patients/:id

GET    /patients/:id/sessions
POST   /sessions
GET    /sessions/:id
PUT    /sessions/:id
DELETE /sessions/:id

GET    /patients/:id/goals
POST   /goals
GET    /goals/:id
PUT    /goals/:id
DELETE /goals/:id

POST   /goals/:id/progresses
GET    /goals/:id/progresses

POST   /family_accesses
DELETE /family_accesses/:id
GET    /family/:token/dashboard
GET    /family/:token/sessions
GET    /family/:token/goals

GET    /messages?patient_id=
POST   /messages
PUT    /messages/:id/read
```

---

## Jobs (Solid Queue)

| Job | Gatilho |
|-----|---------|
| `FamilyMagicLinkJob` | Criação de FamilyAccess |
| `SessionConfirmationJob` | Sessão confirmada pelo terapeuta |
| `SessionReminderJob` | 24h antes da sessão agendada |

---

## Wireframes aprovados

- **Dashboard:** saudação + 4 métricas + agenda do dia com status colorido
- **Prontuário:** tabs (visão geral / objetivos / sessões / família), progresso por objetivo em barra
- **Portal Família:** header com próxima sessão, gráfico semanal, última nota do terapeuta

---

## Fora do MVP (v2)

- Gestão financeira (mensalidades, cobranças, Stripe/Abacate Pay)
- Relatórios para plano de saúde / INSS
- App mobile para família (Expo/React Native)
- Notificações push
- Integração Google Calendar

## Estratégia Mobile (v2)

Quando iniciar o app mobile, converter o repo para **Turborepo monorepo**:

```
florir/
  apps/
    web/        ← Next.js (atual)
    mobile/     ← Expo / React Native
  packages/
    ui/         ← componentes compartilhados (.tsx + .native.tsx)
    lib/        ← hooks, tipos, API client, validações
```

Next.js é React puro — zero retrabalho no código web ao migrar para monorepo.
