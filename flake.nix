{
  description = "Nix tooling for running OCI images inside microsandbox microVMs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
    in
    {
      overlays.default = final: _prev: {
        microsandbox = final.callPackage ./pkgs/microsandbox.nix { };
        microsandboxTools = final.callPackage ./lib { };
      };

      legacyPackages = forAllSystems pkgsFor;

      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          example = pkgs.microsandboxTools.buildSandbox {
            name = "nix-msb-example";
            contents = [ pkgs.busybox ];
            config = {
              cmd = [
                "/bin/sh"
                "-c"
                "echo 'hello from nix-msb' && uname -a"
              ];
              net = "none";
            };
          };
        in
        {
          microsandbox = pkgs.microsandbox;
          example-rootfs = example.rootfs;
          example-image = example.image;
          example-launch = example.launch;
          default = example.launch;
        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt-rfc-style);
    };
}
