{ pkgs, inputs, ... }:

let
  zig = inputs.zig-overlay.packages.${pkgs.stdenv.hostPlatform.system}.master;
in
pkgs.stdenv.mkDerivation {
  pname = "ren-demo";
  version = "0.1.0";

  src = ./..;

  nativeBuildInputs = [ zig ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    # Create local cache directories for Zig
    export XDG_CACHE_HOME="$TMPDIR/cache"
    mkdir -p "$XDG_CACHE_HOME"

    zig build \
      --cache-dir "$TMPDIR/zig-cache" \
      --global-cache-dir "$TMPDIR/zig-global-cache" \
      -Doptimize=ReleaseSafe

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp zig-out/bin/ren-demo $out/bin/

    runHook postInstall
  '';

  meta = {
    description = "Ren (練) - Refined Terminal Rendering for Zig";
    license = pkgs.lib.licenses.mit;
    mainProgram = "ren-demo";
  };
}
