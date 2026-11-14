{
  # The only inputs (FY-0017): consumers make the atom use their copies with
  # inputs.treefmt-nix.follows = "treefmt-nix"; and
  # inputs.git-hooks.follows = "git-hooks";
  inputs = {
    treefmt-nix.url = "git+https://github.com/numtide/treefmt-nix?ref=main&rev=0d6d739a833ba9a9c93034862e4a7b061a062a1c&shallow=1";
    git-hooks.url = "git+https://github.com/cachix/git-hooks.nix?ref=master&rev=204b6977e00caac19e2313015a598543ca7be150&shallow=1";
  };

  outputs = inputs: { flakeModules.default = import ./nix inputs; };
}
