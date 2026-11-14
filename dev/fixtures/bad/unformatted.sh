#!/usr/bin/env bash
# Passes shellcheck, but is indented by four spaces.
if [[ -n ${1:-} ]]; then
    echo "$1"
fi
