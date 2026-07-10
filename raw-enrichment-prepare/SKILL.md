---
name: raw-enrichment-prepare
description: Prepare a bounded, incremental web-enrichment queue for the RAW NAS book catalog. Use when Codex needs to select unprocessed books by recency or batch size, inspect enrichment coverage, or create the next safe candidate queue without calling external APIs.
---

# RAW Enrichment Prepare

Work under `D:\00_main_work\raw_analysis\enrichment`. Read `catalog_data.json` and `enrichment_cache.json`; do not call web APIs or alter NAS files.

## Workflow

1. Confirm `catalog_data.json` is current. If NAS content changed, invoke `raw-catalog-update` first.
2. Count valid titled works, cached IDs, and cache statuses. Exclude empty titles.
3. Select only uncached items. Keep `not-found` and `error` records out of automatic retries unless the user asks to retry them.
4. For a latest-10 trial, run:

```powershell
rtk powershell -ExecutionPolicy Bypass -File D:\00_main_work\tools\build_raw_enrichment_seed.ps1
```

5. For a resumable batch, create an immutable run manifest. Never overwrite `latest_candidates.json` without an explicit request.

```powershell
rtk powershell -ExecutionPolicy Bypass -File D:\00_main_work\tools\build_raw_enrichment_queue.ps1 -Count 25 -QueuePath D:\00_main_work\raw_analysis\enrichment\runs\<run-id>\run_manifest.json
```
6. Deduplicate external queries only when normalized title and normalized author agree. Keep each catalog work ID in the queue so results remain traceable.
7. Write a small batch preview with item count, titles, selection rule, skipped cache statuses, and the intended output paths.

## Boundaries

- Default maximum is 25 items until the user explicitly approves a larger verified batch.
- Do not alter `enrichment_cache.json`; `raw-enrichment-fetch` owns cache updates.
- Do not expose API keys or modify `translation_usage.json`.
