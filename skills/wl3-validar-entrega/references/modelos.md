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

**Insumos:** ambiente, massa, modo do parceiro.
**Flags:** `<flag>` ligada: <resultado>; desligada: <resultado> (uma linha por flag).
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

### 🚩 Feature flags
| Funcionalidade | Flag | Ligada | Desligada |
|---|---|---|---|

### ⚠️ Pontos para o PO
1. ...

### Testes automatizados
MR × base, falhas comparadas por nome.

### 📎 Evidências
![<cenário>-<passo>](/uploads/<hash>/<arquivo>)
`evidencias-<card>/reteste-<data>/cenarios/...`
```

Todo modelo deste arquivo leva evidência (regra fixa da `SKILL.md`): nenhum bug, comentário ou nota sai sem pelo menos um print do momento do teste por cenário citado.

## Pedido de feature flag

Usado quando o portão de feature flag barra a entrega. Vai como comentário no card (história ou subtarefa da ponta) e como nota em cada MR afetada, só com a aprovação do usuário.

```markdown
## 🚩 Homologação bloqueada: funcionalidade nova sem feature flag

Analisado em `<branch>` @ `<sha>` (MR !<n>) em <data>. A homologação não segue enquanto a funcionalidade nova não estiver atrás de uma feature flag.

| Funcionalidade | Ponta | Situação | Onde |
| --- | --- | --- | --- |
| <o que é novo> | <back/BFF/site/app> | <sem flag / flag não protege este caminho> | `<arquivo>:<linha>` |

### O que precisa entrar
* Uma feature flag (no serviço de flags do time) que protege todo o caminho novo, em todas as pontas listadas.
* Com a flag desligada, o comportamento é o mesmo da base: sem chamada, consulta, evento ou layout novos.
* Nome da flag e como ligá-la no ambiente de teste, na descrição da MR.

### Próximo passo
Com a flag na MR, o reteste testa a entrega com a flag ligada e desligada.

### 📎 Evidências
* [`<arquivo>:<linha>`](<link para a linha no diff da MR>): <o que roda sem flag>
* <print do comportamento novo ativo sem flag que o desligue, quando já houver ambiente de pé>
```

## Relatório da rodada (`RELATORIO-RETESTE-<n>.md`)

1. Cabeçalho: SHAs de cada ponta, base de comparação, ambiente, massa, patches de harness.
2. Veredito em uma linha (`APROVADO`, `REPROVADO`, `BLOQUEADO: sem feature flag`).
3. Feature flags: funcionalidade, flag, cobertura (protegida/parcial/sem flag), resultado ligada, resultado desligada, evidência de cada estado. Exceção liberada pelo usuário: quem decidiu e o motivo.
4. Tabela por item: item, critério, resultado, evidência.
5. Defeitos novos: onde, erro, medido, por que não apareceu, impacto.
6. Pontos para o PO.
7. Regressão OK.
8. Testes automatizados (MR × base).
9. Problemas de ambiente e como foram contornados.
