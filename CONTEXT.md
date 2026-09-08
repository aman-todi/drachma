# Drachma

A personal-finance app that aggregates Plaid-linked bank, credit card, 401k, and brokerage data, then answers natural-language questions about spending, recurring charges, and net worth — through a web dashboard, an in-app chat, and a remote MCP server for external personal assistants (Claude, ChatGPT).

## Language

### Plaid & data

**Connection**:
One linked Plaid Item: a single login to one financial institution, which may expose multiple accounts underneath it (e.g. checking + savings from one bank login). The unit billing tiers are metered by.
_Avoid_: Linked account, integration, institution link.

**Token vault**:
Encrypted storage for a Connection's Plaid access token, decrypted only by the backend when making Plaid API calls on that Connection's behalf.
_Avoid_: Credentials store, secrets store.

**Mirror**:
The backend's own Postgres copy of accounts, transactions, and holdings, kept current by the sync worker and queried directly for analytics instead of calling Plaid live on every question.
_Avoid_: Cache, Plaid data, local copy.

**Curated view**:
A per-user, read-only Postgres view built on top of the Mirror, scoped by row-level security. The only data surface the tool layer is allowed to query — raw Mirror tables are never exposed directly.
_Avoid_: Raw table, schema, base table.

### Tool layer

**Curated tool**:
One of the five fixed analytics functions (`spend_between`, `recurring_charges`, `top_vendors`, `net_worth`, `account_balance`), built once and exposed identically to the web dashboard, the in-app chat, and the MCP server.
_Avoid_: Endpoint, analytics function (bare), query.

**Custom query tool**:
The one tool that runs a constrained, model-authored SELECT against curated views (never raw Mirror tables), for questions the curated tools don't cover. Read-only role, auto-injected LIMIT, query timeout, and separately audited/rate-limited from the curated tools.
_Avoid_: Ad-hoc query tool, raw SQL tool.

### AI surfaces

**Connected assistant**:
An external personal-assistant application (Claude, ChatGPT) that a user connects to the MCP server via OAuth. Its own underlying model is outside this project's control.
_Avoid_: MCP client (when the user, not the protocol, is meant).

**Model provider**:
The swappable interface powering the in-app chat's own reasoning (initially DeepSeek V4 Flash). Distinct from a Connected assistant's model, which this project never chooses.
_Avoid_: The LLM, AI provider (bare).

### Account lifecycle

**Account record**:
The user's profile, Tier, and billing state — distinct from the Mirror and Token vault, which hold Plaid-sourced data instead.
_Avoid_: Account shell, profile (bare).

**Closure window**:
The 48-hour period after an account-closure request during which the account record and Mirror survive (soft-deleted, Connections' tokens already revoked) and Reactivation is still possible, before permanent purge.
_Avoid_: Grace period, undo window.

**Reactivation**:
The explicit, user-confirmed action that cancels a pending account closure inside the Closure window. Logging back in alone does not trigger it.
_Avoid_: Recovery, undelete.

### Billing & usage

**Tier**:
A paid subscription level ($10 or $20/mo) that caps both Connections and monthly usage units.
_Avoid_: Plan (fine informally, but Tier is canonical in specs).

**Usage unit**:
The metered event consumed against a Tier's monthly quota, shared across the MCP server and the in-app chat. Charged per underlying tool invocation, not per user question, and weighted by the invocation's complexity — the exact weighting is expected to be tuned after v1 based on real usage.
_Avoid_: Call, MCP call, question, request.
