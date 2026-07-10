# レイアウト

標準構成は次のとおり。

```text
~/.bash_aliases
~/.config/codex-shortcuts/
├── shortcuts.sh
└── registry/
    ├── ozcodex.sh
    └── <name>.sh
```

## 役割

- `~/.bash_aliases`
  - 読込エントリだけを持つ
- `shortcuts.sh`
  - `myshortcuts`
  - `shortcuthelp`
  - `addshortcut`
  - `rmshortcut`
  - `reloadshortcuts`
- `registry/<name>.sh`
  - 1 ショートカット 1 ファイルの定義

## 確認ポイント

- `~/.bash_aliases` が `shortcuts.sh` を source していること
- `registry/` 配下が `shortcuts.sh` から読まれていること
- 既存ショートカットがファイル分割されていること

