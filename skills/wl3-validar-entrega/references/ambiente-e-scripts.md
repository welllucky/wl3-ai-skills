# Ambiente e scripts

Hosts, IDs de projeto, pastas de repositório e esquemas de build vêm do perfil local (`~/.claude/homologacao/perfil.md`). Os exemplos abaixo usam placeholders.

## Onde ficam os scripts

| Pasta | Conteúdo | Ciclo de vida |
|---|---|---|
| `scripts/` desta skill | versão versionada dos scripts reutilizáveis + `README.md` | acompanha a skill |
| `~/.claude/homologacao/scripts/` | cópia em uso, com os scripts que o usuário salvou + `README.md` | permanente |
| `evidencias-<card>/scripts/` | scripts e patches específicos da atividade | apagados quando a atividade é liberada |

Ordem: global → `scripts/` da skill (copie para a global se ela não existir) → local da atividade → adaptar um existente → criar novo. Ao criar, perguntar se salva também na global; se sim, atualizar o `README.md` da global.

## Back (.NET)

### Worktrees
```bash
git worktree add --detach <scratchpad>/wt-mr  origin/<branch-da-mr>
git worktree add --detach <scratchpad>/wt-base $(git merge-base origin/<destino> origin/<branch-da-mr>)
```
Para testes automatizados, worktrees limpos separados (sem patch de harness).

### Patches de harness (mínimos, sempre em `.diff`)
- Cache distribuído inacessível localmente → `services.AddDistributedMemoryCache()`.
- Chamadas a broker de mensagens sem instância local → try/catch que devolve vazio.
- Nunca alterar a lógica da feature. Contorno de defeito encontrado vai em patch **separado**, usado só em cenários funcionais e documentado no relatório.
- Ao reverter um patch com `git apply -R`, confira se o `.diff` não carregava junto outro patch do mesmo arquivo.

### Execução
- `ASPNETCORE_ENVIRONMENT=<ambiente do perfil>`, `ASPNETCORE_URLS=http://127.0.0.1:<porta>`; MR e base em portas diferentes (ex. 5081/5082).
- Overrides por variável de ambiente (`Secao__Chave`): URL do serviço de flags, URL do parceiro, prazos.
- `dotnet run --no-restore` depois de restaurar uma vez.
- Script de espera: loop com `curl` até a porta responder (macOS não tem `timeout`).

### Stubs
- **Flags (Unleash ou similar)**: servidor HTTP que devolve as flags reais (`curl -H "Authorization: <ApiKey>" <url-flags>/client/features`) e sobrescreve só as da feature a partir de `state.json`.
- **Parceiro externo**: proxy com modos lidos de `state.json` a cada chamada: `proxy` (real), `canned:<ms>` (resposta fixa após atraso), `delay:<ms>`, `slow`, `500`, `flaky:<ms>` (alterna lento/rápido). Grava cada chamada em `.jsonl` (payload, status, tempo upstream) para contar chamadas e conferir o payload enviado.

### Prazos
- **Regime funcional**: override do prazo (a rede do notebook é mais lenta que a produção).
- **Regime de medição**: prazos reais, sem override, código original.

### Cenários e coleta
- Script de percurso: chama página por página carregando o estado que o cliente carregaria (histórico, cookie, headers), grava JSON por cenário com IDs por página, contagens, duplicados, chamadas ao parceiro e payload.
- Cenários de API: `scripts/api_capture.py` (`call` + `render`) grava a chamada e gera o print no momento.

### Testes automatizados
`dotnet test <csproj> --no-restore --logger "trx;LogFileName=..."` na MR e na base; extrair `testName` com `outcome="Failed"` dos `.trx` e comparar por nome (`comm`).

## Site (Next.js)

- Worktree da branch no scratchpad; instalar dependências com o gerenciador do repo (`pnpm install --frozen-lockfile --prefer-offline`).
- Ambiente local: copiar o arquivo de variáveis local do usuário para o worktree e trocar só a URL base da API pelo proxy local.
- **Proxy de API**: o serviço testado → serviço local da MR; resto → ambiente remoto. Adiciona CORS e grava cada chamada (`User-Agent` distingue SSR `node` de cliente). Serve para contar requisições por navegação.
- **Build de produção**: `next build` + `next start -p 3000`. O modo dev pode entrar em loop de "Fast Refresh full reload" e mascarar o teste.
- Headers do SSR via `curl -D -` (Cache-Control, Set-Cookie), com e sem cookie.
- Navegação no browser embutido: quando a paginação não está renderizada (lista sob demanda, painel oculto), usar `window.next.router.push(..., { shallow: true })`. `find`/`read_page` para ler links; `get_page_text` para texto.
- Specs alteradas: `pnpm exec jest <caminhos>` dentro de cada pacote.

## App (React Native, iOS)

- Worktree da branch no scratchpad; dependências com o gerenciador do repo; `bundle exec pod install` com `LANG=en_US.UTF-8`.
- Para contar chamadas ou forçar bordas: trocar a URL base da API no arquivo de ambiente do worktree por `http://localhost:<porta-do-proxy>/` (o esquema de homologação precisa permitir `NSAllowsLocalNetworking`) e subir `scripts/qa_api_proxy.py`.
- Build: `xcodebuild -workspace ios/<App>.xcworkspace -scheme <esquema> -configuration Release -sdk iphonesimulator -destination id=<udid> -derivedDataPath <scratchpad>/dd build`.
- Ferramenta do simulador: `attach` antes do build; `launch` com o `.app`.
- A cada cenário: `scripts/sim_reopen.sh` (encerra, abre e navega por deep link) e `scripts/sim_shot.sh` (print no momento).
- Checkout compartilhado do app pode trocar de branch sozinho: conferir a branch antes de qualquer coisa.

## Remoto (dev, QAS)

- Confirmar que o deploy corresponde ao SHA da MR (versão exposta, pipeline, tag da imagem, comportamento novo) antes de testar.
- Testes só leitura em produção (classificação bug × incidente).

## Prints

- **No momento**: screenshot do browser/simulador durante o passo; para API, gravar comando + status + headers + trecho do corpo + horário e renderizar em imagem logo após a chamada. Nome único por captura.
- **Resumo** (complemento): HTML com tabela → PNG com Chrome headless:
  `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --hide-scrollbars --window-size=1150,1400 --screenshot=<png> file://<html>`
- Upload no Git host para usar a imagem em Jira e MR (GitLab: `curl -H "PRIVATE-TOKEN: <token>" -F file=@<png> https://<gitlab>/api/v4/projects/<id>/uploads` → `full_path`). Host, token e IDs no perfil.
