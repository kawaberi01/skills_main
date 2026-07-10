---
name: pr-followup-review
description: PR 初回レビュー指摘の対応状況を再確認し、未クローズ指摘ごとの対応表、詳細指摘、短い再指摘コメントをテンプレート形式で出力する。Use when the user asks to verify whether Azure DevOps PR review comments were addressed, perform PR follow-up review, check unresolved review comments, or create re-review Markdown files under .workstate\Review.
---

# PR Follow-up Review

## Purpose

Use this skill for PR follow-up review after initial comments were added. Do not perform a full new review unless a new issue is directly caused by the follow-up changes or affects production behavior.

Priority:

1. Verify unresolved PR comments from `PR_URL`.
2. Check whether each comment's root cause is fixed.
3. Check whether similar issues remain nearby.
4. Check whether the fix introduces regressions or unnecessary diff from `main`.
5. Check whether verification evidence exists according to `REVIEW_GUIDE_PATH`.

## Required Input Block

Require the user request to provide these keys near the top:

```text
TARGET_NAME = BlobFunctions
PR_URL = https://dev.azure.com/.../pullrequest/6275
REVIEW_GUIDE_PATH = .\docs\005-動作確認ガイド.md
REFERENCE_IMPLEMENTATION_PATH = .workstate\src\Functions\iDrugStore.Functions\CancelOrder
```

Treat values as literal strings. If `REFERENCE_IMPLEMENTATION_PATH` is omitted, use `.workstate\src\Functions\iDrugStore.Functions\CancelOrder`.

Do not infer `TARGET_NAME`, `PR_URL`, or `REVIEW_GUIDE_PATH` from branch names, local filenames, existing review reports, PR IDs embedded in filenames, commit messages, or repository history. If any required key is missing from the current user request, ask the user first and stop before running PR lookup commands, Azure DevOps commands, git diff inspection for review, or output-file creation.

## Stop Conditions

Before creating files, stop and ask the user when any of these are true:

- `TARGET_NAME` is missing.
- `PR_URL` is missing.
- `REVIEW_GUIDE_PATH` is missing or does not exist.
- `TARGET_NAME` clearly conflicts with the main diff's primary subject.
- `PR_URL` clearly points to a different repository than the current workspace remote.
- PR comments cannot be checked and the user did not allow proceeding with local-only evidence.

Use this question format:

```md
指示に矛盾または確認不能な点があります。

- TARGET_NAME: `...`
- PR_URL: `...`
- REVIEW_GUIDE_PATH: `...`
- main 差分で確認した主な対象: `...`
- 確認不能な内容: `...`

どの前提で再レビューすればよいですか？
```

## Workflow

1. Parse the input block.
   - If `TARGET_NAME`, `PR_URL`, or `REVIEW_GUIDE_PATH` is absent, stop immediately and ask for the missing values.
   - Do not continue by guessing from local artifacts such as `PR_*.md` files.
2. Confirm the workspace root and current branch:
   - `git rev-parse --show-toplevel`
   - `git branch --show-current`
   - `git remote -v`
3. Compare with `main`:
   - `git merge-base HEAD main`
   - `git diff --name-status main...HEAD`
   - `git diff --stat main...HEAD`
4. Read `REVIEW_GUIDE_PATH`.
5. Read docs `.\docs\001-*` through `.\docs\004-*` only as needed.
6. Read `REFERENCE_IMPLEMENTATION_PATH` only when PR comments or changed files require pattern comparison.
7. Inspect `PR_URL` and identify unresolved review comments only.
   - Prefer Azure DevOps MCP tools when available for Azure DevOps PR / repository / project reads.
   - Before falling back to `az repos` / `az devops invoke`, check whether an Azure DevOps MCP tool is available through tool discovery.
   - Use CLI fallback only when the MCP tools cannot retrieve the required PR detail, review thread state, inline comments, or repository context.
   - Exclude closed/resolved/completed comments.
   - If state cannot be determined, mark `状態不明`.
   - If comments cannot be retrieved, mark `PR コメント確認不可` and stop unless the user permitted local-only continuation.
8. For each unresolved comment, compare:
   - original pointed file/line/method
   - current diff
   - nearby similar code
   - tests and verification evidence
9. Create a new folder:
   - `.workstate\Review\{TARGET_NAME}PrFollowupReview_YYYYMMDD_HHMMSS`
10. Generate all required Markdown files from assets templates.
11. Run the validation script:
   - `.\scripts\validate_review_output.ps1 -ReviewDir "<created folder>"`

## Output Templates

Always use these templates:

- `assets/review-result.template.md` -> `review-result.md`
- `assets/review-comments.template.md` -> `review-comments.md`
- `assets/pr-comment-checklist.template.md` -> `pr-comment-checklist.md`
- `assets/pr-recheck-comments.template.md` -> `pr-recheck-comments.md`

Do not delete template headings. If no content applies, write `該当なし`. If evidence cannot be checked, write `確認不可`, `対応不明`, or `PR コメント確認不可`.

## Status Labels

Use only these statuses for PR comments:

- `対応済み`
- `一部対応`
- `未対応`
- `対応不明`
- `確認不可`
- `状態不明`

Use `確認記録不足` only for missing verification evidence; keep it separate from code defects.

## Comment Output Policy

- `review-result.md`: full report.
- `pr-comment-checklist.md`: one row/section per unresolved PR comment.
- `review-comments.md`: detailed comments for non-OK items.
- `pr-recheck-comments.md`: short re-comment text for PR posting.

Do not include `対応済み` items in `review-comments.md` or `pr-recheck-comments.md` unless there is residual risk that must be posted.

`pr-recheck-comments.md` comments must be short: 3 to 6 lines per item.

## Severity

- Critical: unresolved PR comment, clear spec difference, or production-impacting regression.
- Major: partially resolved comment, design boundary issue, maintainability issue that affects the fix, or lack of evidence that blocks confidence.
- Minor: naming, readability, light cleanup, or verification-record gap.

## Validation

After writing files, run:

```powershell
.\scripts\validate_review_output.ps1 -ReviewDir "<created folder>"
```

If validation fails, fix only missing files/headings and run again. Do not alter findings merely to satisfy the script.
