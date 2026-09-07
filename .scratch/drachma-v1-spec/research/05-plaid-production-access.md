# Plaid production access: requirements, per-product approval, limits, and turnaround

## Summary

Moving from Sandbox to full Production access is a Dashboard application, not a per-product certification. Plaid gates the request button on integration validation, plus a completed application profile, company profile, and security questionnaire, one field of which is a live privacy policy. Transactions, Investments, Liabilities, Balance, and the Recurring Transactions add-on are each requested individually on the production form. Nothing here rides on a blanket approval. An intermediate "Limited Production" tier (a "Trial plan" for teams created after April 15, 2026) lets you run against live data under capped usage before full approval comes through. Plaid's docs put full-Production review at roughly a couple of business days once the profile and questionnaire are done; OAuth registration and the security questionnaire are the parts most likely to stretch that out, and Europe/UK access runs on its own track with a stated minimum of about a week.

## What full production approval requires

Plaid's Launch checklist page names the concrete gates. Before the "Request Production Access" button even appears in the Dashboard, your integration has to pass Plaid's endpoint validation, meaning a working Sandbox (or Limited Production) integration exercised end to end stands in for a "demo." You also need to strip out Sandbox-only code, such as the `user_good` test user or any `/sandbox/*` calls, and switch to your Production secret. Source: [Launch checklist](https://plaid.com/docs/launch-checklist/).

That same checklist page lists the Dashboard profile fields Plaid requires before you can apply: legal company name, product name, website, logo, support contact, a privacy policy, and a plain explanation of how you use bank data. The privacy policy is a named required field, not optional boilerplate, which answers this ticket's question directly: yes, Plaid wants a live privacy policy URL at submission time, and ticket 03's data-deletion answer needs to be published before Drachma applies. Source: [Launch checklist](https://plaid.com/docs/launch-checklist/).

OAuth-based connections, which many large US and European institutions require, need that same application and company profile plus a security questionnaire. Chase specifically won't grant access until the questionnaire is approved, unless you're on a Trial plan. The questionnaire covers security practices such as keeping an audit trail and logs for production events. As part of company information, Plaid also asks for a Legal Entity Identifier, optional in general but required under the CFPB's Section 1033 rule for anyone using OAuth to connect to US institutions. Source: [Link, OAuth guide](https://plaid.com/docs/link/oauth/).

Beyond the Dashboard's privacy-policy field, Plaid's Developer Policy separately requires giving notice and getting consent for Plaid to process end-user data, consistent with Plaid's End User Privacy Policy. Some customers handle this by linking to Plaid's policy from their own; others build a just-in-time consent screen into onboarding. As of October 31, 2024, new US and Canada customers are auto-enrolled in Data Transparency Messaging and must pick a use case before using Link in Production. Source: [Developer Policy](https://plaid.com/developer-policy/).

If Drachma ever needs European or UK institutions and isn't itself based in Europe, that's a separate support ticket with its own review, and Plaid says to allow at least a week. Source: [Launch checklist](https://plaid.com/docs/launch-checklist/).

## Per-product approval: separate, not blanket

Plaid does not grant one approval that covers every product. On a paid plan, you keep production access only for the products you actually requested on the production form. Source: [Account, pricing and billing](https://plaid.com/docs/account/billing/).

Investments, Liabilities, and Transactions are each subscription-fee products in their own right. A single Item can carry more than one of these subscriptions at once (Transactions plus Liabilities, say), but each is billed and tracked separately. Source: [Account, pricing and billing](https://plaid.com/docs/account/billing/).

Recurring Transactions (`/transactions/recurring/get`) is an add-on for existing Transactions customers in the US, Canada, and UK. It needs its own product access request, or a request through your Plaid account manager, rather than coming bundled with base Transactions approval, though it's available in Limited Production as a way to try it early. Source: [Transactions overview](https://plaid.com/docs/transactions/).

Balance gets the same treatment. Plaid's docs tie other feature availability, such as `/signal/evaluate`, to customers who received Balance production access after a specific date, which only makes sense if Balance approval is tracked as its own grant rather than inherited from another product. Sources: [Balance overview](https://plaid.com/docs/balance/), [API, Accounts](https://plaid.com/docs/api/accounts/).

Practically, this means Drachma's production request should name every product it needs (Transactions, Recurring Transactions as an add-on, Investments, Liabilities, and Balance) rather than assuming approval for one carries the rest.

## Usage caps and per-institution limits during review

Before full approval, everything runs through Limited Production, a capped mode of the real Production environment. Teams created on or after April 15, 2026 get a Trial plan instead. Source: [How are Sandbox, Production, Trial plan, and Limited Production different?](https://support.plaid.com/hc/en-us/articles/16110110883479-How-are-Sandbox-Production-Trial-plan-and-Limited-Production-different).

Limited Production caps API calls per product, and both failed and successful calls count against that cap. Calls not tied to a specific product, like `/accounts/get`, don't count. There's also a cap on total Items you can create, which lifts once you have full production access for at least one product. Source: [How are Sandbox, Production, Trial plan, and Limited Production different?](https://support.plaid.com/hc/en-us/articles/16110110883479-How-are-Sandbox-Production-Trial-plan-and-Limited-Production-different).

Limited Production also blocks connections to certain large OAuth institutions, Bank of America, Chase, and Wells Fargo, until you have full production access for at least one product and have completed OAuth registration. Source: [Sandbox overview](https://plaid.com/docs/sandbox/).

The newer Trial plan (for teams created from April 15, 2026 onward) is less restrictive on this front: it supports up to 10 Production Items and grants access to most OAuth institutions, Bank of America, Chase, and Wells Fargo included, before full approval. Source: [How are Sandbox, Production, Trial plan, and Limited Production different?](https://support.plaid.com/hc/en-us/articles/16110110883479-How-are-Sandbox-Production-Trial-plan-and-Limited-Production-different).

Sandbox itself, before either of these tiers, has no such limits. It's free, runs on mock data only, and allows unlimited test Items. Source: [Sandbox overview](https://plaid.com/docs/sandbox/).

## Typical turnaround time

Plaid's own docs describe full-Production review as taking a couple of business days once submitted. Source: [Launch checklist](https://plaid.com/docs/launch-checklist/).

That estimate assumes the Dashboard profile and security questionnaire are already done. OAuth registration and an unapproved questionnaire are the parts Plaid calls out as adding lead time, since Chase access specifically waits on questionnaire approval. Source: [Link, OAuth guide](https://plaid.com/docs/link/oauth/).

Europe and UK access run on a separate, slower track. Plaid says to allow at least a week after filing the support ticket. Source: [Launch checklist](https://plaid.com/docs/launch-checklist/).

## Sequencing implications for Drachma's build

1. Publish the privacy policy (per ticket 03's data-deletion answer) before submitting the production request. It's a required Dashboard field, not a placeholder you can fill in later.
2. Build and validate the Sandbox integration end to end, covering Link and every product endpoint Drachma needs, so Plaid's validation unlocks the "Request Production Access" button.
3. Fill out the company and application profile and get through the OAuth security questionnaire while development is still underway. Chase, Bank of America, and Wells Fargo access, all likely needed for a personal-finance aggregator, wait on the questionnaire specifically, not just on the base production request.
4. Submit one production request that names every product Drachma needs: Transactions, Recurring Transactions as an add-on, Investments, Liabilities, and Balance. None of these ride on another's approval.
5. Plan for a review measured in business days for the core request, with a buffer if the security questionnaire stalls, and a longer track (a week or more) if Drachma ever needs European institutions.

## Sources consulted (Plaid official docs and support center)

- [Launch checklist](https://plaid.com/docs/launch-checklist/)
- [Sandbox overview](https://plaid.com/docs/sandbox/)
- [Link, OAuth guide](https://plaid.com/docs/link/oauth/)
- [Account, pricing and billing](https://plaid.com/docs/account/billing/)
- [Transactions overview](https://plaid.com/docs/transactions/)
- [Balance overview](https://plaid.com/docs/balance/)
- [API, Accounts](https://plaid.com/docs/api/accounts/)
- [Developer Policy](https://plaid.com/developer-policy/)
- [How are Sandbox, Production, Trial plan, and Limited Production different?](https://support.plaid.com/hc/en-us/articles/16110110883479-How-are-Sandbox-Production-Trial-plan-and-Limited-Production-different)

Plaid also publishes a separate "Core Exchange" doc set at `plaid.com/core-exchange/docs/`, covering the bank side of Plaid's business, where financial institutions feed data to Plaid directly. Those pages reuse terms like "production access" and "validation" for a different program aimed at banks, not at API customers like Drachma, so they were left out of the claims above.
