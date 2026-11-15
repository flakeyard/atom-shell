# The configuration of the tools (FY-0037). shellcheck: the flags of
# config/shellcheck.nix, or none when the project has a .shellcheckrc or a
# shellcheckrc at its root, which shellcheck then reads alone; a .shellcheckrc
# below the root is read next to the flags. shfmt: flakeyard's flags, or none when the project
# has an .editorconfig at its root, which shfmt then reads.
{
  facts,
  fixture,
  root,
  ...
}:
{
  perSystem =
    { pkgs, system, ... }:
    let
      inherit (pkgs) lib;
      project = name: (fixture { inherit name; }).allSystems.${system};
      args = name: (project name).pre-commit.settings.hooks.shellcheck.args;
      shfmt = name: lib.sort lib.lessThan (project name).treefmt.settings.formatter.shfmt.options;
      check = name: check: (fixture { inherit name; }).checks.${system}.${check};
    in
    {
      checks = {
        test-configs = facts pkgs "test-configs" {
          "without .shellcheckrc, shellcheck gets the flags of the atom" =
            args "good" == import (root + "/config/shellcheck.nix");
          "with .shellcheckrc, shellcheck gets no flags" = args "project-config" == [ ];
          "with shellcheckrc, shellcheck gets no flags" = args "undotted-config" == [ ];
          # Restated: the flags are the interface (FY-0035).
          "without .editorconfig, shfmt gets -i 2 -ci -bn" =
            shfmt "good" == lib.sort lib.lessThan [
              "-w"
              "-i"
              "2"
              "-ci"
              "-bn"
            ];
          "with .editorconfig, shfmt gets no formatting flags" = shfmt "editorconfig" == [ "-w" ];
        };
        # The scripts pass only with the project's files: the .shellcheckrc
        # and the shellcheckrc disable a check and enable no optional one;
        # .editorconfig asks
        # for four spaces and no indented patterns of case, where shfmt
        # without flags would indent with tabs; sub/.shellcheckrc disables a
        # check that the flags enable.
        test-configs-project = check "project-config" "shell";
        test-configs-undotted = check "undotted-config" "shell";
        test-configs-editorconfig = check "editorconfig" "treefmt";
        test-configs-nested = check "nested-config" "shell";
      };
    };
}
