# The atom in a project with atom-workspace: shfmt formats through the hook
# treefmt and the substitutable checks.treefmt, checks.pre-commit is off, and
# devShells.default holds shellcheck and shfmt.
{ facts, fixture, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      inherit (pkgs) lib;
      flake = fixture { name = "good"; };
      values = flake.allSystems.${system};
      checks = flake.checks.${system};
      shell = flake.devShells.${system}.default;
      # The shell holds the output out of a package, not its first output.
      holds = package: lib.elem package.out shell.nativeBuildInputs;
    in
    {
      checks.test-workspace = facts pkgs "test-workspace" {
        "treefmt runs shfmt of the project's nixpkgs" =
          values.treefmt.settings.formatter.shfmt.command == lib.getExe pkgs.shfmt;
        "the hook treefmt is enabled" = values.pre-commit.settings.hooks.treefmt.enable;
        "checks.treefmt is substitutable" = checks.treefmt.allowSubstitutes;
        "checks.pre-commit is off" = !(checks ? pre-commit);
        "the shell holds shellcheck" = holds pkgs.shellcheck;
        "the shell holds shfmt" = holds pkgs.shfmt;
      };
    };
}
