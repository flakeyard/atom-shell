# The project's global excludes, pre-commit.settings.excludes, apply to the
# check as to the hook: the failing scripts of dev/fixtures/bad pass once
# excluded, and still fail when the excludes name other files.
{ fixture, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      excluding =
        excludes:
        (fixture {
          name = "bad";
          module.perSystem.pre-commit.settings = { inherit excludes; };
        }).checks.${system}.shell;
      failure = pkgs.testers.testBuildFailure (excluding [ ''^other\.sh$'' ]);
    in
    {
      checks.test-excluded = excluding [ ''^(lint\.sh|optional\.sh|bin/tool)$'' ];
      checks.test-not-excluded = pkgs.runCommand "test-not-excluded" { } ''
        log=${failure}/testBuildFailure.log
        cat "$log"
        grep -F 'SC2086' "$log"
        grep -F 'SC2164' "$log"
        touch $out
      '';
    };
}
