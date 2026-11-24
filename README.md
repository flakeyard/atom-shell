# atom-shell

A flake-parts module that formats shell scripts with shfmt, through treefmt, and
lints them with shellcheck, as a git hook and as the check `checks.shell`
([FY-0017][fy-0017], [ADR-0001][adr-0001]).

## Inputs

The atom has two inputs, `treefmt-nix` and `git-hooks`, which the project makes
it share with `follows` ([FY-0017][fy-0017]). It also pins [lib-atom][lib-atom],
the functions that atoms share, in its own `flake.lock`; the project neither
declares nor follows it ([FY-0040][fy-0040]). While the atom is `0.y.z`, only
flakeyard's own repositories use it, in the form of [FY-0016][fy-0016]:

```nix
{
  inputs = {
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-26.05&rev=<commit>&shallow=1";
    flake-parts = {
      url = "git+https://github.com/hercules-ci/flake-parts?ref=main&rev=<commit>&shallow=1";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "git+https://github.com/numtide/treefmt-nix?ref=main&rev=<commit>&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "git+https://github.com/cachix/git-hooks.nix?ref=master&rev=<commit>&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    atom-shell = {
      url = "git+https://github.com/flakeyard/atom-shell?ref=v0&rev=<commit>&shallow=1";
      inputs.treefmt-nix.follows = "treefmt-nix";
      inputs.git-hooks.follows = "git-hooks";
    };
    atom-workspace.url = "git+https://github.com/flakeyard/atom-workspace?ref=v0&rev=<commit>&shallow=1";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      imports = [
        inputs.atom-shell.flakeModules.default
        inputs.atom-workspace.flakeModules.default
      ];
    };
}
```

Without a `follows` line, evaluation fails with, for example:

```text
atom-shell: input 'git-hooks' is locked twice; add to input atom-shell:
  inputs.git-hooks.follows = "git-hooks";
```

[atom-workspace][atom-workspace] joins the shell of the atom into
`devShells.default`, installs its hook, enables the hook `treefmt`, makes
`checks.treefmt` substitutable and switches off the aggregated
`checks.pre-commit` of git-hooks.nix.

## Files it reads

From the project's source, which for a git flake holds only tracked files:

- shell scripts, as pre-commit selects the type `shell`: by name, such as
  `*.sh`, `*.bash`, `.envrc` and `direnvrc`, and executable files with a shell
  in their shebang; and the files they `source`;
- for shfmt, through treefmt: `*.sh`, `*.bash`, `*.envrc` and `*.envrc.*`;
- `.shellcheckrc` or `shellcheckrc` at the root, whose presence decides the
  flags of shellcheck, and every `.shellcheckrc` or `shellcheckrc` that
  shellcheck finds in the directory of a script or above it;
- `.editorconfig` at the root, whose presence decides the flags of shfmt, and
  the `.editorconfig` files that shfmt reads when it gets no flags.

shellcheck cannot parse zsh, so the hook skips the files that pre-commit tags
`zsh`: `*.zsh`, `.zshrc`, `.zprofile`, `.zshenv`, `.zlogin`, `.zlogout` and
executables with a zsh shebang. A project excludes other files from the hook and
the check with `perSystem.pre-commit.settings.excludes`, for every hook, or
`perSystem.pre-commit.settings.hooks.shellcheck.excludes`, for shellcheck alone:
lists of regular expressions on paths, such as `[ "^vendor/" ]`.

A direnv `.envrc` names no shell, so shellcheck needs a directive in it:

```sh
# shellcheck shell=bash
use flake
```

## Tools and configuration

Neither tool gets a configuration file from the atom ([FY-0037][fy-0037]).
shellcheck takes flags only, and shfmt is configured by `.editorconfig`, which
belongs to the project:

| Tool       | Standard path     | Default        | Project's file     |
| ---------- | ----------------- | -------------- | ------------------ |
| shellcheck | `[.]shellcheckrc` | [flags][flags] | replaces the flags |
| shfmt      | `.editorconfig`   | `-i 2 -ci -bn` | replaces the flags |

- shellcheck gets, without a `.shellcheckrc` or `shellcheckrc` at the root, the
  flags of [`config/shellcheck.nix`][flags]: `-x`, to follow `source`,
  `--severity=style` and ten optional checks, each explained there with the one
  that is not enabled. With either, it gets no flags and reads that file alone;
  write `external-sources=true` there to keep what `-x` does.
