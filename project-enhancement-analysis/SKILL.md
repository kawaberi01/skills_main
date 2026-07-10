---
name: project-enhancement-analysis
description: Current-project enhancement analysis and spec creation. Use when Codex needs to inspect the current workspace, treat references as hypotheses and code as authoritative, then create current behavior notes, implementation spec, implementation plan, implementation instructions, and minimal progress records under .workstate.
---

# Project Enhancement Analysis

この skill は、現在開いているプロジェクト自身の改修・機能追加に向けて、仕様調査と実装仕様作成を行う。
マイグレーションや作り直しではなく、既存コード、設定、テスト、画面 / API / Job 構造を直接調査する。

## Scope
- 対象 root は現在のワークスペース root とする。ユーザーが別 root を明示した場合のみ、その root を対象にする。
- 実装、ビルド、テスト実行、デプロイは行わない。
- 改修目的に不要な大規模リファクタ、最適化、技術刷新を混ぜない。
- `Project` は現在ワークスペース内の対象プロジェクト名、`Feature` は対象機能名として扱う。

## Outputs
対象範囲が明確で、ユーザーが分析成果物の作成まで求めている場合は、以下を作成する。

```text
.workstate/<Project>/<Feature>/spec/000-<Feature>前提メモ.md
.workstate/<Project>/<Feature>/spec/005-<Feature>現行仕様整理.md
.workstate/<Project>/<Feature>/spec/010-<Feature>実装仕様書.md
.workstate/<Project>/<Feature>/spec/020-<Feature>実装計画書.md
.workstate/<Project>/<Feature>/spec/030-<Feature>実装指示書.md
```

`.workstate` がない軽微な分析では、無理に全成果物を作らず、最終報告に現行仕様、差分、実装方針、残件をまとめてもよい。

## Workflow
1. 対象 root、ユーザー要件、成果物 root を確認する。
2. reference 候補を選ぶ。見つからない場合は止まらず実コード調査へ進む。
3. reference がある場合は、プロジェクト構成仮説、既存流儀、注意点を整理する。
4. README、solution、project files、設定、テスト構成を必要最小限に確認する。
5. 対象機能が曖昧な場合は、軽量な候補絞り込みだけを行い、深掘り前に止める。
6. 対象機能の入口と呼び出し関係を実コードから調査する。
7. 現行仕様、入力、出力、副作用、エラー、ログ、設定、テストを根拠付きで整理する。
8. reference 仮説と実コードの差分を整理する。
9. 要件と現行仕様の差分を整理する。
10. 実装仕様書、実装計画書、実装指示書を作成する。
11. progress はイベントに応じて必要なファイルだけ最小更新する。

利用可能なら、以下の専門 skill に委譲する。

- `project-reference-router`
- `project-reference-intake`
- `project-code-grounding-analysis`
- `project-enhancement-analysis`
- `project-enhancement-implementation-spec`
- `project-enhancement-progress-pack`

専門 skill が利用できない場合も、この workflow と contracts に従って直接進める。

## Skill Handoff Contract
| Step | Required output |
| --- | --- |
| reference routing | reference 候補、対象プロジェクト候補、入口候補、reference_status |
| reference intake | プロジェクト構成仮説、既存流儀、注意点、未確認事項 |
| code grounding | 入口、呼び出し経路、入出力、副作用、設定、テスト、reference との差分 |
| enhancement analysis | 現行仕様、要件との差分、影響範囲、未確定事項 |
| implementation spec | `010`, `020`, `030` の内容、対象外、停止条件 |
| progress pack | イベントに応じた最小限の progress 更新 |

## Implementation Handoff
`030-<Feature>実装指示書.md` には、実装 agent が追加判断しなくてよい粒度で次を含める。

- 対象機能名と改修目的
- 変更してよい範囲
- 変更してはいけない範囲
- 実装順序
- 追加 / 修正対象ファイル候補
- テスト観点
- 結合テスト化できる確認
- 人手確認観点
- ビルド / テストを人間へ引き継ぐ前提での静的確認観点
- 実行禁止コマンド
- progress 更新はイベント駆動・最小更新で行うこと
- 禁止事項
- 未確定事項が残る場合の停止条件

## Progress Policy
- progress はイベント駆動で最小更新する。毎回すべての progress ファイルを読み書きしない。
- 通常の進捗は `002-進捗サマリ.md`、次回再開点は `006-次回着手メモ.md` にまとめる。
- 重要な判断がある場合のみ `003-意思決定ログ.md` を更新する。
- 検証結果がある場合のみ `005-検証メモ.md` を更新する。
- agent / skill 改善材料がある場合のみ `007-agent-skill-improvement-log.md` を更新する。

## Cost Guards
- 全探索、全ファイル精査、無差別な Explore をしない。
- 初回調査は README、`.sln`、主要 `csproj`、対象入口候補、関連ファイル候補に絞る。
- 代表ファイルの確認は原則 3〜5 ファイルを目安にする。
- 1 回の表示 / 読み込みで 100 行を超える取得は原則避ける。
- `.git`, `node_modules`, `bin`, `obj`, `dist`, `packages`, 生成物、大容量ログは読まない。
- build, test, restore, install, lint、大量ログ出力コマンドを実行しない。

## Stop Conditions
- 対象範囲が曖昧な場合は、入口候補と関連ファイル候補だけ整理して止める。
- 仕様差分が大きい場合は、実装へ進まず仕様策定に留める。
- 実コードで裏取りできない内容は確定仕様にせず、未確認 / 要確認として残す。
