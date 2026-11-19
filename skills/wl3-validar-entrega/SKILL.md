---
name: wl3-validar-entrega
description: Homologa (testa, valida, retesta) uma entrega de desenvolvimento ponta a ponta — back, BFF, site e app — a partir de um card do Jira ou de uma lista de MRs/PRs. Lê o fluxo completo, monta ambiente (local com harness ou remoto), exige feature flag em toda funcionalidade nova (sem flag, barra a entrega e pede a inserção ao dev), executa matriz de cenários com prints no momento do teste e cada flag ligada e desligada, compara com a base, classifica achados, gera relatório e, com aprovação do usuário, abre bugs, comenta e move status no Jira e no GitLab/GitHub. Use quando o usuário pedir para homologar, testar, validar, retestar ou revisar uma entrega, uma MR, um card ou uma correção de bug, ou disser "houve ajustes, teste de novo".
---

# wl3-validar-entrega

Processo de homologação de entrega. Siga as etapas na ordem. Cada etapa tem saída obrigatória antes da próxima.

## Perfil do ambiente

Tudo que é específico da empresa (hosts, IDs de projeto, cloudId do Jira, tipo de issue de bug, repositórios, regras do time) fica num **perfil local**, fora deste repositório: `~/.claude/homologacao/perfil.md`.

- Leia o perfil no início da etapa 0.
- Não existe (primeira execução do usuário): crie seguindo `references/perfil-modelo.md` — descubra sozinho o que der (Git host, Jira, tipos de issue, repositórios, URLs de ambiente, padrão de commit), pergunte só o resto numa única rodada, mostre o perfil montado e grave só depois da confirmação.
- Dado do perfil se mostrou errado durante a homologação: corrija só o trecho afetado, com confirmação.
- Nunca copie dados do perfil para este repositório.

Referências (leia quando a etapa pedir):
- `references/ambiente-e-scripts.md` — harness local, stubs, proxy, build do front, simulador, scripts globais e locais.
- `references/matriz-cenarios.md` — grupos de cenários e como escolher.
- `references/modelos.md` — modelos de bug, comentário de subtarefa, comentário de MR, relatório.
- `references/armadilhas.md` — problemas de ambiente já resolvidos e padrões de defeito já encontrados.
- `references/perfil-modelo.md` — modelo do perfil local.
- `scripts/` — scripts reutilizáveis (proxy de API, captura de API com print, screenshot e reabertura do simulador).

## Regras fixas

- **Feature flag é obrigatória em funcionalidade nova.** Todo comportamento novo da entrega (tela, componente, fluxo, regra, endpoint, integração, consulta nova) fica atrás de uma feature flag que, desligada, devolve o comportamento anterior. Funcionalidade nova sem flag, ou com parte do caminho novo fora da flag, **barra a homologação**: veredito `BLOQUEADO: sem feature flag`, nenhum cenário funcional é executado e o pedido de inserção da flag vai ao dev (modelo em `references/modelos.md`, com a aprovação de envio da regra de ações externas). Correção de bug e refatoração sem mudança de comportamento não exigem flag nova; na dúvida se é funcionalidade nova, pergunte ao usuário antes de seguir.
- **Toda flag é testada ligada e desligada**, sem exceção: os dois estados entram na matriz, com print de cada um. Desligada = comportamento da base, sem chamada, consulta, evento ou layout novos. Um estado que não pôde ser testado impede o veredito `APROVADO`.
- Afirmação do dev é hipótese, não fato. Toda afirmação vira cenário medido.
- Acontece em produção → incidente. Não acontece → bug (o tipo de issue e o pai vêm do perfil). Conferir produção (só leitura: GET, headers, logs) antes de classificar e registrar o porquê.
- Ações externas **só com aprovação explícita do usuário**, uma vez por rodada, depois de mostrar o resumo: criar card ou subtarefa, mudar status no Jira, comentar no Jira, comentar no Git host. Achou bug no meio do teste: anote e conte no final, não abra.
- **Evidência sempre publicada no card e na MR.** Todo registro externo leva a evidência do que afirma: bug, comentário em história e subtarefa, nota de MR (inclusive das MRs de outros ambientes), pedido de feature flag e comentário que acompanha mudança de status. Evidência = print do momento do teste (tela ou captura de API) de cada cenário citado, sucesso e falha, com os dois estados de cada flag; mais o SHA testado e o caminho do JSON do cenário. Pedido de feature flag: link para `arquivo:linha` no diff da MR do caminho sem proteção. Imagem sobe pelo Git host (Jira com URL absoluta, MR com o campo `markdown` do upload) e a renderização é conferida antes de publicar. Sem evidência, não publique: gere a evidência ou diga ao usuário o que falta. Conferir depois de publicar que as imagens abrem no Jira e na MR.
- Mudança de status: tente a transição. Se o workflow ou a permissão impedir, informe a transição que falhou e o status em que o card ficou.
- Nunca push, merge ou force-push em branch protegida. Merge local para testar é permitido em worktree temporário.
- Nunca trabalhar no worktree principal do usuário. Worktrees de teste ficam no scratchpad.
- Commits, branches e comentários seguem o CLAUDE.md do usuário e as regras do perfil.

