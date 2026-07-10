---
name: develop-functionapp-scaffold
description: Create or update Terraform root modules for Azure Function Apps under azure/subscriptions/develop/workloads by interactively classifying the workload as http or worker, applying the established naming, subnet, plan, and app settings rules, and stopping before terraform plan/apply. Use when the user wants to scaffold a new develop Function App stack, revise an existing develop http/worker stack, or confirm Azure CLI prechecks by showing az login and subscription usage without executing az except for command existence checks.
---

# Develop FunctionApp Scaffold

`develop` 環境の Function App 用 Terraform root module を、対話で値を確定しながら作成・更新するスキルです。  
対象は `azure/subscriptions/develop/workloads` 配下です。  
このスキルは **`terraform plan` 実行前で止まります**。

## 使う場面

- `develop` に新しい Function App を追加したい
- `http` と `worker` のどちらかで Terraform 定義を作りたい
- 命名規則、サブネット、共用 plan 参照を既存流儀に合わせたい
- Azure CLI の事前確認手順を案内したい

## このスキルが行うこと

このスキルは、`develop` 環境向け Function App の Terraform 定義を作るための入力整理テンプレートを提示し、その内容をもとに `main.tf`、`variables.tf`、`backend.hcl` を作成・更新する。  
対象は `http` と `worker` の 2 種別で、命名、ネットワーク、plan 参照、app settings を既存流儀に合わせて固定する。  
生成後は `terraform plan` 実行前で停止する。

## 最初に守る制約

- `az` は **存在確認以外は実行しない**
- `az login`、`az account show`、`az account list`、`az account set` は **usage の提示のみ**
- `terraform plan`、`terraform apply`、`terraform destroy` は実行しない
- `terraform` を扱うのは root module のみ。`modules` 直下では扱わない
- 既存変更は巻き戻さず、最小差分で編集する

## 事前確認

必要なら `az` の存在確認だけを行う。  
ログイン状態やサブスクリプション状態は自動確認しない。  
代わりに次の usage を提示する。

```powershell
az login
az login --use-device-code
az account list --output table
az account show --output table
az account set --subscription "56281941-613f-4c92-bd9a-a064b26b1576"
```

## 入力モード

このスキルには 2 つの入力モードがある。

### 対話型

- スキルが 1 問ずつ確認する
- 軽微な修正や、まだ要件が固まっていない場合に使う
- app settings の個別値が多い場合は向かない

### テンプレート記入型

- スキルが最初に種別に応じた記入用テンプレートを出力する
- ユーザーはテンプレート内の値を必要に応じて修正して返す
- 返却されたテンプレートを正として Terraform 定義を作る
- 既定ではこのモードを優先する

## 対話型で最初に確認する項目

1. 種別は `http` か `worker` か
2. workload 名は何か
3. 4桁サフィックスは自動生成か手入力か
4. Resource Group は `oz-test-functions` でよいか
5. monitoring は `oz-test-monitoring` / `law-develop-platform` を使うか
6. VNet 統合を有効にするか
7. 共通 app settings を流用するか

追加確認:

- `http` の場合は `functions-http` を使うか
- `worker` の場合は `asp-functions-worker-001` と `functions-worker` を使うか

## 分類ルール

### http

- module: `../../../../modules/workload_functionapp_flex`
- profile: Flex Consumption
- サブネット: `functions-http`
- delegation 前提: `Microsoft.App/environments`
- app settings のキーは `__` を使う

### worker

- module: `../../../../modules/workload_functionapp`
- hosting: Dedicated
- service plan: `asp-functions-worker-001`
- service plan RG: `oz-test-functions`
- サブネット: `functions-worker`
- delegation 前提: `Microsoft.Web/serverFarms`
- `always_on = true`

## 命名ルール

4桁サフィックスを使う。  
環境名サフィックスは使わない。

### worker の既定ルール

- Function App: `func-<workload>-<suffix>`
- App Insights: `appi-<workload>-<suffix>`
- Storage Account: `strage0<suffix>`

### http の既定ルール

