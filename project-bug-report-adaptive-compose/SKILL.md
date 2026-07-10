---
name: project-bug-report-adaptive-compose
description: intake、routing、evidence、decision の出力を受け取り、事実・推測・要確認を分けた統合レポートを1ファイルで作成するスキル。固定章の強制は行わず、根拠がある項目だけを採用する。
---

# Project Bug Report Adaptive Compose

統合レポートを作るための整形専用スキル。

## 目的

- 調査内容を1ファイルへ統合する
- 章埋めを目的化しない
- 根拠のある項目だけを出す

## 入力

- `project-bug-report-adaptive-intake` の出力
- `project-bug-report-adaptive-routing` の出力
- `project-bug-report-adaptive-evidence` の出力
- `project-bug-report-adaptive-decision` の出力

## 必須セクション

- インシデント概要
- 症状要約
- 期待値 / 実際値
- 対象プロジェクト候補と判定根拠
- 関連ファイル候補
- 原因候補
- 最有力候補または未確定理由
- 判定結果
- 次に取るべき行動

## 条件付きセクション

- 処理フロー
- データモデル詳細
- 影響範囲
- 暫定回避策
- 改修方針
- 工数概算
- リスクと制約
- 実装引き継ぎメモ

## 出力ルール

- `事実`
- `推測`
- `要確認`

を明確に分ける。

- 情報がない章は作らなくてよい
- 情報が不足しているが重要な論点は `要確認` として残す
- 改修方針、工数概算は根拠が弱い場合は省略する
- 判定結果と次アクションは必ず含める

## テンプレート

必要時のみ `references/integrated-report-template.md` を使う。
