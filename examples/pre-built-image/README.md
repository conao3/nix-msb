# pre-built-image

Build an OCI image *outside* of `buildSandbox` and pass it in via the `image` argument. Use this shape when you already have a `dockerTools.buildImage` / `dockerTools.buildLayeredImage` derivation lying around and just want microsandbox to run it.

## Try it

```sh
nix run 'github:conao3/nix-msb?dir=examples/pre-built-image'
```

Expected output:

```
[pre-built-image] image was built outside of buildSandbox
[pre-built-image] uname: Linux msb-xxxxxxxx 6.12.68 #1 SMP PREEMPT_DYNAMIC ... x86_64 GNU/Linux
```

## Shape

```nix
let
  image = pkgs.dockerTools.buildLayeredImage {
    name = "myapp";
    tag  = "latest";
    contents = [ ... ];
    config.Cmd = [ "/bin/myapp" ];
  };
in
pkgs.microsandboxTools.buildSandbox {
  name = "myapp";
  inherit image;
  config = {
    cmd = [ "/bin/myapp" ];   # see note below
    net = "none";
  };
}
```

`image` and `contents` are mutually exclusive. Pass exactly one; passing both (or neither) raises a `throw` at evaluation time.

## Why `config.cmd` is still required

`msb run <dir>` does **not** read the OCI image config when the image is mounted as a rootfs directory — so the bundled `Cmd` is ignored by microsandbox. `buildSandbox` therefore relies on `config.cmd` to know what to exec inside the guest. Until microsandbox grows native support for reading the image config off a rootfs, you need to mirror the `Cmd` on both sides (or just set `config.cmd` and skip the image-side `Cmd`).
