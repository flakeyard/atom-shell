#!/usr/bin/env bash
# Formatted as .editorconfig says: four spaces, and the patterns of case not
# indented, which -ci would change.
case ${1:-} in
"")
    echo none
    ;;
*)
    echo "$1"
    ;;
esac
