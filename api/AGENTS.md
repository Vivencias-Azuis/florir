# Rails API CRUD Agent Rules

## Objetivo

Estas regras existem para reduzir variacao desnecessaria quando agentes alteram um app Rails API com topologia CRUD.

## Regras principais

1. Controllers devem ser finos. Eles recebem request, chamam o fluxo necessario e respondem JSON.
2. Models nao devem falar com APIs externas. Integracoes externas ficam em adapters, clients ou services dedicados.
3. Callbacks de ActiveRecord devem ser evitados para side effects importantes. Prefira fluxos explicitos.
4. Em CRUD simples, nao crie service object por reflexo. Extraia apenas quando houver regra de negocio ou orquestracao real.
5. Queries complexas devem sair de controller. Use scope, query object ou classe equivalente.
6. Request specs sao obrigatorios para endpoints CRUD publicos e relevantes.
7. JSON relevante deve ter contrato estavel por serializer, presenter ou approved fixture.
8. Migrations devem ser reversiveis, pequenas e com impacto operacional avaliado.
9. Nomes devem refletir o dominio. Evite classes genericas como `Processor`, `Manager`, `Utils` e `Helper` sem contexto.
10. Se uma mudanca tocar arquitetura, rode `script/check_architecture` antes de concluir.
11. Se um endpoint novo for criado, ele deve vir acompanhado de rota, controller, cobertura de request spec e resposta JSON coerente.

## Fluxo minimo do agente

Antes de editar:

- ler `docs/architecture.md`
- ler o how-to relevante em `docs/`
- inspecionar exemplos em `app/` e `spec/requests/` antes de inventar nova estrutura

Antes de concluir:

- rodar `script/ci-fast`
- corrigir os erros encontrados
- se houver mudanca estrutural, rodar `script/ci-full`

## Sinais de alerta

Pare e reavalie se a mudanca:

- adiciona mais de uma nova abstracao para resolver um problema simples
- move regra de negocio para callback sem deixar o fluxo explicito
- adiciona mais uma concern generica
- aumenta acoplamento entre modulos sem documentar o motivo
- cria endpoint sem request spec correspondente
