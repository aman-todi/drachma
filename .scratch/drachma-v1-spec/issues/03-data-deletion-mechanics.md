Type: grilling
Status: open

## Question

What happens, mechanically, when a user removes a Connection or closes their account? Needs a stated rule for: calling Plaid's Item removal endpoint, purging (vs. retaining for billing/audit history) the corresponding rows in the Mirror and the Token vault, and the timing (immediate vs. a grace period). This also determines what a privacy policy can truthfully promise, which matters for the Plaid production-access application (ticket 05).
