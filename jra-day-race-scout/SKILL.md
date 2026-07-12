---
name: jra-day-race-scout
description: Scout all JRA races for a specified day through the local API and return up to five races for later detailed prediction. Use when the user asks for an early-morning JRA day overview, races worth revisiting, or candidates before the first race; do not use it to generate or save betting tickets.
---

# JRA Day Race Scout

## Workflow

1. Confirm the target date. Use the server date when the user says today.
2. Call the local API once:

   `POST http://127.0.0.1:8000/jra/days/{YYYY-MM-DD}/race-scout?max_candidates=5&refresh=false&max_concurrency=3`

3. If the API is unreachable, report that the local API must be started. Do not scrape JRA or substitute guessed meeting coordinates.
4. Treat `provisional_value` only as an early value signal requiring a later check. Never call it a confirmed buy or wager.
5. Do not create, display, or save tickets from this scout response.
6. For each candidate, show rank, course, race number, race name, start time, grade, signals, short reasons, and whether recheck is required.
7. Summarize X entries and API errors separately without inventing missing values.
8. Recommend running `$jra-race-predictor` near post time for detailed prediction of selected races.

## Fixed Output

Return concise Japanese text in this order:

- `実行状況`: date, observed time, status, analyzed/total races.
- `詳細予想候補`: at most five candidates in API order.
- `除外・取得エラー`: only when entries or errors require attention.
- `再確認`: state that odds/value are provisional and name the races to pass to `$jra-race-predictor`.

If `status=unavailable`, explain the API-provided reason and stop. If `status=partial`, keep valid candidates and clearly identify failed components.
