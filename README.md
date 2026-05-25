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

## Examples

`examples/` 配下に独立 flake のサンプルを置いている。git clone せずに直接試せる:

| サンプル | コマンド | 内容 |
|---|---|---|
| `hello` | `nix run github:conao3/nix-msb?dir=examples/hello` | busybox + 自前 shell script の最小例 |
| `python-http` | `nix run github:conao3/nix-msb?dir=examples/python-http` | `python -m http.server` を 8888 番で公開 (別 terminal で `curl http://localhost:8888/`) |

詳細は各 example の `README.md` を参照。`flake.nix` の `microsandboxTools.buildSandbox { ... }` をコピペして書き換えれば任意の sandbox の雛形になる。

## 同梱されるもの

- `pkgs.microsandbox` — `msb` CLI の packaging (Linux x86_64 + aarch64)。[NixOS/nixpkgs#523829](https://github.com/NixOS/nixpkgs/pull/523829) が merge されるまでの暫定同梱で、merge 後は upstream の `pkgs.microsandbox` に依存を切り替える
- `pkgs.microsandboxTools.buildSandbox` — 本体 library

## 動作前提

- Linux + KVM (`/dev/kvm` にアクセスできるユーザー)
- nixpkgs `nixos-unstable` (glibc 2.39 以上)

## ライセンス

[Apache-2.0](./LICENSE)
