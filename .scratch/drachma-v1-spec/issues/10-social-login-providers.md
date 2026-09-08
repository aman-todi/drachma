Type: grilling
Status: resolved
Blocks: 08

## Question

Which social login providers, if any, should Drachma support at v1 alongside Supabase Auth's email/password? Ticket 08 (Supabase project setup) needs a concrete list of providers to enable when provisioning the Supabase project, and this decision was never made — it was referenced from ticket 08 as if it had been.

## Answer

Google and Apple, alongside Supabase Auth's built-in email/password. No GitHub at v1 — Drachma's audience is general personal-finance users, not a technical/developer crowd, so GitHub login adds a provider to configure and support without matching demand. Google covers the broadest low-friction OAuth base; Apple matters both for the iOS-leaning share of that audience and because Apple requires offering Sign in with Apple on any iOS app that also offers another social login, so getting it into the Supabase project now avoids retrofitting it later if a native app follows the SPA.

Ticket 08 (Supabase project setup) is unblocked: provision the project with Google and Apple OAuth providers enabled alongside email/password.
