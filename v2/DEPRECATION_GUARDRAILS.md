# Deprecation Guardrails

This workspace includes a lightweight guardrail to track API surface drift and potential deprecation candidates.

## What it checks

- Frontend API wrappers exported from `v2/frontend/src/api/endpoints.ts`
- Wrapper usage across `v2/frontend/src/**/*.tsx`
- Backend routes defined in `v2/backend/routers/*.py`
- Route mappings that are not represented by frontend wrappers

## Run

From repo root:

`node v2/scripts/deprecation_guardrail.mjs`

## Output

- Generates `v2/DEPRECATION_GUARDRAIL_REPORT.md`
- Report contains:
  - summary counts,
  - unused frontend wrappers,
  - backend routes not mapped by frontend wrappers,
  - review notes.

## Suggested cadence

- Run once per sprint (or before release hardening).
- Review each flagged item as one of:
  - keep (intended backend-only path),
  - wire (missing UI integration),
  - deprecate/remove.
