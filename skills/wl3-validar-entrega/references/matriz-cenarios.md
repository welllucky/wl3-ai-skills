# Matriz de cenários

Fontes da matriz: critérios de aceite e de reteste de cada subtarefa, afirmações do dev (etapa 0), suspeitas da leitura do código (etapa 2), regressão do que já foi aprovado e feature flags. Cada linha da matriz tem: ID do cenário, grupo, origem (critério/hipótese/suspeita), passos, resultado esperado, evidência.

| Grupo | O que cobrir | Exemplo |
|---|---|---|
| Funcional | fluxo completo até o fim; invariantes (total = únicos, nada perdido, nada repetido) | percorrer todas as páginas de uma busca: exibidos = únicos |
| Perfis | identificado × anônimo × sem cookie × logado/deslogado × B2B | visitante sem identificador de sessão |
| Massa | volumes e formatos diferentes: poucos, muitos, vazio, limites de tamanho | termo com 2 páginas, com 800 itens, sem resultado; page size mínimo e máximo |
| Formato | textos e arredondamentos de cada faixa | "3h", "2h 24min", "45 min", "1 min" |
| Tempo | limites de janela, contagem em tela, virada de faixa com a tela aberta | entra nas últimas 24h e a mensagem aparece sozinha |
| Navegação | voltar, recarregar, pular, deep link, troca de filtro/ordem, segundo plano | 1→2→1, F5 na p2, app volta do segundo plano |
| Falha e prazos | parceiro rápido, no limite, lento, erro 5xx, fora, dado inválido; contar chamadas (retentativa) | parceiro em 0/300/600/1500 ms, 3 s, 500, campo `"abc"` |
| Recuperação | falha seguida de sucesso: a falha não fica presa (cache, marca) | 500 → próxima chamada já recupera |
| Relógio | hora do servidor × aparelho, resposta em cache (`Date`, `Age`) | servidor adiantado 30 min; `Age` 600 |
| Compatibilidade | clientes antigos (sem parâmetro novo), versões de contrato | app antigo sem o campo novo |
| Feature flag | ligada e desligada, e a troca com o app aberto | flag OFF = layout antigo e nenhuma consulta nova |
| Robustez | entrada malformada, adulterada, grande, versão desconhecida | parâmetro com versão inexistente, IDs fora do domínio |
| Cache e privacidade | um usuário recebe o resultado de outro? chave inclui o dono? endpoint que não pode ter cache tem? | anônimo B recebe o resultado do anônimo A; `X-Cache` e `Cache-Control` |
| Contrato com parceiro | payload que realmente sai (campos nulos, literais "undefined") | `"opaqueUserId": "undefined"` |
| Espelho | mesmo cenário em todas as camadas que implementam a regra | API e BFF |
| Latência | MR × base, a frio (entrada nova por rodada), mediana | 4 páginas somadas |
| Front | specs alteradas; headers do SSR em build de produção; E2E contando requisições; estado persistido (cookie/storage) | 1 requisição por navegação; F5 sem segunda requisição |
| Acessibilidade | rótulos, ordem de leitura, anúncios dinâmicos | rótulo junta modalidade, prazo, valor e tempo |
| Analytics | eventos do card: disparo, parâmetros, deduplicação | evento uma vez por exibição, não a cada minuto |
| Intermitência | N rodadas quando depende de ordem/tempo externo | resultado varia entre chamadas do parceiro |
| Ambientes | mesma entrega em cada MR de ambiente; build distribuído | staging sem os commits da develop; build saiu da tag anterior |

## Como decidir o que entra

- Todo critério de aceite e de reteste do card vira pelo menos um cenário.
- Toda afirmação do dev vira um cenário que pode refutá-la.
- Toda suspeita da leitura vira um cenário.
- Toda feature flag da entrega é testada ligada e desligada.
- Regressão: repetir pelo menos um cenário de cada item já aprovado nas rodadas anteriores.
- Grupo que não se aplica à entrega: registrar "não se aplica" no relatório; o que se aplica mas não pôde ser testado: registrar "não testado" e o motivo.
