#!/usr/bin/env bash
#
# Instala as skills deste repositório nos agentes de IA (Claude Code, Codex,
# Gemini CLI, Cursor, Copilot, OpenCode e a pasta compartilhada ~/.agents),
# criando links simbólicos para as pastas em skills/.
#
# Uso: ./install.sh [opções]      (sem opções: seletor interativo)
#
#   -s, --skills a,b      skills a instalar (padrão: seletor; "all" = todas)
#   -p, --providers x,y   provedores (padrão: seletor; "all" = todos;
#                         "detected" = só os encontrados nesta máquina)
#   -u, --uninstall       remove os links que apontam para este repositório
#   -c, --copy            copia em vez de criar link simbólico
#   -f, --force           substitui o que já existe no destino (pasta real vira backup)
#   -y, --yes             não pede confirmação
#   -n, --dry-run         mostra o que faria, sem alterar nada
#   -l, --list            lista skills, provedores e o estado de cada instalação
#   -h, --help            esta ajuda
#
# Pasta de cada provedor pode ser trocada por variável de ambiente:
#   SKILLS_DIR_CLAUDE, SKILLS_DIR_CODEX, SKILLS_DIR_AGENTS, SKILLS_DIR_GEMINI,
#   SKILLS_DIR_CURSOR, SKILLS_DIR_COPILOT, SKILLS_DIR_OPENCODE
#
# Exemplos:
#   ./install.sh
#   ./install.sh -s all -p claude,codex -y
#   ./install.sh -s wl3-validar-entrega -p detected
#   ./install.sh -u -p all -y

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$REPO_DIR/skills"
COPY_MARK=".instalado-por-wl3-ai-skills"

PROVIDER_IDS=(claude codex agents gemini cursor copilot opencode)
PROVIDER_NAMES=("Claude Code" "OpenAI Codex" "Pasta compartilhada (.agents)" "Gemini CLI" "Cursor" "GitHub Copilot" "OpenCode")
PROVIDER_DEFAULTS=(
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.agents/skills"
  "$HOME/.gemini/skills"
  "$HOME/.cursor/skills"
  "$HOME/.copilot/skills"
  "$HOME/.config/opencode/skills"
)

if [ -t 1 ]; then
  B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; D=$'\033[2m'; N=$'\033[0m'
else
  B=""; G=""; Y=""; R=""; D=""; N=""
fi

info() { printf '%s\n' "$*"; }
ok()   { if [ "${DRY_RUN:-0}" = 1 ]; then printf '%s~%s %s (simulado)\n' "$D" "$N" "$*"; else printf '%s✓%s %s\n' "$G" "$N" "$*"; fi; }
warn() { printf '%s!%s %s\n' "$Y" "$N" "$*" >&2; }
die()  { printf '%s✗%s %s\n' "$R" "$N" "$*" >&2; exit 1; }

pretty() { local h="$HOME"; case "$1" in "$h"/*) printf '~%s' "${1#"$h"}" ;; *) printf '%s' "$1" ;; esac; }

usage() { sed -n '2,/^$/p' "$0" | sed -E 's/^# ?//'; exit 0; }

provider_dir() {
  local i=$1 id var
  id=${PROVIDER_IDS[$i]}
  var="SKILLS_DIR_$(printf '%s' "$id" | tr '[:lower:]' '[:upper:]')"
  printf '%s' "${!var:-${PROVIDER_DEFAULTS[$i]}}"
}

provider_detected() {
  local dir parent
  dir=$(provider_dir "$1")
  parent=$(dirname "$dir")
  [ -d "$dir" ] || [ -d "$parent" ]
}

provider_index() {
  local i
  for i in "${!PROVIDER_IDS[@]}"; do
    [ "${PROVIDER_IDS[$i]}" = "$1" ] && { printf '%s' "$i"; return 0; }
  done
  return 1
}

load_skills() {
  SKILL_NAMES=()
  SKILL_DESCS=()
  local d name desc
  for d in "$SKILLS_SRC"/*/; do
    [ -f "$d/SKILL.md" ] || continue
    name=$(basename "$d")
    desc=$(awk '/^---$/{n++; next} n==1 && /^description:/{sub(/^description:[ ]*/, ""); print; exit}' "$d/SKILL.md")
    SKILL_NAMES+=("$name")
    SKILL_DESCS+=("${desc:0:90}")
  done
  [ "${#SKILL_NAMES[@]}" -gt 0 ] || die "nenhuma skill encontrada em $SKILLS_SRC"
}

