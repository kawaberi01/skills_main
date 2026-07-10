---
name: project-bug-report-adaptive
description: Redmine ticket or bug report investigation for the current project. Use when Codex needs to triage a defect report, narrow candidate projects/files, evaluate evidence from code/logs/settings/tests, decide stop vs limited follow-up vs implementation handoff, and produce one concise report without changing code.
---

# Project Bug Report Adaptive

この skill は、Redmine チケットまたは不具合報告文を起点に、段階的な不具合調査と統合レポート作成を行う。
コード変更は行わない。`edit` はレポート作成にのみ使う。

## Goals
- 現象、期待値、実際値、再現条件を整理する。
- 対象プロジェクト候補と入口候補を低コストに絞る。
- 実コード、設定、ログ、テストで裏取りできた原因候補だけを整理する。
- `停止 / 限定確認 / 実装引き継ぎ` の判断を根拠付きで示す。
- ステークホルダーと開発者が読める統合レポートを 1 ファイルで出力する。

## Output
原則としてワークスペース root に以下の形式で出力する。

```text
redmine-<ticket-id>-<slug>.md
```

チケット ID がない場合は、報告件名から短い slug を作る。既存同名ファイルがある場合は `-v2` などを付ける。

## Workflow
1. 調査上限を固定する: 読込上限、検索上限、追加確認の停止条件。
2. 入力を整理する: 現象、期待値、実際値、再現条件、不足情報。
3. 対象を絞る: 対象プロジェクト候補、入口候補、reference 候補、探索境界。
4. 根拠を評価する: 有力候補、代替候補、否定済み候補、要確認事項。
5. 判断する: 停止、限定確認、実装引き継ぎ、最小修正単位、残件。
6. 事実 / 推測 / 要確認が分かる統合レポートを作成する。

利用可能なら、以下の専門 skill に委譲する。

- `project-bug-report-adaptive-token-guard`
- `project-bug-report-adaptive-intake`
- `project-bug-report-adaptive-routing`
- `project-bug-report-adaptive-evidence`
- `project-bug-report-adaptive-decision`
- `project-bug-report-adaptive-compose`

専門 skill が利用できない場合も、この workflow と output contract に従って直接進める。

## Output Contract
統合レポートには、根拠がある範囲で次を含める。

- チケット概要
- 症状要約
- 期待値 / 実際値
- 対象プロジェクト候補と判定根拠
- 関連ファイル候補
- 原因候補
- 最有力候補または未確定理由
- 判定結果
- 次アクション

実装引き継ぎに進む場合は、次も含める。

- 対象ファイル候補
- 最小修正単位
- 実装前の停止条件
- 未確認事項
- 変更してはいけない範囲

## Investigation Policy
- 初回から詳細分析、横断影響範囲全件調査、工数見積もりを強制しない。
- 大容量ファイルは全文読みせず、検索結果、周辺行、要約単位で扱う。
- 追加確認は、対象が絞れた場合またはユーザーが続行を求めた場合に限る。
- 判断優先順位は `実コード / 再現結果 / テスト結果 / ログ > reference > 推測` とする。
- 根拠不十分のまま改修案や工数を断定しない。
- `全件調査`, `DB詳細`, `工数概算`, `改修案比較` は常設必須にしない。

## Stop Conditions
- 対象プロジェクト候補または入口候補が広すぎる場合は、未確定理由と次アクションを示して止める。
- 有力な原因候補に根拠がない場合は、推測で埋めず `要確認` とする。
- 実装指示書の作成やコード修正へ進まない。
