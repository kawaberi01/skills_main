# Usage

## Http / dev / Flex Consumption

ユーザー:

> 新しく追加したFunctionプロジェクトのデプロイpipelineを作成してください。

アシスタント:

> 対象の`.csproj`を指定してください。

ユーザー:

> `src\Functions\iDrugStore.Functions\ReturnOrder\Http\iDrugStore.ReturnOrder.Http.csproj`

アシスタント:

> 以下を推定しました。
>
> - 機能名: `ReturnOrder`
> - 種別: `Http`
> - pipeline key: `id-return-order`
> - 成果物名: `return-order-http`
>
> 対象環境とホスティング方式を指定してください。

ユーザー:

> `dev`、`Flex Consumption`

アシスタント:

> 次の開発環境設定を指定してください。
>
> - Function App名
> - Azureサービスコネクション名
> - Azure DevOps environment名
>
> Function App名は必須です。Azure 上の実在名を確認して、その名前を自由入力してください。命名パターンは `func-id-return-order-http-dev` のようになる場合がありますが、これは候補例であり推奨値ではありません。Function App名については、推奨候補やおすすめボタンを出さず、必ず自由入力で確認します。Azureサービスコネクション名とAzure DevOps environment名は、未指定なら `dev-connection` と `Development-Test` を使います。

悪い例:

> 推奨名 `func-id-return-order-http-dev` を使いますか？

良い例:

> Azure 上の Function App 実在名を入力してください。命名パターン例: `func-id-return-order-http-dev`

ユーザー:

> Function App名は`func-id-return-order-http-a1b2`、接続は`dev-connection`、environmentは`Development-Test`です。

アシスタント:

> テスト設定として以下を使用します。
>
> - テストプロジェクト: `src\Tests\OZInternational.Application.Tests\OZInternational.Application.Tests.csproj`
> - フィルター: `FullyQualifiedName~ReturnOrder`
>
> `.azure\pipelines\azure-pipelines-id-return-order-http-dev.yml`を作成してよいですか。

承認後、スキルは`Http + Flex`テンプレートからYAMLを生成する。

## File creation rules

YAMLは必ず `scripts/render_pipeline_template.ps1` で生成する。会話内でYAML本文を手書きしない。

dev/prodを両方作る場合は、1ファイルにまとめず、次のように2ファイルへ分ける。

- `.azure\pipelines\azure-pipelines-id-return-order-worker-dev.yml`
- `.azure\pipelines\azure-pipelines-id-return-order-worker-prod.yml`

禁止例:

- `.azure\pipelines\return-order-worker.yml`
- `.azure\pipelines\np-rest-shipments-worker.yml`
- `.azure\pipelines\azure-pipeline-id-return-order-worker.yml`

## Http / dev / App Service Plan

HttpプロジェクトでもApp Service Planに乗せる場合は、ホスティング方式に`Plan`を指定する。

ユーザー:

> `src\Functions\iDrugStore.Functions\ReturnOrder\Http\iDrugStore.ReturnOrder.Http.csproj` のdev用pipelineを作成してください。ホスティングはPlanです。

アシスタント:

> `.azure\pipelines\azure-pipelines-id-return-order-http-dev.yml`を、`AzureFunctionApp@1`、`functionApp`、`deploymentMethod: runFromPackage`で生成してよいですか。

承認後、スキルは`Http + Plan`テンプレートからYAMLを生成する。

## Http / prod / hosting selection

Httpプロジェクトは本番環境でも`Flex Consumption`または`App Service Plan`を選択できる。
`prod`では選択されたホスティング方式に応じて、`function-http-flex-prod.yml`または`function-http-plan-prod.yml`を使う。

## Worker / prod / Azure設定未定

ユーザー:

> Workerプロジェクトの本番pipelineを作成してください。Azureの設定値はまだ未定です。

アシスタント:

> 対象の`.csproj`を指定してください。

ユーザー:

> `src\Functions\iDrugStore.Functions\ReturnOrder\Worker\iDrugStore.ReturnOrder.Worker.csproj`

アシスタント:

> 次の内容で生成します。
>
> - 種別: `Worker`
> - 環境: `prod`
> - ホスティング: `App Service Plan`
> - トリガー: `main`
> - 出力: `.azure\pipelines\azure-pipelines-id-return-order-worker-prod.yml`
> - Function App名、サービスコネクション、environment: 空欄
>
> 作成してよいですか。

承認後、未確定値を空文字で生成し、完了報告で未設定項目を示す。

## 明示的な呼び出し

```text
$oz-function-pipeline-generator を使って、
src\Functions\...\MyFunction\Http\MyFunction.Http.csproj
のdev用pipelineを作成してください。
```

## 上書き時

同名ファイルが存在する場合、スキルは生成を停止して差分確認または上書き承認を求める。
