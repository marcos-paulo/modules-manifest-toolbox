#!/bin/bash
# modules-toolbox.sh — clona/atualiza módulos git listados em modules-manifest.txt,
# incluindo remotos extras e worktrees declarados pra cada módulo.
#
# Uso:
#   modules-toolbox.sh clone                  # clona módulos, cria remotos e worktrees
#   modules-toolbox.sh update                 # atualiza módulos, remotos e worktrees
#   modules-toolbox.sh clone|update <nome>    # só um módulo específico (e seus remotos/worktrees)
#   modules-toolbox.sh --version|-v           # mostra a versão do script
#
# Variáveis de ambiente opcionais:
#   MODULES_MANIFEST=/caminho/modules-manifest.txt  (padrão: ao lado deste script)
#   MODULES_DIR=/caminho/onde/clonar                 (padrão: ao lado deste script)
#
# Convenção: módulos são clonados direto na raiz do projeto (mesma pasta
# deste script), em <nome>/, um por módulo. Adicione o nome de cada módulo
# ao .gitignore do host -- eles não são submódulo git nem vivem numa pasta
# única "modules/".
#
# Formato do manifest: ver modules-manifest.txt (linhas "modulo"/"remoto"/"worktree").
#
# Licença: MIT (ver LICENSE).

set -euo pipefail

MODULES_TOOLBOX_VERSION="0.1.0"

PATH_SCRIPT=$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")
MANIFEST="${MODULES_MANIFEST:-$PATH_SCRIPT/modules-manifest.txt}"
MODULES_DIR="${MODULES_DIR:-$PATH_SCRIPT}"

function log(){
  echo "[modules-toolbox] $*" >&2
}

# Imprime, por linha, os campos (sem a palavra-chave) de todas as linhas do
# tipo pedido ("modulo", "remoto" ou "worktree"), ignorando comentários e
# linhas vazias.
function linhas_do_tipo(){
  local tipo="$1"
  [ -f "$MANIFEST" ] || { log "manifest não encontrado: $MANIFEST"; exit 1; }
  grep -vE '^[[:space:]]*(#|$)' "$MANIFEST" \
    | awk -v t="$tipo" '$1==t { $1=""; sub(/^[ \t]+/,""); print }'
}

