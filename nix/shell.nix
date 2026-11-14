# devShells.flakeyard-shell: the tools of the domain for people (FY-0017);
# atom-workspace joins it into devShells.default.
{
  _file = ./shell.nix;

  config.perSystem =
    { config, pkgs, ... }:
    let
      warning = import ./warning.nix {
        inherit (pkgs) lib;
        file = ./next-major.nix;
      };
    in
    {
      devShells.flakeyard-shell = warning (
        pkgs.mkShellNoCC {
          packages = [
            config.pre-commit.settings.hooks.shellcheck.package
            config.treefmt.programs.shfmt.package
          ];
        }
      );
    };
}
