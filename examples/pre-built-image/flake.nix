{
  description = "nix-msb example: pass a pre-built OCI image into buildSandbox";

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
        echo "[pre-built-image] image was built outside of buildSandbox"
        echo "[pre-built-image] uname: $(uname -a)"
      '';

      image = pkgs.dockerTools.buildLayeredImage {
        name = "pre-built-image";
        tag = "latest";
        contents = [
          pkgs.busybox
          greet
        ];
        config = {
          Cmd = [ "/bin/greet" ];
        };
      };

      sandbox = pkgs.microsandboxTools.buildSandbox {
        name = "pre-built-image";
        inherit image;
        config = {
          cmd = [ "/bin/greet" ];
          net = "none";
        };
      };
    in
    {
      packages.${system} = sandbox // {
        default = sandbox.launch;
      };
    };
}
