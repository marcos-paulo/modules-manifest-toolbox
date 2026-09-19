#!/bin/sh
# download-self-worktrees.sh — baixa modules-toolbox-self-worktrees.sh e um
# self-worktrees-manifest.txt modelo pro diretório atual (onde o comando é
# executado). Só baixa arquivos -- não instala nada no sistema (sem PATH,
# sem symlink, sem dependência).
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/marcos-paulo/modules-manifest-toolbox/main/download-self-worktrees.sh | sh
#
# POSIX sh de propósito (roda em "sh", não precisa de bash).
# Não sobrescreve um self-worktrees-manifest.txt que já exista no
# diretório -- só o modules-toolbox-self-worktrees.sh é sempre atualizado
# pra última versão.
#
# Diferente do download.sh (que baixa o modules-toolbox.sh de módulos),
# este baixa a ferramenta de worktrees do PRÓPRIO repositório -- rode a
# partir da raiz de um repositório git.

set -eu

REPO_RAW_BASE="https://raw.githubusercontent.com/marcos-paulo/modules-manifest-toolbox/main"

baixar() {
  arquivo="$1"
  destino="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$REPO_RAW_BASE/$arquivo" -o "$destino"
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$REPO_RAW_BASE/$arquivo" -O "$destino"
  else
    echo "download-self-worktrees.sh: precisa de curl ou wget instalado" >&2
    exit 1
  fi
}

echo "download-self-worktrees.sh: baixando modules-toolbox-self-worktrees.sh" >&2
baixar "modules-toolbox-self-worktrees.sh" "modules-toolbox-self-worktrees.sh"
chmod +x modules-toolbox-self-worktrees.sh

if [ -f self-worktrees-manifest.txt ]; then
  echo "download-self-worktrees.sh: self-worktrees-manifest.txt já existe aqui, não sobrescrevendo" >&2
else
  echo "download-self-worktrees.sh: baixando self-worktrees-manifest.txt (modelo)" >&2
  baixar "self-worktrees-manifest.txt" "self-worktrees-manifest.txt"
fi

echo "download-self-worktrees.sh: pronto. Edite self-worktrees-manifest.txt e rode ./modules-toolbox-self-worktrees.sh clone" >&2
