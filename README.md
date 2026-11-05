# wl3-ai-skills

Coleção de skills para o [Claude Code](https://docs.claude.com/en/docs/claude-code).

Uma skill é uma pasta com um `SKILL.md` (instruções e quando usar), referências de apoio e, se precisar, scripts. O Claude Code carrega a skill quando o pedido combina com a descrição dela, ou quando você a chama pelo nome. As skills daqui nasceram de trabalho real e são escritas para serem reaproveitadas em qualquer time: nada específico de empresa fica no repositório.

## Skills disponíveis

| Skill | O que faz | Quando usar |
|---|---|---|
| [`wl3-validar-entrega`](skills/wl3-validar-entrega/SKILL.md) | Homologa uma entrega ponta a ponta (back, BFF, site, app): lê o fluxo completo, monta o ambiente, executa a matriz de cenários com print no momento de cada teste, compara com a base, gera relatório e, com a sua aprovação, abre bugs, comenta e move status no Jira e no GitLab/GitHub. | "homologue a ECUX-123", "teste as MRs !10 e !11", "houve ajustes, teste de novo" |

## Estrutura

```text
install.sh          instalador das skills nos agentes
skills/
  <nome-da-skill>/
    SKILL.md        instruções, regras e etapas
    references/     material lido sob demanda pela skill
    scripts/        scripts reutilizáveis usados pela skill
```

## Instalação

1. Clone o repositório:

   ```bash
   git clone https://github.com/welllucky/wl3-ai-skills.git
   cd wl3-ai-skills
   ```

2. Rode o instalador e escolha as skills e os agentes no seletor:

   ```bash
   ./install.sh
   ```

   Ele cria um link simbólico de cada skill escolhida na pasta de skills de cada agente escolhido. Os agentes encontrados na máquina já vêm marcados.

3. Abra uma nova sessão do agente. A skill aparece na lista de skills disponíveis.

Para atualizar: `git pull` dentro do repositório (os links acompanham o repositório).

### Agentes suportados

| Id | Agente | Pasta padrão | Variável para trocar a pasta |
|---|---|---|---|
| `claude` | Claude Code | `~/.claude/skills` | `SKILLS_DIR_CLAUDE` |
| `codex` | OpenAI Codex | `~/.codex/skills` | `SKILLS_DIR_CODEX` |
| `agents` | Pasta compartilhada entre agentes | `~/.agents/skills` | `SKILLS_DIR_AGENTS` |
| `gemini` | Gemini CLI | `~/.gemini/skills` | `SKILLS_DIR_GEMINI` |
| `cursor` | Cursor | `~/.cursor/skills` | `SKILLS_DIR_CURSOR` |
| `copilot` | GitHub Copilot | `~/.copilot/skills` | `SKILLS_DIR_COPILOT` |
| `opencode` | OpenCode | `~/.config/opencode/skills` | `SKILLS_DIR_OPENCODE` |

As pastas variam entre versões dos agentes. Se a sua for outra, use a variável: `SKILLS_DIR_CODEX=~/.agents/skills ./install.sh`.

### Opções do instalador

| Opção | Efeito |
|---|---|
| `-s, --skills a,b` | skills a instalar (`all` = todas); sem a opção, abre o seletor |
| `-p, --providers x,y` | agentes (`all` = todos, `detected` = os encontrados na máquina); sem a opção, abre o seletor |
| `-u, --uninstall` | remove os links e as cópias feitos por este repositório (o resto fica) |
| `-c, --copy` | copia em vez de criar link |
| `-f, --force` | substitui o que já existe no destino; pasta real vira backup `.bak-<data>` |
| `-n, --dry-run` | mostra o que faria, sem alterar nada |
| `-y, --yes` | não pede confirmação |
| `-l, --list` | lista skills, agentes e o estado de cada instalação |

Exemplos:

```bash
./install.sh -s all -p detected -y          # todas as skills nos agentes encontrados
./install.sh -s wl3-validar-entrega -p claude,codex
./install.sh -l                             # o que está instalado onde
./install.sh -u -s all -p all -y            # desinstala tudo
```

No seletor: digite números ou faixas para marcar e desmarcar (`1 3 5-7`), `a` para todos, `n` para nenhum, Enter para confirmar e `q` para sair. Em ambiente sem terminal interativo (CI, scripts), informe `--skills` e `--providers`.

## Como usar

### Chamando a skill

- Pelo nome: `/wl3-validar-entrega ECUX-123` ou `/wl3-validar-entrega !1662 !570`.
- Em linguagem natural: "homologue a ECUX-123 em QAS", "teste de novo a MR !1662, o dev ajustou". O Claude Code reconhece o pedido pela descrição da skill.

### O que acontece numa homologação (`wl3-validar-entrega`)

1. **Entrada:** você informa o card ou as MRs. A skill pergunta em qual ambiente testar (local, dev, QAS/staging, sandbox) e confere se os repositórios estão clonados.
2. **Leitura:** lê os critérios do card, os comentários e o código do fluxo completo, e transforma cada afirmação do dev em um cenário que pode ser medido.
3. **Ambiente e matriz:** monta o ambiente, propõe a matriz de cenários e mostra antes de executar.
4. **Execução:** roda os cenários e tira o print no momento de cada passo, de sucesso ou de falha.
5. **Relatório:** grava o relatório em `evidencias-<card>/reteste-<data>/`, com cenários, prints e testes automatizados comparados com a base.
6. **Comunicação:** mostra o veredito e os bugs propostos e **só então**, com o seu ok, abre bugs, comenta no Jira e nas MRs e move status.

### Primeira execução: perfil local

Hosts, IDs de projeto, Jira, tipos de issue e regras do time ficam num perfil na sua máquina, `~/.claude/homologacao/perfil.md`, e nunca neste repositório.

Na primeira execução, a skill cria esse perfil:

- **Descobre sozinha** o Git host, os projetos, o Jira, os tipos de issue, os repositórios, as URLs de ambiente e o padrão de commit, pelos repositórios, CLIs e MCPs disponíveis.
- **Pergunta só o resto**, numa única rodada (regra bug × incidente, branches protegidas, quem muda status).
- **Grava depois da sua confirmação.**

O modelo está em [`references/perfil-modelo.md`](skills/wl3-validar-entrega/references/perfil-modelo.md).

### Scripts

Os scripts da skill ficam em [`skills/wl3-validar-entrega/scripts/`](skills/wl3-validar-entrega/scripts/README.md). Na primeira vez em que forem necessários, são copiados para `~/.claude/homologacao/scripts/`, onde ficam os scripts reutilizáveis da sua máquina.

| Script | Para que serve |
|---|---|
| `qa_api_proxy.py` | Proxy entre o cliente e a API: registra cada chamada e, por regra, reescreve campos, desloca `Date`/`Age` ou injeta falha |
| `api_capture.py` | Faz a chamada de API e gera o print dela no momento |
| `sim_shot.sh` | Screenshot do simulador iOS |
| `sim_reopen.sh` | Reabre o app no simulador e navega por deep link |

## Requisitos

| Necessário para | Ferramenta |
|---|---|
| Todas as skills | Claude Code |
| Jira | MCP da Atlassian conectado ao Claude Code |
| GitLab / GitHub | `glab` / `gh` autenticados |
| Prints de API e relatórios | Python 3 e Google Chrome (modo headless) |
| Back .NET local | .NET SDK da versão do projeto |
| Site | Node e o gerenciador de pacotes do projeto |
| App iOS | macOS, Xcode com simulador, CocoaPods |

As ferramentas que faltarem só limitam a parte da homologação que depende delas; a skill avisa quando algo não puder ser testado.

## Contribuindo

- Uma skill por pasta em `skills/`, com `SKILL.md` contendo `name` e `description` no frontmatter.
- Nada específico de empresa (hosts, IDs, cards, nomes de pessoas, segredos): isso vai para o perfil local de quem usa.
- Aprendizado que vale para qualquer time entra nas referências da skill (ex. `references/armadilhas.md`).
- Commits no padrão `tipo(escopo): descrição` em português.