skill_index() {
  local i
  for i in "${!SKILL_NAMES[@]}"; do
    [ "${SKILL_NAMES[$i]}" = "$1" ] && { printf '%s' "$i"; return 0; }
  done
  return 1
}

status_of() {
  local src=$1 dst=$2 target
  if [ -L "$dst" ]; then
    target=$(readlink "$dst")
    [ "$target" = "$src" ] && { printf 'link'; return; }
    [ -e "$dst" ] && printf 'outro-link' || printf 'link-quebrado'
  elif [ -d "$dst" ] && [ -f "$dst/$COPY_MARK" ] && [ "$(cat "$dst/$COPY_MARK")" = "$src" ]; then
    printf 'copia'
  elif [ -d "$dst" ]; then
    printf 'pasta'
  else
    printf 'ausente'
  fi
}

# Seletor interativo: recebe o título e as linhas; usa/atualiza o array SEL (0/1).
select_items() {
  local title=$1; shift
  local items=("$@") i input tok a b k
  while true; do
    printf '\n%s%s%s\n' "$B" "$title" "$N"
    for i in "${!items[@]}"; do
      if [ "${SEL[$i]}" = 1 ]; then mark="${G}[x]${N}"; else mark="[ ]"; fi
      printf '  %s %2d) %s\n' "$mark" "$((i + 1))" "${items[$i]}"
    done
    printf '%sNúmeros ou faixas para marcar/desmarcar (ex.: 1 3 5-7), a = todos, n = nenhum, Enter = confirmar, q = sair%s\n> ' "$D" "$N"
    IFS= read -r input || exit 1
    case "$input" in
      "") break ;;
      q|Q) info "Cancelado."; exit 0 ;;
      a|A) for i in "${!items[@]}"; do SEL[$i]=1; done ;;
      n|N) for i in "${!items[@]}"; do SEL[$i]=0; done ;;
      *)
        for tok in $input; do
          if [[ $tok =~ ^([0-9]+)-([0-9]+)$ ]]; then
            a=${BASH_REMATCH[1]}; b=${BASH_REMATCH[2]}
          elif [[ $tok =~ ^[0-9]+$ ]]; then
            a=$tok; b=$tok
          else
            warn "ignorado: $tok"; continue
          fi
          for ((k = a; k <= b; k++)); do
            i=$((k - 1))
            if [ "$i" -ge 0 ] && [ "$i" -lt "${#items[@]}" ]; then
              if [ "${SEL[$i]}" = 1 ]; then SEL[$i]=0; else SEL[$i]=1; fi
            else
              warn "fora da lista: $k"
            fi
          done
        done
        ;;
    esac
  done
}

list_state() {
  local s p src dst
  printf '%sSkills em %s%s\n' "$B" "$SKILLS_SRC" "$N"
  for s in "${!SKILL_NAMES[@]}"; do
    printf '  - %s %s%s%s\n' "${SKILL_NAMES[$s]}" "$D" "${SKILL_DESCS[$s]}" "$N"
  done
  printf '\n%sProvedores%s\n' "$B" "$N"
  for p in "${!PROVIDER_IDS[@]}"; do
    if provider_detected "$p"; then det="${G}detectado${N}"; else det="${D}não encontrado${N}"; fi
    printf '  - %-9s %-30s %s  %s\n' "${PROVIDER_IDS[$p]}" "${PROVIDER_NAMES[$p]}" "$(pretty "$(provider_dir "$p")")" "$det"
    for s in "${!SKILL_NAMES[@]}"; do
      src="$SKILLS_SRC/${SKILL_NAMES[$s]}"
      dst="$(provider_dir "$p")/${SKILL_NAMES[$s]}"
      printf '      %-28s %s\n' "${SKILL_NAMES[$s]}" "$(status_of "$src" "$dst")"
    done
  done
  exit 0
}

run() {
  if [ "$DRY_RUN" = 1 ]; then printf '%s[dry-run]%s %s\n' "$D" "$N" "$*"; else "$@"; fi
}

