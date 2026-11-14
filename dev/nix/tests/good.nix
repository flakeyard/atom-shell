# A project whose scripts pass shellcheck with the flags of the atom, also a
# script without an extension, and are formatted: both checks succeed.
{ fixture, ... }:
{
  perSystem =
    { system, ... }:
    let
      inherit (fixture { name = "good"; }) checks;
    in
    {
      checks.test-good = checks.${system}.shell;
      checks.test-good-format = checks.${system}.treefmt;
    };
}
