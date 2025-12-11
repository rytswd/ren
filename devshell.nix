{ pkgs, inputs }:
pkgs.mkShell {
  # Add build dependencies
  packages = [
    inputs.zig-overlay.packages.${pkgs.system}.master
    pkgs.asciinema
    pkgs.asciinema-agg
  ];

  # Add environment variables
  env = { };

  # Load custom bash code
  shellHook = ''

  '';
}
