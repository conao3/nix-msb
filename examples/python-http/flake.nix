{
  description = "nix-msb example: serve a directory over HTTP from inside microsandbox";

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

      docroot = pkgs.runCommand "python-http-docroot" { } ''
        mkdir -p $out
        cat > $out/index.html <<'EOF'
        <!doctype html>
        <html>
          <head><meta charset="utf-8"><title>nix-msb python-http</title></head>
          <body>
            <h1>Hello from a Nix-built microsandbox</h1>
            <p>This page is served by python -m http.server inside microsandbox.</p>
          </body>
        </html>
        EOF
      '';

      sandbox = pkgs.microsandboxTools.buildSandbox {
        name = "python-http";
        contents = [
          pkgs.python312
          docroot
        ];
        config = {
          cmd = [
            "/bin/python3"
            "-m"
            "http.server"
            "8000"
          ];
          workdir = "/";
          ports = [ "8888:8000" ];
          env = {
            PYTHONUNBUFFERED = "1";
          };
        };
      };
    in
    {
      packages.${system} = sandbox // {
        default = sandbox.launch;
      };
    };
}
