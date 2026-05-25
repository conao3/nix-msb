# nix-msb

[microsandbox](https://microsandbox.dev/) を Nix から扱うための薄い library + 起動ラッパー。`pkgs.dockerTools.buildLayeredImage` で組んだ closure を microVM sandbox に流す手順をひとつの関数に閉じる。

## 何を提供するか

`microsandboxTools.buildSandbox { name; contents; config }` を呼ぶと attrset が返る:

| attr | 中身 |
|---|---|
| `rootfs` | layer 展開済み + `/etc` stub 入りの read-only rootfs derivation |
| `image` | OCI image tarball (registry push 用) |
| `launch` | writable tmpdir 確保 + `msb run` + cleanup を 1 本にまとめた app |
| `sandboxfile` | `Sandboxfile` 文字列 derivation (現状 stub) |

`config` の対応 key:

- `cmd` — `[ "/bin/sh" "-c" "..." ]`
- `cpus`, `memory` — リソース割当 (`msb run --cpus` / `--memory`)
- `net` — `"none"` / `"public"` / `"any"` (`--no-net` のみ実装、他は flag を渡さない fallback)
- `ports` — `[ "8080:8000" ]`
- `env` — `{ KEY = "value"; }`
- `user`, `workdir` — `msb run --user` / `--workdir`

## 使い方

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

## 同梱されるもの

- `pkgs.microsandbox` — `msb` CLI の packaging (Linux x86_64 + aarch64)。[NixOS/nixpkgs#523829](https://github.com/NixOS/nixpkgs/pull/523829) が merge されたら upstream に切り替える予定の暫定コピー
- `pkgs.microsandboxTools.buildSandbox` — 本体

## 動作前提

- Linux + KVM
- nixpkgs `nixos-unstable` (glibc 2.39 以上)

## ライセンス

Apache-2.0
