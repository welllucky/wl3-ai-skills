# wl3-ai-skills

Skills para o Claude Code.

## Skills

| Skill | O que faz |
|---|---|
| [`wl3-validar-entrega`](skills/wl3-validar-entrega/SKILL.md) | Homologa uma entrega ponta a ponta (back, BFF, site, app) a partir de um card do Jira ou de MRs/PRs: lê o fluxo completo, monta o ambiente, executa a matriz de cenários com prints no momento do teste, compara com a base, gera relatório e, com aprovação, abre bugs e comenta no Jira e no Git host. |

## Instalação

Crie um link simbólico (ou copie) a pasta da skill em `~/.claude/skills/`:

```bash
ln -s "$(pwd)/skills/wl3-validar-entrega" ~/.claude/skills/wl3-validar-entrega
```

## Perfil local

Dados específicos de empresa (hosts, IDs de projeto, Jira, regras do time) **não** ficam neste repositório. Na primeira execução, a `wl3-validar-entrega` cria `~/.claude/homologacao/perfil.md` na máquina do usuário, descobrindo o que der pelos repositórios, CLIs e MCPs disponíveis e perguntando o resto. Modelo em [`references/perfil-modelo.md`](skills/wl3-validar-entrega/references/perfil-modelo.md).
