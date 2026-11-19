# The formatter shfmt of treefmt-nix (FY-0017). shfmt is configured by
# .editorconfig (FY-0037): when the project has one at the root, the atom
# passes no formatting flags, since shfmt reads .editorconfig only without
# them; otherwise it passes flakeyard's style, -i 2 -ci -bn.
{ self, ... }:
{
  _file = ./formatter.nix;

  config.perSystem =
    { lib, pkgs, ... }:
    let
      # Tracked files only, for a git flake.
      editorconfig = builtins.pathExists (self.outPath + "/.editorconfig");
    in
    {
      treefmt.programs.shfmt = {
        enable = lib.mkOverride 900 true;
        package = lib.mkOverride 900 pkgs.shfmt;
        # treefmt-nix passes -i for indent_size and -s for simplify. The atom
        # leaves useEditorConfig unset, false: it passes no flags either, and
        # later revisions of treefmt-nix fail with infinite recursion while it
        # is true, since its assertion reads the options it defines.
        indent_size = lib.mkOverride 900 (if editorconfig then null else 2);
        simplify = lib.mkOverride 900 false;
      };
      # A plain definition, since treefmt-nix defines the list at plain
      # priority (FY-0017): -ci indents the patterns of case, -bn puts binary
      # operators at the start of a continued line.
      treefmt.settings.formatter.shfmt.options = lib.optionals (!editorconfig) [
        "-ci"
        "-bn"
      ];
    };
}
