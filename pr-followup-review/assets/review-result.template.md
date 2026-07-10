# {TARGET_NAME} PR フォローアップレビュー結果

## レビュー概要
- 対象: `{TARGET_NAME}`
- PR: `{PR_URL}`
- ブランチ: `{BRANCH_NAME}`
- 比較先: `main`
- merge-base: `{MERGE_BASE}`
- 変更ファイル数: `{CHANGED_FILE_COUNT}`
- コミット数: `{COMMIT_COUNT}`
- 最終判定: `{FINAL_DECISION}`

## 確認した範囲
{CHECKED_SCOPE}

## 参照した PR
- `{PR_URL}`
- PR コメント取得可否: `{PR_COMMENT_FETCH_STATUS}`

## PR コメント取得可否
{PR_COMMENT_FETCH_DETAIL}

## 参照した資料
{REFERENCES}

## main 差分の概要
{MAIN_DIFF_SUMMARY}

## PR 未クローズ指摘の対応状況一覧
| No | PR 指摘概要 | 対象ファイル | 状態 | 確認結果 | 根拠 |
|---:|---|---|---|---|---|
| 1 | {COMMENT_SUMMARY} | {TARGET_FILE} | {STATUS} | {CHECK_RESULT} | {EVIDENCE} |

## 動作確認ガイドに沿った確認形跡
{VERIFICATION_EVIDENCE}

## 設計境界の確認結果
{BOUNDARY_RESULT}

## namespace の確認結果
{NAMESPACE_RESULT}

## NuGet / ProjectReference の確認結果
{NUGET_RESULT}

## DI 登録の確認結果
{DI_RESULT}

## CancelOrder 実装との整合性確認結果
{REFERENCE_IMPLEMENTATION_RESULT}

## 指摘一覧

### Critical
{CRITICAL_FINDINGS}

### Major
{MAJOR_FINDINGS}

### Minor
{MINOR_FINDINGS}

## 修正推奨内容
{RECOMMENDATIONS}

## 未確認事項
{UNCONFIRMED_ITEMS}
