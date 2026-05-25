# pre-built-image

Build an OCI image *outside* of `buildSandbox` and pass it in via the `image` argument. This example exercises **both** flavours that `nixpkgs.dockerTools` ships, so you can confirm that either works as input to `buildSandbox`:

- `dockerTools.buildLayeredImage` — auto-layered (one Nix store path per layer)
- `dockerTools.buildImage` — single flat layer

## Try it

Layered image:

```sh
nix run 'github:conao3/nix-msb?dir=examples/pre-built-image#layered'
```

Flat (single-layer) image:

```sh
nix run 'github:conao3/nix-msb?dir=examples/pre-built-image#flat'
```

`#default` is the layered variant.

Expected output (label changes between the two variants):

```
[pre-built-image] built with: buildLayeredImage
[pre-built-image] uname: Linux msb-xxxxxxxx 6.12.68 #1 SMP PREEMPT_DYNAMIC ... x86_64 GNU/Linux
```

## Shape

```nix
let
  rootContents = pkgs.buildEnv {
    name = "root";
    paths = [ pkgs.busybox myApp ];
  };

  layeredImage = pkgs.dockerTools.buildLayeredImage {
    name = "myapp-layered";
    tag = "latest";
    contents = [ rootContents ];
    config.Cmd = [ "/bin/myapp" ];
  };

  flatImage = pkgs.dockerTools.buildImage {
    name = "myapp-flat";
    tag = "latest";
    copyToRoot = rootContents;
    config.Cmd = [ "/bin/myapp" ];
  };

  sandbox = pkgs.microsandboxTools.buildSandbox {
    name = "myapp";
    image = layeredImage;        # or flatImage
    config.cmd = [ "/bin/myapp" ];
  };
in sandbox.launch
```

`image` and `contents` on `buildSandbox` are mutually exclusive. Pass exactly one. (Note: `dockerTools.buildLayeredImage` itself accepts `contents` while `dockerTools.buildImage` takes `copyToRoot`. They are different argument schemas even though both produce a Docker v1 tarball.)

## Why both work

`buildSandbox`'s rootfs extractor pre-creates every directory entry under umask permissions before running `tar --no-overwrite-dir`. This sidesteps a quirk of `buildImage`'s single-layer tarball, which ships intermediate directories with mode `0555` that would otherwise block tar from writing files into them. `buildLayeredImage` does not hit this quirk because each layer is shallow, but the same handling applies to both.

## Why `config.cmd` is still required

`msb run <dir>` does not read the OCI image config when the image is mounted as a rootfs directory — so the `Cmd` bundled inside the image is ignored by microsandbox. `buildSandbox` therefore relies on `config.cmd` to know what to exec inside the guest. Until microsandbox gains native support for reading the image config off a rootfs, you need to mirror the `Cmd` on both sides (or just set `config.cmd` and skip the image-side `Cmd`).
