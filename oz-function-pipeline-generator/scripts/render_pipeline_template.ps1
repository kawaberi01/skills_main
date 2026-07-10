#
# 概要:
#   oz-function-pipeline-generator スキル用の Azure DevOps pipeline YAML 生成スクリプトです。
#   テンプレート YAML を選択し、入力値でプレースホルダーを置換して
#   リポジトリ配下 .azure\pipelines へ実ファイルを書き出します。
#
# 主な用途:
#   - 新しく追加した Functions プロジェクト向けの dev / prod pipeline を生成する
#   - Http / Worker、Flex / Plan の違いに応じた既存規約の YAML を作る
#
# 主要引数:
#   -RepositoryRoot
#     リポジトリのルート パスです。
#     例: D:\git\OZInternational.Functions
#
#   -ProjectPath
#     対象 .csproj のリポジトリ相対パスです。
#     例: src\Functions\iDrugStore.Functions\NpRestShipments\Worker\iDrugStore.NpRestShipments.Worker.csproj
#
#   -Kind
#     Functions の種別です。Http または Worker を指定します。
#
#   -TargetEnvironment
#     生成対象環境です。dev または prod を指定します。
#
#   -Hosting
#     デプロイ先のホスティング種別です。Flex または Plan を指定します。
#     Worker は Plan のみ対応です。
#
#   -LogicalName
#     機能の論理名です。テスト フィルターやタイトル生成に利用します。
#     例: CancelOrder, NpRestShipments
#
#   -PipelineKey
#     ファイル名規約に使うキーです。
#     例: id-cancel-order, id-np-rest-shipments
#
#   -FunctionAppName
#     Azure 上の実在する Function App 名です。必須です。
#
#   -AzureSubscription
#     Azure DevOps のサービス コネクション名です。
#     dev で未指定の場合は dev-connection を既定使用します。
#
#   -AzureDevOpsEnvironment
#     Azure DevOps の environment 名です。
#     dev で未指定の場合は Development-Test を既定使用します。
#
# 出力:
#   規約に従うファイル名
#   azure-pipelines-{pipeline-key}-{kind}-{env}.yml
#   を .azure\pipelines 配下へ生成します。
#
# 注意:
#   - YAML 本文を手書きせず、このスクリプト経由で生成します
#   - dev / prod を 1 ファイルへまとめません
#   - 出力ファイル名は規約どおりでなければエラーにします
#
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$RepositoryRoot,

    [Parameter(Mandatory)]
    [string]$ProjectPath,

    [Parameter(Mandatory)]
    [ValidateSet("Http", "Worker")]
    [string]$Kind,

    [Parameter(Mandatory)]
    [ValidateSet("dev", "prod")]
    [string]$TargetEnvironment,

    [Parameter(Mandatory)]
    [ValidateSet("Flex", "Plan")]
    [string]$Hosting,

    [Parameter(Mandatory)]
    [string]$LogicalName,

    [Parameter(Mandatory)]
    [string]$PipelineKey,

    [string]$FunctionAppName = "",
    [string]$AzureSubscription = "",
    [string]$AzureDevOpsEnvironment = "",
    [string]$ArtifactName = "",
    [string]$TestProject = "src/Tests/OZInternational.Application.Tests/OZInternational.Application.Tests.csproj",
    [string]$TestFilter = "",
    [string]$OutputFile = "",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$textInputs = @{
    ProjectPath = $ProjectPath
    LogicalName = $LogicalName
    PipelineKey = $PipelineKey
    FunctionAppName = $FunctionAppName
    AzureSubscription = $AzureSubscription
    AzureDevOpsEnvironment = $AzureDevOpsEnvironment
    ArtifactName = $ArtifactName
    TestProject = $TestProject
    TestFilter = $TestFilter
    OutputFile = $OutputFile
}
foreach ($entry in $textInputs.GetEnumerator()) {
    if ($entry.Value -match "[`r`n']") {
        throw "$($entry.Key) must not contain line breaks or single quotes."
    }
}
if ($PipelineKey -notmatch "^[a-z0-9][a-z0-9-]*$") {
    throw "PipelineKey must contain lowercase letters, digits, and hyphens only."
}
if ($LogicalName -notmatch "^[A-Za-z0-9.-]+$") {
    throw "LogicalName contains unsupported characters."
}

if ($Kind -eq "Worker" -and $Hosting -ne "Plan") {
    throw "Supported combinations are Http + Flex, Http + Plan, and Worker + Plan."
}

