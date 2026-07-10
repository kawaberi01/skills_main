---
name: bash-shortcut-manager
description: Bash のショートカット管理基盤を確認し、未導入なら導入、導入済みなら既存ルールに従ってショートカットを追加・更新・削除するためのスキル。長いコマンドを短縮したい、一覧できる形で管理したい、既存ショートカット運用に従って追加したい場合に使う。
---

# Bash Shortcut Manager

このスキルは、Bash ショートカットを毎回違う流儀で作らず、既存の管理基盤に沿って追加・更新・削除するために使う。

## 起動トリガー

次のような依頼で使う。

- `長いコマンドを短縮したい`
- `ショートカットを追加したい`
- `一覧できる形で管理したい`
- `既存ショートカット運用に従って追加したい`
- `このコマンドの使い方を表示できるようにしたい`

単発の一時 alias だけが欲しい依頼には使わない。

## 基本方針

1. `~/.config/codex-shortcuts/shortcuts.sh` があるか確認する
2. あればその基盤を前提に `registry/*.sh` を追加または更新する
3. なければ第2版構成を導入する
4. 新規定義は 1 ショートカット 1 ファイルとし、`SHORTCUT_DESC` と `SHORTCUT_USAGE` を必須にする
5. 使い方確認は `shortcuthelp <name>` に集約する

## 実施手順

### 1. 現状確認

- `~/.bash_aliases` の読込方法を確認する
- `~/.config/codex-shortcuts/shortcuts.sh` の有無を確認する
- `~/.config/codex-shortcuts/registry/` の既存定義を確認する
- 既存名と衝突しないかを確認する

レイアウト詳細は [references/layout.md](references/layout.md) を参照。

### 2. 追加または更新

- 新規追加: `templates/shortcut-template.sh` をもとに `registry/<name>.sh` を作る
- 既存更新: 既存ファイルを編集し、同名の重複作成はしない
- 説明、使い方、必要なら実行例を設定する
- `alias` ではなく `function` を優先する

定義形式は [references/definition-format.md](references/definition-format.md) を参照。

### 3. 検証

- `source ~/.bashrc` または `source ~/.bash_aliases` で再読込
- `myshortcuts` に表示されることを確認
- `shortcuthelp <name>` で説明と使い方が見えることを確認
- 必要なら実コマンドの最低限の挙動を確認

### 4. 削除

- 削除は `rmshortcut <name>` を優先する
- 手動削除が必要な場合も `registry/<name>.sh` 単位で扱い、他定義と混在させない

## 参照ファイル

- レイアウト: [references/layout.md](references/layout.md)
- 定義形式: [references/definition-format.md](references/definition-format.md)
- 典型依頼: [references/prompts.md](references/prompts.md)
- 雛形: [templates/shortcut-template.sh](templates/shortcut-template.sh)

