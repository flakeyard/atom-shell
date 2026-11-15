#!/usr/bin/env bash
# Passes only with the project's shellcheckrc: SC2086 is disabled there, and
# require-double-brackets is no longer enabled.
if [ -n "${1:-}" ]; then
  echo $1
fi
