{
  description = "nix-msb example: pass a pre-built OCI image (buildImage or buildLayeredImage) into buildSandbox";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-msb.url = "github:conao3/nix-msb";
    nix-msb.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      nix-msb,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nix-msb.overlays.default ];
      };

      greet = pkgs.writeShellScriptBin "greet" ''
        echo "[pre-built-image] built with: $1"
        echo "[pre-built-image] uname: $(uname -a)"
      '';

      rootContents = pkgs.buildEnv {
        name = "pre-built-image-root";
        paths = [
          pkgs.busybox
          greet
        ];
      };

      layeredImage = pkgs.dockerTools.buildLayeredImage {
        name = "pre-built-layered";
        tag = "latest";
        contents = [ rootContents ];
        config.Cmd = [
          "/bin/greet"
          "buildLayeredImage"
        ];
      };

      flatImage = pkgs.dockerTools.buildImage {
        name = "pre-built-flat";
        tag = "latest";
        copyToRoot = rootContents;
        config.Cmd = [
          "/bin/greet"
          "buildImage"
        ];
      };

      layered = pkgs.microsandboxTools.buildSandbox {
        name = "pre-built-layered";
        image = layeredImage;
        config = {
          cmd = [
            "/bin/greet"
            "buildLayeredImage"
          ];
          net = "none";
        };
      };

      flat = pkgs.microsandboxTools.buildSandbox {
        name = "pre-built-flat";
        image = flatImage;
        config = {
          cmd = [
            "/bin/greet"
            "buildImage"
          ];
          net = "none";
        };
      };
    in
    {
      packages.${system} = {
        layered = layered.launch;
        flat = flat.launch;
        default = layered.launch;
      };
    };
}
