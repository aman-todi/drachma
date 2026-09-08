Type: grilling
Status: claimed

## Question

What does a Usage unit cost per invocation for v1? The shared quota (200/mo on the $10 Tier, 500/mo on the $20 Tier) is charged per underlying tool invocation, weighted by complexity, not per user question — but the weighting formula itself is still open. Needs a simple v1 heuristic (e.g., flat 1 unit per Curated tool call, N units for a Custom query tool call) that's cheap to implement and explain to users, with the explicit expectation that it gets tuned post-v1 based on real usage.
