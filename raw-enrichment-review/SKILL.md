---
name: raw-enrichment-review
description: Triage uncertain, failed, or duplicate candidate metadata in the RAW book enrichment cache. Use when Codex needs to inspect medium or low confidence matches, not-found records, API errors, or duplicate-title candidates before approving catalog display.
---

# RAW Enrichment Review

Review results without changing NAS names or archive contents. Work from `enrichment_cache.json`, a batch result JSON, and `catalog_data.json`.

## Review Rules

1. Group records by `fetchStatus`, `fetchConfidence`, provider, and translation status.
2. Require a high-confidence title match before automatic publication.
3. For medium/low matches, compare source title, source URL, author, title normalization, and summary subject. Do not approve a match from title similarity alone.
4. For `not-found`, classify the cause as title noise, missing provider data, or likely unavailable work.
5. For errors, retain the error and retry only transient failures such as HTTP 429 or 503.
6. Treat identical normalized titles as separate works unless author and source match support reuse.

## Output

Produce a concise review report with approved IDs, rejected IDs, deferred IDs, reason, source URL, and required title/author correction. Store manual decisions in a dedicated review or override file; do not edit generated HTML directly.

## Boundaries

- Do not call external APIs unless the user explicitly asks to retry an approved correction.
- Do not overwrite successful high-confidence cache records.
- Do not make rename decisions; file and folder normalization is a separate phase.
