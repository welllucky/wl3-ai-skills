# Scripts globais de homologação

Usados pela skill `wl3-validar-entrega`. Antes de criar um script novo, verifique se um destes serve. Os scripts e patches específicos de uma atividade ficam em `evidencias-<card>/scripts/` e são apagados quando a atividade é liberada; os desta pasta ficam.

| Script | Para que serve | Uso |
|---|---|---|
| `qa_api_proxy.py` | Proxy HTTP entre o cliente (app, site) e uma API remota. Repassa tudo, registra cada chamada em `.jsonl` (status, `Date`, `Age`, `X-Cache`, opções devolvidas) e, por regra, reescreve campos da resposta ou injeta falha | `QA_PROXY_STATE=<state.json> QA_PROXY_LOG=<calls.jsonl> QA_PROXY_UPSTREAM=<url-base-da-api> QA_PROXY_PORT=5199 python3 qa_api_proxy.py` |
| `api_capture.py` | Funções `call(url)` (requisição com horário, status, headers, corpo) e `render(png, título, veredito, nota, chamadas)` (print da chamada no momento, HTML → PNG com Chrome headless) | `from api_capture import call, render` num script de cenários |
| `sim_shot.sh` | Screenshot do simulador iOS no momento do passo | `sim_shot.sh <udid> <arquivo.png>` |
| `sim_reopen.sh` | Encerra e reabre o app no simulador e navega por deep link, forçando nova consulta | `sim_reopen.sh <udid> <bundle_id> <deep_link> [espera_s]` |

## qa_api_proxy.py: regras (`state.json`)

O arquivo é relido a cada requisição. A primeira regra que casa vale.

```json
{"rules": [
  {"name": "A05-options", "path": "/api/v1/options", "product": "12345", "deadline_in_s": 75},
  {"name": "A05-pd", "path": "/api/v1/deadline", "product": "12345", "deadline_in_s": 10800, "value": 19.9},
  {"name": "A11-falha", "path": "/api/v1/deadline", "mode": "500"}
]}
```

| Campo | Efeito |
|---|---|
| `path`, `product` | casa pelo prefixo do path e pelo `ProductId` da query |
| `deliveryTypeId` | modalidade reescrita (padrão 1) |
| `deadline_in_s` | `purchaseDeadline` = agora + N s, fixo enquanto o `state.json` não mudar |
| `deadline_null`, `deadline_raw` | `null` ou valor literal (ex. `"abc"`) |
| `value`, `arrivesText`, `arrivesTextShort`, `arrives` | sobrescrevem o campo |
| `date_shift_s` | desloca o header `Date` (simula relógio do servidor diferente) |
| `age` | força o header `Age` (simula resposta em cache) |
| `mode` | `500`, `timeout` (com `sleep_s`), `empty` (`options: []`), `garbage` |

As regras de reescrita foram feitas para o formato de opções de frete (`options` como lista ou `{serverTime, options}`). Para outro contrato, adapte a função `rewrite_options`.

Cuidado: o proxy usa `send_response_only` para não injetar um segundo `Date`; não troque por `send_response`.

## qa_api_proxy.py: campos configuráveis

| Campo | Padrão | Uso |
|---|---|---|
| `product_param` | `ProductId` | parâmetro da query usado por `product` |
| `list_field` | `options` | lista dentro do corpo quando ele é objeto |
| `type_field` + valor | `deliveryTypeId` = 1 | item da lista que recebe a reescrita (`"type_field": "kind", "kind": "express"`) |
| `deadline_field` | `purchaseDeadline` | campo reescrito por `deadline_in_s`, `deadline_null`, `deadline_raw` |
| `set` | — | objeto com campos fixos a sobrescrever (`{"price": 9.9}`) |

`QA_PROXY_SUMMARY_PREFIX` limita a quais paths o log grava o resumo do corpo (padrão: todos).

## App no simulador apontando para o proxy

No worktree do app, troque a URL base da API no arquivo de ambiente de homologação por `http://localhost:5199/` antes do build. O esquema de homologação precisa permitir `NSAllowsLocalNetworking`.
