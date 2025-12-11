{
  description = "Ren (練) - sophisticated terminal rendering library for Zig";

  # Add all your dependencies here
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";
    zig-overlay.url = "github:mitchellh/zig-overlay";
    zig-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  # Load the blueprint from nix/ directory
  outputs = inputs: inputs.blueprint { inherit inputs; prefix = "nix"; };
}
