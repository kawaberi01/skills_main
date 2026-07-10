param(
    [Parameter(Mandatory = $true)]
    [string]$ReviewDir
)

$requiredFiles = @(
    "review-result.md",
    "review-comments.md",
    "pr-comment-checklist.md",
    "pr-recheck-comments.md"
)

foreach ($file in $requiredFiles) {
    $path = Join-Path $ReviewDir $file
    if (-not (Test-Path $path)) {
        throw "Required file missing: $file"
    }
}

$reviewResultPath = Join-Path $ReviewDir "review-result.md"
$reviewResult = Get-Content $reviewResultPath -Raw

$requiredHeadings = @(
    "## レビュー概要",
    "## 確認した範囲",
    "## 参照した PR",
    "## PR コメント取得可否",
    "## main 差分の概要",
    "## PR 未クローズ指摘の対応状況一覧",
    "## 動作確認ガイドに沿った確認形跡",
    "## 指摘一覧",
    "## 未確認事項"
)

foreach ($heading in $requiredHeadings) {
    if (-not $reviewResult.Contains($heading)) {
        throw "Required heading missing in review-result.md: $heading"
    }
}

$checklist = Get-Content (Join-Path $ReviewDir "pr-comment-checklist.md") -Raw
if (-not $checklist.Contains("## 対応状況一覧")) {
    throw "Required heading missing in pr-comment-checklist.md: ## 対応状況一覧"
}

$shortComments = Get-Content (Join-Path $ReviewDir "pr-recheck-comments.md") -Raw
if (-not $shortComments.Contains("## 再指摘コメント")) {
    throw "Required heading missing in pr-recheck-comments.md: ## 再指摘コメント"
}

Write-Output "Review output validation passed."