## Etapa 0 — Entrada

1. Leia o perfil local.
2. Aceite as duas formas:
   - **ID do card**: buscar história, subtarefas, links e comentários; achar as MRs nos links, comentários e branches com o ID.
   - **Lista de MRs/PRs**: `glab mr view <n> -F json` ou `gh pr view <n> --json ...` (rodar de dentro do repo); achar o card pelo nome da branch ou título.
3. **Pergunte o ambiente** de teste (local com harness, dev, QAS/staging, sandbox) e qual MR/branch vale para cada ponta. Não assuma dev.
4. **Localize os repositórios** de cada ponta afetada (pastas do perfil). Faltou algum: avise e pergunte se o usuário clona ou se você clona.
5. Leia descrição, critérios de aceite, critérios de reteste das subtarefas, comentários anteriores (último reteste, pontos com o PO) e a mensagem do dev sobre o ajuste.
6. Liste as afirmações do dev ("sem cache", "anônimo não manda null", "latência igual ou melhor") e transforme cada uma em hipótese testável.
7. Liste as funcionalidades novas da entrega e a feature flag de cada uma (nome, serviço, onde é lida em cada ponta, valor no ambiente escolhido, como ligar e desligar nesse ambiente). Funcionalidade nova sem flag citada no card, na MR ou no código: marque como **sem flag**; o portão da etapa 2 confirma.

Saída: tabela com card, subtarefas abertas, MRs (repo, origem → destino, SHA do head), funcionalidades novas × flag, ambiente escolhido, hipóteses.

## Etapa 1 — Versões

1. `git fetch` de todas as branches envolvidas. O SHA de referência é o head da MR no Git host (pega force-push e rebase).
2. Diff desde o SHA do último reteste, por ponta. Commit rebaseado: compare os arquivos da feature (`git diff --stat old new -- <arquivos>`) para saber se o teste anterior ainda vale.
3. **Feature × branch de merge**: liste código que existe no destino e não na feature. Defeito que só aparece depois do merge nasce aqui.
4. Confira se as MRs de cada ambiente têm os mesmos commits da feature. Atrasada → registrar.
5. Build distribuído (loja interna, Firebase, TestFlight): confira de que commit ele saiu.

Saída: SHAs, commits novos, divergências entre ambientes.

## Etapa 2 — Leitura do código

1. Leia o **fluxo completo**, ponta a ponta, em todas as camadas (API, BFF, site, app), não só o diff.
2. Parte não implementada (critério sem código, ponta sem MR, flag sem consumidor, subtarefa finalizada sem entrega): **pergunte** se entra no teste ou fica fora do escopo.
3. Anote suspeitas; cada uma vira cenário. Procure sempre: concorrência (tarefas em paralelo sobre recurso com escopo, como DbContext), chave de cache (compartilhada entre usuários?), caminho legado ainda ativo, revisita e recarga, prazos e retentativa, entrada vinda do cliente (cookie, query), chaves que precisam bater entre SSR e cliente, valores literais "undefined"/"null" vindos do front, regra de exibição que depende de texto em vez de tipo.

4. **Cobertura da flag**: para cada funcionalidade nova, siga o caminho novo em todas as pontas e confirme que a flag o protege por inteiro. Procure: código novo alcançável com a flag desligada (chamada, consulta, evento de analytics, migração, job, rota), ponta que não lê a flag (back protegido, app não), flag lida só no front com o back já mudando o contrato para todos, valor padrão ligado quando o serviço de flags falha, flag que não volta ao comportamento da base.

Saída: mapa do fluxo + lista de suspeitas + cobertura da flag por funcionalidade (protegida / parcial / sem flag).

### Portão de feature flag

Antes da etapa 3, com o resultado da etapa 0 (item 7) e da etapa 2 (item 4):

- Toda funcionalidade nova protegida por flag nas pontas que ela toca: siga.
- Alguma funcionalidade nova **sem flag** ou com **cobertura parcial**: pare aqui. Não monte ambiente nem execute cenário funcional. Mostre ao usuário o veredito `BLOQUEADO: sem feature flag`, a lista (funcionalidade, ponta, arquivo/linha do caminho sem proteção) e o pedido ao dev pronto (modelo "Pedido de feature flag" em `references/modelos.md`). Com a aprovação, publique o pedido no card e na MR e, se o perfil permitir, devolva o card ao dev. Reteste só depois que a flag entrar; a rodada seguinte recomeça na etapa 1.
- O usuário decide liberar sem flag (exceção do time): registre a decisão, quem decidiu e o motivo no relatório e no comentário do card; a exceção não muda o teste dos dois estados de qualquer outra flag da entrega.

## Etapa 3 — Ambiente