install_one() {
  local src=$1 dst=$2 st backup
  st=$(status_of "$src" "$dst")
  case "$st" in
    link)
      if [ "$MODE" = copy ]; then
        run rm "$dst"
      else
        ok "já instalada: $(pretty "$dst")"; COUNT_SKIP=$((COUNT_SKIP + 1)); return
      fi
      ;;
    outro-link|link-quebrado)
      if [ "$FORCE" = 1 ]; then
        run rm "$dst"
      else
        warn "pulado (já existe outro link): $dst → $(readlink "$dst"). Use --force para substituir."
        COUNT_SKIP=$((COUNT_SKIP + 1)); return
      fi
      ;;
    copia)
      run rm -rf "$dst"
      ;;
    pasta)
      if [ "$FORCE" = 1 ]; then
        backup="$dst.bak-$(date +%Y%m%d%H%M%S)"
        run mv "$dst" "$backup"
        warn "pasta existente movida para $backup"
      else
        warn "pulado (já existe uma pasta): $dst. Use --force para fazer backup e substituir."
        COUNT_SKIP=$((COUNT_SKIP + 1)); return
      fi
      ;;
  esac
  run mkdir -p "$(dirname "$dst")"
  if [ "$MODE" = copy ]; then
    run cp -R "$src" "$dst"
    if [ "$DRY_RUN" != 1 ]; then printf '%s\n' "$src" > "$dst/$COPY_MARK"; fi
    ok "copiada: $(pretty "$dst")"
  else
    run ln -s "$src" "$dst"
    ok "link criado: $(pretty "$dst") → $(pretty "$src")"
  fi
  COUNT_DONE=$((COUNT_DONE + 1))
}

uninstall_one() {
  local src=$1 dst=$2
  local st
  st=$(status_of "$src" "$dst")
  if [ "$st" = link ]; then
    run rm "$dst"
    ok "removida: $(pretty "$dst")"
    COUNT_DONE=$((COUNT_DONE + 1))
  elif [ "$st" = copia ]; then
    run rm -rf "$dst"
    ok "cópia removida: $(pretty "$dst")"
    COUNT_DONE=$((COUNT_DONE + 1))
  elif [ -e "$dst" ] || [ -L "$dst" ]; then
    warn "mantida (não é um link para este repositório): $dst"
    COUNT_SKIP=$((COUNT_SKIP + 1))
  fi
}

SKILLS_ARG=""; PROVIDERS_ARG=""; ACTION=install; MODE=link; FORCE=0; YES=0; DRY_RUN=0; LIST=0
while [ $# -gt 0 ]; do
  case "$1" in
    -s|--skills) SKILLS_ARG=${2:-}; shift 2 ;;
    -p|--providers) PROVIDERS_ARG=${2:-}; shift 2 ;;
    -u|--uninstall) ACTION=uninstall; shift ;;
    -c|--copy) MODE=copy; shift ;;
    -f|--force) FORCE=1; shift ;;
    -y|--yes) YES=1; shift ;;
    -n|--dry-run) DRY_RUN=1; shift ;;
    -l|--list) LIST=1; shift ;;
    -h|--help) usage ;;
    *) die "opção desconhecida: $1 (veja --help)" ;;
  esac
done

load_skills
[ "$LIST" = 1 ] && list_state

INTERACTIVE=0
if [ -z "$SKILLS_ARG" ] || [ -z "$PROVIDERS_ARG" ]; then
  [ -t 0 ] || die "sem terminal interativo: informe --skills e --providers"
  INTERACTIVE=1
fi

SEL_SKILLS=()
if [ -n "$SKILLS_ARG" ]; then
  for i in "${!SKILL_NAMES[@]}"; do SEL_SKILLS[$i]=0; done
  if [ "$SKILLS_ARG" = all ]; then
    for i in "${!SKILL_NAMES[@]}"; do SEL_SKILLS[$i]=1; done
  else
    IFS=',' read -r -a wanted <<< "$SKILLS_ARG"
    for w in "${wanted[@]}"; do
      i=$(skill_index "$w") || die "skill desconhecida: $w (veja --list)"
      SEL_SKILLS[$i]=1
    done
  fi
else
  SEL=()
  for i in "${!SKILL_NAMES[@]}"; do SEL[$i]=1; done
  lines=()
  for i in "${!SKILL_NAMES[@]}"; do lines+=("${SKILL_NAMES[$i]} ${D}${SKILL_DESCS[$i]}${N}"); done
  if [ "$ACTION" = install ]; then title="Quais skills instalar?"; else title="Quais skills remover?"; fi
  select_items "$title" "${lines[@]}"
  SEL_SKILLS=("${SEL[@]}")
