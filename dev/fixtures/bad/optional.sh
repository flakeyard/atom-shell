#!/usr/bin/env bash
# Found only by the optional check require-double-brackets.
if [ -n "${1:-}" ]; then
  echo "$1"
fi
