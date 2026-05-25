# hello

Smallest possible example. Combines busybox with a shell script via `microsandboxTools.buildSandbox` and launches it under microsandbox.

## Try it

```sh
nix run 'github:conao3/nix-msb?dir=examples/hello'
```

Expected output:

```
[hello] Hello from a Nix-built microsandbox
[hello] uname:  Linux msb-xxxxxxxx 6.12.68 #1 SMP PREEMPT_DYNAMIC ... x86_64 GNU/Linux
[hello] whoami: root
```

The `6.12.68` kernel reported by `uname` is the one bundled with libkrun. It is different from the host kernel, which means the microVM boundary is in effect.

## Inspect the artifacts

```sh
# OCI image tarball
nix build 'github:conao3/nix-msb?dir=examples/hello'#image

# Extracted rootfs directory
nix build 'github:conao3/nix-msb?dir=examples/hello'#rootfs
ls ./result/bin/
```

## Hack on it locally

```sh
git clone https://github.com/conao3/nix-msb
cd nix-msb/examples/hello
nix run .
```

Edit `flake.nix` and tweak `contents` or `config.cmd` to experiment.
