# Rails API CRUD Harness Template

Template semi-executavel para aumentar a confianca no uso de coding agents em uma topologia especifica: `Rails API CRUD`.

Compare com os outros templates em [../docs/template-comparison-matrix.md](../docs/template-comparison-matrix.md).

## Topologia alvo

Este template assume um backend Rails focado em API JSON com fluxo CRUD classico:

- recursos REST expostos por controllers
- persistencia em ActiveRecord
- serializers ou camada equivalente para respostas publicas
- request specs como sensor principal de comportamento
- services opcionais apenas quando existe caso de uso real

## O que este template entrega

- guias para o agente em `AGENTS.md` e `docs/`
- scripts executaveis em `script/`
- exemplos de sensores arquiteturais em `spec/architecture/`
- exemplo de request spec em `spec/requests/`
- esqueleto ilustrativo de API em `app/`
- espacos para contratos e approved fixtures

## Estrutura

```text
template/
├── AGENTS.md
├── app/
├── docs/
├── script/
└── spec/
```

## Como usar

1. Copie o conteudo de `template/` para a raiz do seu app Rails API.
2. Ajuste os guias em `docs/` e `AGENTS.md` para as convencoes do time.
3. Revise os exemplos em `app/` e `spec/requests/` para alinhar com seu recurso real.
4. Revise os scripts em `script/` e adapte os checks que fazem sentido.
5. Rode:

```bash
chmod +x script/ci-fast script/ci-full script/check_architecture script/check_harness
script/check_harness
script/ci-fast
```

## Dependencias esperadas

O template funciona melhor quando o app possui:

- `rspec-rails`
- `rubocop`
- `brakeman`
- `simplecov` opcional

Os scripts fazem deteccao defensiva e pulam checks ausentes, mas o valor real do harness cresce quando essas ferramentas existem de fato.

## Filosofia

O objetivo nao e travar o time com regras arbitrarias. O objetivo e:

- reduzir erro estrutural
- encurtar o loop de autocorrecao do agente
- fazer o humano revisar so o que realmente importa

## O que o template considera "bom" para Rails API CRUD

- controller fino, com fluxo HTTP claro
- model com invariantes locais e sem IO externo
- JSON estavel para endpoints relevantes
- request specs cobrindo os fluxos publicos
- service object apenas quando ha regra de negocio que justifica a extracao
