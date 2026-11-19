# zsh, which shellcheck cannot parse: the hook skips it.
setopt extended_glob
for f in **/*(.N); do print -r -- ${f:t}; done
typeset -A m=(a 1)
