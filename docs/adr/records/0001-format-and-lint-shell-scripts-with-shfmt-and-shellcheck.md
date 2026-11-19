---
id: ADR-0001
title: Format and lint shell scripts with shfmt and shellcheck
status: accepted
date: 2026-11-14
supersedes: []
superseded_by: []
related: []
affects:
  ["flake.nix", "flake.lock", "nix/**", "config/**", "dev/**", "README.md"]
review_by:
---

## Context

atom-shell is the atom of step 3 of [FY-0038][fy-0038], with atom-nix, after
which the repositories that keep copies of the shell checks ([FY-0035][fy-0035])
adopt it. It owns shell scripts, with shfmt as the formatter and shellcheck as
the linter ([FY-0017][fy-0017]). Decisions of flakeyard require of it:

- [FY-0017][fy-0017]: inputs are exactly the upstream flakes whose modules the
  atom imports, `treefmt-nix` and `git-hooks`, each checked against the
  consumer's input of the same name before the import. Upstream options are set
  with `lib.mkOverride 900`, list options that upstream defines at plain
  priority at plain priority, and tool packages come from the consumer's `pkgs`.
  The domain has one check, built with `lib.<system>.run` of git-hooks.nix from
  only the domain's hooks and the project's global excludes, over the project's
  source filtered at most by the hooks' `files`; formatting is checked by
  `checks.treefmt`, which atom-workspace makes substitutable. Developer tools
  are `devShells.flakeyard-<atom>`. Tests live in `dev/` with their own lock and
  import the atom as consumers do.
- [FY-0037][fy-0037]: shellcheck is a tool of the kind "flags only": the atom
  passes its defaults as flags when the project has no file at the standard
  path, and none when it has one. shfmt is configured by `.editorconfig`, which
  belongs to the project. A project's file is detected with
  `builtins.pathExists` on the project's source, which for a git flake holds
  only tracked files.
- [FY-0024][fy-0024] and [FY-0038][fy-0038]: releases start at `v0.1.0` with the
  moving tag `v0`, a stricter default ships first as an opt-in under
  `config/next/`, and the warning of the next major version lives in
  `nix/next-major.nix`.

Reading treefmt-nix at `0d6d739a`, git-hooks.nix at `204b6977` and the tools of
`nixos-26.05` (shellcheck 0.11.0, shfmt 3.13.1), and running them, showed:

- treefmt-nix's `programs.shfmt` formats `*.sh`, `*.bash`, `*.envrc` and
  `*.envrc.*`. Its options `indent_size` (default 2) and `simplify` (default
  true) become the flags `-i` and `-s`; with `useEditorConfig` both default to
  none, and an assertion forbids setting them. It has no option for `-ci` or
  `-bn`; extra flags go into `settings.formatter.shfmt.options`, a list it
  defines at plain priority. shfmt reads `.editorconfig` only when it gets no
  formatting flags.
- treefmt-nix at `0ba5d67225c3f5c88eb134e1a665a379bfd3bea9` defaults
  `indent_size` to none and `simplify` to false, and its assertion for
  `useEditorConfig` reads `settings.formatter.shfmt.options`, the option whose
  value it defines: while `useEditorConfig` is true, evaluation fails with
  infinite recursion. With `useEditorConfig` false and neither `indent_size` nor
  `simplify` set, both revisions pass shfmt no formatting flags.
- git-hooks.nix defines the hook `shellcheck` with `types = [ "shell" ]`, its
  package as a `mkDefault`, no arguments and no `exclude_types`. pre-commit
  selects the type by the file's name, such as `.sh`, `.bash`, `.zsh`, `.envrc`
  and `direnvrc`, and, for an executable file whose name says nothing, by its
  shebang.
- pre-commit (identify 2.6.19) tags `*.zsh`, `.zshrc`, `.zprofile`, `.zshenv`,
  `.zlogin`, `.zlogout` and executables with a zsh shebang as both `shell` and
  `zsh`. shellcheck cannot parse zsh: it reports SC1071 on a zsh shebang, and
  without one SC2148 and findings on zsh syntax that are not errors in zsh.
- shellcheck reads a `.shellcheckrc`, or a `shellcheckrc` without the dot, in
  the directory of each script or above it, also when it gets flags; without one
  it falls back to the user's `~/.shellcheckrc`. It cannot be given a
  configuration file other than by `--rcfile`, which FY-0037 does not use for
  it. A `.shellcheckrc` sets `external-sources=true` for what `-x` does on the
  command line.
- shellcheck reports SC2148 on a direnv `.envrc` without a shebang or a
  `# shellcheck shell=bash` directive, since nothing in it names the shell.
