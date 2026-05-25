{
  description = "nix-msb example: minimal hello sandbox";

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

      hello = pkgs.writeShellScriptBin "hello" ''
        echo "[hello] Hello from a Nix-built microsandbox"
        echo "[hello] uname:  $(uname -a)"
        echo "[hello] whoami: $(whoami 2>/dev/null || id)"
      '';

      sandbox = pkgs.microsandboxTools.buildSandbox {
        name = "hello";
        contents = [
          pkgs.busybox
          hello
        ];
        config = {
          cmd = [ "/bin/hello" ];
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
