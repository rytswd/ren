{ pkgs, inputs }:
pkgs.mkShell {
  # Add build dependencies
  packages = [
    inputs.zig-overlay.packages.${pkgs.system}.master
  ];

  # Add environment variables
  env = { };

  # Load custom bash code
  shellHook = ''

  '';
}
