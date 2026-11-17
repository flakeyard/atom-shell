# devShells.flakeyard-shell: the tools of the domain for people (FY-0017);
# atom-workspace joins it into devShells.default.
{ warning }:
{
  _file = ./shell.nix;

  config.perSystem =
    { config, pkgs, ... }:
    {
      devShells.flakeyard-shell = warning pkgs.lib (
        pkgs.mkShellNoCC {
          packages = [
            config.pre-commit.settings.hooks.shellcheck.package
            config.treefmt.programs.shfmt.package
          ];
        }
      );
    };
}