- shellcheck reads a `.shellcheckrc` below the root next to the flags, as it
  defines; it applies to the scripts in that directory and below. Locally,
  without either file in the project, shellcheck also reads the user's
  `~/.shellcheckrc`; the check runs without one.
- shfmt gets, without an `.editorconfig` at the root, `-i 2 -ci -bn`: two
  spaces, indented patterns of `case` and binary operators at the start of a
  continued line. With one, it gets no formatting flags and reads
  `.editorconfig`; a file without a section for shell scripts gives shfmt's own
  defaults, tabs.

To replace a default, commit the file at the root. Since the atom reads only
tracked files, an untracked file is seen by the tools in the working tree but
not by the atom.

## Options

The atom sets the hook `shellcheck` of git-hooks.nix and `programs.shfmt` of
treefmt-nix with `lib.mkOverride 900`, so a plain definition of the project,
such as `perSystem.pre-commit.settings.hooks.shellcheck.args = [ ... ];`,
replaces a value of the atom without `mkForce`. The check runs the hook's
`entry` and `args`, so such a definition changes it too, and honours the hook's
other options and the project's global `perSystem.pre-commit.settings.excludes`:
pre-commit selects the files in the check as the installed hook does.

The options `-ci` and `-bn` of shfmt are a plain definition of
`perSystem.treefmt.settings.formatter.shfmt.options`, which treefmt-nix defines
at plain priority; a project adds to that list, and replaces it with
`lib.mkForce`.

## Outputs

- `flakeModules.default`: the module. It adds to every system:
  - the hook `shellcheck`, enabled, with the package of the project's nixpkgs
    and the type `zsh` excluded;
  - the formatter `shfmt` of treefmt, enabled, with the package of the project's
    nixpkgs;
  - `checks.shell`: the hook, run by pre-commit through `lib.<system>.run` of
    git-hooks.nix with the project's global excludes, over the whole source of
    the project, without network access. Formatting is checked by
    `checks.treefmt`;
  - `devShells.flakeyard-shell`: shellcheck and shfmt, which atom-workspace
    joins into `devShells.default`.

Supported systems are `x86_64-linux` and `aarch64-linux`.

## Supported upstream revisions

The oldest supported revisions are those the tests run with: treefmt-nix
`0d6d739a833ba9a9c93034862e4a7b061a062a1c`, git-hooks.nix
`204b6977e00caac19e2313015a598543ca7be150`, flake-parts
`ea2630b7470978622c7689a1ff75d2b389175399` and nixpkgs `nixos-26.05` at
`ac588ef1c914865dad517b337ea0eb9694a4021c`, with shellcheck 0.11.0 and shfmt
3.13.1.

## Public API

Releases follow [semantic versioning][versioning] ([FY-0024][fy-0024]). The
public API is the inputs `treefmt-nix` and `git-hooks`, `flakeModules.default`,
the hook `shellcheck` and the formatter `shfmt`, the values the atom sets whose
change rewrites files or fails a project that passed before (the flags of
shellcheck and shfmt, the type `zsh` that the hook skips), the files it reads,
the outputs `checks.shell` and `devShells.flakeyard-shell`, the supported
systems and the oldest supported upstream revisions. Versions of shellcheck and
shfmt come from the project's nixpkgs and are not part of it.

The last minor release before a major one contains `nix/next-major.nix`; while
it exists, the check and the shell warn at evaluation that the next major
version is coming and where its migration guide is ([FY-0038][fy-0038]).

## Develop in the container

Open the repository in the flakeyard dev container: the editor reads
[`.devcontainer/devcontainer.json`](.devcontainer/devcontainer.json), and
`direnv` loads the shell of [`dev/flake.nix`](dev/flake.nix) through
[`.envrc`](.envrc) ([FY-0012][fy-0012]). [atom-workspace][atom-workspace] builds
the shell and installs the git hooks each time it starts. The container runs
`devcontainer-setup` when it is created ([FY-0042][fy-0042]): it allows the
shell, fails when the shell or its git hooks are broken, and makes git record
worktrees by relative paths. Create worktrees inside the workspace with
`git worktree add .worktrees/<name>` and work in them from the same container;
git on the host must be 2.48 or newer to use them. Run `direnv allow` once in
every worktree, and run `direnv block` before you check out a branch you do not
trust, since entering the directory runs that branch's shell hook. Commit inside
the container, whose Nix store has the tools of the hooks. With Nix on the host,
`direnv allow` or `nix develop ./dev` gives the same shell.

