# DevFlow Engineering Standards: Data Persistence (Technology-Agnostic)

> **Version:** 1.0.0 | **Last Updated:** 2026-09-17

> **Apply when:** the change defines or modifies a persisted schema (tables, collections, documents), writes a migration, or performs a multi-step write against durable storage. All examples are illustrative — adapt to the detected persistence technology (relational, document, key-value, or a managed data service).

This standard covers what makes stored data trustworthy over time: that the schema itself rejects what it shouldn't hold, that changing it doesn't break what's already running, and that a multi-step write leaves nothing half-done. `performance.md` §2 owns query efficiency (N+1, indexing for speed); this standard owns correctness and evolvability of the schema and the writes against it.

## 1. Schema Invariants

- **What:** A business rule that the schema itself can enforce (a required field, a unique value, a valid reference, a bounded range) should be enforced there, not only in application code that every write path must remember to call.
- **DO:**
  - Express known invariants as schema-level constraints where the storage technology supports them: not-null, uniqueness, foreign keys, check constraints, or their equivalent.
  - Treat "the application always validates this" as a WARN-level gap, not a substitute for a constraint the schema can enforce — application code changes; the schema is the last line of defense against every write path, present and future.
- **DON'T:**
  - Rely solely on application-level validation for an invariant the schema could enforce directly, especially when multiple write paths (services, migrations, ad hoc scripts) can reach the same table/collection.

## 2. Migrations: Reversible and Backward-Compatible

- **What:** A schema migration runs once, against live data, often while old and new application code are both briefly in flight (rolling deploys) — it must not strand either version.
- **DO:**
  - Write every migration with a working rollback path — a `down` migration, or an explicit, tested manual rollback procedure if the storage technology has no native reverse operation.
  - Sequence a breaking schema change (dropping/renaming a column, tightening a constraint) as multiple deploys: add the new shape, migrate/dual-write, switch reads, then remove the old shape — never all in one step that assumes the old application code has already stopped running.
  - Test a migration against a representative copy of production-shaped data before it runs against the real thing, including the rollback path.
- **DON'T:**
  - Ship a migration that only the *new* application code can tolerate, when the *old* code is still serving traffic during a rolling deploy.
  - Treat "we'll fix it forward if it breaks" as a substitute for a tested rollback — under an active incident is the worst time to discover the rollback was never verified.

## 3. Transactional Boundaries

- **What:** A logical unit of work that touches multiple rows/documents/tables must either fully apply or fully not apply — a failure partway through must not leave some of the writes committed and others not.
- **DO:**
  - Wrap a multi-step write that must be atomic in a transaction, or use the storage technology's equivalent (a conditional/batched write, a saga with compensating actions when no native transaction spans the writes).
  - Keep transactions short — the same discipline `concurrency.md` §3 requires for in-process locks applies to database transactions: no slow external calls or unrelated work inside an open transaction.
- **DON'T:**
  - Perform a multi-step write with no transactional boundary and no compensating-action plan, betting that "the second write basically always succeeds if the first one did."
  - Hold a transaction open across a network call to another service.

## 4. Referential Integrity

- **What:** A reference from one record to another (a foreign key, an embedded id) should not be able to point at something that doesn't exist or was deleted out from under it.
- **DO:**
  - Enforce referential integrity at the schema level where supported (foreign key constraints), or, where the storage technology has no native support, define and apply an explicit application-level invariant with a documented enforcement point.
  - Decide explicitly what happens to dependents when a referenced record is deleted (cascade, restrict, nullify) — and make that decision, don't leave it to whatever the storage technology defaults to.
- **DON'T:**
  - Delete a record without deciding what happens to what references it — an orphaned reference is a defect any consumer might dereference later.

## 5. Query Patterns Drive Indexing

- **What:** An index that doesn't match how the data is actually queried costs write overhead for no read benefit; a query with no supporting index costs a scan every time it runs.
- **DO:**
  - Add an index for every access pattern a new query introduces that will run frequently or against a growing table.
  - Review existing indexes when a query's filter/sort/join pattern changes — an index tuned for the old pattern may no longer help (`performance.md` §2 owns the query-efficiency judgment this feeds).
- **DON'T:**
  - Add an index reflexively for every column "just in case" — each index has a write-time and storage cost; add it where a query pattern justifies it.

## 6. Logical vs. Physical Deletion

- **What:** Whether a "deleted" record is actually removed or only marked as deleted changes what every other query against that table/collection must account for.
- **DO:**
  - Decide explicitly, per entity, whether deletion is physical (row/document removed) or logical (marked, retained) — and document which, since it changes the contract every reader of that data must honor.
  - When using logical deletion, ensure every query that should exclude deleted records actually filters them out — a forgotten filter resurrects "deleted" data.
- **DON'T:**
  - Mix the two undocumented within the same entity (some code paths hard-delete, others soft-delete) — a consumer written against one behavior breaks against the other.

## 7. Multi-Tenant Data Isolation

- **What:** In a system with more than one tenant/customer/organization sharing storage, a query that omits the tenant identifier can return or modify another tenant's data.
- **DO:**
  - Include the tenant identifier as part of every query's filter and, where supported, as part of the schema-level enforcement (a composite key, a row-level security policy) — not only as an application-level convention every query author must remember.
  - Treat cross-tenant data exposure as a security-severity finding, not merely a data-modeling nitpick (`security.md` §2 owns the authorization angle of "who may see this tenant's data"; this section owns the schema/query mechanism that makes isolation structurally hard to bypass).
