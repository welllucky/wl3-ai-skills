# Modelos

Jira: cloudId, tipo de issue de bug, projeto e labels vêm do perfil local. Bug = filho da história, responsável = dev da entrega, prioridade pela gravidade, labels da área (`back`, `bff`, `site`, `app`, ...). Imagem: link do upload no Git host; o MCP do Jira não anexa arquivo. No Jira, URL absoluta (`https://<gitlab>` + `full_path`); na MR, o campo `markdown` do upload (`/uploads/<hash>/<arquivo>`). Ver `ambiente-e-scripts.md` › Prints.

## Bug

Título: `[BACK|BFF|SITE|APP] <efeito para o usuário>: <causa curta>`

```markdown
## 🐞 Descrição
Encontrado no reteste de <data> da `<branch>` @ `<sha>` (MR !<n>). <efeito>. <por que é bug e não incidente>.

## 🔍 Causa
* <arquivo/método> faz X.
* <arquivo/método> faz Y.
* **Por que não apareceu antes:** <merge com destino, mocks, ambiente>.

## 🧪 Como reproduzir
<ambiente, branch, flags>. <requisição ou passos>.

| Variação | Resultado | Observação |
| --- | --- | --- |

## ❌ Comportamento atual
* ...

## ✅ Comportamento esperado
* ... (a forma da correção é decisão técnica)

## 🧪 Critérios de reteste
- [ ] ...

## 📎 Evidências
`evidencias-<card>/reteste-<data>/cenarios/...`
[<nome do print>](<url absoluta: https://<gitlab> + full_path>)
```

## Comentário de subtarefa

```markdown
## <✅|❌|⚠️> Reteste <data>: <veredito em uma linha>

Testado em `<branch>` @ `<sha>` (<commits relevantes>).

| Cenário | Esperado | Obtido |
| --- | --- | --- |

**Insumos:** ambiente, massa, modo do parceiro, flags.
**Passo a passo:** 1. ... 2. ...
**Ressalvas / pontos para o PO:** ...

Evidências: `<caminhos>`
[<nome do print>](<url absoluta: https://<gitlab> + full_path>)
```

## Nota de MR

```markdown
## Reteste <n> (<data>) · `<sha>` · **<APROVADO|REPROVADO ...>**

<!-- imagens: ![<cenário>](/uploads/<hash>/<arquivo>), campo `markdown` do upload; nunca /-/project/<id>/uploads/... -->

### ❌ <card do bug> · <título>
<causa em 2-3 linhas, números, link do card>

### ✅ O que passou
| Item | Resultado |
|---|---|

### ⚠️ Pontos para o PO
1. ...

### Testes automatizados
MR × base, falhas comparadas por nome.
```

## Relatório da rodada (`RELATORIO-RETESTE-<n>.md`)

1. Cabeçalho: SHAs de cada ponta, base de comparação, ambiente, flags, massa, patches de harness.
2. Veredito em uma linha.
3. Tabela por item: item, critério, resultado, evidência.
4. Defeitos novos: onde, erro, medido, por que não apareceu, impacto.
5. Pontos para o PO.
6. Regressão OK.
7. Testes automatizados (MR × base).
8. Problemas de ambiente e como foram contornados.
