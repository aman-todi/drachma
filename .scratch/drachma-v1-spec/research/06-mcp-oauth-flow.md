# Research: MCP OAuth flow for remote server connections (Claude + ChatGPT)

Question: [../issues/06-mcp-oauth-flow.md](../issues/06-mcp-oauth-flow.md)

## Sources consulted

- MCP spec, Authorization section, revision 2025-06-18: `docs/specification/2025-06-18/basic/authorization.mdx` in [modelcontextprotocol/modelcontextprotocol](https://github.com/modelcontextprotocol/modelcontextprotocol) (fetched via raw.githubusercontent.com; the rendered version normally lives at modelcontextprotocol.io, which was unreachable from this environment).
- MCP spec, Authorization section, revision 2025-11-25 (current): same repo path, `docs/specification/2025-11-25/basic/authorization.mdx`.
- MCP blog, "Evolving OAuth Client Registration in the Model Context Protocol" at blog.modelcontextprotocol.io/posts/client_registration/.
- Anthropic, [MCP connector docs](https://platform.claude.com/docs/en/agents-and-tools/mcp-connector) (Claude Developer Platform / Messages API).
- Anthropic's client-selection algorithm for connector OAuth, corroborated by [anthropic/claude-code#36861](https://github.com/anthropics/claude-code/issues/36861) and third-party writeups of Claude's custom-connector settings. support.claude.com and claude.com/docs were both blocked by this environment's egress proxy, so those two claims are one hop removed from primary. Flagged below.
- OpenAI Apps SDK / ChatGPT connector behavior, via OpenAI developer community threads and third-party technical writeups. developers.openai.com and help.openai.com were both blocked by this environment's egress proxy. Flagged below.
- RFC 7591 (Dynamic Client Registration), RFC 8414 (Authorization Server Metadata), RFC 9728 (Protected Resource Metadata), RFC 8707 (Resource Indicators), OAuth 2.1 draft, all referenced directly by the MCP spec.

## 1. Is Dynamic Client Registration required?

No. And the spec's own answer to this changed between revisions, which matters for how durable this answer needs to be.

In the 2025-06-18 revision (the version most third-party MCP-auth tutorials still describe), DCR is a SHOULD, not a MUST: "MCP clients and authorization servers SHOULD support the OAuth 2.0 Dynamic Client Registration Protocol" (RFC 7591), justified by clients not being able to know all possible servers in advance.

The current 2025-11-25 revision downgrades DCR further, to MAY, and calls it out as "included for backwards compatibility with earlier versions." In its place, the spec now says clients and authorization servers SHOULD support OAuth Client ID Metadata Documents (CIMD): a client identifies itself with an HTTPS URL pointing at a JSON metadata document instead of registering a `client_id` through an API call. The spec gives an explicit priority order for how a client picks a client identity for a given server: CIMD first, pre-registration second (a client ID issued out of band, through a developer portal or manual entry), DCR third.

Nothing in either revision makes DCR mandatory for the server. An MCP server (the OAuth authorization server, or a resource server pointing at one) is always free to skip a DCR endpoint. What's required instead is that the server's metadata correctly advertises what it does support, so the client can fall back accordingly.

For Drachma: a pre-registered OAuth client per connecting assistant is a spec-sanctioned alternative to DCR, and it now sits ahead of DCR in the spec's own priority order. Anthropic's own product confirms this. Claude's custom connectors pick between three ways to establish a client identity for a given remote MCP server (summarized via search, since the connector docs page itself is proxy-blocked, corroborated by anthropic/claude-code#36861 discussing the same mechanism):

1. CIMD, selected automatically when the server's authorization-server metadata advertises `client_id_metadata_document_supported: true` and lists `"none"` in `token_endpoint_auth_methods_supported`.
2. Anthropic-held client credentials: the server operator registers one `client_id`/`client_secret` pair with Anthropic once, through connector-directory review, and Anthropic reuses it across every Claude surface (web, Desktop, mobile, Cowork). This is a pre-registered-client model.
3. DCR, used only when neither of the above is available. The custom-connector UI also lets a person paste in an OAuth Client ID and Secret manually under "Advanced settings," which is a pre-registered-client path from the server's point of view.

For ChatGPT, OpenAI Developer Community threads ("OAuth Client ID is no longer optional," "Auth Dynamic Client Registration (DCR) Problem") and third-party Apps SDK auth guides suggest ChatGPT's connector flow has leaned on DCR (registering a fresh client per connection) but is moving toward the same CIMD model the MCP spec now recommends, acting as either a public CIMD client (`none` token-endpoint auth) or a private one (`private_key_jwt`). I could not verify this against developers.openai.com or help.openai.com directly, since both were blocked in this environment. Treat this paragraph as corroborated, not primary, and re-check it against OpenAI's own docs before relying on it for anything load-bearing, such as assuming ChatGPT can only use pre-registered clients.

Bottom line: a single pre-registered OAuth client per connecting assistant, one for Claude and one for ChatGPT, is spec-compliant. No DCR endpoint is required. Supabase Auth can serve as the authorization server as-is, provided it can issue tokens to those two pre-registered clients; DCR support is not a blocker.

## 2. Token issuance and refresh flow

The 2025-11-25 spec builds MCP authorization directly on OAuth 2.1.

Authorization Code grant is the expected flow for user-delegated access; there's no user to delegate for under client-credentials, so that grant type doesn't apply here.

PKCE is mandatory for clients: "MCP clients MUST implement PKCE according to [OAuth 2.1 Section 7.5.2]" and "MUST use the S256 code challenge method when technically capable." The client checks `code_challenge_methods_supported` in the authorization server's metadata to confirm S256 support before proceeding.

The `resource` parameter is mandatory on both legs of the flow. Clients MUST include it (RFC 8707, Resource Indicators for OAuth 2.0) in both the authorization request and the token request, set to the canonical URI of the target MCP server (lowercase scheme and host, no fragment). This ties the issued token to one resource server instead of letting it float as a bearer credential good for anything the authorization server protects.

For refresh tokens, the spec says: "For public clients, authorization servers MUST rotate refresh tokens" per OAuth 2.1 Section 4.3.1. Every refresh-token use invalidates the old one and issues a new one. Beyond that, the spec doesn't define an MCP-specific refresh endpoint or grant type. It's the standard `grant_type=refresh_token` request against the authorization server's token endpoint.

The spec recommends, but doesn't mandate, short-lived access tokens, to limit the damage from a leaked token, paired with the rotating refresh token for long sessions.

One distinction worth noting: Anthropic's own MCP connector at the API layer (Messages API) doesn't drive the OAuth exchange itself. Its docs say plainly that "API consumers are expected to handle the OAuth flow and obtain the access token prior to making the API call, and to refresh the token as needed," and pass the resulting bearer token in as `authorization_token`. That's the API-integration surface, separate from the claude.ai/ChatGPT "Connected apps" surface, which does drive the browser-based OAuth redirect itself. For Drachma's use case, claude.ai and ChatGPT as end-user-facing connected assistants, it's the latter surface, and the OAuth exchange happens between the assistant's backend and Drachma's authorization server, per the flow above.

## 3. Mandatory discovery and `.well-known` metadata endpoints

Two metadata documents come into play, both MUST-level for a compliant server under the 2025-11-25 spec.

OAuth 2.0 Protected Resource Metadata (RFC 9728) has to be published by the MCP server itself (the resource server), and returned when it rejects an unauthenticated or unauthorized request. On a 401, the server MUST send a `WWW-Authenticate` header pointing at the resource metadata URL. This document lives under a `.well-known/oauth-protected-resource` path (with MCP-server-path insertion, for example `https://example.com/.well-known/oauth-protected-resource/mcp`, falling back to the bare root `https://example.com/.well-known/oauth-protected-resource`). Its `authorization_servers` field names which authorization server(s) issue tokens accepted here, which is how client and resource server can be decoupled, i.e. how a separate or dedicated auth-server component, or Supabase Auth, gets discovered.

OAuth 2.0 Authorization Server Metadata (RFC 8414), or equivalently OpenID Connect Discovery, has to be published by the authorization server named above, at `.well-known/oauth-authorization-server` (or `.well-known/openid-configuration`), again with path-based variants for tenant or sub-path deployments. This is where `authorization_endpoint`, `token_endpoint`, `registration_endpoint` (if DCR is supported), `code_challenge_methods_supported`, and the CIMD-related `client_id_metadata_document_supported` / `token_endpoint_auth_methods_supported` fields (see §1) live.

Clients do discovery in that order: hit the protected MCP endpoint unauthenticated, read `WWW-Authenticate`, fetch protected-resource metadata, follow `authorization_servers`, fetch authorization-server metadata, then run the authorization code plus PKCE flow against whatever endpoints that metadata names.

For Drachma, the resource server (Drachma's MCP endpoint) and the authorization server don't have to be the same service, but the resource server does need to publish the RFC 9728 document pointing at whichever service is the authorization server. Supabase Auth would need to be reachable as that authorization server and expose RFC 8414 metadata, or OIDC discovery, which it already does at `/.well-known/openid-configuration` since it's OIDC-compliant, at a stable URL Drachma's server can list under `authorization_servers`.

## 4. How the token scopes subsequent tool calls to one user

The spec is explicit about audience, which server can accept the token, and leaves identity, which user the token represents, to standard OAuth resource-server practice.

Audience binding is explicit and MUST-level: "MCP servers MUST validate that access tokens were specifically issued for them as the intended audience, according to [RFC 8707 Section 2]," and "MUST only accept tokens specifically intended for themselves and MUST reject tokens that do not include them in the audience claim." This is what the `resource` parameter from §2 sets up. The authorization server is expected to mint a token whose audience claim, or equivalent for opaque tokens validated via introspection, is scoped to this one MCP server, so a token minted for a different resource server can't be replayed against Drachma's.

User binding follows from standard OAuth practice rather than MCP-specific normative text. The access token comes out of an Authorization Code flow the user completed interactively at the authorization server (they log into Drachma or Supabase Auth and consent). The token is scoped to that one authenticated user by construction, since it's a delegated-authority token, not a service credential. On each tool call, the MCP server validates the bearer token (locally if it's a JWT with a verifiable signature and `sub` claim, or via the authorization server's introspection endpoint if opaque), resolves the user id from it, and applies that identity to every downstream action in the request, the same way any OAuth resource server scopes API calls to the token's subject. Every distinct end user connecting through Claude or ChatGPT runs their own authorization-code flow and gets their own token. The "one connection, one user" property Drachma wants falls out of ordinary OAuth token issuance, not from an extra MCP-specific mechanism.

This second point is an inference from OAuth 2.1 and RFC 6750 resource-server norms that the MCP spec assumes by reference, not a distinct MCP clause. Flagged so it isn't mistaken for a directly quotable spec requirement the way §§1 through 3 are.

## Summary for the ticket

DCR is not required. The current (2025-11-25) spec ranks CIMD first, pre-registered or manual client credentials second, DCR third and optional. Anthropic's Claude connectors already implement this fallback order, and a single pre-registered OAuth client per assistant (one for Claude, one for ChatGPT) is spec-compliant, matching Anthropic's own documented second-choice mechanism.

The token flow is OAuth 2.1 Authorization Code plus mandatory PKCE (S256), with a mandatory `resource` parameter (RFC 8707) binding the token's audience to Drachma's MCP server, and mandatory refresh-token rotation for public clients.

A compliant server has to expose OAuth 2.0 Protected Resource Metadata (RFC 9728) at `.well-known/oauth-protected-resource`, returned via `WWW-Authenticate` on a 401, naming the authorization server(s). The authorization server has to expose RFC 8414 (or OIDC discovery) metadata. These can be two different services: Supabase Auth can act as the authorization server, since it already exposes OIDC discovery, as long as Drachma's MCP server publishes the RFC 9728 document pointing at it.

Per-user scoping of tool calls comes from validating the token's audience (server-side, MUST per RFC 8707) and resolving the authenticated subject from the token (`sub` or introspection). This is standard OAuth resource-server behavior the spec assumes rather than a new MCP-specific mechanism, but it's what makes "one OAuth connection equals one Drachma user" hold.
