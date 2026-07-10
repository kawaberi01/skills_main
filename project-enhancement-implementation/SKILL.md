---
name: project-enhancement-implementation
description: Current-project direct implementation for one feature or small change. Use when Codex needs to implement from 030/020 specs or a concrete user request, make scoped code/test edits in the same workspace, perform static self-review, and hand off build/test verification with minimal progress updates.
---

# Project Enhancement Implementation

この skill は、現在開いているプロジェクト自身に対して、1 機能 / 1 改修単位の実装を進める。
標準の主入力は `030-<Feature>実装指示書.md` と `020-<Feature>実装計画書.md` とする。

## Scope
- 同一ワークスペース内の既存プロジェクトへ直接変更する。
- 別ディレクトリに一時的な開発用プロジェクトを作らない。
- 必要時のみ `010-<Feature>実装仕様書.md`, `005-<Feature>現行仕様整理.md`, `000-<Feature>前提メモ.md` を参照する。
- デプロイ、環境配置、本番反映、コミット、プッシュは明示指示がある場合のみ行う。
- ビルド / テスト実行確認は原則として人間へ引き継ぐ。

## Workflow
1. 対象機能名と spec / progress の場所を確認する。
2. `progress/006-次回着手メモ.md` と `progress/002-進捗サマリ.md` がある場合は、再開位置と注意点を確認する。
3. `030` と `020` がある場合は、対象機能、変更範囲、対象外、実装順序、対象ファイル、テスト観点、禁止事項、停止条件を確定する。
4. `030 / 020` がない小さな改修では、暫定実装契約を固定してから進める。
5. 不足時のみ `010 / 005 / 000`, `003-意思決定ログ.md`, `004-保留事項一覧.md` を参照する。
6. 関連ファイルを必要最小限に読み、仕様資料または暫定実装契約と現行コードに矛盾がないか確認する。
7. 対象ファイルや根拠が不足する場合のみ、実装前の根拠確認を行う。
8. 矛盾、危険な未確定事項、変更範囲の拡大があれば、実装前にユーザーへ確認する。
9. 実装契約を固定してからコード変更を開始する。
10. 対象プロジェクトの既存パターンに沿って最小実装する。
11. テスト追加または人手確認観点を整理する。
12. 静的確認、仕様突合、自己レビューを行う。
13. progress はイベントに応じて必要なファイルだけ最小更新する。

利用可能なら、以下の専門 skill に委譲する。

- `project-enhancement-progress-pack`
- `project-enhancement-implementation-intake`
- `project-code-grounding-analysis`
- `project-enhancement-direct-implementation`

専門 skill が利用できない場合も、この workflow と implementation rules に従って直接進める。

## Temporary Implementation Contract
`030 / 020` がない軽微な修正では、作業開始前に短く固定する。

```md
## 暫定実装契約
- 対象:
- 変更範囲:
- 対象外:
- 停止条件:
- 検証方法:
- テスト追加可否:
- 人手確認観点:
- progress 作成要否:
```

## Decision Rules
- Spec-led, Code-verified.
- 実装判断の優先順位は `030 / 020 > ユーザーの明示指示 > 実コードで確認した事実 > 010 / 005 / 000 > reference > 推測` とする。
- レビュー後の修正や実装中の追加対応は、まず `implementation-only` と `spec-update-required` に分類する。
- `implementation-only` は、既存の `030 / 020` または暫定実装契約の範囲内で修正する。
- `spec-update-required` は、対象範囲、対象外、既存挙動、責務分担、実装順序のいずれかが変わる場合とし、実装前に分析またはユーザー確認へ戻す。
- 既存構成にない抽象化は、`030 / 010` に理由が明記されている場合、またはユーザーが明示した場合のみ行う。

## Implementation Rules
- 既存構成、命名、依存方向、設定方式、テスト方式に合わせる。
- 仕様書にない最適化、横断リファクタ、技術刷新を混ぜない。
- 既存挙動変更は、仕様書またはユーザー指示で明示された変更に限定する。
- 機密情報、接続文字列、固定宛先、環境依存値をコードへ埋め込まない。
- 既存構成にない DTO / Repository / Service / DI 分離などを標準作成しない。
- 仕様資料と実コードが矛盾する場合は、実装で勝手に解決せず、実装前確認として分離する。

## Progress Policy
- progress はイベント駆動で最小更新する。毎回すべての progress ファイルを読み書きしない。
- 通常の進捗変化は `002-進捗サマリ.md`、次回再開点は `006-次回着手メモ.md` にまとめる。
- 重要な判断が発生した場合のみ `003-意思決定ログ.md` に追記する。
- テスト / 検証結果がある場合のみ `005-検証メモ.md` を更新する。
- タスク構成変更がある場合のみ `001-詳細タスク.md` を更新する。
- 未移植 / 保留 / 別トラック追加がある場合のみ `004-保留事項一覧.md` を更新する。
- agent / skill 改善材料がある場合のみ `007-agent-skill-improvement-log.md` を更新する。
- `.workstate` がない軽微な修正では、無理に新規作成せず、最終報告に実装契約、変更内容、検証引き継ぎ、残件をまとめる。

## Command Policy
- `dotnet build`, `dotnet test`, `msbuild`, `npm test`, `npm install`, `restore`, `lint`, 大量ログ出力コマンドの実行は原則禁止。
- ユーザーが実行してよいコマンドを明示した場合のみ、その指定範囲で 1 回ずつ実行してよい。
- 実行に失敗しても、自動デバッグループや再実行ループに入らず、失敗内容と人間への引き継ぎ事項を整理して止める。

## Static Verification
ビルド / テストを実行しない場合でも、以下は静的に確認する。

- `using` / `namespace` / クラス名 / メソッド名 / プロパティ名の整合
- 既存の呼び出し元、View、Route、DI、設定キー、ファイル名との整合
- `.sln`, `.csproj`, 設定ファイル、既存テストプロジェクトへの含有有無
- 既存の命名、配置、責務分担、エラー処理、ログ方針との整合
- テスト未実行により残る不確実性

## Completion Criteria
- `030 / 020` または暫定実装契約の対象変更がすべて反映されている。
- 対象外作業が混入していない。
- 既存の構成、命名、責務分担、テスト方式に合っている。
- 必要なテスト追加または人手確認観点の整理が終わっている。
- 静的確認と自己レビューが終わっている。
- `.workstate` がある案件では、再開可能な進捗が必要最小限で残っている。

## Stop Conditions
- `030 / 020` があるのに読まずに実装へ入ることは禁止。
- `030 / 020` がない場合に、暫定実装契約を固定せずに実装へ入ることは禁止。
- 仕様差分が大きく、`010 / 020 / 030` を作らないと範囲が曖昧な場合は実装しない。
- 既存業務挙動を変えるかどうかの判断が必要な場合は止める。
- 影響範囲が複数機能、複数プロジェクト、DB スキーマ、外部連携に広がる場合は止める。
