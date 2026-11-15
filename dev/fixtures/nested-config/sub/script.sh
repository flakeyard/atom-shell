#!/usr/bin/env bash
# Passes only with sub/.shellcheckrc, which disables require-double-brackets.
if [ -n "${1:-}" ]; then
  echo "$1"
fi
