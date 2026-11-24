{
  description = "atom-shell: the tests of the atom and the checks of this repository.";

  inputs = {
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-26.05&rev=0dc498bfe49baeb18b0f9891e800b53bb2603193&shallow=1";
    flake-parts = {
      url = "git+https://github.com/hercules-ci/flake-parts?ref=main&rev=ea2630b7470978622c7689a1ff75d2b389175399&shallow=1";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "git+https://github.com/numtide/treefmt-nix?ref=main&rev=a0a97e31a897a3537eea5c49df4f8adaa83b3b37&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # A later revision of treefmt-nix, whose module of shfmt asserts on its
    # own options while useEditorConfig is true; only the test of
    # .editorconfig on it uses this input.
    treefmt-nix-assert = {
      url = "git+https://github.com/numtide/treefmt-nix?ref=main&rev=0ba5d67225c3f5c88eb134e1a665a379bfd3bea9&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "git+https://github.com/cachix/git-hooks.nix?ref=master&rev=204b6977e00caac19e2313015a598543ca7be150&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    atom-data-formats = {
      url = "git+https://github.com/flakeyard/atom-data-formats?ref=v0&rev=933cbb3ff234825dd19a55c91a1bb279ea2682cb&shallow=1";
      inputs.treefmt-nix.follows = "treefmt-nix";
      inputs.git-hooks.follows = "git-hooks";
    };
    atom-markdown = {
      url = "git+https://github.com/flakeyard/atom-markdown?ref=v0&rev=90a9dc7b59521c187fabd6662205b88e712d088d&shallow=1";
      inputs.treefmt-nix.follows = "treefmt-nix";
      inputs.git-hooks.follows = "git-hooks";
    };
    atom-nix = {
      url = "git+https://github.com/flakeyard/atom-nix?ref=v0&rev=c591b0716c9fe3f16074637e63ee9128e602ee6a&shallow=1";
      inputs.treefmt-nix.follows = "treefmt-nix";
      inputs.git-hooks.follows = "git-hooks";
    };
    atom-text = {
      url = "git+https://github.com/flakeyard/atom-text?ref=v0&rev=68467987a5d8db04681d587ffaa2d9aa755a4f62&shallow=1";
      inputs.git-hooks.follows = "git-hooks";
    };
    atom-workspace.url = "git+https://github.com/flakeyard/atom-workspace?ref=v0&rev=19b05dd722aa405c6110364ca60438d94855d1fe&shallow=1";
    import-tree.url = "git+https://github.com/vic/import-tree?ref=main&rev=eb1b52eaecc57f7c136d07ae8a93e724dfecac46&shallow=1";
  };

  outputs =
    inputs:
    let
      # The root of the repository; every other file reaches it as the module
      # argument root.
      root = ../.;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      # The loader of lib-atom (FY-0040): the source of the revision that the
      # atom's root flake.lock pins, so that the atom has one pin of it.
      lock = builtins.fromJSON (builtins.readFile (root + "/flake.lock"));
      lib-atom-source = builtins.fetchTree lock.nodes.${lock.nodes.root.inputs.lib-atom}.locked;
      lib-atom = (import (lib-atom-source + "/flake.nix")).outputs { };
      # The atom as a consumer with the inputs projectInputs gets it with
      # the follows lines of treefmt-nix and git-hooks: its flake's outputs
      # over the consumer's copies and its own lib-atom, unless given. An
      # input path:.. would leave the directory of this flake, which the pin
      # form of action-flake-lock forbids for path inputs.
      atomFor =
        projectInputs: given:
        (import (root + "/flake.nix")).outputs (
          {
            inherit (projectInputs) treefmt-nix git-hooks;
            inherit lib-atom;
          }
          // given
        );
      # The helpers of the tests for fixture projects with the inputs
      # projectInputs, from the same revision of lib-atom; every fixture
      # project imports atom-workspace.
      testingFor =
        projectInputs:
        import (lib-atom-source + "/internal/testing") {
          inherit root systems;
          inputs = projectInputs;
          atom = atomFor projectInputs;
          imports = [ inputs.atom-workspace.flakeModules.default ];
          lib-atom = lib-atom.lib;
        };
      testing = testingFor inputs;
    in
    inputs.flake-parts.lib.mkFlake
      {
        # The project is the whole repository, not dev/.
        inputs = inputs // {
          self = inputs.self // {
            outPath = root;
          };
        };
      }
      {
        inherit systems;
        imports = [
          (atomFor inputs { }).flakeModules.default
          inputs.atom-data-formats.flakeModules.default
          inputs.atom-markdown.flakeModules.default
          inputs.atom-nix.flakeModules.default
          inputs.atom-text.flakeModules.default
          inputs.atom-workspace.flakeModules.default
          # Every file under nix/ is a flake-parts module.
          (inputs.import-tree ./nix)
        ];
        _module.args = {
          inherit root testing;
          inherit (testing) facts fixture;
          # fixtureOn upstream: fixture for projects whose inputs upstream
          # replace those of this flake, such as treefmt-nix.
          fixtureOn = upstream: (testingFor (inputs // upstream)).fixture;
        };
        # The fixtures fail on purpose; the tests check them.
        perSystem = {
          pre-commit.settings.excludes = [ "^dev/fixtures/" ];
          treefmt.settings.excludes = [ "dev/fixtures/*" ];
        };
      };
}
