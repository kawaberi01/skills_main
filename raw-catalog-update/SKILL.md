---
name: raw-catalog-update
description: Refresh the NAS-backed RAW book catalog under `D:\00_main_work\raw_analysis` by rescanning `\\192.168.1.101\raw`, regenerating `catalog.html` and its JSON/CSV artifacts, and preserving incremental cache behavior. Use when Codex needs to update the local catalog after files were added, removed, or changed on the NAS, or when the user asks to rebuild the catalog outputs or inspect update deltas.
---

# Raw Catalog Update

## Overview

Update the local RAW catalog by running the existing build script, then verify the generated outputs and the latest delta summary. Reuse the incremental manifest; do not reintroduce AI-wide reclassification unless the user explicitly asks for it.

## Workflow

1. Confirm the working area exists:
   `D:\00_main_work\raw_analysis`
   `D:\00_main_work\tools\build_raw_catalog.ps1`

2. Run the catalog build command exactly:

```powershell
rtk powershell -ExecutionPolicy Bypass -File D:\00_main_work\tools\build_raw_catalog.ps1
```

3. Check that these outputs were regenerated:
   `D:\00_main_work\raw_analysis\catalog.html`
   `D:\00_main_work\raw_analysis\catalog_manifest.json`
   `D:\00_main_work\raw_analysis\catalog_data.json`
   `D:\00_main_work\raw_analysis\catalog_delta.json`
   `D:\00_main_work\raw_analysis\catalog_works.csv`

4. Read `catalog_delta.json` and report the counts for:
   `new`
   `changed`
   `unchanged`
   `deleted`

5. If the user is focused on the human-facing catalog, point them to:
   `D:\00_main_work\raw_analysis\catalog.html`

## Operating Rules

- Treat `catalog.html` as generated output. Edit `catalog_template.html` instead when layout changes are required.
- Treat `catalog_manifest.json` as the incremental cache. Keep it so unchanged works avoid reprocessing.
- Treat `catalog_overrides.json` as the manual metadata layer. Preserve it across rebuilds.
- Prefer reporting deltas from `catalog_delta.json` instead of manually diffing the full catalog.
- Do not rename NAS folders or ZIP files as part of this skill. That belongs to a separate cleanup phase.

## Troubleshooting

- If the catalog looks stale, rerun the build script before deeper investigation.
- If UI text looks wrong, inspect `D:\00_main_work\raw_analysis\catalog_template.html` and then regenerate.
- If the user asks whether a full AI pass is needed, answer no by default; only new or changed works should need further inspection.
- If output generation fails, report the failing command and stop at the first real blocker instead of guessing.
