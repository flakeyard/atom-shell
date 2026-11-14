# checks.shell: the hook shellcheck, as the project's configuration holds it
# (FY-0017). Built with lib.<system>.run of git-hooks.nix from only this hook
# and the project's global excludes, so pre-commit selects the files by
# `files`, `types` and `excludes` as the installed hook does. Its source is
# the whole project: the hook selects scripts by their content, not by a
# `files` pattern, and shellcheck reads the .shellcheckrc of the project and
# the files that scripts source.
{ git-hooks }:
{ self, ... }:
{
  _file = ./checks.nix;

  config.perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    let
      inherit (config.pre-commit) settings;
      warning = import ./warning.nix {
        inherit (pkgs) lib;
        file = ./next-major.nix;
      };
    in
    {
      checks.shell = warning (
        git-hooks.lib.${system}.run {
          src = self.outPath;
          # Every option of the project's hook; raw is computed from the
          # others.
          hooks.shellcheck = removeAttrs settings.hooks.shellcheck [ "raw" ];
          inherit (settings) excludes package gitPackage;
        }
      );
    };
}
