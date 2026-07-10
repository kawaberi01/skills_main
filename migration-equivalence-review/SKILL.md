---
name: migration-equivalence-review
description: 移行元と移行先の処理同等性を最優先で確認し、移行漏れ、仕様差異、副作用差分、例外・リトライ・ログ差分をテンプレート形式でレビュー出力する。Use when the user asks for migration review, source-to-destination comparison, old Functions to isolated worker review, main diff review focused on migrated behavior, or output Markdown review files under .workstate\Review.
---

# Migration Equivalence Review

## Purpose

Use this skill to review whether migrated code preserves behavior from the old source. Treat architecture, namespace, DI, and formatting as secondary unless they affect behavior, production risk, or future migration-diff detection.

Priority:

1. Source/destination behavior equivalence.
2. Missing migrated logic, spec differences, and production-impacting behavior changes.
3. Differences in errors, return values, logs, side effects, external calls, DB updates, files, queues, mail, and retries.
4. Architecture boundaries, DI, namespaces, NuGet, folder layout.
5. Naming, readability, and minor cleanup.

## Required Input Block

Require the user request to provide these keys near the top:

```text
TARGET_NAME = TrackingCheckFunctions
OLD_SOURCE_PATH = .workstate\OldFunctions\CommonFunctions\TrackingCheckFunctions
EXPECTED_DESTINATION_HINT = TrackingCheck
REFERENCE_IMPLEMENTATION_PATH = src\Functions\iDrugStore.Functions\CancelOrder
```

Treat values as literal strings. If `REFERENCE_IMPLEMENTATION_PATH` is omitted, use `src\Functions\iDrugStore.Functions\CancelOrder`.

Do not infer `TARGET_NAME`, `OLD_SOURCE_PATH`, or `EXPECTED_DESTINATION_HINT` from branch names, local filenames, existing review reports, changed files, commit messages, repository history, or `.workstate` contents. If any required key is missing from the current user request, ask the user first and stop before running migration review commands, git diff inspection for review, broad source/destination searches, or output-file creation.

## Stop Conditions

Before creating files, stop and ask the user when any of these are true:

- `TARGET_NAME` is missing.
- `OLD_SOURCE_PATH` is missing.
- `EXPECTED_DESTINATION_HINT` is missing.
- `TARGET_NAME` clearly conflicts with `OLD_SOURCE_PATH`.
- `EXPECTED_DESTINATION_HINT` clearly points to a different feature.
- The main diff's primary subject clearly conflicts with `TARGET_NAME`.
- Multiple plausible destinations exist and the correct one cannot be inferred safely.

Use this question format:

```md
指示に矛盾があるため確認させてください。

- 冒頭の TARGET_NAME: `...`
- 冒頭の OLD_SOURCE_PATH: `...`
- EXPECTED_DESTINATION_HINT: `...`
- main 差分で確認した主な対象: `...`
- 判断不能な内容: `...`

どの対象をレビューすればよいですか？
```

Do not create review result files until the user resolves the contradiction.

## Workflow

1. Parse the input block.
   - If `TARGET_NAME`, `OLD_SOURCE_PATH`, or `EXPECTED_DESTINATION_HINT` is absent, stop immediately and ask for the missing values.
   - Do not continue by guessing from local artifacts, branch names, main diff, or `.workstate` paths.
2. Confirm workspace and branch:
   - `git rev-parse --show-toplevel`
   - `git branch --show-current`
   - `git merge-base HEAD main`
   - `git diff --name-status main...HEAD`
   - `git diff --stat main...HEAD`
3. Read docs `.\docs\001-*` through `.\docs\004-*`.
4. Confirm `OLD_SOURCE_PATH` exists.
5. Read only `OLD_SOURCE_PATH` first. Do not broadly search `.workstate\OldFunctions` until source calls require it.
6. Trace source calls only when directly referenced:
   - common logic
   - gateway/repository
   - utility/extension
   - mail, DB, file, blob, queue, timer, HTTP trigger
   - external API
   - retry/notification
   - enum/const/settings
7. Identify destination by this priority:
   - changed files in main diff matching `TARGET_NAME` or `EXPECTED_DESTINATION_HINT`
   - `.workstate\src` matching `TARGET_NAME` or `EXPECTED_DESTINATION_HINT`
   - `src` matching `TARGET_NAME` or `EXPECTED_DESTINATION_HINT`
8. Inventory source and destination with the same categories.
9. Build an equivalence matrix before writing findings.
10. Review design/placement only after behavior comparison.
11. Create a new folder:
    - `.workstate\Review\{TARGET_NAME}Review_YYYYMMDD_HHMMSS`
12. Generate all required Markdown files from assets templates.
13. Run the validation script:
    - `.\scripts\validate_review_output.ps1 -ReviewDir "<created folder>"`

## Inventory Categories

Use these categories in source and destination inventories:

- Function list.
- Trigger type, function name, route, HTTP method.
- Input model, required fields, validation.
- Output model, success/failure response shape.
- Major called methods.
- Application/use case/service calls.
- Infrastructure/gateway calls.
- Conditions and branches.
- Loops, ordering, termination conditions.
- Exception handling.
- Logs.
- External HTTP URL, method, query/form/header, encoding, HTML selector.
- DB updates, file operations, blob operations, mail, queue output, notifications.
- Enum, const, settings keys, connection string keys.

## Equivalence Checks

Check especially:

- Every source Function exists in destination.
- Every source public/private method's behavior has a destination equivalent.
- Trigger type, function name, route, and HTTP method match.
- Input/output model fields, types, required rules, and validation match.
- Normal processing order matches.
- Branch conditions, comparison values, thresholds match.
- Loop counts, termination, ordering, target data match.
- Enum values, order, string representation, DisplayName match.
- Const values, URLs, queue names, blob paths, settings keys match.
- External API URL, method, query, form values, headers, encoding, selectors match.
- Retry count, delay, and final failure behavior match.
- Exception swallow/rethrow, return value, messages, and logs match.
- Side effects are not missing.
- Shared source helper calls have equivalent destination implementation.

Classify differences as:

- `移行漏れ`
- `仕様差異`
- `意図的変更か判断不能`
- `設計上の改善だが挙動影響なし`
- `未確認`
- `差異なし`

## Output Templates

Always use these templates:

- `assets/review-result.template.md` -> `review-result.md`
- `assets/review-comments.template.md` -> `review-comments.md`
- `assets/source-inventory.template.md` -> `source-inventory.md`
- `assets/destination-inventory.template.md` -> `destination-inventory.md`
- `assets/equivalence-matrix.template.md` -> `equivalence-matrix.md`

Do not delete template headings. If no content applies, write `該当なし`. If evidence cannot be checked, write `未確認`, `確認不可`, or `対応不明`.

## Comment Policy

`review-comments.md` is for PR/chat-ready comments. Include only meaningful findings. Do not include minor formatting preferences unless they affect migration equivalence or production risk.

## Severity

- Critical: migration omission, clear spec difference, or production-impacting behavior change.
- Major: design/boundary issue affecting maintainability, or a gap that blocks future migration-diff detection.
- Minor: naming, readability, light cleanup.

## Validation

After writing files, run:

```powershell
.\scripts\validate_review_output.ps1 -ReviewDir "<created folder>"
```

If validation fails, fix only missing files/headings and run again. Do not alter findings merely to satisfy the script.
