{
  # The upstream inputs (FY-0017): consumers make the atom use their copies
  # with inputs.treefmt-nix.follows = "treefmt-nix"; and
  # inputs.git-hooks.follows = "git-hooks";
  # lib-atom is pinned by the atom in its own flake.lock; consumers neither
  # declare nor follow it (FY-0040).
  inputs = {
    treefmt-nix.url = "git+https://github.com/numtide/treefmt-nix?ref=main&rev=a0a97e31a897a3537eea5c49df4f8adaa83b3b37&shallow=1";
    git-hooks = {
      url = "git+https://github.com/cachix/git-hooks.nix?ref=master&rev=204b6977e00caac19e2313015a598543ca7be150&shallow=1";
      # One nixpkgs in the atom's own lock, which action-flake-lock checks
      # (FY-0040). Consumers replace git-hooks with follows, so this does not
      # reach them.
      inputs.nixpkgs.follows = "treefmt-nix/nixpkgs";
    };
    lib-atom.url = "git+https://github.com/flakeyard/lib-atom?ref=v0&rev=99d4af06332a1a4b33f51aa4d2ccf2b3627af46b&shallow=1";
  };

  outputs = inputs: { flakeModules.default = import ./nix inputs; };
}