- Over the 299 shell scripts of flakeyard's 20 repositories, without `.envrc`,
  `-x --severity=style` reports nothing. The optional checks `add-default-case`,
  `avoid-negated-conditions`, `avoid-nullary-conditions`, `deprecate-which`,
  `quote-safe-variables`, `require-double-brackets` and `useless-use-of-cat` add
  3 findings, `require-variable-braces` about 7000, `check-extra-masked-returns`
  about 600 and `check-set-e-suppressed` about 100; flakeyard's scripts are
  fixed for all of them before they adopt the atom. `check-unassigned-uppercase`
  reports the variables of runners and stays off.

## Decision

### Inputs

The public flake has two inputs, `treefmt-nix` (numtide/treefmt-nix) and
`git-hooks` (cachix/git-hooks.nix). Before importing the module of either, the
atom fails evaluation with the line `inputs.<name>.follows = "<name>";` when the
consumer's input of that name has another store path.

Amended for [FY-0040][fy-0040]: the public flake also declares `lib-atom`, which
the atom pins in its own `flake.lock` and consumers neither declare nor follow.
The check of `follows` and the warning of the next major version are the
functions `upstream` and `warning` of lib-atom, with the same messages; the atom
keeps no copy of them.

### Formatter

The atom enables `programs.shfmt` of treefmt-nix with `pkgs.shfmt` of the
consumer. When the project has no `.editorconfig` at its root, it passes
flakeyard's style, the style of every flakeyard repository: `indent_size = 2`,
`simplify = false` and the options `-ci` and `-bn`, so shfmt gets
`-i 2 -ci -bn`. When the project has one, it sets `indent_size = null` and
`simplify = false` and passes no options, so shfmt gets no formatting flags and
`.editorconfig` replaces the default wholly. Amended: the atom leaves
`useEditorConfig` unset, false, since later revisions of treefmt-nix fail with
infinite recursion while it is true and it adds nothing to the empty flags. The
options are a plain definition, as FY-0017 requires for a list upstream defines
at plain priority; the other values use `lib.mkOverride 900`. The atom adds no
hook of its own for formatting: atom-workspace enables the hook `treefmt`, and
`checks.treefmt` checks formatting.

### Linter

The atom enables the upstream hook `shellcheck` with `pkgs.shellcheck` of the
consumer and owns it. Its `files` and `types` stay upstream's. Amended: the hook
gets `exclude_types = [ "zsh" ]` with `lib.mkOverride 900`, since git-hooks.nix
leaves the list at its default, so pre-commit skips the files of zsh, which
shellcheck cannot parse, in the hook and in the check alike. A project excludes
other files with `pre-commit.settings.excludes` or
`pre-commit.settings.hooks.shellcheck.excludes`. When the project has neither
`.shellcheckrc` nor `shellcheckrc` at its root, the hook gets the flags of
`config/shellcheck.nix`, the one place they are written:

- `-x`, to follow the files that `source` reads;
- `--severity=style`, every finding;
- `--enable=` with ten of the eleven optional checks, each with a comment.

The one optional check that is not enabled, `check-unassigned-uppercase`, is
listed there with the reason. When the project has a `.shellcheckrc` or a
`shellcheckrc` at its root, the hook gets no arguments, so shellcheck reads that
file alone; `external-sources=true` there takes the place of `-x`. A
`.shellcheckrc` below the root is read by shellcheck next to the flags, as
shellcheck defines.

### Check and shell

`checks.shell` is built with `lib.<system>.run` of git-hooks.nix from only the
hook `shellcheck`, with every option the project's configuration holds for it,
the project's global `pre-commit.settings.excludes` and the project's
`pre-commit` and `git` packages. Its source is the whole project: the hook has
no `files` pattern, since it selects scripts by their content, and shellcheck
reads the project's `.shellcheckrc` and the files that scripts source.
pre-commit selects the files, as the installed hook does.

`devShells.flakeyard-shell` holds shellcheck and shfmt.

### Next major version

While `nix/next-major.nix` exists, `checks.shell` and
`devShells.flakeyard-shell` warn with `lib.warn` of the consumer's nixpkgs: the
version, the end of support 6 months after it, and the link to the migration
guide the file names ([FY-0016][fy-0016], [FY-0038][fy-0038]).

### Tests

