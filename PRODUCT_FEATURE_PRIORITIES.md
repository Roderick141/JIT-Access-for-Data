## Purpose

This is a prioritized feature roadmap to evolve this project from a “JIT access request + approval + grant issuance” tool into a **data access governance platform** comparable (feature-wise) to leading vendors (e.g., Microsoft Purview and other Gartner-category competitors).

Prioritization is based on **added product value** (adoption, risk reduction, operational efficiency) and typical enterprise expectations for a data access governance tool.

---

## Current baseline (what this repo is already strong at)

- **JIT access workflow**: request → approve/deny → issue grant → expire grant
- **Role catalog** (requestable roles) and eligibility rules
- **Approver & steward/admin views**
- **Audit logging** (foundation for compliance evidence)

The biggest gaps vs market leaders are **automated discovery/metadata**, **policy-based access**, **connector architecture**, **enterprise integrations**, and **operational governance loops** (certifications, SoD, analytics, lifecycle).

---

## Priority 0 (highest impact, foundational “platform” upgrades)

### 1) Source scanning + metadata harvesting (schema, objects, ownership)
**What**: Scan connected sources (DWH/DBs) to ingest:
- databases/schemas/tables/views/columns
- data types, nullability, keys, constraints, row counts (optional)
- owners/stewards, tags, descriptions (where available)

**Why it matters**: Without discovery + metadata, access requests stay “role-name based” and users can’t reliably request access to *data products*, *datasets*, or *specific objects*.

**Minimum viable shape**:
- A “Scanner” job (scheduled + on-demand) per source
- Metadata store tables for assets + schema snapshots
- UI pages to browse/search assets

### 2) Pluggable connector architecture (multiple data source types)
**What**: Redesign backend data access layer so adding a connector doesn’t require rewriting business logic.

**Why it matters**: Enterprise environments have multiple platforms (SQL Server, Snowflake, Databricks, Synapse, Postgres, BigQuery, etc.). Purview-class tools win by connecting broadly.

**Implementation direction**:
- Define an interface like `Connector` with capabilities:
  - `scan_metadata()`
  - `grant_access(policy_or_entitlement)`
  - `revoke_access(grant)`
  - optional: `validate_principal()`, `list_entitlements()`, `test_connection()`
- Add a connector registry + config table
- Start with **SQL Server connector** (existing), then expand

### 3) Policy model upgrade: from “roles” to “assets + entitlements”
**What**: Introduce a normalized model:
- **Data Assets** (discovered objects)
- **Entitlements** (what access means: read, write, execute, row-filtered, etc.)
- **Policies** mapping users/teams/attributes → entitlements with constraints (time-bound, justification, ticket)

**Why it matters**: Market leaders are policy-first. Roles are a useful UX wrapper, but governance needs explicit asset/entitlement semantics.

### 4) Strong identity integration + lifecycle
**What**:
- Integrate with enterprise IdP (Entra ID/Azure AD, Okta, etc.)
- Support groups, service principals, managed identities
- Automated provisioning/deprovisioning signals

**Why it matters**: Governance platforms are judged on how well they fit identity lifecycle and reduce manual admin work.

**MVP**:
- Sync users and groups (SCIM or Graph API)
- Request access for **group membership** as a first-class target (common in enterprises)

### 5) End-to-end audit & evidence quality (compliance ready)
**What**:
- Durable, queryable audit events for: request, approval, policy decision, grant issued, revoke, expiry, exceptions
- Exportable evidence packs (time range, user, asset, approver)
- Tamper-evident logging (append-only, hash chaining optional)

**Why it matters**: A major buying driver is compliance and reducing audit pain.

---

## Priority 1 (major differentiators that drive adoption and trust)

### 6) Data classification + sensitivity labeling
**What**:
- Automated classification rules (PII, PCI, PHI, secrets)
- Manual override + steward curation
- Sensitivity drives policy (extra approval, shorter durations, ticket required)

**Why it matters**: Purview and peers heavily emphasize classification because it ties directly to risk.

### 7) Lineage (technical + logical) and impact analysis
**What**:
- Capture lineage between tables/views/jobs (where possible)
- Show “upstream/downstream” dependencies

**Why it matters**: Access decisions and incident response depend on understanding what a dataset contains and influences.

