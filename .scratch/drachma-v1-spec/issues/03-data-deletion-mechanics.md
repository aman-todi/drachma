Type: grilling
Status: open

## Question

What happens, mechanically, when a user removes a Connection or closes their account? Needs a stated rule for: calling Plaid's Item removal endpoint, purging (vs. retaining for billing/audit history) the corresponding rows in the Mirror and the Token vault, and the timing (immediate vs. a grace period). This also determines what a privacy policy can truthfully promise, which matters for the Plaid production-access application (ticket 05).

Now confirmed blocking, not just related: [Plaid production access](05-plaid-production-access.md) found that a live privacy policy URL is a required field on Plaid's production-access application, so this ticket's answer needs to be published as an actual privacy policy before that application can be submitted.
