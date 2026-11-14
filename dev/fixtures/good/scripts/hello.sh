#!/usr/bin/env bash
# Passes shellcheck with the flags of the atom and is formatted by shfmt
# -i 2 -ci -bn. It sources a file, which -x follows.
set -euo pipefail
# shellcheck source=scripts/lib/greet.sh
source "${BASH_SOURCE[0]%/*}/lib/greet.sh"

case ${1:-} in
  "")
    greet world
    ;;
  *)
    if [[ -n $1 ]] \
      && [[ $1 != -* ]]; then
      greet "$1"
    fi
    ;;
esac
