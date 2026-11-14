# A project whose scripts fail: checks.shell reports the findings of
# shellcheck, also in a script without an extension that pre-commit selects
# by its shebang and in a script that only an optional check of the atom
# flags; checks.treefmt reports the script that shfmt would change.
{ fixture, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      inherit (fixture { name = "bad"; }) checks;
      failure = check: pkgs.testers.testBuildFailure checks.${system}.${check};
    in
    {
      checks.test-bad = pkgs.runCommand "test-bad" { } ''
        log=${failure "shell"}/testBuildFailure.log
        cat "$log"
        grep -F 'In lint.sh line 3:' "$log"
        grep -F 'SC2086' "$log"
        grep -F 'In bin/tool line 3:' "$log"
        grep -F 'SC2164' "$log"
        grep -F 'In optional.sh line 3:' "$log"
        grep -F 'SC2292' "$log"
        if grep -F 'unformatted.sh' "$log"; then exit 1; fi
        touch $out
      '';
      checks.test-bad-format = pkgs.runCommand "test-bad-format" { } ''
        log=${failure "treefmt"}/testBuildFailure.log
        cat "$log"
        grep -F 'unformatted.sh' "$log"
        touch $out
      '';
    };
}
