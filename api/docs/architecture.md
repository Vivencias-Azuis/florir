# Architecture

## Objetivo

Este arquivo define as fronteiras minimas de uma topologia `Rails API CRUD`.

## Estrutura alvo

```text
app/
├── controllers/
├── models/
├── serializers/        # ou camada equivalente
└── services/           # opcional, quando houver caso de uso real

spec/
├── requests/
├── architecture/
└── contracts/
```

## Regras

- controllers recebem request, resolvem fluxo HTTP e respondem JSON
- models representam estado e invariantes locais
- serializers, presenters ou contratos equivalentes estabilizam JSON publico
- services ou processos representam casos de uso quando necessario, nao por reflexo
- integracoes externas nao vivem em controllers nem models
- request specs validam o comportamento do endpoint do ponto de vista da API

## Fronteiras

- controllers nao devem montar query complexa diretamente
- controllers nao devem instanciar clients externos
- models nao devem chamar HTTP, filas externas ou SDKs de terceiros
- serializers nao devem carregar regra de negocio central
- services nao substituem modelagem de dominio; eles orquestram

## Decisoes que exigem justificativa

- callback com side effect
- concern compartilhada por muitos models
- novo service object generico
- endpoint sem request spec
