Type: grilling
Status: resolved

## Question

What does a Usage unit cost per invocation for v1? The shared quota (200/mo on the $10 Tier, 500/mo on the $20 Tier) is charged per underlying tool invocation, weighted by complexity, not per user question — but the weighting formula itself is still open. Needs a simple v1 heuristic (e.g., flat 1 unit per Curated tool call, N units for a Custom query tool call) that's cheap to implement and explain to users, with the explicit expectation that it gets tuned post-v1 based on real usage.

## Answer

- Flat 1 Usage unit for every Curated tool call, no per-tool variation among the five (`spend_between`, `recurring_charges`, `top_vendors`, `net_worth`, `account_balance`) — they're all pre-built, indexed queries against Curated views, so complexity is uniform enough at v1's scale that splitting them out would add a table users have to memorize for no real benefit.
- Flat 3 Usage units for a Custom query tool call — enough to nudge both the model and the user toward the cheaper fixed tools first, but a flat number rather than query-cost-based, since real cost data doesn't exist pre-launch and that kind of weighting is exactly what's deferred to post-v1 tuning.
- A unit is charged only for an invocation that actually executes against the database. A call rejected before it runs (bad SQL, a permission check failure) is free; a call that starts executing and then errors or times out mid-run still costs a unit, since it already spent the resource.
