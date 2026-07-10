# 定義形式

各ショートカットは `registry/<name>.sh` に定義する。

## 必須メタ項目

```bash
SHORTCUT_NAME="ozcodex"
SHORTCUT_DESC="OZInternational.Functions に移動して Codex を起動"
SHORTCUT_USAGE="ozcodex [codex options]"
```

## 任意メタ項目

```bash
SHORTCUT_CATEGORY="project"
SHORTCUT_EXAMPLE="ozcodex --help"
```

## 本体

```bash
ozcodex() {
    cd /home/masaruishikawa/workspace/OZInternational.Functions || return
    codex --dangerously-bypass-approvals-and-sandbox "$@"
}
```

## ルール

- 関数名は `SHORTCUT_NAME` と一致させる
- `SHORTCUT_DESC` と `SHORTCUT_USAGE` は空にしない
- 危険な削除や上書きを含むコマンドは説明へ明記する
- 既存名がある場合は新規追加ではなく更新として扱う

