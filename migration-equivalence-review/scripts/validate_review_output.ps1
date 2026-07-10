param(
    [Parameter(Mandatory = $true)]
    [string]$ReviewDir
)

$requiredFiles = @(
    "review-result.md",
    "review-comments.md",
    "source-inventory.md",
    "destination-inventory.md",
    "equivalence-matrix.md"
)

foreach ($file in $requiredFiles) {
    $path = Join-Path $ReviewDir $file
    if (-not (Test-Path $path)) {
        throw "Required file missing: $file"
    }
}

$reviewResult = Get-Content (Join-Path $ReviewDir "review-result.md") -Raw
$requiredReviewHeadings = @(
    "## レビュー概要",
    "## 指示整合性チェック結果",
    "## 確認した範囲",
    "## main 差分の概要",
    "## 移行元処理の棚卸し",
    "## 移行先処理の棚卸し",
    "## 移行元と移行先の処理対応表",
    "## 移行漏れ確認結果",
    "## 仕様差異確認結果",
    "## 副作用の確認結果",
    "## 例外処理・リトライ・ログの同等性確認結果",
    "## 指摘一覧",
    "## 未確認事項"
)

foreach ($heading in $requiredReviewHeadings) {
    if (-not $reviewResult.Contains($heading)) {
        throw "Required heading missing in review-result.md: $heading"
    }
}

$matrix = Get-Content (Join-Path $ReviewDir "equivalence-matrix.md") -Raw
if (-not $matrix.Contains("## 対応表")) {
    throw "Required heading missing in equivalence-matrix.md: ## 対応表"
}

$source = Get-Content (Join-Path $ReviewDir "source-inventory.md") -Raw
if (-not $source.Contains("## Function 一覧")) {
    throw "Required heading missing in source-inventory.md: ## Function 一覧"
}

$destination = Get-Content (Join-Path $ReviewDir "destination-inventory.md") -Raw
if (-not $destination.Contains("## Function 一覧")) {
    throw "Required heading missing in destination-inventory.md: ## Function 一覧"
}

Write-Output "Migration equivalence review output validation passed."
