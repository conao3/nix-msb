# hello

最小サンプル。busybox + 自前の `hello` シェルスクリプトを `microsandboxTools.buildSandbox` で組んで microsandbox で起動する。

## 試し方

```sh
nix run github:conao3/nix-msb?dir=examples/hello
```

期待出力:

```
[hello] Hello from a Nix-built microsandbox
[hello] uname:  Linux msb-xxxxxxxx 6.12.68 #1 SMP PREEMPT_DYNAMIC ... x86_64 GNU/Linux
[hello] whoami: root
```

`uname` の kernel `6.12.68` は libkrun 同梱のゲストカーネルで、ホストの kernel とは別物。これが出力されれば microVM 隔離が成立している。

## 中身を覗く

```sh
# OCI image (tarball) を取り出す
nix build github:conao3/nix-msb?dir=examples/hello#image

# rootfs (展開済みディレクトリ) を取り出す
nix build github:conao3/nix-msb?dir=examples/hello#rootfs
ls ./result/bin/
```

## ローカルで編集する

```sh
git clone https://github.com/conao3/nix-msb
cd nix-msb/examples/hello
nix run .
```

`flake.nix` を編集すれば `contents` や `config.cmd` を差し替えて挙動を確かめられる。
