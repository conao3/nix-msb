# python-http

`python -m http.server` を microsandbox 内で動かし、ホスト側の `localhost:8888` に port forward する例。`config.ports` / `config.cmd` / `config.env` / `config.workdir` の組合せを確認できる。

## 試し方

ターミナル 1:

```sh
nix run github:conao3/nix-msb?dir=examples/python-http
```

起動すると microVM 内で Python が 8000 番ポートで listen を始める。ホスト側の 8080 番にマッピングされている。

ターミナル 2:

```sh
curl http://localhost:8888/
```

`<h1>Hello from a Nix-built microsandbox</h1>` を含む HTML が返れば成功。`Ctrl-C` で sandbox を停止する。

## 構成

- `contents` に `pkgs.python312` を入れているので、`/bin/python3` は Nix store 経由で sandbox に届く
- `docroot` は `index.html` だけ入った Nix derivation。`microsandboxTools.buildSandbox` の `contents` に渡すと、その store path が rootfs にコピーされる
- `workdir = "/"` を指定すると `python -m http.server` がカレントディレクトリを listing する。sandbox 内の `/` 直下に docroot の `index.html` が出ているのでそれが配られる
- `ports = [ "8888:8000" ]` で `msb run --port 8888:8000` 相当の forward が立つ。ホスト側で 8888 番が他サービスに使われていれば別の番号に差し替える
- `config.net` を指定していないので egress は msb のデフォルト動作になる。ingress (publish した port) は default-allow

## ポイント

このサンプルは「Nix で組んだ closure を microsandbox で外向きサービスとして公開する」というユースケースの最小形。`contents` を差し替えれば任意の Nix-built サーバを同じ枠で動かせる。
