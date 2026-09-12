#!/bin/sh
# install.sh — baixa modules-toolbox.sh e um modules-manifest.txt modelo pro
# diretório atual (onde o comando é executado).
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/marcos-paulo/modules-manifest-toolbox/main/install.sh | sh
#
# POSIX sh de propósito (roda em "sh", não precisa de bash).
# Não sobrescreve um modules-manifest.txt que já exista no diretório --
# só o modules-toolbox.sh é sempre atualizado pra última versão.

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
    echo "install.sh: precisa de curl ou wget instalado" >&2
    exit 1
  fi
}

echo "install.sh: baixando modules-toolbox.sh" >&2
baixar "modules-toolbox.sh" "modules-toolbox.sh"
chmod +x modules-toolbox.sh

if [ -f modules-manifest.txt ]; then
  echo "install.sh: modules-manifest.txt já existe aqui, não sobrescrevendo" >&2
else
  echo "install.sh: baixando modules-manifest.txt (modelo)" >&2
  baixar "modules-manifest.txt" "modules-manifest.txt"
fi

echo "install.sh: pronto. Edite modules-manifest.txt e rode ./modules-toolbox.sh install" >&2
