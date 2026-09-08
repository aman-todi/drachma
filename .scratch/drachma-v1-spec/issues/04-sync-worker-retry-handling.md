Type: grilling
Status: resolved

## Question

How should the sync worker handle a failed Plaid webhook delivery or a failed `/transactions/sync` call? Needs a stated retry/backoff policy, a dead-letter path for repeated failures, and whether/how a user-visible staleness indicator surfaces when a Connection's Mirror data falls behind. The worker runs as an AWS ECS Fargate service, so consider AWS-native primitives (e.g. SQS as a durable queue in front of the worker) rather than in-process retry only.

## Answer

**Pipeline shape**: the API service receives and JWT-verifies Plaid webhooks, then enqueues onto SQS; the sync worker only consumes from SQS and calls `/transactions/sync`. "Failed webhook delivery" in scope means the API failing to enqueue (retried inline, then a 5xx back to Plaid so Plaid's own webhook retry covers the rest) — not Plaid failing to reach us at all.

**Failure taxonomy**: Plaid errors split into transient (`INTERNAL_SERVER_ERROR`, `RATE_LIMIT_EXCEEDED`, timeouts) and terminal-for-the-Connection (`ITEM_LOGIN_REQUIRED`, `ITEM_ACCESS_REVOKED`, `INVALID_ACCESS_TOKEN`). Terminal errors skip retry/DLQ entirely and flip the Connection to a `needs_reauth` state on the first occurrence.

**Queue topology**: SQS FIFO, `MessageGroupId = connection_id` — guarantees per-Connection ordering and prevents concurrent `/transactions/sync` calls racing on the same cursor. The API dedups at enqueue time (a `pending_sync` flag on the Connection row): a second "there's new data" webhook while one's already queued/in-flight for that Connection is a no-op, since a fresh cursor-based sync already picks up everything new.

**Backoff**: app-level exponential backoff via `ChangeMessageVisibility`, keyed off `ApproximateReceiveCount`, on transient failures only: 1m → 5m → 30m → 2h → 6h → 12h → 24h. `maxReceiveCount: 8` (~45h total), landing just under the staleness threshold below.

**Idempotency**: the sync cursor is persisted to the Mirror after every successful paginated page, not just at the end of a full sync, so a retry resumes from the last good page instead of restarting the whole sync.

**Dead-letter path**: after 8 attempts, the message lands in a DLQ; a CloudWatch alarm on DLQ depth pages the team (transient-error exhaustion reads as an outage, not a per-user issue). Redrive to the source queue is a manual ops action once the underlying cause is confirmed resolved — no auto-replay loop.

**Staleness surfacing**: every Connection always shows a "Last synced" timestamp. It flips to a distinct warning state once either (a) no successful sync in 48h, or (b) the Connection is `needs_reauth` — visually distinct from each other since one is "hang tight" and the other needs the user to act. Exact UI treatment deferred to the dashboard prototype tickets once the tool layer and MCP schema settle (see map's Not yet specified).

Follow-on: [AWS infra setup](issues/07-aws-infra-setup.md) updated to provision the SQS FIFO queue, DLQ, and CloudWatch alarm this decision requires.
