# The atom in a project with atom-workspace: shfmt formats through the hook
# treefmt and the substitutable checks.treefmt, checks.pre-commit is off, and
# devShells.default holds shellcheck and shfmt.
{ testing, ... }:
{
  perSystem = testing.workspace (
    { pkgs, ... }:
    {
      formatters.shfmt = pkgs.shfmt;
      packages = {
        inherit (pkgs) shellcheck shfmt;
      };
    }
  );
}
