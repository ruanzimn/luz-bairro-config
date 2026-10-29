#!/usr/bin/env bash
# Prepara um pull request de promocao: copia a imagem (digest) e a versao do overlay dev para outro ambiente.
# Rode dentro do clone do repositorio de CONFIGURACAO:
#
#   bash scripts/promover.sh          # dev -> prod
#   bash scripts/promover.sh hml      # dev -> hml
#
# O script cria um branch, altera SOMENTE o overlay de destino e faz o commit.
# O push e o pull request ficam com voce (a revisao humana e o ponto da promocao).
set -euo pipefail

DESTINO="${1:-prod}"
case "$DESTINO" in prod|hml) ;; *) echo "Destino invalido: use prod ou hml." >&2; exit 2;; esac

DEV="overlays/dev/kustomization.yaml"
ALVO="overlays/${DESTINO}/kustomization.yaml"
[ -f "$DEV" ] && [ -f "$ALVO" ] || { echo "Execute na raiz do repositorio de configuracao." >&2; exit 2; }

DIGEST="$(sed -n -E 's/^[[:space:]]*digest:[[:space:]]*(sha256:[0-9a-f]{64}).*/\1/p' "$DEV")"
VERSAO="$(sed -n -E 's/^[[:space:]]*- APP_VERSION=(.*)$/\1/p' "$DEV")"
[ -n "$DIGEST" ] && [ -n "$VERSAO" ] || { echo "Nao encontrei digest/APP_VERSION em $DEV." >&2; exit 2; }
case "$DIGEST" in sha256:0000000000000000000000000000000000000000000000000000000000000000)
  echo "O overlay dev ainda tem o digest de exemplo: rode o pipeline antes de promover." >&2; exit 2;; esac

BRANCH="promover-${DESTINO}-${VERSAO}"
git switch -c "$BRANCH"

sed -i.bak -E "s|^([[:space:]]*digest:).*|\1 ${DIGEST}|" "$ALVO"
sed -i.bak -E "s|^([[:space:]]*- APP_VERSION=).*|\1${VERSAO}|" "$ALVO"
rm -f "${ALVO}.bak"

git --no-pager diff --stat
git add "$ALVO"
git commit -m "promove ${VERSAO} (${DIGEST}) para ${DESTINO}"

echo
echo "Branch ${BRANCH} pronto. Proximos passos:"
echo "  git push -u origin ${BRANCH}"
echo "  abra o pull request ${BRANCH} -> main no GitHub, revise o diff e faca o merge."
