{ pkgs, inputs, ... }:
{
  # Run zig build test
  ren-test = pkgs.stdenv.mkDerivation {
    pname = "ren-test";
    version = "0.1.0";

    src = ./..;

    nativeBuildInputs = [
      inputs.zig-overlay.packages.${pkgs.system}.master
    ];

    buildPhase = ''
      zig build test
    '';

    installPhase = ''
      mkdir -p $out
      echo "Tests passed" > $out/result
    '';

    meta = {
      description = "Test suite for ren";
    };
  };
}
