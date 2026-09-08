# Drachma v1 spec

## Destination

A written product/architecture spec for Drachma v1: a paid, multi-tenant personal-finance app that aggregates Plaid data (bank, credit card, 401k, brokerage) and answers questions through a web dashboard with in-app chat and a remote, OAuth-gated MCP server for external personal assistants (Claude, ChatGPT). The spec is handed off to a build session once every ticket below is resolved.

## Notes

- **Domain**: see `CONTEXT.md` at the repo root for vocabulary (Connection, Token vault, Mirror, Curated view, Curated tool, Custom query tool, Connected assistant, Model provider, Tier, Usage unit). See `docs/adr/0001-supabase-postgres-over-aws-rds.md` for why Postgres lives on Supabase despite the app being AWS-hosted.
- **Architecture shell already settled** (not re-litigated by tickets below): Python/FastAPI backend; Supabase Postgres + Auth; React + Vite SPA; both the API and the sync worker run as AWS ECS Fargate services (one container image, two task definitions); a shared Curated-tool analytics layer (`spend_between`, `recurring_charges`, `top_vendors`, `net_worth`, `account_balance`) plus a views-scoped Custom query tool, both exposed identically to the MCP server, the in-app chat, and the web dashboard; the MCP server is OAuth-gated and is the primary surface; the in-app chat calls a swappable Model provider (DeepSeek V4 Flash initially — keep this integration loosely coupled so the provider can be swapped without touching calling code); two paid Tiers ($10/mo for 10 Connections, $20/mo for 20 Connections) share one Usage-unit quota tracked via atomic counters in the same Supabase Postgres database; Stripe handles billing; v1 is USD-only.
- **Skills every session should consult**: call the Skill tool for `grilling` and `domain-modeling` on any decision ticket (challenge terms against `CONTEXT.md` as they come up); call the Skill tool for `research` on any research ticket.

## Decisions so far

- [Usage unit weighting](issues/01-usage-unit-weighting.md): Flat 1 Usage unit per Curated tool call, 3 units per Custom query tool call; a unit is only charged for an invocation that actually executes against the database (rejected-before-execution calls are free, calls that error or time out mid-run still cost).
- [Plaid production access](issues/05-plaid-production-access.md): No blanket approval — Transactions, Investments, Liabilities, and Balance are each requested/billed separately, Recurring Transactions is a further add-on. Requires a passing Sandbox integration and a live privacy policy URL at submission (blocks on [Data-deletion mechanics](issues/03-data-deletion-mechanics.md)), plus a security questionnaire for OAuth institutions (Chase, BofA, Wells Fargo). Runs capped until full approval; typical review is a couple of business days once the profile is complete.
- [MCP OAuth flow](issues/06-mcp-oauth-flow.md): Dynamic Client Registration isn't required — a pre-registered OAuth client per assistant (Claude, ChatGPT) is spec-compliant. Token flow is OAuth 2.1 + PKCE with a mandatory `resource` parameter (RFC 8707) and mandatory refresh-token rotation; the server must expose OAuth 2.0 Protected Resource Metadata (RFC 9728). Supabase Auth can act as the authorization server since it already exposes OIDC discovery, as long as the MCP server publishes the RFC 9728 document pointing at it.
- [Net-worth calculation](issues/02-net-worth-calculation.md): Priced holdings use the Mirror's last-synced price with no staleness check; unpriced holdings are excluded and listed in the response; all Liabilities types are subtracted as positive magnitudes (`current_balance` for cards/loans, `outstanding_principal_balance` for mortgages).
- [Sync worker retry handling](issues/04-sync-worker-retry-handling.md): API enqueues verified webhooks onto an SQS FIFO queue (keyed by `connection_id`) that the sync worker consumes; terminal Plaid errors (`ITEM_LOGIN_REQUIRED`, etc.) skip retry and flip the Connection to `needs_reauth`, transient errors get app-level exponential backoff (1m→24h, 8 attempts) via `ChangeMessageVisibility` before landing in a DLQ that pages the team. Sync cursor persisted per-page for resumable retries. Connections show "Last synced" always, with a distinct warning state past 48h stale or `needs_reauth`.
- [Data-deletion mechanics](issues/03-data-deletion-mechanics.md): Connection removal purges the Token vault and Mirror immediately, with a call to Plaid's `/item/remove`. Account closure revokes Plaid access and clears the Token vault immediately, but gives a 48-hour Closure window (soft-deleted Mirror, explicit Reactivation required) before the Mirror and Account record are purged for good; billing/audit records are kept 7 years separately. Unblocks the privacy-policy requirement in [Plaid production access](issues/05-plaid-production-access.md).

## Not yet specified

- Dashboard and in-app chat UI/IA — will sharpen into prototype tickets once the tool layer and MCP schema (ticket 06) are settled.
- Exact MCP tool JSON schemas for each Curated tool and the Custom query tool.
- Test/QA plan for the analytics layer and the sync worker.

## Out of scope

- Ads integration and any Tier/pricing changes beyond the two Tiers set here — explicitly deferred to after v1 launch and real usage feedback.
