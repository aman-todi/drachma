Type: grilling
Status: resolved

## Question

What happens, mechanically, when a user removes a Connection or closes their account? Needs a stated rule for: calling Plaid's Item removal endpoint, purging (vs. retaining for billing/audit history) the corresponding rows in the Mirror and the Token vault, and the timing (immediate vs. a grace period). This also determines what a privacy policy can truthfully promise, which matters for the Plaid production-access application (ticket 05).

Now confirmed blocking, not just related: [Plaid production access](05-plaid-production-access.md) found that a live privacy policy URL is a required field on Plaid's production-access application, so this ticket's answer needs to be published as an actual privacy policy before that application can be submitted.

## Answer

**Connection removal** (account stays open): immediate, no Closure window. Plaid's `/item/remove` is called and the Token vault row deleted right away; the Connection's Mirror rows (accounts, transactions, holdings) are purged immediately too.

**Account closure**: a 48-hour Closure window, split by data type:

- Token vault: every Connection's `/item/remove` is called and every token deleted immediately at the closure request, not held for the Closure window.
- Mirror: soft-deleted (hidden, not purged) for the Closure window, then purged in full once it lapses.
- An email goes out immediately at closure request, stating the permanent-deletion date and carrying a Reactivation link.
- Reactivation requires explicit confirmation ("Reactivate my account") — logging in alone doesn't cancel closure.
- Reactivating restores the Account record and the historical Mirror snapshot; Connections come back needing to be re-linked, since Plaid access can't be un-revoked once `/item/remove` has run.
- After the Closure window: permanent, unrecoverable purge of the Mirror and the Account record.
- Billing/audit records (Stripe invoice history plus a minimal internal log — user id, Tier, Usage unit totals per billing period, timestamps) survive closure for a fixed 7-year retention. No Plaid-sourced financial data is part of that retained log.

This gives the Plaid production-access application (ticket 05) a truthful privacy-policy sentence: access is revoked and the Token vault cleared immediately on disconnection; financial data is purged immediately on Connection removal and within 48 hours of account closure (sooner if not reactivated); billing records are kept 7 years for audit purposes.

New canonical terms recorded in `CONTEXT.md`: Account record, Closure window, Reactivation.
