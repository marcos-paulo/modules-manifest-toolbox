#!/bin/bash
# modules-toolbox-self-worktrees.sh — cria/atualiza worktrees do PRÓPRIO
# repositório onde este script mora (não de um módulo clonado à parte).
#
# Diferente do modules-toolbox.sh (que clona módulos externos e pode criar
# worktrees deles), este script não clona nada: a pasta onde ele está
# precisa já ser a raiz de um repositório git, e cada worktree listado no
# manifest nasce como pasta FILHA dessa raiz, irmã das outras -- nunca um
# dentro do outro.
#
# Uso:
#   modules-toolbox-self-worktrees.sh clone                # cria os worktrees que faltam
#   modules-toolbox-self-worktrees.sh update                # atualiza os worktrees existentes
#   modules-toolbox-self-worktrees.sh clone|update <pasta>  # só um worktree específico
#   modules-toolbox-self-worktrees.sh --version|-v          # mostra a versão do script
#
# Variáveis de ambiente opcionais:
#   SELF_WORKTREES_MANIFEST=/caminho/self-worktrees-manifest.txt  (padrão: ao lado deste script)
#
# Formato do manifest: ver self-worktrees-manifest.txt (linha "worktree").
#
# Licença: MIT (ver LICENSE).

set -euo pipefail

MODULES_TOOLBOX_VERSION="0.1.0"

PATH_SCRIPT=$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")
MANIFEST="${SELF_WORKTREES_MANIFEST:-$PATH_SCRIPT/self-worktrees-manifest.txt}"

function log(){
  echo "[modules-toolbox-self-worktrees] $*" >&2
}

# Imprime, por linha, os campos (sem a palavra-chave "worktree") de todas
# as linhas desse tipo, ignorando comentários e linhas vazias.
function linhas_worktree(){
  [ -f "$MANIFEST" ] || { log "manifest não encontrado: $MANIFEST"; exit 1; }
  grep -vE '^[[:space:]]*(#|$)' "$MANIFEST" \
    | awk '$1=="worktree" { $1=""; sub(/^[ \t]+/,""); print }'
}

# Resolve um caminho relativo a partir da raiz do repositório (onde fica
# este script); caminho absoluto é devolvido como está.
function resolver_caminho(){
  local caminho="$1"
  case "$caminho" in
    /*) echo "$caminho" ;;
    *) echo "$PATH_SCRIPT/$caminho" ;;
  esac
}

function checar_repositorio(){
  if ! git -C "$PATH_SCRIPT" rev-parse --is-inside-work-tree &>/dev/null; then
    log "$PATH_SCRIPT não é um repositório git -- este script cria worktrees do próprio repo, não clona nada"
    exit 1
  fi
}

# --- worktrees ---------------------------------------------------------------

function criar_worktree(){
  local pasta="$1" ref="$2"
  local pasta_resolvida
  pasta_resolvida=$(resolver_caminho "$pasta")
  if [ -e "$pasta_resolvida" ]; then
    log "worktree já existe em '$pasta_resolvida', pulando (use 'update')"
    return 0
  fi
  log "criando worktree em '$pasta_resolvida' (ref: $ref)"
  if ! git -C "$PATH_SCRIPT" worktree add --quiet "$pasta_resolvida" "$ref"; then
    log "falha ao criar worktree em '$pasta_resolvida' (ref '$ref' já em uso em outro worktree?), pulando"
    return 0
  fi
}

function atualizar_worktree(){
  local pasta="$1" ref="$2"
  local pasta_resolvida
  pasta_resolvida=$(resolver_caminho "$pasta")
  if [ ! -e "$pasta_resolvida/.git" ]; then
    log "worktree '$pasta' não existe ainda, use 'clone' primeiro"
    return 0
  fi
  log "atualizando worktree em '$pasta_resolvida'"
  if ! git -C "$PATH_SCRIPT" fetch --quiet origin; then
    log "falha no fetch pro worktree '$pasta_resolvida', pulando"
    return 0
  fi
  if ! git -C "$pasta_resolvida" checkout --quiet "$ref"; then
    log "falha ao mudar worktree '$pasta_resolvida' pra ref '$ref' (ref já em uso em outro worktree?), pulando"
    return 0
  fi
  git -C "$pasta_resolvida" pull --quiet origin "$ref" 2>/dev/null || true
}

# --- laço principal ----------------------------------------------------------

function main(){
  local comando="${1:-}"
  local alvo="${2:-}"

  case "$comando" in
    --version|-v)
      echo "modules-toolbox-self-worktrees.sh $MODULES_TOOLBOX_VERSION"
      exit 0
      ;;
    clone|update) ;;
    *)
      echo "Uso: $(basename "$0") clone|update [pasta-do-worktree]" >&2
      echo "     $(basename "$0") --version" >&2
      exit 1
      ;;
  esac

  checar_repositorio

  local encontrou_alvo=0

  while read -r pasta ref; do
    if [ -n "$alvo" ] && [ "$pasta" != "$alvo" ]; then
      continue
    fi
    encontrou_alvo=1
    if [ "$comando" = "clone" ]; then
      criar_worktree "$pasta" "$ref"
    else
      atualizar_worktree "$pasta" "$ref"
    fi
  done < <(linhas_worktree)

  if [ -n "$alvo" ] && [ "$encontrou_alvo" -eq 0 ]; then
    log "worktree '$alvo' não encontrado no manifest"
    exit 1
  fi
}

main "$@"
