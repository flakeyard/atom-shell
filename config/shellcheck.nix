# flakeyard's flags of shellcheck (FY-0037). shellcheck has no configuration
# file it can be given, so the atom passes these flags when the project has
# neither .shellcheckrc nor shellcheckrc at its root, and none when it has
# either.
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
    # $x instead of ${x} (SC2250).
    "require-variable-braces"
    # A command substitution whose exit code is lost, such as an argument
    # $(cmd) of another command (SC2312).
    "check-extra-masked-returns"
    # A function called in a condition, where set -e does not apply inside it
    # (SC2310, SC2311).
    "check-set-e-suppressed"
  ];
  # Not enabled: check-unassigned-uppercase (SC2154), which reports the
  # variables that runners and the environment set.
in
[
  # Follow the files that source reads.
  "-x"
  # Every finding, down to style.
  "--severity=style"
  "--enable=${builtins.concatStringsSep "," enabled}"
]
