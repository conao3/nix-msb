# python-http

Runs `python -m http.server` inside microsandbox and forwards it to the host's `localhost:8888`. Demonstrates how `config.ports`, `config.cmd`, `config.env`, and `config.workdir` combine.

## Try it

Terminal 1:

```sh
nix run 'github:conao3/nix-msb?dir=examples/python-http'
```

Python starts listening on port 8000 inside the microVM. The sandbox forwards host port 8888 to it.

Terminal 2:

```sh
curl http://localhost:8888/
```

You should see HTML containing `<h1>Hello from a Nix-built microsandbox</h1>`. Press `Ctrl-C` in terminal 1 to stop the sandbox.

## How it works

- `contents` includes `pkgs.python312`, so `/bin/python3` is wired into the sandbox via the Nix store.
- `docroot` is a Nix derivation containing a single `index.html`. Passing it as part of `contents` copies the store path into the rootfs.
- `workdir = "/"` makes `python -m http.server` serve the sandbox root directory, which is where `docroot`'s `index.html` ends up.
- `ports = [ "8888:8000" ]` translates to `msb run --port 8888:8000`. If host port 8888 is taken, change the host side of the mapping.
- `config.net` is not set, so egress follows microsandbox's default policy. Ingress on published ports is allowed by default.

## Why it matters

A minimal recipe for publishing a Nix-built service through a microsandbox boundary. Swap `contents` for any Nix-built server and you have the same shape.
