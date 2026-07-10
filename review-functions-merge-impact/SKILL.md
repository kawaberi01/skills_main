---
name: review-functions-merge-impact
description: main へマージする変更、またはマージ済みブランチの最終状態について、他の Azure Functions への影響を共有点ベースで読み取り専用レビューする。Program.cs、DI Extensions、共通設定、Legacy、Messaging、.sln/.csproj、テスト基盤、local.settings.json の変更があり、先行・既存 Functions の起動、参照、DI、設定、テストへの影響を確認したい場合に使用する。
---

# Functions マージ影響レビュー

## 原則

- コードを変更せず、読み取り専用でレビューする。
- Function 名ではなく共有点から影響候補を特定する。
- 推測を結果に混ぜず、事実、推測、未確認を分ける。
- 最終出力は必ず [references/review-template.md](references/review-template.md) を使用する。
- 一般的なコード品質ではなく、他 Functions への回帰影響を優先する。

## トークンガードレール

以下を必須制約とする。

1. リポジトリ全体の全ファイル精査を禁止する。
2. `rg --files` の無条件実行や、巨大ディレクトリへの再帰的全文出力を禁止する。
3. 1 回のファイル出力は 100 行未満にする。まず `rg -n`、`git diff --name-status`、限定 pathspec を使う。
4. 初回調査は最大 5 コマンドとし、ブランチ、比較基準、変更ファイル一覧、変更統計、共有点候補だけを取得する。
5. 1 フェーズで本文を読む代表ファイルは最大 5 件とする。
6. 同じ目的の検索を繰り返さない。1 回の `rg` に関連パターンをまとめる。
7. 変更ファイルが 20 件を超える場合も全差分を読まない。共有点カテゴリに該当する差分だけを優先する。
8. テストは影響候補に対応する最大 3 プロジェクトに限定する。Solution 全体テストは禁止する。
9. 並列ビルドによるファイルロックを避けるため、共有依存を持つ .NET テストは `-m:1 -p:UseSharedCompilation=false` を使う。
10. マルチエージェントや外部調査は自動起動しない。
11. 上限を超える追加調査が必要なら、その理由、対象、見込みコマンド数を示して停止する。
12. 根拠が不足する項目は無理に結論を出さず、`未確認` として残す。

## フェーズ 1: 差分境界の固定

最初に次だけを確認する。

```powershell
git status --short
git branch --show-current
git merge-base HEAD origin/main
git diff --name-status "<merge-base>..HEAD"
git diff --stat "<merge-base>..HEAD"
```

`main` が `master` のリポジトリでは `origin/master` を使う。

HEAD がすでに比較先へ取り込まれていて差分が空になる場合、勝手に別基準を採用しない。次の順で利用可能な証跡を確認する。

1. ユーザー指定のマージ前基準コミット
2. PR の source/target commit
3. 明示されたマージコミットの親
4. 現在のブランチ reflog

差分境界を一意に確定できない場合は停止し、必要なコミット ID を求める。推測した差分でレビューを続けない。

変更ファイルを次の固定カテゴリへ分類し、フェーズ 1 の結果を報告して停止する。

- `Program.cs` / host 起動
- `Extensions` / DI
- 設定クラス / 設定キー / appsettings
- `OZInternational.Infrastructure.Data.Legacy`
- `OZInternational.Infrastructure.Messaging`
- その他の共通 Infrastructure
- `.sln` / `.csproj` / package
- テスト基盤 / 共通 helper
- Function 専用追加
- 共有影響なし

複数工程の一括実行を依頼されても、フェーズ 1 の報告後に次フェーズの承認を待つ。

## フェーズ 2: 共有点と影響候補の確定

承認後、共有点カテゴリに該当する差分だけを読む。

- `git diff <base>..HEAD -- <最大5 pathspec>` で取得する。
- 参照元は `rg -n "SymbolA|SymbolB" src/Functions src/Tests` のようにまとめて検索する。
- DI 拡張は定義、呼び出し元、登録 lifetime、重複登録、必須設定を確認する。
- 設定変更はキー名、fallback、必須判定、既存 Function の利用箇所を確認する。
- `.csproj` は ProjectReference、PackageReference、content copy、target framework を確認する。
- test helper は既存メソッドの変更か追加だけかを区別する。

各影響候補 Function に対して、接点と根拠ファイルを 1 行で記録する。接点が検索で否定できた Function は「対象外」として根拠を残す。

候補が 5 Functions または代表ファイル 5 件を超える場合、そこで停止し、追加調査対象を提示する。

## フェーズ 3: 限定検証

承認後、影響候補に直接対応する検証だけを実行する。

優先順位:

1. 変更された既存 Function プロジェクトの `dotnet build --no-restore`
2. 変更された共有部品の unit test
3. 既存 Function を参照する test project の build
4. 環境条件が揃う場合だけ smoke/integration test

実 DB、外部 API、秘密情報が必要なテストは自動実行しない。未実施理由を記録する。

ビルドやテスト失敗は、コード不整合、環境、ロック、restore/network に分類する。環境失敗を機能不具合として扱わない。

## 判定基準

- `承認`: 共有変更がない、または全影響候補について参照、DI、設定、ビルド/テストの必要証跡が揃い、回帰を示す事実がない。
- `条件付き承認`: 静的確認と限定ビルドは成立したが、実 DB、外部 API、host 起動など必要な確認が残る。
- `要修正`: 既存 Function の起動、DI 解決、設定、参照、成果物生成、テストに具体的な破綻がある。
- `判定不能`: 差分境界を確定できない、または必要な証跡が取得できない。

重大度は次で固定する。

- `重大`: 本番起動不能、DI 解決不能、設定必須化による既存 Function 停止、参照切れ、既存動作の明確な変更。
- `要改善`: 回帰を否定するテスト不足、設定 fallback 不明、影響記録不足。
- `問題なし`: 接点なしを検索で確認、追加専用で既存呼び出しなし、限定検証成功。

## 出力規則

- Findings を先頭に置き、重大度順に記載する。
- 指摘にはファイルと行番号、影響 Function、発生条件、改善案を含める。
- 指摘がない場合は「重大・要改善の指摘なし」と明記する。
- 実行コマンドを羅列せず、証跡表へ要約する。
- 確認していない Function を「影響なし」と断定しない。
- テンプレートの章を削除しない。該当なしは `なし` と記載する。
