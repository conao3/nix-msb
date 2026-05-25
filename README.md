# nix-msb

A thin Nix library and launch wrapper for running closures inside [microsandbox](https://microsandbox.dev/) microVMs. It folds the boilerplate of building an OCI image with `pkgs.dockerTools.buildLayeredImage`, extracting it to a writable rootfs, and starting `msb run` into a single function call.

## What it provides

Calling `microsandboxTools.buildSandbox { name; contents | image; config }` returns an attrset:

| attr | content |
|---|---|
| `rootfs` | Read-only rootfs derivation. Image layers are extracted and a minimal `/etc` (`passwd`, `group`, `os-release`) is stubbed in |
| `image` | OCI image tarball (either the one you passed in, or one built internally from `contents`) |
| `launch` | App derivation that copies `rootfs` into a writable tmpdir, runs `msb run`, and cleans up on exit |
| `sandboxfile` | `Sandboxfile`-string derivation (currently a stub) |

You build the image one of two ways. They are mutually exclusive:

- **`contents = [ ... ];`** — `buildSandbox` calls `dockerTools.buildLayeredImage` internally with your `contents` and `config`.
- **`image = <derivation>;`** — pass an OCI image you already built (e.g. with `pkgs.dockerTools.buildImage` or `pkgs.dockerTools.buildLayeredImage`). See `examples/pre-built-image` for the full shape.

Passing both, or neither, raises a `throw` at evaluation time.

Recognised keys in `config`:

- `cmd` — `[ "/bin/sh" "-c" "..." ]`
- `cpus`, `memory` — resource limits (`msb run --cpus` / `--memory`)
- `net` — `"none"` (maps to `--no-net`) / `"public"` / `"any"` (no flag passed)
- `ports` — `[ "8080:8000" ]`
- `env` — `{ KEY = "value"; }`
- `user`, `workdir` — `msb run --user` / `--workdir`

## Usage

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-msb.url = "github:conao3/nix-msb";
  };
  outputs =
    { nixpkgs, nix-msb, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nix-msb.overlays.default ];
      };
      sandbox = pkgs.microsandboxTools.buildSandbox {
        name = "hello";
        contents = [ pkgs.busybox ];
        config = {
          cmd = [ "/bin/sh" "-c" "echo hello && uname -a" ];
          net = "none";
        };
      };
    in
    {
      packages.${system} = sandbox // { default = sandbox.launch; };
    };
}
```

```sh
nix run .
# → hello
# → Linux msb-xxxxxxxx 6.12.68 #1 SMP ... x86_64 GNU/Linux
```

## Examples

Self-contained flakes under `examples/`. You can run them straight from GitHub without cloning:

| Example | Command | What it shows |
|---|---|---|
| `hello` | `nix run 'github:conao3/nix-msb?dir=examples/hello'` | Minimal busybox sandbox running a shell script (`net = "none"`) |
| `python-http` | `nix run 'github:conao3/nix-msb?dir=examples/python-http'` | `python -m http.server` published on host port 8888 (verify with `curl http://localhost:8888/` from another terminal) |
| `pre-built-image` | `nix run 'github:conao3/nix-msb?dir=examples/pre-built-image'` | Build an OCI image with `dockerTools` outside of `buildSandbox` and pass it in via the `image` argument |

See each example's `README.md` for details. Copy the `microsandboxTools.buildSandbox { ... }` call from any example and adapt the `contents` / `config` to bootstrap your own sandbox.

> The flake URLs are quoted because zsh treats `?` as a glob character. Bash needs no quotes, but quoting works in either shell.

## Bundled packages

- `pkgs.microsandbox` — Packaging of the `msb` CLI for Linux x86_64 and aarch64. This is a temporary in-tree copy that will be removed once [NixOS/nixpkgs#523829](https://github.com/NixOS/nixpkgs/pull/523829) lands and the dependency can be switched to upstream nixpkgs.
- `pkgs.microsandboxTools.buildSandbox` — The library itself.

## Requirements

- Linux with KVM (the invoking user must be able to access `/dev/kvm`)
- nixpkgs `nixos-unstable` (glibc 2.39 or newer)

## License

[Apache-2.0](./LICENSE)