fi

SEL_PROVIDERS=()
if [ -n "$PROVIDERS_ARG" ]; then
  for i in "${!PROVIDER_IDS[@]}"; do SEL_PROVIDERS[$i]=0; done
  case "$PROVIDERS_ARG" in
    all) for i in "${!PROVIDER_IDS[@]}"; do SEL_PROVIDERS[$i]=1; done ;;
    detected) for i in "${!PROVIDER_IDS[@]}"; do provider_detected "$i" && SEL_PROVIDERS[$i]=1; done ;;
    *)
      IFS=',' read -r -a wanted <<< "$PROVIDERS_ARG"
      for w in "${wanted[@]}"; do
        i=$(provider_index "$w") || die "provedor desconhecido: $w (opções: ${PROVIDER_IDS[*]})"
        SEL_PROVIDERS[$i]=1
      done
      ;;
  esac
else
  SEL=()
  lines=()
  for i in "${!PROVIDER_IDS[@]}"; do
    if provider_detected "$i"; then SEL[$i]=1; det="${G}detectado${N}"; else SEL[$i]=0; det="${D}não encontrado${N}"; fi
    lines+=("$(printf '%-30s %-32s %s' "${PROVIDER_NAMES[$i]}" "$(pretty "$(provider_dir "$i")")" "$det")")
  done
  select_items "Em quais provedores?" "${lines[@]}"
  SEL_PROVIDERS=("${SEL[@]}")
fi

chosen_skills=(); chosen_providers=()
for i in "${!SKILL_NAMES[@]}"; do [ "${SEL_SKILLS[$i]}" = 1 ] && chosen_skills+=("$i"); done
for i in "${!PROVIDER_IDS[@]}"; do [ "${SEL_PROVIDERS[$i]}" = 1 ] && chosen_providers+=("$i"); done
[ "${#chosen_skills[@]}" -gt 0 ] || die "nenhuma skill selecionada"
[ "${#chosen_providers[@]}" -gt 0 ] || die "nenhum provedor selecionado"

printf '\n%sResumo%s\n' "$B" "$N"
if [ "$ACTION" = install ]; then
  if [ "$MODE" = copy ]; then verb="copiar"; else verb="criar link simbólico de"; fi
else
  verb="remover"
fi
info "  Ação: $verb"
info "  Skills: $(for i in "${chosen_skills[@]}"; do printf '%s ' "${SKILL_NAMES[$i]}"; done)"
for p in "${chosen_providers[@]}"; do info "  → ${PROVIDER_NAMES[$p]}: $(pretty "$(provider_dir "$p")")"; done
[ "$FORCE" = 1 ] && info "  --force: substitui links e faz backup de pastas existentes"
[ "$DRY_RUN" = 1 ] && info "  --dry-run: nada será alterado"

if [ "$YES" != 1 ] && [ "$INTERACTIVE" = 1 -o -t 0 ]; then
  printf 'Confirmar? [S/n] '
  IFS= read -r answer || exit 1
  case "$answer" in ""|s|S|y|Y) ;; *) info "Cancelado."; exit 0 ;; esac
fi

COUNT_DONE=0; COUNT_SKIP=0
echo
for p in "${chosen_providers[@]}"; do
  base=$(provider_dir "$p")
  printf '%s%s%s\n' "$B" "${PROVIDER_NAMES[$p]}" "$N"
  for s in "${chosen_skills[@]}"; do
    src="$SKILLS_SRC/${SKILL_NAMES[$s]}"
    dst="$base/${SKILL_NAMES[$s]}"
    if [ "$ACTION" = install ]; then install_one "$src" "$dst"; else uninstall_one "$src" "$dst"; fi
  done
done

echo
if [ "$ACTION" = install ]; then
  info "Concluído: $COUNT_DONE instalada(s), $COUNT_SKIP já existente(s) ou pulada(s)."
  [ "$MODE" = link ] && info "Os links acompanham o repositório: para atualizar, rode git pull em $REPO_DIR."
  info "Abra uma nova sessão do agente para ele carregar as skills."
else
  info "Concluído: $COUNT_DONE removida(s), $COUNT_SKIP mantida(s)."
fi
