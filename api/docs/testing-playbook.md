# Testing Playbook

## Piramide recomendada

- unit specs para regra local
- request specs para comportamento HTTP
- architecture specs para drift estrutural
- contract tests ou approved fixtures para JSON importante

## Regras

- nao confiar apenas em tests gerados pela IA
- preferir request specs para fluxos principais
- manter fixtures aprovadas quando o contrato for load-bearing
- usar mutation testing seletivo em fluxos criticos quando o custo compensar

## Quando revisar manualmente

- mudanca com side effect relevante
- mudanca em autorizacao
- mudanca em contrato publico
- mudanca em performance sensivel