Leia `references/ambiente-e-scripts.md`.

1. **Scripts**: procure primeiro em `~/.claude/homologacao/scripts/` (veja o `README.md`); se a pasta não existir, copie de `scripts/` desta skill. Depois procure em `evidencias-<card>/scripts/`. Só crie se nada servir. Ao criar, pergunte se salva também na pasta global.
2. **Local**: worktrees da MR e da base no scratchpad; patches de harness mínimos e salvos em `.diff`; stubs de flags e parceiros; dois regimes de prazo (funcional com override, medição com prazos reais); contorno de defeito só em patch separado.
3. **Remoto (dev/QAS)**: confirme que o deploy corresponde ao SHA da MR antes de testar.
4. **Front**: site em build de produção (`next build` + `next start`) com proxy de API quando local; app no simulador com o build da branch, apontando para o proxy quando precisar contar chamadas ou forçar bordas.

Saída: ambiente de pé, com SHA, portas, modos dos stubs e patches aplicados registrados.

## Etapa 4 — Matriz de cenários

Leia `references/matriz-cenarios.md`. Monte a matriz a partir de: critérios de aceite e de reteste + hipóteses da etapa 0 + suspeitas da etapa 2 + regressão do que já foi aprovado + cada flag ligada e desligada (obrigatório, nunca "não se aplica" em entrega com flag). Use só os grupos que fazem sentido para a entrega. Mostre a matriz ao usuário antes de executar quando ela for nova (primeira rodada).

## Etapa 5 — Execução e coleta

1. **Print no momento do teste**, de sucesso e de falha:
   - navegador ou app: screenshot da tela durante a navegação, com URL/estado visível;
   - API: captura da requisição e da resposta na hora da chamada (comando, status, trecho de corpo e headers, horário), gravada e renderizada em imagem.
   Nome do print = cenário + passo (`H15-1-volta-p1.png`, `H15-2-...`). Nunca reaproveitar um nome: cada captura é um arquivo novo, inclusive a de uma falha inesperada, que é a evidência mais importante.
2. Cada cenário grava JSON (IDs, contagens, payload enviado ao parceiro, tempo) em `evidencias-<card>/reteste-<data>/cenarios/`.
3. Cruze cada falha com o log da aplicação até a exceção.
4. Intermitente: N rodadas (o critério do card manda; padrão 5) antes de dizer "não reproduziu".
5. Testes automatizados: MR × base em worktrees limpos, comparação **por nome** das falhas (há baseline vermelho). Timeout com a máquina carregada: reexecutar isolado antes de acusar.

## Etapa 6 — Análise

Para cada item: defeito real ou artefato do ambiente? Depois classifique: aprovado, reprovado, bloqueado (sem feature flag ou flag com cobertura parcial), intermitente, regressão, ponto para o PO (diferente do descrito sem quebrar critério), fora de escopo. Bug × incidente. Gravidade. Causa raiz com arquivo/método e por que não apareceu antes.

## Etapa 7 — Relatório

`evidencias-<card>/reteste-<data>/RELATORIO-RETESTE-<n>.md` conforme `references/modelos.md`, com cenários, testes, `.diff` e prints do momento. Print-resumo (tabela HTML → PNG) só como complemento. Upload das imagens no Git host (endpoint e IDs no perfil), URLs em `prints/uploads.tsv`: na MR use o campo `markdown` do upload (`/uploads/...`), no Jira a URL absoluta; confira a renderização antes de publicar (`references/ambiente-e-scripts.md` › Prints).

## Etapa 8 — Comunicação (com aprovação)

Mostre ao usuário: veredito, bugs propostos, comentários por card e por MR (com as imagens já enviadas e renderizadas), transições de status. Após o ok:
1. Bugs com o tipo de issue do perfil, como filhos da história, responsável = dev da entrega, com os prints da falha e da base.
2. Comentário em cada subtarefa testada e na história, com os prints dos cenários e dos dois estados de cada flag.
3. Nota em cada MR, inclusive as de outros ambientes afetados, com os mesmos prints.
4. Transições de status, cada uma com o comentário de evidência no card; informe as que falharem.
5. Abra cada card e MR publicados e confira que as imagens aparecem; quebrada, corrija editando o mesmo comentário ou nota.

## Etapa 9 — Encerramento

1. Memória: só o que não é óbvio. Aprendizado que vale para qualquer empresa → `references/armadilhas.md`; específico da empresa → perfil local.
2. Quando tudo estiver ok e a atividade for liberada: parar servidores, remover worktrees, apagar `evidencias-<card>/scripts/` e as evidências locais. Scripts globais e perfil ficam.
3. Até lá, evidências e scripts locais ficam para o próximo reteste.

## Fechamento de cada rodada

Termine com: veredito, tabela de flags (funcionalidade, flag, resultado ligada, resultado desligada), tabela por item (resultado + evidência), achados novos, pontos para o PO, o que não foi testado e por quê, e a pergunta de aprovação da etapa 8.
