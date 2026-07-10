---
name: raw-enrichment-fetch
description: Fetch and cache book summaries, representative images, and optional Japanese translations for a prepared RAW catalog queue. Use when Codex needs to run Kitsu, Wikipedia, DeepL, or Google Cloud enrichment for a small controlled batch and record results safely.
---

# RAW Enrichment Fetch

This is the only RAW catalog skill that makes external requests or uses translation keys. Work in `D:\00_main_work\raw_analysis\enrichment`.

## Preconditions

- Read `translation_config.json` and `translation_usage.json` without printing keys.
- Confirm the candidate queue contains only intended work IDs.
- Use a dedicated results and summary path for non-default queues.
- Keep the default maximum at 50 items. Do not launch a full-library run.

## Run

Use the wrapper because it loads persisted Windows API-key environment variables before `uv` starts Python. For a resumable batch, use its run ID rather than an ad hoc queue path.

```powershell
rtk powershell -ExecutionPolicy Bypass -File D:\00_main_work\tools\run_raw_enrichment.ps1 --run-id <run-id>
```

The runner stores its fixed manifest, event log, result, report, lock, and checkpoint state under `runs/<run-id>/`. Re-run the same command after an interruption; do not create a new manifest.

Use the queue-path form only for one-off tests:

```powershell
rtk powershell -ExecutionPolicy Bypass -File D:\00_main_work\tools\run_raw_enrichment.ps1 --queue <queue.json> --results <results.json> --summary <results.md>
```

The default queue is `latest_candidates.json`. The script updates `enrichment_cache.json` by work ID and tracks translation use in `translation_usage.json`.

## Validate

Report counts for `success`, `not-found`, and `error`; high/medium/low confidence; Japanese summaries; translated summaries; images; and each translation provider's character usage.

Treat HTTP 429 and 503 as temporary failures. Do not immediately rerun the same queue. Record the affected IDs for a later retry after a backoff period.

## Boundaries

- Prefer Japanese source summaries. Translate only when no Japanese prose summary is available.
- Do not print, commit, or write API keys.
- Do not mark medium/low confidence results as approved. Send them to `raw-enrichment-review`.
- Preserve successful cached results; do not force-refresh them without an explicit request.