- **DON'T:**
  - Rely solely on application code remembering to filter by tenant on every query, with no schema-level or framework-level backstop.

## 8. Code Review Checklist
When reviewing, verify:
- [ ] Known invariants (required fields, uniqueness, valid references, ranges) are enforced at the schema level where the storage technology supports it (§1).
- [ ] Every migration has a working rollback path, and a breaking change is sequenced across multiple deploys rather than one step (§2).
- [ ] A multi-step write that must be atomic is wrapped in a transaction or an equivalent compensating-action mechanism (§3).
- [ ] Deleting a record accounts for what references it (§4).
- [ ] A new or changed query pattern has a supporting index (§5).
- [ ] Logical vs. physical deletion is a documented, consistent decision per entity, and queries that should exclude deleted records do (§6).
- [ ] Multi-tenant queries and writes are scoped by tenant, ideally with a schema-level backstop (§7).

## 9. Severity Classification

Use when raising findings in code review or the Validation Gate. Always cite this file and section (e.g., `data-persistence.md §3`).

| Severity | Triggers |
|----------|---------|
| 🔴 **BLOCK** | A migration with no working rollback path ships a breaking change that strands the previous application version during a rolling deploy (§2); a multi-step write that must be atomic has no transactional boundary and a failure partway through leaves inconsistent data (§3); a query or write path omits the tenant identifier in a multi-tenant system, exposing or modifying another tenant's data (§7) |
| 🟡 **WARN** | A known invariant (uniqueness, required field, valid reference) relies solely on application-level validation with no schema-level constraint, and multiple write paths can reach the same data (§1); a record is deleted with no decision made about what references it (§4); a frequent or growing query has no supporting index (§5); logical and physical deletion are mixed within the same entity with no documented rule (§6) |
| 🟢 **INFO** | A migration's rollback path exists but was not tested against representative data (§2); an index exists but its access pattern is no longer the dominant query shape after a recent change (§5) |

## 10. Applying This Standard with a Limited Scope

When applying this standard to a **specific set of files or modules** (the declared Core scope), follow these constraints:

1. **Only modify files inside Core directly.** If a persistence violation is found in a schema/migration outside Core, apply the Impact Zone / backlog handling below rather than editing it unconditionally.
2. **Adding a missing constraint, rollback path, transaction boundary, or tenant filter within a migration/query already in Core is always allowed** — required fixes for code already being touched.
3. **A schema change that requires touching a shared migration history or a table used by modules outside Core** is an Impact Zone concern — apply the handling below rather than modifying it unilaterally.
4. **Do not perform a broad backfill or reindex of existing data as a side effect** of an unrelated in-scope change — that is a separate, deliberate migration.
5. **Changing the deletion strategy (logical vs. physical) for an existing entity outside the scope of this task is not a scope-safe improvement** — it changes the contract every reader of that entity depends on; propose it separately.

**Handling violations outside the Core scope** (per [`rules.md`](../rules.md) → Scope-Locking — Three Zones): a file is either in the **Impact Zone** (a dependent or dependency of a file already in Core, discoverable via `devflow-ctl scope impact <file>`) or **Outside**.
- **Impact Zone + one of the six closed coherence reasons** (broken caller, broken import, contract violation, duplicated logic the task just introduced, a test that now fails, a type/schema that must change together): fix it, then record `devflow-ctl scope justify <file> "<reason>"`.
- **Impact Zone without a closed coherence reason, or Outside entirely:** do not edit it. Defer it instead: `devflow-ctl backlog add <file> "<reason>" --severity {incomplete|info}` — use `incomplete` if the in-scope change is functionally incoherent without that follow-up, `info` if it is a separate improvement.

## 11. Design-Time Decisions

Record these in the spec's **Data Structures** and **Standards Applied** sections:

- **Schema constraints** — which invariants are enforced at the schema level versus application level, and why for anything left to application level (§1).
- **Migration sequencing** — for a breaking change, the deploy sequence (add → dual-write/migrate → switch → remove) and the rollback path for each migration (§2).
- **Transaction boundaries** — which multi-step writes must be atomic, and the mechanism used (§3).
- **Referential rules** — the cascade/restrict/nullify decision for every reference that can be deleted (§4).
- **Index plan** — the indexes the new access patterns require (§5).
- **Deletion strategy** — logical or physical, per entity (§6).
- **Tenant scoping** — how tenant isolation is enforced for any new table/collection in a multi-tenant system (§7).

## 12. Implementation Self-Check

Before marking a task done:

- [ ] Every invariant the schema can enforce is expressed as a constraint, not left to application code alone (§1).
- [ ] Any new migration has a rollback path, and a breaking change is sequenced across deploys, not a single step (§2).
- [ ] Any multi-step write that must be atomic is inside a transaction or its equivalent (§3).
- [ ] Deleting a record has a defined, implemented effect on what references it (§4).
- [ ] Any new query pattern has a supporting index (§5).
- [ ] The deletion strategy for any touched entity matches its documented decision, and exclusion filters are applied where required (§6).
- [ ] Any new query or write against multi-tenant data is scoped by tenant (§7).
