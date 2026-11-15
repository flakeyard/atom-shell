# The hook shellcheck of git-hooks.nix, which selects shell scripts by type,
# also those without an extension that start with a shebang and are
# executable. shellcheck takes flags only (FY-0037): the atom passes
# flakeyard's flags of config/shellcheck.nix when the project has neither
# .shellcheckrc nor shellcheckrc at its root, and none when it has either, so
# that shellcheck reads that file alone. The check runs the same entry and
# arguments.
{ root }:
{ self, ... }:
{
  _file = ./hooks.nix;

  config.perSystem =
    { lib, pkgs, ... }:
    let
      # Tracked files only, for a git flake. shellcheck reads both names.
      shellcheckrc = lib.any (name: builtins.pathExists (self.outPath + "/${name}")) [
        ".shellcheckrc"
        "shellcheckrc"
      ];
    in
    {
      pre-commit.settings.hooks.shellcheck = {
        enable = lib.mkOverride 900 true;
        package = lib.mkOverride 900 pkgs.shellcheck;
        args = lib.mkOverride 900 (if shellcheckrc then [ ] else import (root + "/config/shellcheck.nix"));
      };
    };
}
