---
name: raw-enrichment-publish
description: Rebuild and verify the local RAW HTML catalog using trusted enrichment cache records. Use when Codex needs to publish approved summaries and images into catalog.html, verify the visible coverage, or report catalog update deltas.
---

# RAW Enrichment Publish

Treat `catalog.html` as generated output. The current publisher is `D:\00_main_work\tools\build_raw_catalog.ps1`; it reads the enrichment cache and also rescans the NAS.

## Workflow

1. Confirm the cache contains only records intended for publication. The catalog builder exposes enrichment only for successful high-confidence records.
2. Run:

```powershell
rtk powershell -ExecutionPolicy Bypass -File D:\00_main_work\tools\build_raw_catalog.ps1
```

3. Verify `catalog.html`, `catalog_data.json`, `catalog_manifest.json`, `catalog_delta.json`, and `catalog_works.csv` were regenerated.
4. Report the NAS delta from `catalog_delta.json` and the count of catalog rows with an exposed summary or image.
5. Check a small sample of approved items in `catalog.html`; do not modify generated HTML by hand.

## Boundaries

- Keep `catalog_manifest.json`, `catalog_overrides.json`, and `enrichment_cache.json` intact.
- Do not publish medium/low confidence records just to increase coverage.
- Do not rename NAS folders or ZIP files.
