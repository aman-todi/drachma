Type: grilling
Status: resolved

## Question

How does `net_worth()` value illiquid and non-standard holdings for v1? Plaid's Investments product surfaces 401k/brokerage holdings with quantity and last-known price, but valuation staleness, unpriced/illiquid assets (e.g. private funds, employer stock without a live quote), and the sign convention for Liabilities (credit cards, loans) all need a stated rule before the function can be built.

## Answer

- **Priced holdings**: value at whatever `institution_price` the Mirror last synced from Plaid, with no staleness check and no `as_of` surfaced. (Prices reach `net_worth()` via the Mirror, kept current by the sync worker — never a live Plaid call at query time, per `CONTEXT.md`'s Mirror definition.)
- **Unpriced holdings** (no quote at all — private funds, unpriced employer stock): excluded from the total. The response carries a structured list of what was excluded (account, holding name, reason) alongside the number, so the calling model can say what was left out rather than presenting a silently-short total.
- **Liabilities**: every type the user's Connections return (credit cards, student loans, mortgages) is in scope, subtracted as a positive magnitude: `net_worth = Σ(asset values) − Σ(liability balances)`.
- **Liability balance field per type**: `current_balance` for credit cards and student loans; `outstanding_principal_balance` for mortgages (the closest analog, since mortgages have no same-named field in Plaid's Liabilities schema).
