# Armadilhas conhecidas

Genéricas. As específicas de uma empresa ficam no perfil local (`~/.claude/homologacao/perfil.md`).

## Ambiente

| Sintoma | Causa | Saída |
|---|---|---|
| `glab`/`gh` responde "Unauthenticated" | rodado fora do repo, aponta para o host público | rodar de dentro do repo |
| `NU1301 ... bad protocol version` no restore | feed NuGet privado falha via .NET (curl funciona) | baixar o `.nupkg` com o token (`/api/v4/projects/<id>/packages/nuget/download/...`) e `dotnet restore -s <pasta-local> -s https://api.nuget.org/v3/index.json`; depois `--no-restore` |
| todos os comandos "not found" no zsh | variável chamada `path` sobrescreve `PATH` | não usar `path`/`$path` em scripts zsh |
| `${r}:arquivo` vira outra coisa no zsh | modificador `:s` do zsh | usar `"${r}:${F}"` |
| `=====` dá "not found" no zsh | `=palavra` é expansão de comando | não começar argumento com `=` |
| lista em variável não separa no `for` do zsh | zsh não faz word splitting | `while read -r` ou `${=VAR}` |
| comando com `timeout` termina na hora | macOS não tem `timeout` | `run_in_background` + espera por loop |
| parceiro real sempre estoura o prazo | latência do notebook > prazo de produção | regime funcional com override; medição com prazo real |
| site em `next dev` recarregando sem parar | Fast Refresh full reload | `next build` + `next start` |
| browser embutido não acha a paginação | lista sob demanda / painel oculto | `window.next.router.push(... shallow)` |
| `git apply -R` removeu patch que não devia | `.diff` gerado do arquivo inteiro levava outro patch junto | reaplicar o patch base só daquele arquivo (`--include`) |
| resultado vazio "do nada" | dependência sem broker local entra em fail-closed | conferir o log antes de concluir que é defeito; se for harness, contornar e documentar |
| checkout troca de branch sozinho | IDE faz checkout/pull | usar refs explícitas e worktree temporário |
| conflito de arquivo inteiro entre branches | EOL CRLF/LF invertido | `git diff --ignore-cr-at-eol` para comparar |
| cliente ignora dado que depende de header (`Date`) atrás do proxy | `BaseHTTPRequestHandler.send_response` injeta um `Date` próprio além do repassado | usar `send_response_only` e repassar o `Date` da origem |
| `pod install` com `Encoding::CompatibilityError` | locale não UTF-8 | `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8` antes do `bundle exec pod install` |
| app RN não consulta de novo ao reabrir a tela por deep link | cache do SWR na mesma chave | `xcrun simctl terminate` + `launch` antes de cada cenário |
| teste jest com timeout de 8–10 s só na suíte cheia | máquina carregada (build em paralelo) | reexecutar isolado (`--runInBand`) antes de acusar falha |
| build distribuído não tem a feature | saiu da tag anterior ao merge | conferir o commit do build antes de testar nele |
| print da falha sumiu | o print seguinte usou o mesmo nome | nome único por captura (cenário + passo) |

## Padrões de defeito já encontrados

- **Código que só existe no destino** quebra a feature depois do merge: testar sempre a branch de merge, não só a feature.
- **Tarefas em paralelo sobre recurso com escopo** (DbContext do EF): `A second operation was started on this context instance`.
- **Chave de cache sem o dono** ("anonymous" compartilhado) entrega o resultado de um usuário para outro.
- **Falha gravada em cache** prende o usuário sem o recurso por todo o TTL.
- **Retentativa sem intervalo** multiplica a carga sobre o parceiro em erro 5xx; corte por tentativa menor que o prazo total desfaz prazos aprovados.
- **Front monta query com `${valor}`** e envia `undefined`/`null` literais; o back só trata string vazia.
- **Revisita refaz a operação** e muda o que o usuário já viu.
- **Regra de exibição por texto** ("hoje/amanhã") em vez de tipo deixa casos válidos de fora.
- **Subtarefa finalizada sem entrega**: conferir no código, não no status.
- **MR de outro ambiente desatualizada**.
- **Testes unitários com mock** não pegam concorrência nem integração com código do destino.