# Resolve um caminho relativo a partir da raiz do projeto (onde fica o
# manifest); caminho absoluto é devolvido como está.
function resolver_caminho(){
  local caminho="$1"
  case "$caminho" in
    /*) echo "$caminho" ;;
    *) echo "$PATH_SCRIPT/$caminho" ;;
  esac
}

# --- módulos ---------------------------------------------------------------

function clonar_modulo(){
  local nome="$1" url="$2" ref="${3:-}"
  local dir="$MODULES_DIR/$nome"
  if [ -d "$dir/.git" ]; then
    log "$nome: já clonado, pulando (use 'update' pra atualizar)"
    return 0
  fi
  log "$nome: clonando de $url"
  git clone --quiet "$url" "$dir"
  if [ -n "$ref" ]; then
    log "$nome: checkout $ref"
    git -C "$dir" checkout --quiet "$ref"
  fi
}

function atualizar_modulo(){
  local nome="$1" url="$2" ref="${3:-}"
  local dir="$MODULES_DIR/$nome"
  if [ ! -d "$dir/.git" ]; then
    log "$nome: não está clonado ainda, use 'clone' primeiro"
    return 0
  fi
  log "$nome: atualizando"
  git -C "$dir" fetch --quiet origin
  local alvo_ref="$ref"
  if [ -z "$alvo_ref" ]; then
    alvo_ref=$(git -C "$dir" remote show origin | awk '/HEAD branch/ {print $NF}')
  fi
  git -C "$dir" checkout --quiet "$alvo_ref"
  git -C "$dir" pull --quiet origin "$alvo_ref" 2>/dev/null || true
}

# --- remotos extras ---------------------------------------------------------

function aplicar_remoto(){
  local modulo="$1" nome_remoto="$2" url="$3"
  local dir="$MODULES_DIR/$modulo"
  if [ ! -d "$dir/.git" ]; then
    log "$modulo: não está clonado ainda, pulando remoto '$nome_remoto'"
    return 0
  fi
  if git -C "$dir" remote get-url "$nome_remoto" &>/dev/null; then
    local url_atual
    url_atual=$(git -C "$dir" remote get-url "$nome_remoto")
    if [ "$url_atual" != "$url" ]; then
      log "$modulo: atualizando url do remoto '$nome_remoto'"
      git -C "$dir" remote set-url "$nome_remoto" "$url"
    fi
  else
    log "$modulo: adicionando remoto '$nome_remoto' ($url)"
    git -C "$dir" remote add "$nome_remoto" "$url"
  fi
}

function atualizar_remoto(){
  local modulo="$1" nome_remoto="$2" url="$3"
  aplicar_remoto "$modulo" "$nome_remoto" "$url"
  local dir="$MODULES_DIR/$modulo"
  [ -d "$dir/.git" ] || return 0
  log "$modulo: fetch do remoto '$nome_remoto'"
  git -C "$dir" fetch --quiet "$nome_remoto"
}

# --- worktrees ---------------------------------------------------------------

function criar_worktree(){
  local modulo="$1" pasta="$2" ref="$3"
  local dir="$MODULES_DIR/$modulo"
  local pasta_resolvida
  pasta_resolvida=$(resolver_caminho "$pasta")
  if [ ! -d "$dir/.git" ]; then
    log "$modulo: não está clonado ainda, pulando worktree '$pasta'"
    return 0
  fi
  if [ -e "$pasta_resolvida" ]; then
    log "$modulo: worktree já existe em '$pasta_resolvida', pulando (use 'update')"
    return 0
  fi
  log "$modulo: criando worktree em '$pasta_resolvida' (ref: $ref)"
  git -C "$dir" worktree add --quiet "$pasta_resolvida" "$ref"
}

function atualizar_worktree(){
  local modulo="$1" pasta="$2" ref="$3"
  local dir="$MODULES_DIR/$modulo"
  local pasta_resolvida
  pasta_resolvida=$(resolver_caminho "$pasta")
  if [ ! -e "$pasta_resolvida/.git" ]; then
    log "$modulo: worktree '$pasta' não existe ainda, use 'clone' primeiro"
    return 0
  fi
  log "$modulo: atualizando worktree em '$pasta_resolvida'"
  git -C "$dir" fetch --quiet origin
  git -C "$pasta_resolvida" checkout --quiet "$ref"
  git -C "$pasta_resolvida" pull --quiet origin "$ref" 2>/dev/null || true
}

# --- laço principal ----------------------------------------------------------

function main(){
  local comando="${1:-}"
  local alvo="${2:-}"

  case "$comando" in
    --version|-v)
      echo "modules-toolbox.sh $MODULES_TOOLBOX_VERSION"
      exit 0
      ;;
    clone|update) ;;
    *)
      echo "Uso: $(basename "$0") clone|update [nome-do-modulo]" >&2
      echo "     $(basename "$0") --version" >&2
      exit 1
      ;;
  esac

  mkdir -p "$MODULES_DIR"

  local encontrou_alvo=0

  while read -r nome url ref; do
    if [ -n "$alvo" ] && [ "$nome" != "$alvo" ]; then
      continue
    fi
    encontrou_alvo=1
    if [ "$comando" = "clone" ]; then
      clonar_modulo "$nome" "$url" "$ref"
    else
      atualizar_modulo "$nome" "$url" "$ref"
    fi
  done < <(linhas_do_tipo modulo)

  while read -r modulo nome_remoto url; do
    [ -n "$alvo" ] && [ "$modulo" != "$alvo" ] && continue
    if [ "$comando" = "clone" ]; then
      aplicar_remoto "$modulo" "$nome_remoto" "$url"
    else
      atualizar_remoto "$modulo" "$nome_remoto" "$url"
    fi
  done < <(linhas_do_tipo remoto)

  while read -r modulo pasta ref; do
    [ -n "$alvo" ] && [ "$modulo" != "$alvo" ] && continue
    if [ "$comando" = "clone" ]; then
      criar_worktree "$modulo" "$pasta" "$ref"
    else
      atualizar_worktree "$modulo" "$pasta" "$ref"
    fi
  done < <(linhas_do_tipo worktree)

  if [ -n "$alvo" ] && [ "$encontrou_alvo" -eq 0 ]; then
    log "módulo '$alvo' não encontrado no manifest"
    exit 1
  fi
}

main "$@"