The public [`flake.nix`](flake.nix) holds only the inputs and the module
([FY-0017][fy-0017]). [`dev/flake.nix`](dev/flake.nix), with its own lock,
imports the atom as consumers do, with [atom-data-formats][atom-data-formats],
[atom-markdown][atom-markdown], [atom-nix][atom-nix], [atom-text][atom-text] and
atom-workspace, and holds the tests:

- `shell`, `treefmt`: the atom's checks of this repository;
- `data-formats`, `markdown`, `nix`, `text`: the checks of the other atoms of
  this repository;
- `test-good`, `test-good-format`: a fixture project in
  [`dev/fixtures`](dev/fixtures) whose scripts, one without an extension, pass
  both checks;
- `test-bad`, `test-bad-format`: a fixture project that fails shellcheck, also
  in a script without an extension and through an optional check, but not in its
  files of zsh, and fails formatting;
- `test-configs`, `test-configs-project`, `test-configs-undotted`,
  `test-configs-editorconfig`, `test-configs-nested`: the flags of both tools,
  and the project's `.shellcheckrc`, `shellcheckrc`, `.editorconfig` and a
  `.shellcheckrc` below the root;
- `test-configs-editorconfig-assert`: the project's `.editorconfig` on the input
  `treefmt-nix-assert`, a later revision of treefmt-nix whose module of shfmt
  fails with infinite recursion while `useEditorConfig` is true;
- `test-excluded`, `test-not-excluded`: the project's global excludes skip the
  failing scripts in the check, and other excludes do not;
- `test-workspace`: the formatter, the check and the shell with atom-workspace;
- `test-follows`: the error for a missing `follows` of either input;
- `test-next-major`: the warning of the next major version.

The dev flake has no input for lib-atom: it fetches the revision that the root
[`flake.lock`](flake.lock) pins, gives it to the atom and takes the fixture
projects and the tests `test-follows`, `test-next-major` and `test-workspace`
from `internal/testing` of that revision ([FY-0040][fy-0040]).

Run the same commands as CI:

```sh
nix flake check --no-update-lock-file ./dev
nix flake check --no-update-lock-file --no-build --all-systems ./dev
```

CI runs [`test.yaml`](.github/workflows/test.yaml), which calls
[workflow-check][workflow-check] with `./dev`: it checks `dev/flake.lock` and
the root `flake.lock`, builds every check on x86_64 and arm64 runners, checks
the pull request title and `renovate.json`, fails on configuration files of atom
tools at their standard root paths ([FY-0037][fy-0037]), and reports
`check / required` ([FY-0034][fy-0034]). Its weekly run builds the checks
against the current branches of nixpkgs, treefmt-nix, git-hooks.nix and
flake-parts instead of the locked revisions ([FY-0038][fy-0038]) and runs the
app `markdown-links`, which checks every link of the Markdown files over the
network. [`scorecard.yaml`](.github/workflows/scorecard.yaml) runs OpenSSF
Scorecard, and [`release.yaml`](.github/workflows/release.yaml) releases the
repository with [workflow-release][workflow-release].

Before a pull request, also run actionlint, zizmor and `reuse lint`; the atoms
that will provide them in this repository are not adopted or released yet
([FY-0038][fy-0038]).

## License

[MIT](LICENSE).

[adr-0001]:
  docs/adr/records/0001-format-and-lint-shell-scripts-with-shfmt-and-shellcheck.md
[atom-data-formats]: https://github.com/flakeyard/atom-data-formats
[atom-markdown]: https://github.com/flakeyard/atom-markdown
[atom-text]: https://github.com/flakeyard/atom-text
[atom-workspace]: https://github.com/flakeyard/atom-workspace
[flags]: config/shellcheck.nix
[fy-0012]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0012-develop-in-container.md
[fy-0042]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0042-set-up-the-dev-container-with-one-command-and-keep-worktrees-inside-it.md
[fy-0016]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0016-pin-form.md
[fy-0017]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0017-atom-contract.md
[fy-0024]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0024-versioning-and-support.md
[fy-0034]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0034-check-every-repository-with-workflow-check.md
[fy-0037]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0037-atoms-ship-default-configs-that-projects-replace.md
[fy-0038]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0038-roll-out-the-atoms.md
[fy-0040]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0040-share-code-through-lib-repositories.md
[lib-atom]: https://github.com/flakeyard/lib-atom
[versioning]: https://github.com/flakeyard/.github/blob/main/VERSIONING.md
[atom-nix]: https://github.com/flakeyard/atom-nix
[workflow-check]: https://github.com/flakeyard/workflow-check
[workflow-release]: https://github.com/flakeyard/workflow-release
