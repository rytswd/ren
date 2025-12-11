{ pkgs, inputs, ... }:
{
  # Build the demo executable
  ren-demo = pkgs.stdenv.mkDerivation {
    pname = "ren-demo";
    version = "0.1.0";

    src = ./..;

    nativeBuildInputs = [
      inputs.zig-overlay.packages.${pkgs.system}.master
    ];

    buildPhase = ''
      zig build -Doptimize=ReleaseSafe
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp zig-out/bin/ren-demo $out/bin/
    '';

    meta = {
      description = "ren (練) - Refined Terminal Rendering for Zig";
      license = pkgs.lib.licenses.mit;
    };
  };
}