- Function App: `func-<workload>-<suffix>`
- App Insights: `appi-<workload>-<suffix>`
- Storage Account: `strage0<suffix>` を基本にしつつ、Azure の命名制約に収まるか確認する

サフィックス未指定なら、4桁の英数字小文字を 1 つ提案する。

## 共通 app settings

新規作成では `:` を使わず `__` を使う。

## 入力テンプレート

このテンプレートは、Function App の Terraform 定義を作る前に、設定する値をまとめて確定するための入力票である。  
テンプレートに書かれた値は、そのまま Terraform へ反映される候補値であり、ユーザーは必要に応じて変更する。  
説明欄は値の意味と変更判断のための補足であり、設定値そのものではない。

テンプレート記入型では、最初に種別ごとのひな型をそのまま提示する。  
ユーザーは必要な項目だけ直して返す。  
スキルは返却内容をもとに定義を作成する。

テンプレート本文は次の別ファイルを使う。

- `references/worker-template.txt`
- `references/http-template.txt`

`.NET` の `IConfiguration` 前提で扱う。  
`<program-defined-Schedule-key>` は固定名ではなく、デプロイするプログラムの仕様に合わせて置き換える。

## 生成するファイル

最低限、以下を作る。

- `main.tf`
- `variables.tf`
- `backend.hcl`

必要なら `README.md` を追加してよいが、原則不要。

## 作成手順

1. 必須参照先の存在を確認する
2. 入力モードを選ぶ。未指定ならテンプレート記入型を優先する
3. 対話型なら `http` / `worker`、workload 名、suffix、network、app settings を順に確認する
4. テンプレート記入型なら、最初に対象種別のテンプレートを出力し、記入済み内容の返却を待つ
5. 対応する既存 stack を 1 つだけ参照する
6. `main.tf`、`variables.tf`、`backend.hcl` を作成する
7. `terraform init -reconfigure -backend-config="backend.hcl"` と `terraform plan` の usage を提示して終了する

## 参照元として優先する既存 stack

ワークスペース直下をルートとして扱い、`./azure` 配下を参照する。

### http の参照元

- `./azure/subscriptions/develop/workloads/id-cancelorder-http`

### worker の参照元

- `./azure/subscriptions/develop/workloads/id-cancelorder-worker`

### 共有基盤

- `./azure/subscriptions/develop/platform/appservice-plan-functions-worker-001`
- `./azure/subscriptions/develop/platform/network-oz-test-vnet-001`

## 参照先が存在しない場合

以下のいずれかが存在しない場合、このスキルはその場で停止し、足りない参照先を短く列挙して「このスキルはまだ使えない」と伝える。

- `./azure/subscriptions/develop/workloads/id-cancelorder-http`
- `./azure/subscriptions/develop/workloads/id-cancelorder-worker`
- `./azure/subscriptions/develop/platform/appservice-plan-functions-worker-001`
- `./azure/subscriptions/develop/platform/network-oz-test-vnet-001`

不足がある状態で推測補完して進めない。

## 参照先の存在確認方法

PowerShell で `Test-Path` を使って確認する。  
一括探索はせず、必須参照先だけを個別に確認する。

```powershell
Test-Path .\azure\subscriptions\develop\workloads\id-cancelorder-http
Test-Path .\azure\subscriptions\develop\workloads\id-cancelorder-worker
Test-Path .\azure\subscriptions\develop\platform\appservice-plan-functions-worker-001
Test-Path .\azure\subscriptions\develop\platform\network-oz-test-vnet-001
```

いずれかが `False` の場合は停止する。

## 出力時の注意

- どのファイルを作成・更新したかを明示する
- `plan` は未実行であることを明示する
- 次にユーザーが実行する PowerShell コマンドだけを簡潔に示す
- テンプレート記入型では、`references/worker-template.txt` または `references/http-template.txt` の内容をそのまま最初に提示する

## 実行しないこと

- `az login`
- `az account set`
- `az account show`
- `az account list`
- `terraform plan`
- `terraform apply`
- `terraform destroy`
- `terraform import`
- `terraform state` 操作