### 8) Access reviews / certifications (recertification campaigns)
**What**:
- Periodic reviews: “Does user X still need access Y?”
- Reviewer workflows (manager/steward)
- Auto-revoke on non-response (configurable)

**Why it matters**: This is a core governance loop in mature organizations.

### 9) Segregation of Duties (SoD) + conflict detection
**What**:
- Define incompatible entitlements (e.g., “ETL write” vs “Finance close approval”)
- Prevent or require escalation for conflicting access

**Why it matters**: SoD is a common audit requirement and a strong enterprise differentiator.

### 10) Fine-grained access controls (FGAC): row/column filtering & masking
**What**:
- Policies that enforce row filters, column masking, dynamic data masking
- Support multiple implementations depending on platform (views, RLS policies, masking functions)

**Why it matters**: Vendors win by enabling least-privilege without exploding role counts.

---

## Priority 2 (scale, reliability, and enterprise operability)

### 11) Workflow engine: configurable approvals, escalations, SLAs
**What**:
- Multi-step approvals (owner → steward → security)
- Escalation, reminders, SLA tracking
- Delegation and out-of-office handling

### 12) High-scale job system for scanning + grant enforcement
**What**:
- Background jobs (queue) for: scans, provisioning, expirations, retries
- Observability: job status, retries, dead-letter, alerting

### 13) Reliability/operability: monitoring, metrics, tracing
**What**:
- Metrics: request volume, approval time, failures, connector health
- Tracing for provisioning actions
- Alerting hooks (email/Teams/Slack)

### 14) Multi-tenant / multi-domain governance model
**What**:
- Separate “domains” or “business units” with delegated admins/stewards
- Domain-scoped policies and catalogs

### 15) Reporting & analytics for governance KPIs
**What**:
- Access risk dashboards (sensitive asset exposure)
- Over-privilege indicators
- “Top approvers”, “approval latency”, “policy violations”

---

## Priority 3 (product maturity, ecosystem, and UX)

### 16) Catalog UX parity: search, facets, glossary, ownership, stewardship
**What**:
- Search across assets, columns, tags, glossary terms
- Facets (domain, sensitivity, source, owner, system)
- Business glossary + term-to-asset mapping

### 17) “Request access” UX upgrade: guided requests and bundling
**What**:
- Request access to a **data product** (bundle of assets)
- Suggested access based on role/team/project
- Justification templates, ticket integration, approval previews

### 18) API-first + automation hooks
**What**:
- Public API for requests, approvals, assets, policies
- Webhooks/events for ITSM, SIEM, data platform automation

### 19) Developer integration: IaC for policies & catalog
**What**:
- Treat policies/entitlements as code (GitOps)
- Validate policy changes in CI

### 20) Privacy/security hardening
**What**:
- Secrets management (Key Vault / Vault)
- Key rotation, encryption at rest, least-privilege service accounts
- Threat modeling and secure defaults

---

## Suggested “next 90 days” plan (highest ROI sequence)

### Phase A: make access governance asset-aware
- Implement **metadata scanning for SQL Server**
- Add **asset catalog tables** + minimal browse/search UI
- Introduce **entitlements** and map existing “roles” to entitlements

### Phase B: make it extensible and enterprise-ready
- Add **connector interface + registry**
- Implement background job runner for scanning/provisioning
- Upgrade audit events for compliance evidence quality

### Phase C: add governance features that buyers expect
- Classification + sensitivity labeling
- Access reviews/certifications
- Workflow configurability (multi-step approvals, SLAs)

---

## Notes / design principles (to stay competitive)

- **Policy-first** (assets + entitlements + constraints), with roles as optional UX abstraction.
- **Connector-driven** backend with consistent provisioning semantics.
- **“Evidence by default”**: every decision and action is auditable.
- **Operate at scale**: async jobs + retries + observability, not synchronous request/response.

---

## Implementation hygiene / deprecation candidates

- **Approver request detail endpoint** `GET /api/approver/requests/{request_id}` is currently a **deprecation candidate**:
  - Current approver UI is fully supported by `GET /api/approver/pending`.
  - Detail endpoint provides limited additional value today and is not wired in active UI flows.
  - Keep temporarily for optional future drill-down; remove if no drill-down feature is planned.

- **Automated guardrail:** run `node v2/scripts/deprecation_guardrail.mjs` once per sprint to generate `v2/DEPRECATION_GUARDRAIL_REPORT.md` and review unused wrappers/routes before removals.