$repositoryFullPath = [System.IO.Path]::GetFullPath($RepositoryRoot).TrimEnd("\")
if (-not [System.IO.Directory]::Exists($repositoryFullPath)) {
    throw "Repository root does not exist: $repositoryFullPath"
}

$normalizedProjectPath = $ProjectPath.Replace("\", "/").TrimStart("/")
$projectFullPath = [System.IO.Path]::GetFullPath(
    [System.IO.Path]::Combine($repositoryFullPath, $normalizedProjectPath.Replace("/", "\"))
)
$repositoryPrefix = "$repositoryFullPath\"
if (-not $projectFullPath.StartsWith($repositoryPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Project path must stay within the repository."
}
if (-not [System.IO.File]::Exists($projectFullPath)) {
    throw "Project file does not exist: $projectFullPath"
}

$kindLower = $Kind.ToLowerInvariant()
if ([string]::IsNullOrWhiteSpace($ArtifactName)) {
    $logicalKebab = [regex]::Replace($LogicalName, "([a-z0-9])([A-Z])", '$1-$2').ToLowerInvariant()
    $ArtifactName = "$logicalKebab-$kindLower"
}
if ([string]::IsNullOrWhiteSpace($TestFilter)) {
    $TestFilter = "FullyQualifiedName~$LogicalName"
}
if ([string]::IsNullOrWhiteSpace($FunctionAppName)) {
    throw "FunctionAppName is required and must be provided by the user."
}
if ($TargetEnvironment -eq "dev") {
    if ([string]::IsNullOrWhiteSpace($AzureSubscription)) {
        $AzureSubscription = "dev-connection"
    }
    if ([string]::IsNullOrWhiteSpace($AzureDevOpsEnvironment)) {
        $AzureDevOpsEnvironment = "Development-Test"
    }
}
$expectedOutputFile = "azure-pipelines-$PipelineKey-$kindLower-$TargetEnvironment.yml"
if ([string]::IsNullOrWhiteSpace($OutputFile)) {
    $OutputFile = $expectedOutputFile
}
if ([System.IO.Path]::GetFileName($OutputFile) -ne $OutputFile) {
    throw "OutputFile must be a file name without directory components."
}
if ($OutputFile -ne $expectedOutputFile) {
    throw "OutputFile must be exactly '$expectedOutputFile'. Do not use a custom pipeline file name."
}

$normalizedTestProject = $TestProject.Replace("\", "/").TrimStart("/")
$testProjectFullPath = [System.IO.Path]::GetFullPath(
    [System.IO.Path]::Combine($repositoryFullPath, $normalizedTestProject.Replace("/", "\"))
)
if (-not $testProjectFullPath.StartsWith($repositoryPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Test project path must stay within the repository."
}
if (-not [System.IO.File]::Exists($testProjectFullPath)) {
    throw "Test project file does not exist: $testProjectFullPath"
}

$templateName = "function-$kindLower-$($Hosting.ToLowerInvariant())-$TargetEnvironment.yml"
$skillRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, ".."))
$templatePath = [System.IO.Path]::Combine($skillRoot, "assets", "templates", $templateName)
if (-not [System.IO.File]::Exists($templatePath)) {
    throw "Template does not exist: $templatePath"
}

$outputDirectory = [System.IO.Path]::Combine($repositoryFullPath, ".azure", "pipelines")
$outputPath = [System.IO.Path]::Combine($outputDirectory, $OutputFile)
if ([System.IO.File]::Exists($outputPath) -and -not $Force) {
    throw "Output file already exists. Confirm overwrite before using -Force: $outputPath"
}

$projectDirectory = [System.IO.Path]::GetDirectoryName($normalizedProjectPath).Replace("\", "/")
$displayEnvironment = if ($TargetEnvironment -eq "dev") { "開発環境" } else { "本番環境" }
$triggerDescription = if ($TargetEnvironment -eq "dev") { "dev/* タグ作成" } else { "main ブランチ更新" }
$purposeTrigger = if ($TargetEnvironment -eq "dev") { "タグ作成時" } else { "main ブランチ更新時" }

$replacements = [ordered]@{
    "__PIPELINE_TITLE__" = "iDrug $LogicalName $Kind $displayEnvironment デプロイ"
    "__PIPELINE_PURPOSE__" = "$purposeTrigger に $LogicalName $Kind のビルド、テスト、パッケージ化、デプロイを実行する"
    "__PROJECT_PATH__" = $normalizedProjectPath
    "__TRIGGER_DESCRIPTION__" = $triggerDescription
    "__PIPELINE_FILE__" = $OutputFile
    "__PROJECT_GLOB__" = "$projectDirectory/**"
    "__LOGICAL_NAME__" = $LogicalName
    "__KIND__" = $Kind
    "__TEST_PROJECT_PATH__" = $normalizedTestProject
    "__TEST_FILTER__" = $TestFilter
    "__AZURE_SUBSCRIPTION__" = $AzureSubscription
    "__FUNCTION_APP_NAME__" = $FunctionAppName
    "__ENVIRONMENT_NAME__" = $AzureDevOpsEnvironment
    "__ARTIFACT_NAME__" = $ArtifactName
}

$content = [System.IO.File]::ReadAllText($templatePath)
foreach ($entry in $replacements.GetEnumerator()) {
    $content = $content.Replace($entry.Key, $entry.Value)
}

if ([regex]::IsMatch($content, "__[A-Z0-9_]+__")) {
    throw "One or more template placeholders were not replaced."
}

[System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
$content = $content -replace "`r?`n", "`r`n"
[System.IO.File]::WriteAllText($outputPath, $content, [System.Text.UTF8Encoding]::new($false))

Write-Output $outputPath
