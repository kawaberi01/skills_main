---
name: daily-prediction-log
description: Create and maintain a daily Markdown log for horse-racing predictions, questions, buy plans, result notes, and retrospectives. Use when the user wants to preserve raw prediction history across thread compression, continue the same betting day from multiple threads, or accumulate a day-by-day source log for later analysis.
---

# Daily Prediction Log

## Overview

Preserve the user's betting-day reasoning as a raw local source file, not just as chat history.
Prefer appending timestamped entries over rewriting past decisions.

## Workflow

1. Determine the log target.
2. Create the daily Markdown file if it does not exist.
3. Append a new timestamped block for each meaningful exchange.
4. Keep the log raw enough for later analysis.

## Log Target

Default to a workspace-local `notes/` directory.

File naming rules:

- If the venue is known, use `YYYY-MM-DD_<venue>_predictions.md`
- Otherwise use `YYYY-MM-DD_predictions.md`
- Reuse the same file for the whole day

Examples:

- `notes/2026-07-08_kawasaki_predictions.md`
- `notes/2026-07-08_predictions.md`

If the user explicitly chooses another path, follow that path instead.

## Entry Rules

Append a new block whenever one of these happens:

- A prediction is requested
- A buy plan changes
- The user asks a question that affects betting judgment
- A result or retrospective note is added
- The daily logging policy changes

Never silently replace older judgment with the new one. Append the new state with a timestamp.

When this skill is active, update the local log file in the same turn as the thread response whenever the exchange affects the betting-day record.

## Content Rules

Keep the log as a source record, not a polished report.

Always preserve:

- Timestamp
- Entry type
- Race or topic
- Prediction mode if relevant
- Materials used or missing
- Core reasoning
- Proposed buy plan if any
- Cautions, uncertainties, or later reversals

Prefer short bullets over long prose inside the file.

## Initialization Template

When creating a new daily file, initialize it with these sections:

```md
# YYYY-MM-DD [venue] 予想ログ

## 運用方針
- 目的:
- 性格: 生ログ寄り
- 記録対象:
- 更新単位:

## 当日メモ
- 日付:
- 場:
- ログ開始:
- 方針:

## ログ

## 回顧用メモ欄
- 実際に買った券種・金額:
- 的中/不的中:
- レース後の感想:
- 次に修正したい点:
```

After initialization, append entries under `## ログ`.

## Entry Template

Use this shape as the default fixed template. Do not vary headings casually.

```md
### YYYY-MM-DD HH:MM:SS
- 種別:
- 対象:
- 内容:
  - ...
- メモ:
  - ...
```

For race predictions, use this fixed template.

```md
### YYYY-MM-DD HH:MM:SS
- 種別: 事前予想
- 対象: [venue] [race]
- 予想モード:
- 使用データ:
  - ...
- 予想順位:
  - ...
- 判断要旨:
  - ...
- 買い方:
  - ...
- 注意点:
  - ...
```

For non-prediction thread exchanges that still matter to the day's reasoning, use this fixed template.

```md
### YYYY-MM-DD HH:MM:SS
- 種別: 質問 / 方針変更 / 回顧 / 結果 / 運用
- 対象:
- 内容:
  - ...
- 判断への影響:
  - ...
- メモ:
  - ...
```

If the user asks to standardize output, prefer these exact labels both in the thread and in the file.

## Thread Response Rule

When replying in the thread, mirror the same structure as much as practical.

Priority order:

1. Update the local daily file
2. Keep the thread response aligned with the same template
3. Preserve raw reasoning and changes

If the thread response is shorter than the file entry, keep the file as the fuller source of truth.

## Operating Principles

- Favor raw history over cleanup
- Keep old mistakes visible
- Record missing data explicitly
- Treat later corrections as new entries, not edits to history
- Perform the local file update in the same turn as the response
