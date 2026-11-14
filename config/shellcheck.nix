# flakeyard's flags of shellcheck (FY-0037). shellcheck has no configuration
# file it can be given, so the atom passes these flags when the project has no
# .shellcheckrc at its root, and none when it has one.
let
  # The optional checks that are enabled, each with what it reports.
  enabled = [
    # A case statement without a default branch, *) (SC2249).
    "add-default-case"
    # A negated test, [[ ! -z $x ]], where the opposite operator exists
    # (SC2335).
    "avoid-negated-conditions"
    # A test of a bare string, [[ $x ]], instead of [[ -n $x ]] (SC2244).
    "avoid-nullary-conditions"
    # which instead of command -v (SC2230).
    "deprecate-which"
    # An unquoted variable, even when its value is known to be safe (SC2248).
    "quote-safe-variables"
    # [ ] or test instead of [[ ]] in bash (SC2292).
    "require-double-brackets"
    # cat of a single file into a pipe (SC2002).
    "useless-use-of-cat"
  ];
  # Not enabled, candidates for config/next/:
  # - require-variable-braces (SC2250): ${x} for every variable is a style
  #   that flakeyard does not use.
  # - check-unassigned-uppercase (SC2154): false positives on the variables
  #   that runners and the environment set.
  # - check-extra-masked-returns (SC2312), check-set-e-suppressed (SC2310,
  #   SC2311): about 700 findings in flakeyard's scripts to fix first.
in
[
  # Follow the files that source reads.
  "-x"
  # Every finding, down to style.
  "--severity=style"
  "--enable=${builtins.concatStringsSep "," enabled}"
]
