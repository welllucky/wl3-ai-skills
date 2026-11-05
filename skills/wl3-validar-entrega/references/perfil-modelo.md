# Perfil local · modelo e criação

O perfil guarda tudo que é específico de uma empresa ou time. Fica em `~/.claude/homologacao/perfil.md`, na máquina de cada usuário, e **nunca** entra no repositório da skill.

## Quando criar

Na primeira execução da skill, se o arquivo não existir. Também quando o usuário pedir ("refaça meu perfil") ou quando um dado do perfil se mostrar errado durante a homologação (atualizar só o trecho afetado, com confirmação).

## Como criar

1. **Descobrir sozinho**, sem perguntar:
   - **Git host e projetos**: `git remote -v` dos repositórios citados pelo usuário ou do diretório atual; `glab auth status` / `gh auth status` para saber qual CLI está autenticado; ID do projeto pela API (`/api/v4/projects/<namespace%2Fprojeto>` no GitLab).
   - **Jira**: MCP da Atlassian (`getAccessibleAtlassianResources`) para o cloudId; `getVisibleJiraProjects` para os projetos; `getJiraProjectIssueTypesMetadata` para os tipos de issue (procurar "Bug", "Bug (Experimental)", "Defeito", e se é subtarefa).
   - **Repositórios**: perguntar só a pasta raiz (ex. `~/Projetos/<empresa>`) e listar os repositórios com `git rev-parse` em cada subpasta; identificar a ponta pelo stack (`*.csproj`, `next.config.*`, `ios/` + `package.json`).
   - **Ambientes de API**: arquivos de ambiente dos repositórios (`.env.*`, `appsettings.*.json`, `mise*.toml`), procurando URLs base por ambiente. Não copiar segredos para o perfil, só a localização deles.
   - **Feature flags**: serviço e URL nos mesmos arquivos (Unleash, LaunchDarkly, ConfigCat...).
   - **Padrão de commit e branch**: `commitlint.config.*`, `git log --oneline -20` e `git branch -r --sort=-committerdate | head -30`.
2. **Perguntar só o que não dá para inferir**, numa única rodada: regra bug × incidente, branches protegidas, quem pode mudar status, esquema/bundle de homologação do app (se não estiver claro no projeto).
3. **Mostrar o perfil montado** e gravar só depois da confirmação.

## Modelo

```markdown
# Perfil de homologação · <empresa> (local, não versionar)

## Ferramentas
| Item | Valor |
|---|---|
| Jira | cloudId `<site>.atlassian.net`, projeto(s) `<KEY>` |
| Tipo de bug | `<nome>` (subtarefa? id), pai = história |
| Git host | `<host>`; CLI `glab`/`gh`; como obter o token |
| Upload de imagem | endpoint e ID de projeto por repositório |
| Feature flags | serviço, URL por ambiente, onde fica a chave |

## Ambientes de API
| Ambiente | Base |
|---|---|
| dev | ... |
| QAS/staging | ... |
| prd | ... (só leitura) |

## Repositórios
| Ponta | Pasta | Observação (fluxo de MR, esquema de build, deep link) |
|---|---|---|

## Regras do time
- Bug × incidente: ...
- Padrão de commit e branch: ...
- Branches protegidas: ...
- Quem pode mudar status / workflow do bug: ...

## Armadilhas da empresa
- ...
```
