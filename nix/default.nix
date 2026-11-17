# The root module of atom-shell (FY-0017). It fails when the consumer locks
# treefmt-nix or git-hooks.nix a second time, imports the modules of both and
# the atom's modules. The atom's inputs and the root of the repository reach
# the other files only as function arguments.
atomInputs:
{ inputs, ... }:
let
  root = ./..;
  # The functions that atoms share, of the revision the atom pins (FY-0040).
  shared = atomInputs.lib-atom.lib;
  upstream = shared.upstream {
    atom = "atom-shell";
    own = atomInputs;
    consumer = inputs;
  };
  # The warning of the next major version, with lib of the consumer's nixpkgs.
  warning =
    lib:
    shared.warning {
      inherit lib;
      atom = "atom-shell";
      inherit root;
    };
in
{
  key = toString ./default.nix;
  _file = ./default.nix;
  imports = [
    (upstream "treefmt-nix" atomInputs.treefmt-nix.flakeModule)
    (upstream "git-hooks" atomInputs.git-hooks.flakeModule)
    ./formatter.nix
    (import ./hooks.nix { inherit root; })
    (import ./checks.nix {
      inherit (atomInputs) git-hooks;
      inherit warning;
    })
    (import ./shell.nix { inherit warning; })
  ];
}
