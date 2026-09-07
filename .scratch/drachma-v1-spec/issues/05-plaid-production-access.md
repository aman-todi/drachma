Type: research
Status: resolved

## Question

What does Plaid require to move from development/sandbox to production access, and how long does approval typically take? Cover: application review requirements (including whether a live privacy policy URL is required at submission time — this interacts with ticket 03's data-deletion answer), which Plaid products need separate approval (Transactions, Recurring Transactions, Investments, Liabilities, Balance), any per-institution or usage limits during the review period, and typical turnaround time so it can be sequenced against the rest of the build.

## Answer

Production access is a Dashboard application, not a per-product certification. Products aren't covered by one blanket approval: Transactions, Investments, Liabilities, and Balance are each requested and billed separately, and Recurring Transactions is a further add-on request on top of Transactions. To apply, Drachma needs a completed company and application profile. Legal name, product name, website, support contact, and a live privacy policy URL are required fields, so ticket 03's data-deletion policy needs to be published before submission. Plaid also requires a passing Sandbox integration (the Dashboard only unlocks the request button once your endpoints validate) and, for OAuth institutions like Chase, Bank of America, and Wells Fargo, an approved security questionnaire. Before full approval, usage runs in a capped "Limited Production" tier with per-product API call caps, an Item cap, and no access to Chase, BofA, or Wells Fargo, or, for newer Plaid accounts, a Trial plan capped at 10 Items. Plaid states typical review takes a couple of business days once the profile and questionnaire are complete, with Europe and UK access as a separate track taking a week or more.

Full findings and sourcing: [../research/05-plaid-production-access.md](../research/05-plaid-production-access.md)