`dev/flake.nix` imports the atom from the flake's own outputs called with the
dev flake's `treefmt-nix` and `git-hooks`, which is what `follows` gives a
consumer, together with atom-workspace, and checks this repository with them.
Fixture projects import both the same way. As amended for [FY-0040][fy-0040],
the dev flake fetches the revision of lib-atom that the root `flake.lock` pins,
gives it to the atom and takes the fixture projects and the tests of `follows`,
the warning and the glue of atom-workspace from its `internal/testing`, with the
messages restated in the tests. Its checks evaluate on x86_64-linux and
aarch64-linux: a project that passes both checks, with a script without an
extension; a project that fails shellcheck, also in a script without an
extension and through an optional check, and fails formatting, next to files of
zsh that it does not report; a project whose `.shellcheckrc` replaces the flags;
a project whose `shellcheckrc` replaces the flags; a project whose
`.editorconfig` replaces the flags of shfmt, also on a second input of
treefmt-nix at a revision whose assertion reads its own options (amended); a
`.shellcheckrc` below the root; the global excludes; the glue of atom-workspace;
the follows error of both inputs; and the next-major warning.

## Constraints

- The public flake MUST declare only the inputs `treefmt-nix`, `git-hooks` and
  `lib-atom` ([FY-0040][fy-0040]), and MUST fail evaluation with the exact
  follows line when the consumer's input of either name has another store path.
- The atom MUST pass shellcheck the flags of `config/shellcheck.nix` exactly
  when the project has neither `.shellcheckrc` nor `shellcheckrc` at its root,
  and no arguments otherwise.
- The atom MUST pass shfmt `-i 2 -ci -bn` exactly when the project has no
  `.editorconfig` at its root, and no formatting flags otherwise.
- The atom MUST NOT set `useEditorConfig` of treefmt-nix.
- The hook `shellcheck` MUST skip the type `zsh`.
- The flags of shellcheck MUST be written in `config/shellcheck.nix` only.
- `checks.shell` MUST be built with `lib.<system>.run` of git-hooks.nix from
  only the hook `shellcheck` and the project's global excludes, and the atom
  MUST NOT select its files.
- Everything listed in the "Public API" of the README is the public API
  ([FY-0017][fy-0017], [FY-0024][fy-0024]).

## Consequences

- (+) A project gets the same findings in the git hook, in `nix flake check` and
  in CI, with flakeyard's flags or its own `.shellcheckrc` or `shellcheckrc`.
- (+) flakeyard's repositories keep their current formatting; a project that
  writes an `.editorconfig` gets its own.
- (−) `checks.shell` depends on the whole source, so any change rebuilds it.
- (−) treefmt formats only scripts with a shell extension and `.envrc`;
  shellcheck also checks scripts without an extension, which shfmt leaves alone.
- (−) Every `.envrc` needs a shebang or `# shellcheck shell=bash`; flakeyard's
  repositories add the directive when they adopt the atom.
- (−) The findings of the optional checks, about 7700 in flakeyard's scripts,
  are fixed in every repository before it adopts the atom.
- (−) Locally, a user's `~/.shellcheckrc` applies to the hook when the project
  has neither `.shellcheckrc` nor `shellcheckrc`; the check in the sandbox has
  none.
- (−) Scripts of zsh are neither linted nor formatted.
- (±) A project with an `.editorconfig` that says nothing about shell files gets
  shfmt's own defaults, tabs, instead of flakeyard's style.

## Alternatives considered

- **shellcheck's `--rcfile` with a default `.shellcheckrc` in `config/`.**
  FY-0037 classes shellcheck as "flags only".
- **`--norc` with the default flags.** It would also drop a `.shellcheckrc`
  below the root, which FY-0037 leaves to the tool.
- **A shfmt hook of git-hooks.nix for scripts without an extension.** A second
  owner of shfmt next to treefmt ([FY-0017][fy-0017]).
- **`simplify`, treefmt-nix's default.** `-s` would rewrite scripts of
  flakeyard's repositories that pass today.
- **`useEditorConfig = true` with an `.editorconfig`.** It passes no flags the
  atom does not already leave out, and later revisions of treefmt-nix fail
  evaluation with infinite recursion while it is set.
- **Excluding zsh files by name.** The type `zsh` of pre-commit also covers the
  startup files and executables with a zsh shebang, which a pattern of names
  misses.
- **Excluding `.envrc` from the hook.** direnv files are bash and are worth
  checking; one directive makes them pass.
- **A coarse filter of the check's source by file extensions.** It would select
  files beside pre-commit, which FY-0017 forbids, and lose scripts without an
  extension.

[fy-0016]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0016-pin-form.md
[fy-0017]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0017-atom-contract.md
[fy-0024]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0024-versioning-and-support.md
[fy-0035]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0035-extract-logic-that-has-two-users.md
[fy-0037]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0037-atoms-ship-default-configs-that-projects-replace.md
[fy-0038]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0038-roll-out-the-atoms.md
[fy-0040]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0040-share-code-through-lib-repositories.md
