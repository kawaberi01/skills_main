---
name: oz-function-pipeline-generator
description: OZInternational.Functionsへ追加したAzure Functionsプロジェクトについて、Http/Worker、dev/prod、Flex Consumption/App Service Planを対話で確認し、既存規約に沿うAzure DevOpsデプロイ用YAMLを生成する。新規Functionsプロジェクトのpipeline作成、分割、雛形作成を依頼された場合に使用する。
---

# OZ Functions Pipeline Generator

OZInternational.Functions向けAzure DevOps pipelineを対話形式で生成する。
利用例は [references/usage.md](references/usage.md) を参照する。

必ずこの `SKILL.md` の手順に従い、`scripts/render_pipeline_template.ps1` で実ファイルを生成する。

## 対象範囲

- `Http + Flex Consumption`
- `Http + App Service Plan`
- `Worker + App Service Plan`
- `dev` または `prod`
- YAMLファイルの生成まで

Azure DevOps上へのpipeline登録や実際のデプロイは行わない。
上記以外の組み合わせは、既存pipelineを調査してから対応可否を確認する。

## 最初に確認すること

リポジトリ全体を探索しない。ユーザー指定のプロジェクトと、必要なら関連pipelineを最大3～5ファイルだけ確認する。

1. 対象`.csproj`の相対パス
2. 種別: `Http` / `Worker`
3. 環境: `dev` / `prod` / 両方
4. ホスティング: `Flex` / `Plan`
5. Function App名
6. Azureサービスコネクション名
7. Azure DevOps environment名
8. テストプロジェクトとテストフィルター

プロジェクト名、pipeline key、成果物名、テストフィルターはパスから推定して提示する。
推定に確信がない値だけ質問する。
`Function AppName` は推定値を推奨として出さない。Azure 上の実在名を確認するよう求め、必要なら `func-{feature}-{kind}-{env}` のような命名パターン例を候補として示す。
`Function AppName` については、`推奨`、`おすすめ`、`既定`、`recommended` のような表現を使わない。選択肢も作らず、必ず自由入力で確認する。

## 固定ルール

### 組み合わせ

- `Http + Flex`: `AzureFunctionApp@2`、`functionAppLinux`、`isFlexConsumption: true`
- `Http + Plan`: `AzureFunctionApp@1`、`functionApp`、`deploymentMethod: runFromPackage`
- `Worker + Plan`: `AzureFunctionApp@1`、`functionApp`、`deploymentMethod: runFromPackage`
- `Http`: `dev` / `prod` ともに `Flex` または `Plan` を選択できる

### トリガー

- `dev`: `dev/*`タグで起動し、`paths.include`は付けない
- `prod`: `main`更新で起動し、対象プロジェクトと共通依存の`paths.include`を付ける
- どちらも`pr: none`

### 既定値

- `buildConfiguration`: `Release`
- `vmImage`: `windows-latest`
- `dotnetSdkVersion`: `10.0.x`
- `publishOutput`: `$(Build.ArtifactStagingDirectory)/publish`
- テストプロジェクト: `src/Tests/OZInternational.Application.Tests/OZInternational.Application.Tests.csproj`
- `dev` の `azureSubscription`: `dev-connection`
- `dev` の `environment`: `Development-Test`
- `Function AppName` は既定補完しない。必ずユーザー入力とする
- `Function AppName` の質問では、Azure 環境上の実在名を確認するよう促す
- `Function AppName` の質問では、推奨候補のボタンや選択肢を出さない

### 本番値

`prod`では以下を空文字のまま生成できる。

- `azureSubscription`
- `functionAppName`
- `environment`

生成後に未設定項目を報告する。

## 生成手順

1. 対象`.csproj`が存在することを確認する。
2. 入力値と推定値をユーザーへ提示する。
   `Function AppName` だけは推定候補を選択肢にせず、Azure 上の実在名を自由入力で確認する。
3. 出力ファイル名と設定概要を提示し、生成承認を得る。
4. `scripts/render_pipeline_template.ps1`をPowerShellで実行する。
5. 同名ファイルが存在する場合は停止する。明示承認なしに`-Force`を使わない。
6. 生成結果を検証する。

禁止事項:

- YAML本文を手書きで組み立てない
- 1つのYAMLにdev/prodをまとめない
- `dev` と `prod` の両方を作る場合は、スクリプトを2回実行して2ファイルを作る
- `.azure\pipelines\np-rest-shipments-worker.yml` のような短縮名を作らない
- `azure-pipeline-id-...` のような単数形 `pipeline` を使わない
- ファイル名は必ず `azure-pipelines-{pipeline-key}-{kind}-{env}.yml`

例:

- `azure-pipelines-id-np-rest-shipments-worker-dev.yml`
- `azure-pipelines-id-np-rest-shipments-worker-prod.yml`

実行例:

```powershell
& "$env:USERPROFILE\.codex\skills\oz-function-pipeline-generator\scripts\render_pipeline_template.ps1" `
  -RepositoryRoot "D:\git_new_work\OZInternational.Functions" `
  -ProjectPath "src\Functions\iDrugStore.Functions\ReturnOrder\Http\iDrugStore.ReturnOrder.Http.csproj" `
  -Kind Http `
  -TargetEnvironment dev `
  -Hosting Flex `
  -LogicalName ReturnOrder `
  -PipelineKey id-return-order `
  -FunctionAppName func-id-return-order-http-a1b2 `
  -AzureSubscription dev-connection `
  -AzureDevOpsEnvironment Development-Test
```

## 検証

- 出力先が`.azure\pipelines`配下である
- 出力ファイル名が `azure-pipelines-{pipeline-key}-{kind}-{env}.yml` と完全一致している
- 対象`.csproj`が存在する
- `__...__`形式のプレースホルダーが残っていない
- `Http + Flex`または`Worker + Plan`の設定が正しい
- UTF-8 BOMなし
- 改行コードがCRLF
- 既存pipelineや無関係なファイルを変更していない

## 出力報告

生成したファイル、採用した組み合わせ、トリガー、未設定値を簡潔に報告する。
